"""Does a VCOM BREAK make the Nu-Link2-Me pulse target nRESET?

Read-only on the target: DHCSR.S_RESET_ST is sticky-clear-on-read, so read it
once to clear, send a 10 ms BREAK on the VCOM, read it again. No halt, reset
request, memory or flash write from the debug side.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
code = r'''
import json, sys
from datetime import datetime, timezone
from pathlib import Path
from time import sleep, monotonic
import serial
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort
from pyocd.coresight.ap import AccessPort, APv1Address

root = Path.cwd()
sys.path.insert(0, str(root / "tools"))
from flash import passive_usb_inventory

probe_id = "13010000003800F1047546CF0000065D"
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": probe_id, "steps": []}
devices = [d for d in passive_usb_inventory()["devices"]
           if d["vid"] == 0x0416 and d["pid"] == 0x2004 and d["serial"] == probe_id]
if len(devices) != 1 or len(devices[0]["ports"]) != 1:
    raise RuntimeError("Expected one identity-matched Nu-Link VCOM")
path = devices[0]["ports"][0]
port = serial.Serial(path, 115200, timeout=0.2, write_timeout=1.0, exclusive=True)
probes = ConnectHelper.get_all_connected_probes(blocking=False, unique_id=probe_id)
if len(probes) != 1:
    raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
p = probes[0]
session = Session(p, auto_open=False, options={"no_config": True, "target_override": "cortex_m",
                                               "auto_unlock": False, "frequency": 1000000})
p.open()
try:
    p.set_clock(1000000)
    dp = DebugPort(p, session.target)
    dp.connect()
    ap = AccessPort.create(dp, APv1Address(0))
    ap.init()
    def dhcsr(tag):
        v = ap.read32(0xE000EDF0)
        info["steps"].append({"tag": tag, "DHCSR": hex(v), "S_RESET_ST": bool(v & (1 << 25)),
                              "S_LOCKUP": bool(v & (1 << 19))})
        return v
    dhcsr("initial (clears sticky)")
    dhcsr("second read (should be clear)")
    port.reset_input_buffer()
    port.break_condition = True
    sleep(0.010)
    port.break_condition = False
    t = monotonic()
    dhcsr("immediately after BREAK")
    sleep(0.1)
    dhcsr("100 ms after BREAK")
    info["uart_bytes_after_break"] = port.read(64).hex()
    # second mechanism: DTR toggle
    dhcsr("before DTR toggle")
    port.dtr = False
    sleep(0.05)
    port.dtr = True
    sleep(0.05)
    dhcsr("after DTR toggle")
    port.rts = True
    sleep(0.05)
    port.rts = False
    sleep(0.05)
    dhcsr("after RTS toggle")
finally:
    try:
        p.disconnect()
    finally:
        p.close()
    port.close()
out = root / ".embedder/hardware/results" / ("break-reset-check-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".json")
out.write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
reset_seen = any(s["S_RESET_ST"] for s in info["steps"][2:])
print(json.dumps({"success": True, "summary": "VCOM BREAK/DTR/RTS reset detection: reset_seen=%s" % reset_seen}))
'''
result = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(result.get("output", ""))
if result.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "break reset check process failed"}))
