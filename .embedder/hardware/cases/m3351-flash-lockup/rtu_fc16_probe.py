"""Raw pySerial reproduction of the FC16 (write 16 registers) no-response case on
the native J3 CDC ACM port: FC3 read, FC16 write of N words, FC3 read again,
then FC6 to see whether the server still answers. Identity-matched port.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
quantities = capture_profile.get("quantities", [1, 4, 8, 12, 16])
code = r'''
import json, struct, sys, time
from datetime import datetime, timezone
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

devs = [d for d in passive_usb_inventory()["devices"] if d["vid"] == 0x0416 and d["pid"] == 0xB002
        and d["serial"] == "00010031047B4B1F00000003"]
if len(devs) != 1 or len(devs[0]["ports"]) != 1:
    raise RuntimeError("expected exactly one identity-matched J3 ACM port")
port = devs[0]["ports"][0]
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "port": port, "steps": []}

def xfer(s, name, pdu, expect_len, timeout=1.0):
    s.reset_input_buffer()
    frame = adu(10, pdu)
    t0 = time.monotonic()
    s.write(frame); s.flush()
    s.timeout = timeout
    rx = s.read(expect_len)
    # drain anything extra
    s.timeout = 0.05
    rx += s.read(256)
    rec = {"step": name, "tx": frame.hex(), "tx_len": len(frame), "rx": rx.hex(), "rx_len": len(rx),
           "ms": round((time.monotonic() - t0) * 1000, 1)}
    info["steps"].append(rec)
    return rx

with serial.Serial(port, 115200, timeout=1.0, write_timeout=1.0, exclusive=True) as s:
    s.dtr = True
    time.sleep(0.2)
    s.reset_input_buffer()
    xfer(s, "fc3_read16_before", bytes([3, 0, 0, 0, 16]), 3 + 32 + 2)
    for i in range(FC6_SWEEP):
        v = (BASE + STEP * i) & 0xFFFF
        rx = xfer(s, "fc6_w%d_%04x" % (i, v), bytes([6, 0, i]) + struct.pack(">H", v), 8)
        if not rx:
            break
        rx = xfer(s, "fc3_after_w%d" % i, bytes([3, 0, 0, 0, 16]), 37)
        if not rx:
            break
    for q in QUANTITIES:
        vals = b"".join(struct.pack(">H", (BASE + STEP * i) & 0xFFFF) for i in range(q))
        pdu = bytes([16, 0, 0, 0, q, 2 * q]) + vals
        rx = xfer(s, "fc16_write_%d" % q, pdu, 8)
        xfer(s, "fc3_read16_after_%d" % q, bytes([3, 0, 0, 0, 16]), 3 + 32 + 2)
        xfer(s, "fc6_after_%d" % q, bytes([6, 0, 15, 0xBE, 0xEF]), 8)
    # restore zero map
    xfer(s, "fc16_zero16", bytes([16, 0, 0, 0, 16, 32]) + bytes(32), 8)
    xfer(s, "fc3_read16_final", bytes([3, 0, 0, 0, 16]), 3 + 32 + 2)
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"rtu-fc16-probe-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
for st in info["steps"]:
    print("%-24s tx=%3d rx=%3d %7.1fms %s" % (st["step"], st["tx_len"], st["rx_len"], st["ms"], st["rx"][:40]))
bad = [st["step"] for st in info["steps"] if st["rx_len"] == 0]
print(json.dumps({"success": not bad, "summary": "fc16 probe: no-response steps=%s" % bad}))
'''
code = "QUANTITIES = %r\nBASE = %d\nSTEP = %d\nFC6_SWEEP = %d\n" % (
    list(quantities), int(capture_profile.get("base", 0x1000)), int(capture_profile.get("step", 1)),
    int(capture_profile.get("fc6_sweep", 0))) + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "fc16 probe did not complete"}))
