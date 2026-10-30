"""Reset-vector catch on the now-valid image: set DHCSR.C_DEBUGEN and
DEMCR.VC_CORERESET, pulse nRESET (DP left powered), then record whether the
core halted at the Secure Bootloader reset vector and in which execution state
(for tools/flash.py's guards). Debug-register writes and a pin reset only; no
flash/config/security/RAM writes; core left halted (not resumed).
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
code = r'''
import json, sys
from datetime import datetime, timezone
from pathlib import Path
from time import monotonic, sleep
root = Path.cwd()
sys.path.insert(0, str(root / "tools"))
import flash as F
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort, DP_CTRL_STAT
from pyocd.coresight.ap import AccessPort, APv1Address
from pyocd.probe.debug_probe import DebugProbe

PROBE = "13010000003800F1047546CF0000065D"
DHCSR, DCRSR, DCRDR, DEMCR, DSCSR = 0xE000EDF0, 0xE000EDF4, 0xE000EDF8, 0xE000EDFC, 0xE000EE08
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE,
        "method": "C_DEBUGEN + VC_CORERESET, nRESET pulse with DP powered, inspect halted state"}
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

def core_reg(n):
    ap.write32(DCRSR, n)
    for _ in range(100):
        if ap.read32(DHCSR) & (1 << 16):
            return ap.read32(DCRDR)
    raise RuntimeError("core register not ready")

try:
    info["before"] = {"DHCSR": hex(ap.read32(DHCSR)), "DEMCR": hex(ap.read32(DEMCR))}
    ap.write32(DHCSR, 0xA05F0001)
    ap.write32(DEMCR, 0x1)          # VC_CORERESET only
    p.flush()
    info["armed"] = {"DHCSR": hex(ap.read32(DHCSR)), "DEMCR": hex(ap.read32(DEMCR))}
    p.assert_reset(True); sleep(0.02); p.assert_reset(False)
    t0 = monotonic(); d = 0
    while monotonic() - t0 < 1.0:
        d = ap.read32(DHCSR)
        if d & (1 << 17):
            break
    info["DHCSR_after_reset"] = hex(d)
    info["halted"] = bool(d & (1 << 17)); info["lockup"] = bool(d & (1 << 19)); info["sde"] = bool(d & (1 << 20))
    info["halt_latency_ms"] = round((monotonic() - t0) * 1000, 2)
    if info["halted"]:
        regs = {n: core_reg(i) for n, i in (("sp", 13), ("lr", 14), ("pc", 15), ("xpsr", 16), ("msp", 17), ("psp", 18), ("ctrl_primask", 20))}
        info["regs"] = {k: hex(v) for k, v in regs.items()}
        info["DSCSR"] = hex(ap.read32(DSCSR))
        info["DAUTHSTATUS"] = hex(ap.read32(F.DAUTHSTATUS))
        ispsts = ap.read32(F.FMC + 0x40)
        info["ISPSTS"] = {"raw": hex(ispsts), "VECMAP": hex((ispsts >> 10) & 0x3FFFF), "ISPFF": (ispsts >> 6) & 1}
        info["ISPCTL"] = hex(ap.read32(F.FMC))
        info["REGLCTL"] = hex(ap.read32(F.REGLOCK))
        info["vector0"] = [hex(x) for x in ap.read_memory_block32(0, 2)]
        info["MSPLIM_S_via_DCRSR"] = hex(core_reg(0x1C))   # MSPLIM_S
        info["CFSR_HFSR"] = [hex(ap.read32(0xE000ED28)), hex(ap.read32(0xE000ED2C))]
        info["FNSADDR"] = hex(ap.read32(F.FNSADDR))
    info["ctrl_stat"] = hex(dp.read_reg(DP_CTRL_STAT))
finally:
    p.disconnect(); p.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"reset-catch-check-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
print(json.dumps({"success": bool(info.get("halted")), "summary": "reset catch: halted=%s pc=%s vecmap=%s" % (info.get("halted"), info.get("regs", {}).get("pc"), info.get("ISPSTS", {}).get("VECMAP"))}))
'''
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "reset-catch check did not complete"}))
