"""Snapshot CDC ACM / UDC / RTU driver state in the healthy state and while the
J3 RTU session is wedged (host port kept open), via pyOCD gdbserver attach and a
batch GDB read of symbols from the programmed ELF. No flash, no reset. The core
is halted for each snapshot and resumed afterwards; the board is left running.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
elf = str(root / capture_profile.get("elf", "build/server/zephyr/zephyr.elf"))
max_attempts = int(capture_profile.get("max_attempts", 8))
code = r'''
import json, os, struct, subprocess, sys, time
from datetime import datetime, timezone
from pathlib import Path
import serial
root = Path.cwd(); sys.path.insert(0, str(root / "tools"))
from flash import passive_usb_inventory

PROBE = "13010000003800F1047546CF0000065D"
GDB = os.path.expanduser("~/.embedder/tools/gdb/xpack-arm-none-eabi-gcc-15.2.1-1.1-darwin-arm64/bin/arm-none-eabi-gdb-py3")

def crc16(data):
    crc = 0xFFFF
    for b in data:
        crc ^= b
        for _ in range(8):
            crc = (crc >> 1) ^ 0xA001 if crc & 1 else crc >> 1
    return struct.pack("<H", crc)

def adu(unit, pdu):
    body = bytes([unit]) + pdu
    return body + crc16(body)

def xfer(s, pdu, expect_len, timeout=1.0):
    s.reset_input_buffer(); s.timeout = timeout
    s.write(adu(10, pdu)); s.flush()
    rx = s.read(expect_len); s.timeout = 0.05
    return rx + s.read(256)

def burst(s):
    n = 0
    for rep in range(3):
        if len(xfer(s, bytes([16, 0, 0, 0, 16, 32]) + bytes(32), 8)) != 8:
            return n
        n += 1
        for i in range(16):
            v = (0x1234 + 0x1111 * i) & 0xFFFF
            if len(xfer(s, bytes([6, 0, i]) + struct.pack(">H", v), 8)) != 8:
                return n
            n += 1
            if len(xfer(s, bytes([3, 0, 0, 0, 16]), 37)) != 37:
                return n
            n += 1
    return -1

EXPRS = [
    "$pc", "uart_data_0.state", "uart_data_0.session_closed", "uart_data_0.session_purged",
    "uart_data_0.dtr_closed", "uart_data_0.echo_mitigated", "uart_data_0.zlp_needed",
    "uart_data_0.line_state", "uart_data_0.rx_enqueued", "uart_data_0.notif_enqueued",
    "uart_data_0.tx_fifo", "uart_data_0.rx_fifo",
    "uart_data_0.tx_fifo.current ? *uart_data_0.tx_fifo.current : *(struct net_buf *)0",
    "uart_data_0.tx_fifo_work", "uart_data_0.irq_cb_work", "uart_data_0.rx_fifo_work",
    "cdc_acm_tx_pool_0", "cdc_acm_rx_pool_0", "cdc_acm_uart_rx_fifo0",
    "rtu._private.io_enabled", "rtu._private.reset", "rtu._private.tx_pending",
    "rtu._private.tx_len", "rtu._private.tx_offset", "rtu._private.tx_deadline",
    "rtu._private.io_error", "rtu._private.rx_count", "rtu._private.rx_overflow",
    "rtu._private.frame_len", "rtu._private.cdc_discard", "rtu._private.frame_invalid",
    "rtu._private.state", "rtu._private.wake",
    "udc_priv_0", "numaker_usbd_ep_pool_0",
    "*(uint32_t *)0x40080000@16",
]

def gdb_snapshot(label):
    srv = subprocess.Popen([str(root / ".venv/bin/pyocd"), "gdbserver", "--uid", PROBE,
                            "--target", "cortex_m", "--no-config", "--connect", "attach",
                            "--port", "3339", "--no-wait", "-O", "auto_unlock=false",
                            "-O", "resume_on_disconnect=false", "-O", "frequency=1000000",
                            "-O", "cache.enable_memory=false", "-O", "cache.read_code_from_elf=false"],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    out = ""
    deadline = time.monotonic() + 20
    try:
        while time.monotonic() < deadline:
            line = srv.stdout.readline()
            if not line:
                break
            out += line
            if "GDB server started on port" in line:
                break
        else:
            raise RuntimeError("gdbserver did not start: " + out)
        args = [GDB, "-q", "-batch", "-ex", "set pagination off", "-ex", "set print pretty on",
                "-ex", "set print elements 400", "-ex", "set confirm off",
                "-ex", "target remote 127.0.0.1:3339", "-ex", "p/x $pc"]
        for e in EXPRS:
            args += ["-ex", 'echo \\n=== %s ===\\n' % e.replace("\\", "\\\\").replace('"', '\\"'), "-ex", "p " + e]
        args += ["-ex", "continue &", "-ex", "shell sleep 0.3", "-ex", "detach", ELF]
        g = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120)
        return {"label": label, "gdb": g.stdout, "gdb_exit": g.returncode, "server_log": out}
    finally:
        srv.terminate()
        try:
            srv.wait(10)
        except subprocess.TimeoutExpired:
            srv.kill()

devs = [d for d in passive_usb_inventory()["devices"] if d["vid"] == 0x0416 and d["pid"] == 0xB002
        and d["serial"] == "00010031047B4B1F00000003"]
if len(devs) != 1 or len(devs[0]["ports"]) != 1:
    raise RuntimeError("expected exactly one identity-matched J3 ACM port")
port = devs[0]["ports"][0]
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "port": port, "elf": ELF, "snapshots": []}
wedged = False
with serial.Serial(port, 115200, timeout=1.0, write_timeout=1.0, exclusive=True) as s:
    s.dtr = True; time.sleep(0.2); s.reset_input_buffer()
    info["healthy_reply_len"] = len(xfer(s, bytes([3, 0, 0, 0, 1]), 7))
    info["snapshots"].append(gdb_snapshot("healthy"))
    time.sleep(0.3)
    info["healthy_after_snapshot_reply_len"] = len(xfer(s, bytes([3, 0, 0, 0, 1]), 7))
    for attempt in range(MAX_ATTEMPTS):
        n = burst(s)
        info.setdefault("attempts", []).append(n)
        if n >= 0:
            wedged = True
            break
    if wedged:
        time.sleep(0.5)
        info["wedged_reply_len"] = len(xfer(s, bytes([3, 0, 0, 0, 1]), 7))
        info["snapshots"].append(gdb_snapshot("wedged"))
        time.sleep(0.3)
        info["wedged_after_snapshot_reply_len"] = len(xfer(s, bytes([3, 0, 0, 0, 1]), 7))
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"rtu-wedge-gdb-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
for snap in info["snapshots"]:
    print("##### " + snap["label"] + " (gdb exit %s)" % snap["gdb_exit"])
    print("--- server: " + snap.get("server_log", "").strip().replace("\n", " | "))
    print(snap["gdb"])
print(json.dumps({k: v for k, v in info.items() if k != "snapshots"}))
print(json.dumps({"success": wedged, "summary": "wedged=%s snapshots=%d" % (wedged, len(info["snapshots"]))}))
'''
code = "MAX_ATTEMPTS = %d\nELF = %r\n" % (max_attempts, elf) + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "gdb snapshot script did not complete"}))
