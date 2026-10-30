"""Does the MaskROM enumerate a USB ISP HID device on J3 after a cold reset?

CONFIG3[9] USBISPDIS=0 (default) enables ROM USB ISP; the vendor tool's USB mode
polls VID 0x0416 PID 0x2000 then 0x200C. With the DP powered down, pulse nRESET
through the CMSIS-DAP pins and poll hidapi/IORegistry for any new 0x0416 device
other than the Nu-Link2 itself. Optionally identify it with the audited A0
command (read-only). No halt, no flash/config/security writes.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
attempts = int(capture_profile.get("attempts", 3))
poll_s = float(capture_profile.get("poll_s", 3.0))
identify = bool(capture_profile.get("identify", False))
code = r'''
import json, sys
from datetime import datetime, timezone
from pathlib import Path
from time import monotonic, sleep
import hid
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort, DP_CTRL_STAT
from pyocd.probe.debug_probe import DebugProbe

root = Path.cwd()
sys.path.insert(0, str(root / "tools"))
from bootloader_protocol import BootloaderHidSession, CONFIG_BASE

PROBE = "13010000003800F1047546CF0000065D"
NULINK_PID = 0x2004
result = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE,
          "scope": "DP power-down, nRESET pulses, HID enumeration polling; identify only if requested",
          "attempts": [], "stage": "init", "success": False, "identify_requested": IDENTIFY}
probe = None

def hid_snapshot():
    out = []
    for d in hid.enumerate(0x0416):
        if d["product_id"] == NULINK_PID:
            continue
        out.append({"pid": hex(d["product_id"]), "path": d["path"].decode(errors="replace"),
                    "interface": d["interface_number"], "product": d["product_string"],
                    "usage_page": d.get("usage_page"), "usage": d.get("usage")})
    return out

try:
    result["stage"] = "probe_open"
    probes = ConnectHelper.get_all_connected_probes(blocking=False, unique_id=PROBE)
    if len(probes) != 1:
        raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
    probe = probes[0]
    session = Session(probe, auto_open=False, options={
        "no_config": True, "target_override": "cortex_m", "auto_unlock": False,
        "frequency": 1000000, "resume_on_disconnect": False})
    probe.open()
    probe.connect(DebugProbe.Protocol.SWD)
    dp = DebugPort(probe, session.target)
    dp.connect()
    dp.power_down_debug()
    result["ctrl_stat_powered_down"] = hex(dp.read_reg(DP_CTRL_STAT))
    result["hid_before"] = hid_snapshot()
    result["stage"] = "pulse_and_poll"
    found = None
    for attempt in range(ATTEMPTS):
        rec = {"attempt": attempt, "seen": []}
        t0 = monotonic()
        probe.assert_reset(True)
        sleep(0.02)
        probe.assert_reset(False)
        deadline = monotonic() + POLL_S
        seen_paths = set()
        while monotonic() < deadline:
            snap = hid_snapshot()
            for d in snap:
                if d["path"] not in seen_paths:
                    seen_paths.add(d["path"])
                    d["first_seen_ms"] = round((monotonic() - t0) * 1000, 1)
                    rec["seen"].append(d)
                    if found is None:
                        found = d
            if found is not None and IDENTIFY:
                break
            sleep(0.02)
        rec["elapsed_ms"] = round((monotonic() - t0) * 1000, 1)
        result["attempts"].append(rec)
        if found is not None:
            break
    result["usb_isp_device"] = found
    if found is None:
        raise RuntimeError("no ROM USB ISP HID device appeared after nRESET pulses")
    if IDENTIFY:
        result["stage"] = "identify"
        h = hid.device()
        h.open_path(found["path"].encode())
        try:
            h.set_nonblocking(0)
            session_isp = BootloaderHidSession(h, expected_pdid=0x03302140)
            identity = session_isp.connect()
            result["identity_words"] = [hex(w) for w in identity.words]
            result["pdid"] = hex(identity.pdid)
            result["stage"] = "config_read"
            cfg = {}
            for i in (0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14):
                try:
                    cfg["CONFIG%d" % i] = hex(session_isp.read_config_word(CONFIG_BASE + 4 * i))
                except Exception as exc:
                    cfg["CONFIG%d" % i] = "error: %s: %s" % (type(exc).__name__, exc)
                    break
            result["config"] = cfg
        finally:
            h.close()
    result["success"] = True
    result["stage"] = "done"
except (Exception, KeyboardInterrupt) as exc:
    result["error"] = "%s: %s" % (type(exc).__name__, exc)
finally:
    if probe is not None:
        try:
            probe.disconnect()
            probe.close()
        except Exception as exc:
            result["probe_close_error"] = "%s: %s" % (type(exc).__name__, exc)
    out = root / ".embedder/hardware/results" / ("rom-usb-isp-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".json")
    out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    print(json.dumps({"success": result["success"], "summary": "ROM USB ISP probe: " + result["stage"] + ("; device=" + str(result.get("usb_isp_device", {}).get("pid")) if result.get("usb_isp_device") else "; no device")}))
'''
code = "ATTEMPTS = %d\nPOLL_S = %r\nIDENTIFY = %r\n" % (attempts, poll_s, identify) + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "ROM USB ISP probe process failed"}))
