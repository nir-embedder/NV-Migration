"""Halted-in-ROM recovery step 2: volatile FMC "Vector Remap" (ISP command 0x2E)
back to APROM page 0, then re-run tools/flash.py guards and take a fresh,
content-addressed backup of the full 1 MiB APROM, LDROM and Data Flash.

Writes only volatile FMC ISP registers (ISPCMD/ISPADDR/ISPTRG) for the remap.
No erase, program, CONFIG, security, LDROM writes; no reset; no resume.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
code = r'''
import hashlib, json, sys
from datetime import datetime, timezone
from pathlib import Path
from time import monotonic
root = Path.cwd()
sys.path.insert(0, str(root / "tools"))
import flash as F
from pyocd.core.helpers import ConnectHelper
from pyocd.core.session import Session
from pyocd.coresight.dap import DebugPort
from pyocd.coresight.ap import AccessPort, APv1Address
from pyocd.probe.debug_probe import DebugProbe

PROBE = "13010000003800F1047546CF0000065D"
ISPCTL, ISPADDR, ISPDAT, ISPCMD, ISPTRG, ISPSTS = (F.FMC + o for o in (0x00, 0x04, 0x08, 0x0C, 0x10, 0x40))
info = {"timestamp": datetime.now(timezone.utc).isoformat(), "probe": PROBE,
        "method": "volatile FMC VECMAP(0x2E)->0x0; guards; fresh full backups; no erase/program/config/reset/resume"}
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

def decode(v):
    return {"raw": hex(v), "VECMAP": hex((v >> 10) & 0x3FFFF), "remap_base": hex(((v >> 10) & 0x3FFFF) << 10),
            "ISPFF": (v >> 6) & 1, "ISPBUSY": v & 1, "FBS": (v >> 30) & 1, "MIRBOUND": (v >> 29) & 1}

try:
    dhcsr = ap.read32(0xE000EDF0)
    info["DHCSR"] = hex(dhcsr)
    info["DAUTHSTATUS"] = hex(ap.read32(F.DAUTHSTATUS))
    if not (dhcsr & (1 << 17)) or not (dhcsr & (1 << 20)):
        raise RuntimeError("core is not halted with secure debug enabled; aborting")
    if ap.read32(0x40000000) != F.PDID:
        raise RuntimeError("PDID mismatch")
    before = ap.read32(ISPSTS)
    info["ISPSTS_before"] = decode(before)
    info["ISPCTL_before"] = hex(ap.read32(ISPCTL))
    info["page0_before_remap"] = [hex(x) for x in ap.read_memory_block32(0, 4)]
    if ap.read32(ISPTRG) & 1 or before & (1 << 6) or not ap.read32(ISPCTL) & 1:
        raise RuntimeError("FMC busy, ISPFF set or ISPEN clear; not issuing VECMAP")
    if ((before >> 10) & 0x3FFFF) != 0:
        info["stage"] = "vecmap"
        ap.write32(ISPCMD, 0x2E)
        ap.write32(ISPADDR, 0x0)
        ap.write32(ISPTRG, 1)
        p.flush()
        deadline = monotonic() + 1.0
        while ap.read32(ISPTRG) & 1:
            if monotonic() > deadline:
                raise RuntimeError("VECMAP ISP command timed out")
        after = ap.read32(ISPSTS)
        info["ISPSTS_after"] = decode(after)
        info["ISPCTL_after"] = hex(ap.read32(ISPCTL))
        if after & (1 << 6) or ap.read32(ISPCTL) & (1 << 6):
            raise RuntimeError("VECMAP reported ISPFF")
        if ((after >> 10) & 0x3FFFF) != 0:
            raise RuntimeError("VECMAP did not return to APROM page 0")
    info["page0_after_remap"] = [hex(x) for x in ap.read_memory_block32(0, 4)]
    info["stage"] = "guards"
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
    info["stage"] = "backup"
    bdir = root / ".embedder/backups"
    out = {}
    for name, (addr, size) in {"aprom": (0, F.FLASH_SIZE), **F.PRESERVED_REGIONS}.items():
        a = bytes(ap.read_memory_block8(addr, size))
        b = bytes(ap.read_memory_block8(addr, size))
        if len(a) != size or a != b:
            raise RuntimeError("unstable %s read" % name)
        path = F.backup_region(a, bdir, name)
        out[name] = {"path": str(path.relative_to(root)), "bytes": size, "sha256": hashlib.sha256(a).hexdigest(),
                     "first_words": [hex(int.from_bytes(a[i:i+4], "little")) for i in range(0, 16, 4)],
                     "nonff_bytes": sum(1 for x in a if x != 0xFF)}
    info["backups"] = out
    info["stage"] = "done"
finally:
    try:
        info["DHCSR_final"] = hex(ap.read32(0xE000EDF0))
    except Exception as exc:
        info["DHCSR_final"] = "ERR %s" % exc
    p.disconnect(); p.close()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
(root / ".embedder/hardware/results" / f"vecmap-restore-backup-{stamp}.json").write_text(json.dumps(info, indent=2) + "\n")
print(json.dumps(info, indent=2))
print(json.dumps({"success": info.get("stage") == "done" and all(v == "ok" for v in info.get("guards", {}).values()),
                  "summary": "VECMAP->0, guards=%s, backups=%s" % (info.get("guards"), list(info.get("backups", {})))}))
'''
res = run_tool([str(root / ".venv/bin/python"), "-c", code])
print(res.get("output", ""))
if res.get("exit_code") != 0:
    print(json.dumps({"success": False, "summary": "VECMAP/backup step did not complete"}))
