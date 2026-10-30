"""Back up full KJ APROM only after a reviewed connection/recovery is available.

The historical 512 KiB backup is partial. Do not run this as a recovery attempt.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[2]
code = r'''
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from pyocd.core.helpers import ConnectHelper
from pyocd.core.target import Target

root = Path.cwd()
probe = "13010000003800F1047546CF0000065D"
backup_dir = root / ".embedder/hardware/results" / ("backup-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"))
backup_dir.mkdir(parents=True, exist_ok=False)
session = ConnectHelper.session_with_chosen_probe(
    unique_id=probe, return_first=False, blocking=False,
    options={"project_dir": str(root), "target_override": "m3351kjcae",
             "auto_unlock": False, "connect_mode": "attach",
             "resume_on_disconnect": False, "frequency": 1000000,
             "cache.enable_memory": False})
if session is None:
    raise RuntimeError("Expected CMSIS-DAP probe unavailable")
with session:
    target = session.target
    state = target.get_state()
    target.halt()
    try:
        # SYS_BASE + PDID offset from the pinned M3351.h/sys_reg.h.
        pdid = target.read32(0x40000000)
        cpuid = target.read32(0xE000ED00)
        boot = target.memory_map.get_boot_memory()
        if boot.start != 0 or boot.length != 0x100000:
            raise RuntimeError("Unexpected exact-device APROM map")
        image = bytearray()
        for address in range(0, 0x100000, 4096):
            image.extend(target.read_memory_block8(address, 4096))
        (backup_dir / "aprom.bin").write_bytes(image)
        info = {"probe": probe, "selected_pack_target": "m3351kjcae",
                "pack": "Nuvoton.NuMicroM33_DFP.1.0.6", "pdid": hex(pdid),
                "cpuid": hex(cpuid), "bytes": len(image),
                "sha256": hashlib.sha256(image).hexdigest(),
                "sp": hex(int.from_bytes(image[0:4], "little")),
                "reset_vector": hex(int.from_bytes(image[4:8], "little")),
                "path": str(backup_dir.relative_to(root)),
                "scope": "APROM only; not option words, LDROM, or security state"}
        (backup_dir / "manifest.json").write_text(json.dumps(info, indent=2) + "\n")
        print(json.dumps(info))
    finally:
        if state != Target.State.HALTED:
            target.resume()
print(json.dumps({"success": True, "summary": "Core identified and 1 MiB APROM backed up; no flash writes or erase"}))
'''
result = run_tool([str(root / '.venv/bin/python'), '-c', code])
print(result.get('output', ''))
if result.get('exit_code') != 0:
    print('{"success": false, "summary": "Target identification/backup failed; no flash operations requested"}')
raise SystemExit(result.get('exit_code', 1))
