"""Passive MEM-AP snapshot, without pack/core initialization, halt, or reset."""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[4]
code = r'''
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort, DP_CTRL_STAT
from pyocd.coresight.ap import AccessPort, APv1Address, MEM_AP_CSW
from pyocd.core.exceptions import TransferError

root = Path.cwd()

def inspect_nonsecure(ap, dp, info):
    info["method"] += "; HNONSEC=1, documented non-secure aliases only"
    info["hnonsec_before"] = ap.hnonsec
    with ap.hnonsec_lock(1):
        if ap.hnonsec != 1:
            raise RuntimeError("AP does not support non-secure transfers")
        info["hnonsec"] = ap.hnonsec
        info["aliases"] = {}
        for name, addr in (("APROM_NS", 0x10000000), ("SRAM_NS", 0x30000000)):
            try:
                data = bytes(ap.read_memory_block8(addr, 16))
                info["aliases"][name] = {"address": hex(addr), "data": data.hex()}
            except TransferError as exc:
                info["aliases"][name] = {"address": hex(addr), "error": str(exc)}
            info["aliases"][name]["csw_after"] = hex(ap.read_reg(MEM_AP_CSW))
            info["aliases"][name]["dp_ctrl_stat_after"] = hex(dp.read_reg(DP_CTRL_STAT))
        if "data" in info["aliases"]["APROM_NS"]:
            image = bytearray()
            try:
                for offset in range(0, 0x100000, 4096):
                    image.extend(ap.read_memory_block8(0x10000000 + offset, 4096))
                stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
                backup = root / '.embedder/hardware/results' / ('kj-aprom-ns-' + stamp + '.bin')
                with backup.open('xb') as output:
                    output.write(image)
                info["backup"] = {"path": str(backup.relative_to(root)),
                                  "bytes": len(image), "sha256": hashlib.sha256(image).hexdigest(),
                                  "scope": "current full KJ APROM via non-secure alias; not original firmware"}
            except TransferError as exc:
                info["backup_error"] = {"bytes_read": len(image), "error": str(exc)}
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    output = root / '.embedder/hardware/results' / ('nonsecure-alias-' + stamp + '.json')
    output.write_text(json.dumps(info, indent=2) + '\n')
    print(json.dumps(info, indent=2))
    print(json.dumps({"success": "backup" in info,
                      "summary": "Read-only non-secure alias check; no reset, halt, flash or security writes"}))

probes = ConnectHelper.get_all_connected_probes(
    blocking=False, unique_id="13010000003800F1047546CF0000065D")
if len(probes) != 1:
    raise RuntimeError("Expected unique Nu-Link2 CMSIS-DAP probe")
p = probes[0]
# A generic unopened session supplies transport settings only; no generic flash.
session = Session(p, auto_open=False, options={
    "no_config": True, "target_override": "cortex_m", "auto_unlock": False,
    "frequency": 1000000, "resume_on_disconnect": False})
info = {"timestamp": datetime.now(timezone.utc).isoformat(),
        "probe": p.unique_id, "method": "MEM-AP only; no core init/reset/halt"}
p.open()
try:
    p.set_clock(1000000)
    dp = DebugPort(p, session.target)
    dp.connect()
    ap = AccessPort.create(dp, APv1Address(0))
    ap.init()
    if NONSECURE:
        inspect_nonsecure(ap, dp, info)
        raise SystemExit(0)
    if RECOVER:
        info["recovery_dhcsr_before"] = hex(ap.read32(0xe000edf0))
        # Exact DebugPortStop DHCSR write from Nuvoton's DFP: disable debugging,
        # not debug authentication. No DAUTHCTRL/DPM/flash/config writes.
        ap.write32(0xe000edf0, 0xa05f0000)
        dp.flush()
        p.reset()
        dp.connect()
        ap = AccessPort.create(dp, APv1Address(0))
        ap.init()
        info["method"] += "; vendor debug-disable then hardware reset"
    if CATCH_RESET:
        info['method'] += '; standard reset vector catch then hardware reset'
        info['auth_before_reset'] = hex(ap.read32(0xe000efb8))
        ap.write32(0xe000edf0, 0xa05f0001)
        ap.write32(0xe000edfc, ap.read32(0xe000edfc) | 1)
        dp.flush()
        if SYSTEM_RESET:
            ap.write32(0xe000ed0c, 0x05fa0004)
            dp.flush()
        else:
            p.reset()
        dp.connect()
        ap = AccessPort.create(dp, APv1Address(0))
        ap.init()
    if HALT:
        info['method'] += '; raw DHCSR halt, no reset'
        from time import monotonic
        info["auth_before_halt"] = hex(ap.read32(0xe000efb8))
        if info["auth_before_halt"] != "0xff":
            raise RuntimeError("Secure debug not enabled; refusing halt test")
        ap.write32(0xe000edf0, 0xa05f0003)
        dp.flush()
        deadline = monotonic() + 0.5
        while monotonic() < deadline:
            if ap.read32(0xe000edf0) & (1 << 17):
                break
    info["dp_idr"] = hex(dp.dpidr.idr) if hasattr(dp.dpidr, "idr") else str(dp.dpidr)
    info["ap_idr"] = hex(ap.idr)
    info["csw"] = hex(ap.read_reg(MEM_AP_CSW))
    # Offsets from pinned M3351 sys/scu/fmc_reg.h and CMSIS core_cm33.h.
    registers = {
        "SYS_PDID": 0x40000000, "SYS_RSTSTS": 0x40000004,
        "SYS_BODCTL": 0x40000018, "SYS_SRAM_STATUS": 0x400000c4,
        "SYS_SRAM_ERRADDR": 0x400000c8, "SYS_SRAM_ECCEN": 0x400000dc,
        "SCU_SRAMNSSET": 0x4002f020, "SCU_FNSADDR": 0x4002f02c,
        "SCU_SVINTSTS": 0x4002f034, "SCU_FLASHVSRC": 0x4002f040,
        "SCU_FLASHVA": 0x4002f044, "SCU_SRAM0VSRC": 0x4002f048,
        "SCU_SRAM0VA": 0x4002f04c, "SCU_SRAM1VSRC": 0x4002f050,
        "SCU_SRAM1VA": 0x4002f054, "FMC_ISPCTL": 0x4000c000,
        "FMC_ISPADDR": 0x4000c004, "FMC_ISPDAT": 0x4000c008,
        "FMC_ISPCMD": 0x4000c00c, "FMC_ISPTRG": 0x4000c010,
        "FMC_ISPSTS": 0x4000c040, "FMC_XOMSTS": 0x4000c0e0,
        "FMC_APWPROT0": 0x4000c110, "FMC_APWPROT1": 0x4000c114,
        "FMC_ECCCTL": 0x4000c130, "FMC_ECCSTS": 0x4000c134,
        "CPUID": 0xe000ed00, "CFSR": 0xe000ed28,
        "HFSR": 0xe000ed2c, "SFSR": 0xe000ede4,
        "DHCSR": 0xe000edf0, "DEMCR": 0xe000edfc,
        "DSCSR": 0xe000ee08, "DAUTHSTATUS": 0xe000efb8,
        "CONFIG0_direct": 0x0f300000, "CONFIG12_direct": 0x0f300030,
    }
    info["registers"] = {}
    for name, addr in registers.items():
        try:
            info["registers"][name] = hex(ap.read32(addr))
        except Exception as exc:
            info["registers"][name] = {"error": str(exc)}
    for addr in (0, 0x20000000, 0x20003c00, 0x30000000):
        try:
            info[hex(addr)] = bytes(ap.read_memory_block8(addr, 16)).hex()
        except Exception as exc:
            info[hex(addr)] = {"error": str(exc)}
    try:
        original = (root / ".embedder/hardware/results/backup-20261028T201055Z/aprom.bin").read_bytes()
        image = bytes(ap.read_memory_block8(0, len(original)))
        info["comparison_range"] = {"start": 0, "bytes": len(original),
                                    "scope": "APROM prefix only; not the full KJ device"}
        info["aprom_prefix_sha256"] = hashlib.sha256(image).hexdigest()
        info["aprom_prefix_unchanged"] = image == original
    except Exception as exc:
        info["aprom_read_error"] = str(exc)
finally:
    p.disconnect()
    p.close()
output = root / (".embedder/hardware/results/raw-halt-snapshot.json" if HALT else
                 ".embedder/hardware/results/recovered-snapshot.json" if RECOVER else
                 ".embedder/hardware/results/passive-snapshot.json")
output = output.with_name(output.stem + '-' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ') + '.json')
output.write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
print(json.dumps({"success": info.get("aprom_prefix_unchanged", False),
                  "summary": "Passive MEM-AP snapshot; partial APROM backup comparison recorded"}))
'''
nonsecure = bool(capture_profile.get('nonsecure', False))
if nonsecure and any(capture_profile.get(key, False) for key in
                     ('recovery', 'halt', 'catch_reset', 'system_reset')):
    raise ValueError('Non-secure alias check must not reset or halt the target')
code = ("NONSECURE = " + repr(nonsecure) +
        "\nRECOVER = " + repr(bool(capture_profile.get('recovery', False))) +
        "\nHALT = " + repr(bool(capture_profile.get('halt', False))) +
        "\nCATCH_RESET = " + repr(bool(capture_profile.get('catch_reset', False))) +
        "\nSYSTEM_RESET = " + repr(bool(capture_profile.get('system_reset', False))) + "\n" + code)
result = run_tool([str(root / '.venv/bin/python'), '-c', code])
print(result.get('output', ''))
if result.get('exit_code') != 0:
    print(json.dumps({'success': False, 'summary': 'Snapshot/recovery did not complete; inspect traceback for the last executed step. No flash or security writes requested.'}))
