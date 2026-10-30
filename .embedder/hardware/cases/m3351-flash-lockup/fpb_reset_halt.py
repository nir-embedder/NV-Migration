"""Deterministic, guard-compliant halt for programming: hardware breakpoint
(FPB comparator 0) on the application's Reset_Handler taken from the current
APROM vector table, C_DEBUGEN on, DP powered DOWN during an nRESET pulse so the
Secure Bootloader never sees a debug connection, then DP power-up and state
check. The core stops at the first application instruction: privileged Thread
mode on MSP, Secure, MSPLIM reset, VECMAP = 0. Debug-register writes and a pin
reset only; no flash/config/security/RAM writes; core left halted.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
wait_ms = int(capture_profile.get("wait_ms", 50))
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
FP_CTRL, FP_REMAP, FP_COMP0 = 0xE0002000, 0xE0002004, 0xE0002008
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE, "wait_ms": WAIT_MS,
        "method": "FPB breakpoint at APROM Reset_Handler; C_DEBUGEN; DP down during nRESET; DP up after wait"}
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
    d0 = ap.read32(DHCSR)
    info["before"] = {"DHCSR": hex(d0), "DEMCR": hex(ap.read32(DEMCR)), "FP_CTRL": hex(ap.read32(FP_CTRL))}
    ispsts = ap.read32(F.FMC + 0x40)
    if (ispsts >> 10) & 0x3FFFF:
        raise RuntimeError("VECMAP is not 0; vector table at 0 is not APROM page 0")
    sp0, reset_handler = ap.read_memory_block32(0, 2)
    info["vector"] = {"sp": hex(sp0), "reset_handler": hex(reset_handler)}
    if not (reset_handler & 1) or not (0x2 <= reset_handler < F.FLASH_SIZE) or not (0x20000000 < sp0 <= 0x20020000):
        raise RuntimeError("APROM vector table does not look like a valid application; not arming")
    bp = reset_handler & ~1
    ap.write32(DEMCR, 0)
    ap.write32(DHCSR, 0xA05F0001)
    ap.write32(FP_CTRL, 0x3)
    ap.write32(FP_COMP0, bp | 1)
    p.flush()
    info["armed"] = {"DHCSR": hex(ap.read32(DHCSR)), "DEMCR": hex(ap.read32(DEMCR)),
                     "FP_CTRL": hex(ap.read32(FP_CTRL)), "FP_COMP0": hex(ap.read32(FP_COMP0))}
    if ap.read32(FP_COMP0) != (bp | 1) or not ap.read32(FP_CTRL) & 1:
        raise RuntimeError("FPB did not arm")
    dp.power_down_debug()
    info["ctrl_stat_down"] = hex(dp.read_reg(DP_CTRL_STAT))
    p.assert_reset(True); sleep(0.02); p.assert_reset(False)
    sleep(WAIT_MS / 1000.0)
    dp.connect()
    ap = AccessPort.create(dp, APv1Address(0)); ap.init()
    d = ap.read32(DHCSR); d = ap.read32(DHCSR)
    info["DHCSR_after"] = hex(d)
    info["halted"] = bool(d & (1 << 17)); info["lockup"] = bool(d & (1 << 19)); info["sde"] = bool(d & (1 << 20))
    info["FP_after"] = {"FP_CTRL": hex(ap.read32(FP_CTRL)), "FP_COMP0": hex(ap.read32(FP_COMP0))}
    info["DAUTHSTATUS"] = hex(ap.read32(F.DAUTHSTATUS))
    if info["halted"]:
        regs = {n: core_reg(i) for n, i in (("sp", 13), ("lr", 14), ("pc", 15), ("xpsr", 16), ("msp", 17), ("psp", 18),
                                           ("ctrl_primask", 20), ("msplim_s", 0x1C), ("psplim_s", 0x1D))}
        info["regs"] = {k: hex(v) for k, v in regs.items()}
        info["at_reset_handler"] = regs["pc"] == bp
        info["DSCSR"] = hex(ap.read32(DSCSR))
        ispsts = ap.read32(F.FMC + 0x40)
        info["ISPSTS"] = {"raw": hex(ispsts), "VECMAP": hex((ispsts >> 10) & 0x3FFFF)}
        info["CFSR_HFSR"] = [hex(ap.read32(0xE000ED28)), hex(ap.read32(0xE000ED2C))]
    # Disarm the breakpoint either way; leave the core as it is.
    ap.write32(FP_COMP0, 0); ap.write32(FP_CTRL, 0x2); p.flush()
    info["FP_disarmed"] = {"FP_CTRL": hex(ap.read32(FP_CTRL)), "FP_COMP0": hex(ap.read32(FP_COMP0))}
    info["ctrl_stat"] = hex(dp.read_reg(DP_CTRL_STAT))
finally:
    p.disconnect(); p.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"fpb-reset-halt-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
ok = bool(info.get("halted")) and bool(info.get("at_reset_handler")) and bool(info.get("sde"))
print(json.dumps({"success": ok, "summary": "fpb reset halt: halted=%s at_reset_handler=%s sde=%s pc=%s" % (
    info.get("halted"), info.get("at_reset_handler"), info.get("sde"), info.get("regs", {}).get("pc"))}))
'''
code = "WAIT_MS = %d\n" % wait_ms + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "FPB reset-halt did not complete"}))
