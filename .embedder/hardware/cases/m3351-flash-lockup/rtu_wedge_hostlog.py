"""Provoke the RTU wedge and collect the macOS unified log (USB / CDC / serial
subsystems) for the window around the wedge, to see whether the host halted or
errored the bulk IN pipe. No flashing, no reset, no probe. Port is closed at the
end so the board recovers.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
code = r'''
import json, struct, subprocess, sys, time
from datetime import datetime, timezone, timedelta
from pathlib import Path
import serial
root = Path.cwd(); sys.path.insert(0, str(root / "tools"))
from flash import passive_usb_inventory

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

devs = [d for d in passive_usb_inventory()["devices"] if d["vid"] == 0x0416 and d["pid"] == 0xB002
        and d["serial"] == "00010031047B4B1F00000003"]
if len(devs) != 1 or len(devs[0]["ports"]) != 1:
    raise RuntimeError("expected exactly one identity-matched J3 ACM port")
port = devs[0]["ports"][0]
start = datetime.now()
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "port": port}
with serial.Serial(port, 115200, timeout=1.0, write_timeout=1.0, exclusive=True) as s:
    s.dtr = True; time.sleep(0.2); s.reset_input_buffer()
    t_wedge = None
    for attempt in range(8):
        n = burst(s)
        if n >= 0:
            t_wedge = datetime.now()
            info["transactions_before_wedge"] = n
            break
    info["wedged"] = t_wedge is not None
    time.sleep(1.0)
    # one more request while wedged so the host-side error, if periodic, shows again
    info["wedged_reply_len"] = len(xfer(s, bytes([3, 0, 0, 0, 1]), 7))
    time.sleep(0.5)
end = datetime.now()
fmt = "%Y-%m-%d %H:%M:%S"
pred = ('(subsystem CONTAINS "usb" OR subsystem CONTAINS "serial" OR senderImagePath CONTAINS "USB" '
        'OR senderImagePath CONTAINS "CDC" OR eventMessage CONTAINS "CDC" OR eventMessage CONTAINS "usbmodem" '
        'OR eventMessage CONTAINS[c] "stall" OR eventMessage CONTAINS[c] "pipe")')
cmd = ["/usr/bin/log", "show", "--style", "compact", "--info", "--debug",
       "--start", (start - timedelta(seconds=2)).strftime(fmt), "--end", (end + timedelta(seconds=1)).strftime(fmt),
       "--predicate", pred]
res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120)
lines = [l for l in res.stdout.splitlines() if l.strip()]
info["log_line_count"] = len(lines)
info["t_wedge"] = t_wedge.strftime("%H:%M:%S.%f") if t_wedge else None
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
out = root / ".embedder/hardware/results" / f"rtu-wedge-hostlog-{stamp}.log"
out.write_text(json.dumps(info) + "\n" + res.stdout)
print(json.dumps(info))
keep = [l for l in lines if not l.startswith("Timestamp") and "Filtering" not in l]
for l in keep[-80:]:
    print(l[:300])
print(json.dumps({"success": info["wedged"], "summary": "wedged=%s host_log_lines=%d -> %s" % (info["wedged"], len(lines), out.name)}))
'''
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "host log probe did not complete"}))
