"""Pre-flight for the halted-in-ROM recovery state, using tools/flash.py's own
routines: CONFIG words via FMC ISP READ (volatile FMC/REGLOCK writes, restored),
FNSADDR, ISPSTS/VECMAP decode, protection registers, reversible 16-byte SRAM
scratch check. No erase/program/config/security writes, no reset, no resume.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
code = r'''
import json, sys
from datetime import datetime, timezone
from pathlib import Path
root = Path.cwd()
sys.path.insert(0, str(root / "tools"))
import flash as F
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort
from pyocd.coresight.ap import AccessPort, APv1Address
from pyocd.probe.debug_probe import DebugProbe

PROBE = "13010000003800F1047546CF0000065D"
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE,
        "method": "halted-in-ROM pre-flight; FMC READ of CONFIG, guards reported individually"}
probes = ConnectHelper.get_all_connected_probes(blocking=False, unique_id=PROBE)
if len(probes) != 1:
    raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
p = probes[0]
s = Session(p, auto_open=False, options={"no_config": True, "target_override": "cortex_m",
                                         "auto_unlock": False, "frequency": 1000000,
                                         "resume_on_disconnect": False})
p.open(); p.connect(DebugProbe.Protocol.SWD)
dp = DebugPort(p, s.target); dp.connect()
ap = AccessPort.create(dp, APv1Address(0)); ap.init()
try:
    dhcsr = ap.read32(0xE000EDF0)
    info["DHCSR"] = hex(dhcsr)
    info["DAUTHSTATUS"] = hex(ap.read32(F.DAUTHSTATUS))
    if not (dhcsr & (1 << 17)) or not (dhcsr & (1 << 20)):
        raise RuntimeError("core is not halted with secure debug enabled; aborting pre-flight")
    info["PDID"] = hex(ap.read32(0x40000000))
    info["RSTSTS"] = hex(ap.read32(0x40000004))
    info["FNSADDR"] = hex(ap.read32(F.FNSADDR))
    ispsts = ap.read32(F.FMC + 0x40)
    info["ISPSTS"] = {"raw": hex(ispsts), "FBS": (ispsts >> 30) & 1, "MIRBOUND": (ispsts >> 29) & 1,
                      "ISPCERR": (ispsts >> 28) & 1, "VECMAP": hex((ispsts >> 10) & 0x3FFFF),
                      "remap_base": hex(((ispsts >> 10) & 0x3FFFF) << 10), "ISPFF": (ispsts >> 6) & 1,
                      "ISPBUSY": ispsts & 1}
    info["ISPCTL"] = hex(ap.read32(F.FMC))
    info["REGLCTL"] = hex(ap.read32(F.REGLOCK))
    info["protection_regs"] = {hex(a): hex(ap.read32(a)) for a in F.PROTECTION_REGS}
    info["stage"] = "config_read"
    cfg = F.read_config(ap, p.flush)
    info["config"] = {hex(k): hex(v) for k, v in cfg.items()}
    guards = {}
    for name, fn in (("flash_guards", lambda: F.check_flash_guards(ap, cfg)),
                     ("sram_scratch", lambda: F.check_sram(ap, p.flush))):
        try:
            fn(); guards[name] = "ok"
        except Exception as exc:
            guards[name] = "FAIL: %s" % exc
    info["guards"] = guards
    info["DHCSR_after"] = hex(ap.read32(0xE000EDF0))
    info["ISPSTS_after"] = hex(ap.read32(F.FMC + 0x40))
    info["stage"] = "done"
finally:
    p.disconnect(); p.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"preflight-config-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
print(json.dumps({"success": info.get("stage") == "done", "summary": "pre-flight: config=%s guards=%s" % (bool(info.get("config")), info.get("guards"))}))
'''
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "pre-flight did not complete"}))
