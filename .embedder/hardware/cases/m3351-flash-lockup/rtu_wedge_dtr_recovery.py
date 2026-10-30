"""Provoke the RTU burst wedge, then measure whether and how fast a DTR drop/raise
on the still-open port recovers replies (polling up to 5 s), and whether a port
close/reopen does. No flashing, no reset, no probe.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
max_attempts = int(capture_profile.get("max_attempts", 8))
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

def poll_recovery(s, max_s):
    t0 = time.monotonic()
    while time.monotonic() - t0 < max_s:
        if len(xfer(s, bytes([3, 0, 0, 0, 1]), 7, timeout=0.25)) == 7:
            return round((time.monotonic() - t0) * 1000, 1)
    return None

devs = [d for d in passive_usb_inventory()["devices"] if d["vid"] == 0x0416 and d["pid"] == 0xB002
        and d["serial"] == "00010031047B4B1F00000003"]
if len(devs) != 1 or len(devs[0]["ports"]) != 1:
    raise RuntimeError("expected exactly one identity-matched J3 ACM port")
port = devs[0]["ports"][0]
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "port": port, "runs": []}
with serial.Serial(port, 115200, timeout=1.0, write_timeout=1.0, exclusive=True) as s:
    s.dtr = True; time.sleep(0.2); s.reset_input_buffer()
    # control: DTR toggle on a healthy session, time to first reply afterwards
    assert len(xfer(s, bytes([3, 0, 0, 0, 1]), 7)) == 7, "board not healthy at start"
    s.dtr = False; time.sleep(0.3); s.dtr = True
    info["healthy_dtr_toggle_recover_ms"] = poll_recovery(s, 5.0)
    for attempt in range(MAX_ATTEMPTS):
        n = burst(s)
        rec = {"attempt": attempt, "transactions_before_wedge": n}
        if n >= 0:
            rec["silence_5s_recover_ms"] = poll_recovery(s, 5.0)
            s.dtr = False; time.sleep(0.3); s.dtr = True
            rec["dtr_toggle_recover_ms"] = poll_recovery(s, 5.0)
            if rec["dtr_toggle_recover_ms"] is None:
                s.dtr = False; time.sleep(1.5); s.dtr = True
                rec["dtr_toggle_long_recover_ms"] = poll_recovery(s, 5.0)
            info["runs"].append(rec); print(json.dumps(rec))
            break
        info["runs"].append(rec); print(json.dumps(rec))
if info["runs"] and info["runs"][-1]["transactions_before_wedge"] >= 0 and \
        info["runs"][-1].get("dtr_toggle_recover_ms") is None and \
        info["runs"][-1].get("dtr_toggle_long_recover_ms") is None:
    time.sleep(0.5)
    with serial.Serial(port, 115200, timeout=1.0, write_timeout=1.0, exclusive=True) as s:
        s.dtr = True
        info["close_reopen_recover_ms"] = poll_recovery(s, 5.0)
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"rtu-wedge-dtr-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps({k: v for k, v in info.items() if k != "runs"}))
wedged = bool(info["runs"]) and info["runs"][-1]["transactions_before_wedge"] >= 0
print(json.dumps({"success": wedged, "summary": "wedged=%s last=%s close_reopen=%s" % (
    wedged, info["runs"][-1] if info["runs"] else None, info.get("close_reopen_recover_ms"))}))
'''
code = "MAX_ATTEMPTS = %d\n" % max_attempts + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "DTR recovery probe did not complete"}))
