"""Reproduce the RTU wedge with raw libusb bulk transfers, bypassing AppleUSBSerial.

Reports the exact libusb error on the failing bulk IN, the packet lengths seen, and
whether CLEAR_FEATURE(ENDPOINT_HALT) on the bulk IN endpoint recovers traffic.
No programming, no debug probe; J3 ACM data interface only.
"""
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[4]
code = r'''
import json, struct, sys, time
from datetime import datetime, timezone
from pathlib import Path
import usb.core, usb.util, libusb_package

root = Path.cwd()
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

info = {"timestamp": datetime.now(timezone.utc).isoformat(), "steps": []}
dev = usb.core.find(idVendor=0x0416, idProduct=0xB002, backend=libusb_package.get_libusb1_backend())
if dev is None:
    raise RuntimeError("J3 device not found")
cfg = dev.get_active_configuration()
data_if = cfg[(1, 0)]
eps = {e.bEndpointAddress: e for e in data_if}
ep_in = [a for a in eps if a & 0x80][0]
ep_out = [a for a in eps if not a & 0x80][0]
info["ep_in"], info["ep_out"] = hex(ep_in), hex(ep_out)
try:
    if dev.is_kernel_driver_active(1):
        dev.detach_kernel_driver(1)
        info["detached_kernel_driver"] = True
except Exception as exc:
    info["detach_error"] = repr(exc)
usb.util.claim_interface(dev, 1)
info["claimed"] = True
# DTR high so the session-isolated CDC ACM class accepts traffic.
# AppleUSBSerial holds the communication interface (0); the class instance also
# owns the data interface (1), so address the request there.
try:
    dev.ctrl_transfer(0x21, 0x22, 0x0003, 1, None, 1000)
    info["dtr_set"] = "wIndex=1 ok"
except usb.core.USBError as exc:
    info["dtr_set"] = repr(exc)
time.sleep(0.2)

def drain():
    n = 0
    try:
        while True:
            r = dev.read(ep_in, 64, 50); n += len(r)
    except usb.core.USBTimeoutError:
        pass
    return n

def xfer(pdu, label, expect):
    rec = {"step": label}
    dev.write(ep_out, adu(10, pdu), 1000)
    rx = bytearray(); t0 = time.monotonic(); pkts = []
    try:
        while len(rx) < expect and time.monotonic() - t0 < 1.0:
            r = dev.read(ep_in, 64, 1000)
            pkts.append(len(r)); rx += bytes(r)
    except usb.core.USBError as exc:
        rec["error"] = repr(exc); rec["errno"] = getattr(exc, "errno", None)
        rec["backend_error_code"] = getattr(exc, "backend_error_code", None)
    rec["rx_len"] = len(rx); rec["packets"] = pkts; rec["ms"] = round((time.monotonic() - t0) * 1000, 1)
    info["steps"].append(rec)
    return rec

drain()
xfer(bytes([16, 0, 0, 0, 16, 32]) + bytes(32), "zero16", 8)
failed = None
for i in range(16):
    v = (0x1234 + 0x1111 * i) & 0xFFFF
    r = xfer(bytes([6, 0, i]) + struct.pack(">H", v), "fc6_%d" % i, 8)
    if r["rx_len"] != 8:
        failed = r; break
    r = xfer(bytes([3, 0, 0, 0, 16]), "fc3_after_%d" % i, 37)
    if r["rx_len"] != 37:
        failed = r; break
info["failed"] = failed
if failed is not None:
    # Is the IN endpoint halted from the host's point of view? Try plain re-read, then clear halt.
    r2 = xfer(bytes([3, 0, 0, 0, 1]), "retry_fc3_1", 7)
    try:
        dev.clear_halt(ep_in); info["clear_halt_in"] = "ok"
    except usb.core.USBError as exc:
        info["clear_halt_in"] = repr(exc)
    r3 = xfer(bytes([3, 0, 0, 0, 1]), "after_clear_halt_fc3_1", 7)
    info["recovered_after_clear_halt"] = r3["rx_len"] == 7
    if r3["rx_len"] == 7:
        # Does the *same* content fail again right away (deterministic)?
        xfer(bytes([3, 0, 0, 0, 16]), "again_fc3_0_16", 37)
# Restore
xfer(bytes([16, 0, 0, 0, 16, 32]) + bytes(32), "zero16_restore", 8)
usb.util.release_interface(dev, 1)
try:
    dev.attach_kernel_driver(1); info["reattached"] = True
except Exception as exc:
    info["reattach_error"] = repr(exc)
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"rtu-wedge-libusb-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=1)[:6000])
print(json.dumps({"success": True, "summary": "libusb repro: failed=%s clear_halt=%s recovered=%s" % (
    (failed or {}).get("step"), info.get("clear_halt_in"), info.get("recovered_after_clear_halt"))}))
'''
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", "")[-12000:])
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "libusb repro did not complete"}))
