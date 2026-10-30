"""Verify the reset-catch halted state: is the core halted with S_SDE=1 and are
APROM/SRAM/SYS/FMC/CONFIG readable? Read-only: DHCSR/DAUTHSTATUS/DSCSR, core
registers via DCRSR (read), memory reads. No reset, no halt/resume, no writes
other than the architectural DCRSR register-read request. DP left powered.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
code = r'''
import json
from datetime import datetime, timezone
from pathlib import Path
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort, DP_CTRL_STAT
from pyocd.coresight.ap import AccessPort, APv1Address
from pyocd.core.exceptions import TransferError
from pyocd.probe.debug_probe import DebugProbe

PROBE = "13010000003800F1047546CF0000065D"
root = Path.cwd()
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE,
        "method": "read-only check of reset-catch halted state; DP left powered"}
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
dp.connect()
ap = AccessPort.create(dp, APv1Address(0))
ap.init()
try:
    v = ap.read32(0xE000EDF0)
    info["DHCSR"] = hex(v)
    info["S_HALT"] = bool(v & (1 << 17)); info["S_SDE"] = bool(v & (1 << 20)); info["S_LOCKUP"] = bool(v & (1 << 19))
    info["DAUTHSTATUS"] = hex(ap.read32(0xE000EFB8))
    info["DSCSR"] = hex(ap.read32(0xE000EE08))
    info["DEMCR"] = hex(ap.read32(0xE000EDFC))
    info["ICSR"] = hex(ap.read32(0xE000ED04))
    info["CPUID"] = hex(ap.read32(0xE000ED00))
    regs = {}
    if info["S_HALT"]:
        for name, sel in (("r0", 0), ("sp", 13), ("lr", 14), ("pc", 15), ("xpsr", 16), ("msp", 17), ("psp", 18),
                          ("ctrl_primask", 20), ("msp_ns", 24), ("psp_ns", 25), ("msplim_s", 28), ("control_s", 0x22)):
            try:
                ap.write32(0xE000EDF4, sel)  # DCRSR read request
                for _ in range(100):
                    if ap.read32(0xE000EDF0) & (1 << 16):
                        break
                regs[name] = hex(ap.read32(0xE000EDF8))
            except TransferError as exc:
                regs[name] = "ERR " + str(exc)
    info["core_regs"] = regs
    mem = {}
    for name, addr in (("APROM0", 0x00000000), ("APROM_E000", 0x0000E000), ("APROM_high", 0x00080000),
                       ("SRAM", 0x20000000), ("SYS_PDID", 0x40000000), ("SYS_RSTSTS", 0x40000004),
                       ("FMC_ISPCTL", 0x4000C000), ("FMC_ISPSTS", 0x4000C040), ("CONFIG0", 0x0F300000),
                       ("CONFIG3", 0x0F30000C), ("CONFIG11_SCRLOCK", 0x0F30002C), ("CONFIG12_NSCBA", 0x0F300030),
                       ("CONFIG13_ARLOCK", 0x0F300034), ("LDROM", 0x0F100000), ("SCU_FNSADDR", 0x4002F000 + 0x1C)):
        try:
            mem[name] = [hex(x) for x in ap.read_memory_block32(addr, 4)]
        except TransferError as exc:
            mem[name] = "FAULT"
            # clear sticky error so later reads work
            try:
                dp.clear_sticky_err()
            except Exception:
                pass
    info["memory"] = mem
    info["ctrl_stat"] = hex(dp.read_reg(DP_CTRL_STAT))
finally:
    p.disconnect()
    p.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"halted-sde-check-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
ok = info.get("S_HALT") and info.get("S_SDE") and info["memory"].get("APROM0") != "FAULT"
print(json.dumps({"success": bool(ok), "summary": "halted=%s SDE=%s APROM0=%s" % (info.get("S_HALT"), info.get("S_SDE"), info["memory"].get("APROM0"))}))
'''
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "halted state check did not complete"}))
