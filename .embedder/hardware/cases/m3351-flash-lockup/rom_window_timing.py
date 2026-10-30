"""How long after an nRESET release (with the DP powered DOWN during reset) does
LOCKUP appear? Powers the DP up immediately after release and timestamps DHCSR
reads. Debug-register reads and DP power control only; no halt, no writes to
flash/config/security/RAM.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
runs = int(capture_profile.get("runs", 3))
sample_ms = int(capture_profile.get("sample_ms", 300))
code = r'''
import json
from datetime import datetime, timezone
from pathlib import Path
from time import monotonic, sleep
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort, DP_CTRL_STAT
from pyocd.coresight.ap import AccessPort, APv1Address
from pyocd.probe.debug_probe import DebugProbe

PROBE = "13010000003800F1047546CF0000065D"
DHCSR = 0xE000EDF0
root = Path.cwd()
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE,
        "method": "DP down during nRESET; DP power-up right after release; DHCSR polling", "runs": []}
probes = ConnectHelper.get_all_connected_probes(blocking=False, unique_id=PROBE)
if len(probes) != 1:
    raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
p = probes[0]
s = Session(p, auto_open=False, options={"no_config": True, "target_override": "cortex_m",
                                         "auto_unlock": False, "frequency": 1000000,
                                         "resume_on_disconnect": False})
p.open()
p.connect(DebugProbe.Protocol.SWD)
dp = DebugPort(p, s.target)
try:
    for run in range(RUNS):
        rec = {"run": run, "rows": []}
        dp.connect()
        ap = AccessPort.create(dp, APv1Address(0))
        ap.init()
        v = ap.read32(DHCSR); v = ap.read32(DHCSR)
        rec["dhcsr_before"] = hex(v)
        dp.power_down_debug()
        rec["ctrl_stat_down"] = hex(dp.read_reg(DP_CTRL_STAT))
        p.assert_reset(True)
        sleep(0.02)
        t0 = monotonic()
        p.assert_reset(False)
        dp.connect()
        ap = AccessPort.create(dp, APv1Address(0))
        ap.init()
        rec["dp_up_ms"] = round((monotonic() - t0) * 1000, 2)
        last = None
        deadline = t0 + SAMPLE_MS / 1000.0
        n = 0
        first_lockup = None
        while monotonic() < deadline:
            try:
                v = ap.read32(DHCSR)
            except Exception as exc:
                v = None
            t = round((monotonic() - t0) * 1000, 2)
            n += 1
            key = hex(v) if v is not None else "ERR"
            if key != last:
                rec["rows"].append({"t_ms": t, "dhcsr": key})
                last = key
            if v is not None and (v & (1 << 19)) and first_lockup is None:
                first_lockup = t
        rec["samples"] = n
        rec["first_lockup_ms"] = first_lockup
        rec["dauth_after"] = hex(ap.read32(0xE000EFB8))
        info["runs"].append(rec)
        sleep(0.2)
    dp.power_down_debug()
finally:
    p.disconnect()
    p.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"rom-window-timing-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
print(json.dumps({"success": True, "summary": "ROM window timing: first_lockup_ms=" + str([r["first_lockup_ms"] for r in info["runs"]])}))
'''
code = "RUNS = %d\nSAMPLE_MS = %d\n" % (runs, sample_ms) + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "ROM window timing did not complete"}))
