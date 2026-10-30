"""Provoke the RTU burst wedge on the J3 ACM port, then discriminate whether the
device still accepts OUT data (TX-side wedge) or NAKs it (RX-side wedge) by
timing a large host write. Also checks whether the wedge clears after waiting
without a DTR cycle. No flashing, no reset.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
max_attempts = int(capture_profile.get("max_attempts", 8))
big = int(capture_profile.get("big_bytes", 65536))
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
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "port": port, "attempts": []}

def xfer(s, pdu, expect_len, timeout=1.0):
    s.reset_input_buffer()
    s.timeout = timeout
    s.write(adu(10, pdu)); s.flush()
    rx = s.read(expect_len)
    s.timeout = 0.05
    return rx + s.read(256)

def burst(s):
    """Return number of transactions completed before the first missing reply (or -1 if all ok)."""
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

wedged = False
for attempt in range(MAX_ATTEMPTS):
    with serial.Serial(port, 115200, timeout=1.0, write_timeout=1.0, exclusive=True) as s:
        s.dtr = True
        time.sleep(0.2)
        s.reset_input_buffer()
        n = burst(s)
        rec = {"attempt": attempt, "transactions_before_wedge": n}
        if n >= 0:
            wedged = True
            # 1) does it recover by itself after 3 s of silence?
            time.sleep(3.0)
            rec["after_3s_silence_reply_len"] = len(xfer(s, bytes([3, 0, 0, 0, 1]), 7))
            # 2) host OUT flow: big write with 3 s write timeout
            s.write_timeout = 3.0
            t0 = time.monotonic()
            try:
                s.write(bytes(BIG)); s.flush()
                rec["big_write"] = {"bytes": BIG, "ms": round((time.monotonic() - t0) * 1000, 1), "result": "accepted"}
            except serial.SerialTimeoutException:
                rec["big_write"] = {"bytes": BIG, "ms": round((time.monotonic() - t0) * 1000, 1), "result": "write_timeout"}
            s.write_timeout = 1.0
            time.sleep(0.5)
            rec["after_big_write_reply_len"] = len(xfer(s, bytes([3, 0, 0, 0, 1]), 7))
            # 3) DTR drop/raise without closing the port
            s.dtr = False; time.sleep(0.3); s.dtr = True; time.sleep(0.3)
            s.reset_input_buffer()
            rec["after_dtr_cycle_reply_len"] = len(xfer(s, bytes([3, 0, 0, 0, 1]), 7))
        info["attempts"].append(rec)
        print(json.dumps(rec))
        if wedged:
            break
# control: big write on a healthy session
with serial.Serial(port, 115200, timeout=1.0, write_timeout=3.0, exclusive=True) as s:
    s.dtr = True; time.sleep(0.2); s.reset_input_buffer()
    t0 = time.monotonic()
    try:
        s.write(bytes(BIG)); s.flush()
        info["healthy_big_write"] = {"bytes": BIG, "ms": round((time.monotonic() - t0) * 1000, 1), "result": "accepted"}
    except serial.SerialTimeoutException:
        info["healthy_big_write"] = {"bytes": BIG, "ms": round((time.monotonic() - t0) * 1000, 1), "result": "write_timeout"}
    time.sleep(0.5)
    info["healthy_after_big_write_reply_len"] = len(xfer(s, bytes([3, 0, 0, 0, 1]), 7))
print(json.dumps({k: v for k, v in info.items() if k != "attempts"}))
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"rtu-wedge-direction-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps({"success": wedged, "summary": "wedge provoked=%s" % wedged}))
'''
code = "MAX_ATTEMPTS = %d\nBIG = %d\n" % (max_attempts, big) + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "wedge-direction probe did not complete"}))
