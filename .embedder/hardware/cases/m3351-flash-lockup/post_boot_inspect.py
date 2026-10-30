"""After the authorized boot of the verified image: attach without reset, read
DHCSR/DAUTHSTATUS/DEMCR, optionally request a debug halt (DHCSR write only),
and if halted record core registers and fault status. Read-only otherwise; no
flash/config/security/RAM writes, no reset, no resume.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
halt = bool(capture_profile.get("halt", False))
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
DHCSR, DCRSR, DCRDR, DEMCR = 0xE000EDF0, 0xE000EDF4, 0xE000EDF8, 0xE000EDFC
root = Path.cwd()
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE,
        "method": "attach, no reset; DHCSR halt request only if requested", "halt_requested": HALT}
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

def rd(a):
    try:
        return hex(ap.read32(a))
    except Exception as exc:
        return "FAULT"

def core_reg(n):
    ap.write32(DCRSR, n)
    for _ in range(100):
        if ap.read32(DHCSR) & (1 << 16):
            return hex(ap.read32(DCRDR))
    return "not ready"

try:
    d = ap.read32(DHCSR)
    info["DHCSR"] = hex(d)
    info["S_LOCKUP"] = bool(d & (1 << 19)); info["S_HALT"] = bool(d & (1 << 17)); info["S_SDE"] = bool(d & (1 << 20))
    info["DAUTHSTATUS"] = rd(0xE000EFB8)
    info["DEMCR"] = rd(DEMCR)
    info["DSCSR"] = rd(0xE000EE08)
    info["mem"] = {"APROM0": rd(0), "APROM4": rd(4), "SYS_PDID": rd(0x40000000), "SYS_RSTSTS": rd(0x40000004),
                   "SRAM0": rd(0x20000000), "FMC_ISPSTS": rd(0x4000C040), "SCU_FNSADDR": rd(0x4002F0D8)}
    if HALT:
        ap.write32(DHCSR, 0xA05F0003)
        p.flush()
        deadline = monotonic() + 1.0
        while monotonic() < deadline:
            d = ap.read32(DHCSR)
            if d & (1 << 17):
                break
        info["DHCSR_after_halt"] = hex(d)
        info["halted"] = bool(d & (1 << 17))
        if info["halted"]:
            info["regs"] = {n: core_reg(i) for n, i in (("r0", 0), ("r1", 1), ("sp", 13), ("lr", 14), ("pc", 15), ("xpsr", 16),
                                                        ("msp", 17), ("psp", 18), ("ctrl_primask", 20))}
            info["faults"] = {"CFSR": rd(0xE000ED28), "HFSR": rd(0xE000ED2C), "MMFAR": rd(0xE000ED34), "BFAR": rd(0xE000ED38),
                              "SFSR": rd(0xE000EDE4), "SFAR": rd(0xE000EDE8), "VTOR": rd(0xE000ED08), "AIRCR": rd(0xE000ED0C),
                              "SHCSR": rd(0xE000ED24)}
            info["mem_after"] = {"APROM0": rd(0), "APROM4": rd(4), "SRAM0": rd(0x20000000)}
            sp = info["regs"]["sp"]
            if sp.startswith("0x"):
                try:
                    info["stack_words"] = [hex(x) for x in ap.read_memory_block32(int(sp, 16), 8)]
                except Exception as exc:
                    info["stack_words"] = "FAULT"
    info["ctrl_stat"] = hex(dp.read_reg(DP_CTRL_STAT))
finally:
    p.disconnect(); p.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"post-boot-inspect-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
print(json.dumps({"success": True, "summary": "post-boot: DHCSR=%s DAUTH=%s halted=%s" % (info["DHCSR"], info["DAUTHSTATUS"], info.get("halted"))}))
'''
code = "HALT = %r\n" % halt + code
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "post-boot inspect did not complete"}))
