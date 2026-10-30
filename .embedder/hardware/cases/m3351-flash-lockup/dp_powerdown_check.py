"""Does the locked-up M3351 reset itself once the debug port is powered down?

TRM: CPU lockup normally causes an immediate chip reset, but not while ICE is
connected. Earlier raw MEM-AP scripts left CDBGPWRUPREQ/CSYSPWRUPREQ asserted.
This script: connect, clear sticky DHCSR bits, power the DP down, close the
probe, wait, reconnect and read DHCSR.S_RESET_ST. Debug-register reads/DP
control only; no core halt, no pin reset, no flash/config/security writes.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
wait_s = float(capture_profile.get("wait_s", 3.0))
code = r'''
import json, time
from datetime import datetime, timezone
from pathlib import Path
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort, DP_CTRL_STAT
from pyocd.coresight.ap import AccessPort, APv1Address

PROBE = "13010000003800F1047546CF0000065D"
DHCSR = 0xE000EDF0
root = Path.cwd()
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE,
        "method": "DP power-down then reconnect; DHCSR reads only", "wait_s": WAIT, "steps": []}

def open_dp():
    probes = ConnectHelper.get_all_connected_probes(blocking=False, unique_id=PROBE)
    if len(probes) != 1:
        raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
    p = probes[0]
    s = Session(p, auto_open=False, options={"no_config": True, "target_override": "cortex_m",
                                             "auto_unlock": False, "frequency": 1000000,
                                             "resume_on_disconnect": False})
    p.open()
    p.connect()
    dp = DebugPort(p, s.target)
    dp.connect()
    ap = AccessPort.create(dp, APv1Address(0))
    ap.init()
    return p, dp, ap

def dhcsr(ap, tag):
    v = ap.read32(DHCSR)
    step = {"tag": tag, "DHCSR": hex(v), "S_RESET_ST": bool(v & (1 << 25)),
            "S_LOCKUP": bool(v & (1 << 19)), "S_HALT": bool(v & (1 << 17))}
    info["steps"].append(step)
    return step

p, dp, ap = open_dp()
try:
    dhcsr(ap, "initial (clears sticky)")
    dhcsr(ap, "second read")
    info["ctrl_stat_before_powerdown"] = hex(dp.read_reg(DP_CTRL_STAT))
    dp.power_down_debug()
    info["ctrl_stat_after_powerdown"] = hex(dp.read_reg(DP_CTRL_STAT))
finally:
    p.disconnect()
    p.close()
time.sleep(WAIT)
p, dp, ap = open_dp()
try:
    first = dhcsr(ap, "after reconnect (sticky since power-down)")
    dhcsr(ap, "after reconnect, second read")
    info["ctrl_stat_after_reconnect"] = hex(dp.read_reg(DP_CTRL_STAT))
    info["reset_seen_while_dp_down"] = first["S_RESET_ST"]
    dp.power_down_debug()
finally:
    p.disconnect()
    p.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"dp-powerdown-check-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
print(json.dumps({"success": True, "summary": "DP power-down check: reset_seen_while_dp_down=" + str(info["reset_seen_while_dp_down"])}))
'''
result = run_tool([str(root / ".venv/bin/python"), "-c", "WAIT = " + repr(wait_s) + "\n" + code])
print(result.get("output", ""))
if result.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "DP power-down check did not complete"}))
