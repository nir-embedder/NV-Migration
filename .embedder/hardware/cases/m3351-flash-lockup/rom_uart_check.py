"""Bounded MaskROM UART identification through the identity-matched Nu-Link VCOM.

No flash/config write, BREAK, probe firmware or security operation. Opening and
closing VCOM changes modem-control state. An optional hardware reset is explicit.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
reset_before_sync = capture_profile.get("reset_before_sync", False)
if type(reset_before_sync) is not bool:
    raise ValueError("reset_before_sync must be Boolean")
baud = capture_profile.get("baud", 115200)
if type(baud) is not int or baud not in (115200, 230400, 460800, 921600):
    raise ValueError("Use a baud rate present in the audited vendor UART menu")
code = r'''
import json
from datetime import datetime, timezone
from pathlib import Path
import sys
import serial

root = Path.cwd()
sys.path.insert(0, str(root / "tools"))
from flash import passive_usb_inventory
from bootloader_protocol import BootloaderUartSession

probe_id = "13010000003800F1047546CF0000065D"
result = {"timestamp": datetime.now(timezone.utc).isoformat(),
          "probe": probe_id, "baud": BAUD, "reset_before_sync": RESET,
          "dtr": True, "rts": False, "break": False,
          "scope": "UART synchronization and identification only; no erase/program/config/security writes",
          "stage": "inventory", "success": False}
port = None
try:
    devices = [d for d in passive_usb_inventory()["devices"]
               if d["vid"] == 0x0416 and d["pid"] == 0x2004
               and d["serial"] == probe_id]
    if len(devices) != 1 or len(devices[0]["ports"]) != 1:
        raise RuntimeError("Expected one identity-matched Nu-Link VCOM; do not guess a port")
    result["usb_device"] = devices[0]
    path = devices[0]["ports"][0]
    if not path.startswith("/dev/cu."):
        raise RuntimeError("Expected a macOS callout serial endpoint")
    result["port"] = path
    result["stage"] = "serial_open"
    port = serial.Serial(port=None, baudrate=BAUD, bytesize=8, parity="N", stopbits=1,
                         timeout=1.0, write_timeout=1.0, rtscts=False, dsrdtr=False,
                         xonxoff=False, exclusive=True)
    port.dtr = True
    port.rts = False
    port.port = path
    port.open()
    protocol = BootloaderUartSession(port, expected_pdid=0x03302140)

    def identify():
        result["stage"] = "synchronize"
        protocol.synchronize()
        result["synchronized"] = True
        result["stage"] = "identify"
        identity = protocol.connect()
        result["identity_words"] = [hex(word) for word in identity.words]
        result["pdid"] = hex(identity.pdid)
        result["success"] = True
        result["stage"] = "identified"

    if RESET:
        result["stage"] = "hardware_reset"
        from pyocd.core.helpers import ConnectHelper
        from pyocd.core.session import Session
        from pyocd.probe.debug_probe import DebugProbe
        probes = ConnectHelper.get_all_connected_probes(blocking=False, unique_id=probe_id)
        if len(probes) != 1:
            raise RuntimeError("Expected unique CMSIS-DAP probe for the explicitly requested reset")
        probe = probes[0]
        session = Session(probe, auto_open=False, options={
            "target_override": "cortex_m", "no_config": True,
            "user_script": "/dev/null", "auto_unlock": False,
            "reset.post_delay": 0.0})
        probe.open()
        try:
            probe.connect(DebugProbe.Protocol.SWD)
            try:
                probe.reset()
                result["hardware_reset_completed"] = True
                result["post_reset_delay_seconds"] = 0.0
                result["probe_held_until_identification"] = True
                identify()
            finally:
                probe.disconnect()
        finally:
            probe.close()
    else:
        identify()
except (Exception, KeyboardInterrupt) as exc:
    result["error"] = f"{type(exc).__name__}: {exc}"
finally:
    if port is not None:
        try:
            port.close()
        except Exception as exc:
            result["close_error"] = f"{type(exc).__name__}: {exc}"
            result["success"] = False
    output = root / ".embedder/hardware/results" / ("rom-uart-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".json")
    output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    print(json.dumps({"success": result["success"], "summary": "UART MaskROM identification: " + result["stage"]}))
'''
code = "RESET = " + repr(reset_before_sync) + "\nBAUD = " + repr(baud) + "\n" + code
result = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(result.get("output", ""))
if result.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "UART diagnostic process failed; no programming requested"}))
