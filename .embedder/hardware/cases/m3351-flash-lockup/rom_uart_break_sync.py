"""MaskROM UART ISP connection the way NuvoISP_BL does it: no SWD session at all.

Vendor-audited flow (docs/validation.md, 415de0/409f70): open VCOM, SetCommBreak
10 ms, ClearCommBreak, wait 5*((attempt % 19) + 1) ms, send 62 x 'a', expect 'A'.
The Nu-Link2-Me VCOM converts the BREAK into a target reset; the ROM ISP routine
then listens on UART0 (PB.12/PB.13) for about 10 ms after boot.

Traffic after a successful sync is identification (A0) and CONFIG reads (D2)
only. No erase/program/config/security write, no probe/SWD operation.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
attempts = int(capture_profile.get("attempts", 19))
baud = int(capture_profile.get("baud", 115200))
stream = bool(capture_profile.get("stream", False))
code = r'''
import json, sys, struct
from datetime import datetime, timezone
from pathlib import Path
from time import monotonic, sleep
import serial

root = Path.cwd()
sys.path.insert(0, str(root / "tools"))
from flash import passive_usb_inventory
from bootloader_protocol import BootloaderUartSession, CONFIG_BASE

probe_id = "13010000003800F1047546CF0000065D"
result = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": probe_id,
          "baud": BAUD, "attempts_requested": ATTEMPTS, "stream": STREAM,
          "scope": "VCOM BREAK reset + UART sync + identify + CONFIG read; no SWD, no writes",
          "stage": "inventory", "success": False, "attempts": []}
port = None
try:
    devices = [d for d in passive_usb_inventory()["devices"]
               if d["vid"] == 0x0416 and d["pid"] == 0x2004 and d["serial"] == probe_id]
    if len(devices) != 1 or len(devices[0]["ports"]) != 1:
        raise RuntimeError("Expected one identity-matched Nu-Link VCOM")
    path = devices[0]["ports"][0]
    if not path.startswith("/dev/cu."):
        raise RuntimeError("Expected a macOS callout serial endpoint")
    result["port"] = path
    result["stage"] = "serial_open"
    port = serial.Serial(port=None, baudrate=BAUD, bytesize=8, parity="N", stopbits=1,
                         timeout=0.2, write_timeout=1.0, rtscts=False, dsrdtr=False,
                         xonxoff=False, exclusive=True)
    port.dtr = True
    port.rts = False
    port.port = path
    port.open()
    synced = False
    for attempt in range(ATTEMPTS):
        rec = {"attempt": attempt}
        port.reset_input_buffer()
        t0 = monotonic()
        rec["stage"] = "break"
        port.break_condition = True
        sleep(0.010)
        port.break_condition = False
        delay = 0.005 * ((attempt % 19) + 1)
        rec["delay_ms"] = round(delay * 1000, 1)
        if STREAM:
            # keep 'a' flowing across the ROM window instead of a single burst
            rec["stage"] = "stream"
            got = b""
            bursts = 0
            port.timeout = 0.003
            deadline = monotonic() + 0.4
            while monotonic() < deadline and not got:
                port.write(b"a" * 62)
                port.flush()
                bursts += 1
                got = port.read(1)
            port.timeout = 0.2
            rec["bursts"] = bursts
            rec["response"] = got.hex()
            rec["elapsed_ms"] = round((monotonic() - t0) * 1000, 1)
            if got == b"A":
                synced = True
        else:
            sleep(delay)
            rec["stage"] = "sync"
            port.write(b"a" * 62)
            port.flush()
            got = port.read(1)
            rec["response"] = got.hex()
            rec["elapsed_ms"] = round((monotonic() - t0) * 1000, 1)
            if got == b"A":
                synced = True
        result["attempts"].append(rec)
        if synced:
            break
    result["synchronized"] = synced
    if not synced:
        raise TimeoutError("no 'A' from ROM on any attempt")
    # drain anything else, then identify with the audited protocol adapter
    sleep(0.02)
    extra = port.read(64)
    result["bytes_after_sync"] = extra.hex()
    protocol = BootloaderUartSession(port, expected_pdid=0x03302140)
    protocol._synchronized = True
    result["stage"] = "identify"
    identity = protocol.connect()
    result["identity_words"] = [hex(w) for w in identity.words]
    result["pdid"] = hex(identity.pdid)
    result["stage"] = "config_read"
    cfg = {}
    for i in (0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14):
        addr = CONFIG_BASE + 4 * i
        try:
            cfg["CONFIG%d" % i] = hex(protocol.read_config_word(addr))
        except Exception as exc:
            cfg["CONFIG%d" % i] = "error: %s: %s" % (type(exc).__name__, exc)
            break
    result["config"] = cfg
    result["success"] = True
    result["stage"] = "done"
except (Exception, KeyboardInterrupt) as exc:
    result["error"] = "%s: %s" % (type(exc).__name__, exc)
finally:
    if port is not None:
        try:
            port.close()
        except Exception as exc:
            result["close_error"] = "%s: %s" % (type(exc).__name__, exc)
    out = root / ".embedder/hardware/results" / ("rom-uart-break-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".json")
    out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    print(json.dumps({"success": result["success"], "summary": "ROM UART via VCOM BREAK reset: " + result["stage"] + (" synced" if result.get("synchronized") else " no sync")}))
'''
code = "ATTEMPTS = %d\nBAUD = %d\nSTREAM = %r\n" % (attempts, baud, stream) + code
result = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(result.get("output", ""))
if result.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "UART ROM process failed; no programming requested"}))
