"""Read-only debug-authentication probe: SCS debug registers and AP CSW behaviour.

MEM-AP only; no pack/core initialization, no reset, no halt, no memory/flash writes.
The only write is to the AP CSW register (HNONSEC bit) to test whether the AP
honours a Secure transaction attribute; CSW is restored afterwards.
"""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[4]
code = r'''
import json
from datetime import datetime, timezone
from pathlib import Path
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort, DP_CTRL_STAT
from pyocd.coresight.ap import AccessPort, APv1Address, MEM_AP_CSW
from pyocd.core.exceptions import TransferError

root = Path.cwd()
REGS = {
    "DHCSR": 0xE000EDF0, "DEMCR": 0xE000EDFC, "DAUTHCTRL": 0xE000EE04,
    "DSCSR": 0xE000EE08, "DAUTHSTATUS": 0xE000EFB8, "CPUID": 0xE000ED00,
    "ICSR": 0xE000ED04, "VTOR": 0xE000ED08, "AIRCR": 0xE000ED0C,
    "SHCSR": 0xE000ED24, "CFSR": 0xE000ED28, "HFSR": 0xE000ED2C,
    "SFSR": 0xE000EDE4, "SFAR": 0xE000EDE8, "SAU_CTRL": 0xE000EDD0,
    "SAU_TYPE": 0xE000EDD4, "MPU_CTRL": 0xE000ED94, "DFSR": 0xE000ED30,
    "CPACR": 0xE000ED88, "NSACR": 0xE000ED8C, "DCRSR": 0xE000EDF4,
    "DCRDR": 0xE000EDF8, "ROM_PIDR4": 0xE00FEFD0, "DWT_CTRL": 0xE0001000,
    "FPB_CTRL": 0xE0002000, "ITM_TCR": 0xE0000E80,
    "CTI_CTRL": 0xE0042000, "SCS_PIDR0": 0xE000EFE0,
}
probes = ConnectHelper.get_all_connected_probes(
    blocking=False, unique_id="13010000003800F1047546CF0000065D")
if len(probes) != 1:
    raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
p = probes[0]
session = Session(p, auto_open=False, options={
    "no_config": True, "target_override": "cortex_m", "auto_unlock": False,
    "frequency": 1000000, "resume_on_disconnect": False})
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": p.unique_id,
        "method": "MEM-AP only; no core init/reset/halt; read-only except CSW HNONSEC test"}
p.open()
try:
    p.set_clock(1000000)
    dp = DebugPort(p, session.target)
    dp.connect()
    ap = AccessPort.create(dp, APv1Address(0))
    ap.init()
    info["ap_idr"] = hex(ap.idr)
    info["csw_initial"] = hex(ap.read_reg(MEM_AP_CSW))
    regs = {}
    for name, addr in REGS.items():
        try:
            regs[name] = hex(ap.read32(addr))
        except TransferError as exc:
            regs[name] = "FAULT: " + str(exc)
            try:
                dp.read_reg(DP_CTRL_STAT)
            except Exception:
                pass
    info["regs"] = regs
    # DSCSR bits: [17] SBRSEL, [16] SBRSELEN, [1] CDSKEY, [0] CDS
    # DAUTHSTATUS: [7:6] SNID, [5:4] SID, [3:2] NSNID, [1:0] NSID (0b10 disabled, 0b11 enabled)
    # DAUTHCTRL: [0] SPIDENSEL, [1] INTSPIDEN, [2] SPNIDENSEL, [3] INTSPNIDEN
    csw_tests = {}
    base = ap.read_reg(MEM_AP_CSW)
    for hn in (0, 1):
        want = (base & ~(1 << 30)) | (hn << 30)
        ap.write_reg(MEM_AP_CSW, want)
        got = ap.read_reg(MEM_AP_CSW)
        csw_tests["hnonsec=%d" % hn] = {"written": hex(want), "readback": hex(got),
                                          "bit30_readback": (got >> 30) & 1}
    ap.write_reg(MEM_AP_CSW, base)
    info["csw_tests"] = csw_tests
    info["dp_ctrl_stat"] = hex(dp.read_reg(DP_CTRL_STAT))
finally:
    try:
        p.disconnect()
    finally:
        p.close()
stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
out = root / '.embedder/hardware/results' / ('dauth-probe-' + stamp + '.json')
out.write_text(json.dumps(info, indent=2) + '\n')
print(json.dumps(info, indent=2))
print(json.dumps({"success": "DAUTHCTRL" in info["regs"],
                  "summary": "read-only debug auth probe; DAUTHCTRL=" + info["regs"].get("DAUTHCTRL", "?")}))
'''
result = run_tool([str(root / '.venv/bin/python'), '-c', code])
print(result.get('output', ''))
if result.get('exit_code') != 0:
    print(json.dumps({'success': False, 'summary': 'debug auth probe process failed'}))
