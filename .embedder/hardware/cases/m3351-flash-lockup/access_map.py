"""Read-only MEM-AP access map: which addresses are readable with HNONSEC=0/1.

No reset, halt, memory or flash write. Only AP CSW (transfer attribute) is changed
and restored.
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
from pyocd.coresight.ap import AccessPort, APv1Address, MEM_AP_CSW
from pyocd.core.exceptions import TransferError

root = Path.cwd()
ADDRS = [
    ("APROM_S", 0x00000000), ("APROM_NS", 0x10000000),
    ("APROM_S_high", 0x00080000), ("APROM_NS_high", 0x10080000),
    ("LDROM_S", 0x0F100000), ("LDROM_NS", 0x1F100000),
    ("CONFIG_S", 0x0F300000), ("CONFIG_NS", 0x1F300000),
    ("BOOTROM?", 0x0F108000), ("SRAM_S", 0x20000000), ("SRAM_NS", 0x30000000),
    ("SRAM_S_top", 0x2001FFF0), ("SYS_S", 0x40000000), ("SYS_NS", 0x50000000),
    ("CLK_S", 0x40200000), ("CLK_NS", 0x50200000),
    ("FMC_S", 0x4000C000), ("FMC_NS", 0x5000C000),
    ("SCU_S", 0x4002F000), ("SCU_NS", 0x5002F000),
    ("GPIOA_S", 0x40004000), ("GPIOA_NS", 0x50004000),
    ("UART0_S", 0x40070000), ("UART0_NS", 0x50070000),
    ("EBI", 0x60000000), ("PPB_ROM", 0xE00FF000),
    ("SCS_DHCSR", 0xE000EDF0), ("SCS_ICSR", 0xE000ED04),
]
probes = ConnectHelper.get_all_connected_probes(blocking=False, unique_id="13010000003800F1047546CF0000065D")
if len(probes) != 1:
    raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
p = probes[0]
session = Session(p, auto_open=False, options={"no_config": True, "target_override": "cortex_m",
                                               "auto_unlock": False, "frequency": 1000000})
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": p.unique_id,
        "method": "MEM-AP only, read-only; no reset/halt/writes", "map": {}}
p.open()
try:
    p.set_clock(1000000)
    dp = DebugPort(p, session.target)
    dp.connect()
    ap = AccessPort.create(dp, APv1Address(0))
    ap.init()
    base = ap.read_reg(MEM_AP_CSW)
    for hn in (0, 1):
        ap.write_reg(MEM_AP_CSW, (base & ~(1 << 30)) | (hn << 30))
        res = {}
        for name, addr in ADDRS:
            try:
                res[name] = hex(ap.read32(addr))
            except TransferError as exc:
                res[name] = "FAULT"
                try:
                    dp.read_reg(DP_CTRL_STAT)
                except Exception:
                    pass
        info["map"]["hnonsec=%d" % hn] = res
    ap.write_reg(MEM_AP_CSW, base)
    info["DHCSR"] = hex(ap.read32(0xE000EDF0))
    info["DAUTHSTATUS"] = hex(ap.read32(0xE000EFB8))
finally:
    try:
        p.disconnect()
    finally:
        p.close()
out = root / ".embedder/hardware/results" / ("access-map-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".json")
out.write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
readable = sum(1 for m in info["map"].values() for v in m.values() if v != "FAULT")
print(json.dumps({"success": True, "summary": "access map captured; readable entries=%d" % readable}))
'''
result = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(result.get("output", ""))
if result.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "access map process failed"}))
