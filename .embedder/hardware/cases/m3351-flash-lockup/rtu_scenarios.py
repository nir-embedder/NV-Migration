"""Isolated RTU scenarios on the native J3 ACM port, one fresh port open each
(DTR cycle resets the server session). Each scenario: FC6 writes, then an FC3
read; record which step first gets no reply. No flashing, no reset.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
scenarios = capture_profile.get("scenarios")
if scenarios is None:
    scenarios = [
        {"name": "abcd_at9_read16", "writes": [[9, 0xABCD]], "read": [0, 16]},
        {"name": "abcd_at0_read1", "writes": [[0, 0xABCD]], "read": [0, 1]},
        {"name": "abcd_at0_read16", "writes": [[0, 0xABCD]], "read": [0, 16]},
        {"name": "9abc_at8_abcd_at9_read16", "writes": [[8, 0x9ABC], [9, 0xABCD]], "read": [0, 16]},
        {"name": "cdab_at9_read16", "writes": [[9, 0xCDAB]], "read": [0, 16]},
        {"name": "beef_at9_read16", "writes": [[9, 0xBEEF]], "read": [0, 16]},
        {"name": "abcd_at9_read_9_1", "writes": [[9, 0xABCD]], "read": [9, 1]},
        {"name": "abcd_at9_read_0_9", "writes": [[9, 0xABCD]], "read": [0, 9]},
    ]
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
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "port": port, "scenarios": []}

def xfer(s, pdu, expect_len):
    s.reset_input_buffer()
    frame = adu(10, pdu)
    s.timeout = 1.0
    s.write(frame); s.flush()
    rx = s.read(expect_len)
    s.timeout = 0.05
    rx += s.read(256)
    return frame, rx

for sc in SCENARIOS:
    rec = {"name": sc["name"], "steps": []}
    with serial.Serial(port, 115200, timeout=1.0, write_timeout=1.0, exclusive=True) as s:
        s.dtr = True
        time.sleep(0.2)
        s.reset_input_buffer()
        # zero the map first so content is exactly the scenario's
        tx, rx = xfer(s, bytes([16, 0, 0, 0, 16, 32]) + bytes(32), 8)
        rec["steps"].append({"step": "zero16", "rx_len": len(rx)})
        ok = len(rx) == 8
        for addr, val in sc["writes"]:
            if not ok: break
            tx, rx = xfer(s, bytes([6, 0, addr]) + struct.pack(">H", val), 8)
            rec["steps"].append({"step": "fc6_%d_%04x" % (addr, val), "rx": rx.hex(), "rx_len": len(rx)})
            ok = len(rx) == 8
        if ok:
            a, q = sc["read"]
            tx, rx = xfer(s, bytes([3, 0, a, 0, q]), 5 + 2 * q)
            rec["steps"].append({"step": "fc3_%d_%d" % (a, q), "rx": rx.hex(), "rx_len": len(rx)})
            ok = len(rx) == 5 + 2 * q
            if ok:
                tx, rx = xfer(s, bytes([6, 0, 15, 0xBE, 0xEF]), 8)
                rec["steps"].append({"step": "fc6_after", "rx_len": len(rx)})
                ok = len(rx) == 8
    rec["ok"] = ok
    info["scenarios"].append(rec)
    print("%-28s %s  %s" % (sc["name"], "OK  " if ok else "WEDGE", " ".join("%s:%d" % (st["step"], st["rx_len"]) for st in rec["steps"])))
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"rtu-scenarios-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
bad = [r["name"] for r in info["scenarios"] if not r["ok"]]
print(json.dumps({"success": True, "summary": "scenarios wedged: %s" % bad}))
'''
code = "SCENARIOS = %r\n" % scenarios + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "scenario probe did not complete"}))
