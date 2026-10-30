#!/usr/bin/env python3
"""Validate or explicitly sector-program the confirmed M3351KJCAE.

Adapted from the user-supplied flash.py. Default operation is offline validation.
--program is NOT a recovery procedure: see docs/validation.md before using it.
No reset, automatic unlock, mass erase, or automatic resume is requested.
"""

import argparse
from contextlib import contextmanager
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
from time import monotonic, sleep
import xml.etree.ElementTree as ET
from xml.parsers.expat import ExpatError
import zipfile

WORKSPACE = Path(__file__).resolve().parents[1]
TARGET = "m3351kjcae"
DEVICE = "M3351KJCAE"
FLASH_SIZE = 0x100000
SECTOR_SIZE = 0x2000
SRAM_BASE = 0x20000000
SRAM_SIZE = 0x20000
PDID = 0x03302140
PACK_NAME = "Nuvoton.NuMicroM33_DFP.1.0.6.pack"
PACK_SHA256 = "0aae782356a261b976169fb677a5785c8647b5e0a0a93fa1632fb71a04b2dde2"
FLM_NAME = "Flash/M3351_AP_1M.FLM"
FLM_SHA256 = "6ad56e7e085dae4ed3f61abd6bcc2edde2ffd53424ca28a6fedc6d743b369717"
FMC = 0x4000C000
REGLOCK = 0x40000100
FNSADDR = 0x4002F02C
DAUTHSTATUS = 0xE000EFB8
DSCSR = 0xE000EE08
MPU_CTRL = 0xE000ED94
# Documented M3351 CONFIG words; skip reserved holes, do not infer ROM-entry bits.
CONFIG_WORDS = tuple(0x0F300000 + n * 4 for n in (*range(7), *range(8, 15), 32, 33, 34))
PROTECTION_REGS = (FMC + 0x110, FMC + 0x114, FMC + 0x11C, FMC + 0xE0)
PRESERVED_REGIONS = {"ldrom": (0x0F100000, 0x4000), "data-flash": (0x0F200000, 0x4000)}


def validate_image(build_dir):
    """Validate all file-backed physical loads, runtime ranges and boot vectors."""
    from elftools.elf.elffile import ELFFile

    directory = Path(build_dir).expanduser().resolve() / "zephyr"
    binary_path = directory / "zephyr.bin"
    size = binary_path.stat().st_size
    if not 8 <= size <= FLASH_SIZE:
        raise ValueError("Binary must contain vectors and fit within 1 MiB KJ APROM")
    binary = binary_path.read_bytes()
    if len(binary) != size:
        raise ValueError("Binary changed during validation")
    expected = bytearray(b"\xff" * size)
    ranges, executable, loads = [], [], []
    with (directory / "zephyr.elf").open("rb") as stream:
        elf = ELFFile(stream)
        if (elf.elfclass != 32 or not elf.little_endian
                or elf["e_machine"] != "EM_ARM" or elf["e_type"] != "ET_EXEC"):
            raise ValueError("ELF must be a little-endian ARM32 executable")
        entry = elf["e_entry"]
        for segment in elf.iter_segments():
            if segment["p_type"] != "PT_LOAD":
                continue
            address, virtual = segment["p_paddr"], segment["p_vaddr"]
            filesz, memsz = segment["p_filesz"], segment["p_memsz"]
            if filesz > memsz:
                raise ValueError("ELF segment file size exceeds its memory size")
            if memsz and not (0 <= virtual < virtual + memsz <= FLASH_SIZE
                              or SRAM_BASE <= virtual < virtual + memsz <= SRAM_BASE + SRAM_SIZE):
                raise ValueError("ELF runtime segment exceeds APROM or 128 KiB SRAM")
            if not filesz:
                continue
            if not 0 <= address < address + filesz <= size:
                raise ValueError("ELF load segment exceeds binary or KJ APROM")
            if any(address < end and start < address + filesz for start, end in ranges):
                raise ValueError("ELF load segments overlap")
            data = segment.data()
            if len(data) != filesz:
                raise ValueError("ELF load segment is truncated")
            ranges.append((address, address + filesz))
            loads.append(segment)
        section_ranges = []
        covered_loads = set()
        for section in elf.iter_sections():
            if not section["sh_flags"] & 2 or section["sh_type"] == "SHT_NOBITS" or not section["sh_size"]:
                continue
            containers = [segment for segment in loads if segment.section_in_segment(section)]
            if len(containers) != 1:
                raise ValueError("Allocated ELF section must belong to exactly one file-backed load segment")
            segment = containers[0]
            offset = section["sh_addr"] - segment["p_vaddr"]
            address = segment["p_paddr"] + offset
            end = address + section["sh_size"]
            if (offset < 0 or offset + section["sh_size"] > segment["p_filesz"]
                    or section["sh_offset"] - segment["p_offset"] != offset
                    or not 0 <= address < end <= size):
                raise ValueError("ELF section exceeds or disagrees with its load segment")
            if any(address < stop and start < end for start, stop in section_ranges):
                raise ValueError("Allocated ELF sections overlap")
            data = section.data()
            if len(data) != section["sh_size"]:
                raise ValueError("ELF section is truncated")
            expected[address:end] = data
            section_ranges.append((address, end))
            if (section["sh_flags"] & 4 and segment["p_flags"] & 1
                    and segment["p_vaddr"] == segment["p_paddr"]):
                executable.append((address, end))
            covered_loads.add(segment["p_paddr"])
        if section_ranges and any(segment["p_paddr"] not in covered_loads for segment in loads):
            raise ValueError("Every file-backed ELF load must contain an allocated payload section")
    if not ranges or min(start for start, _ in ranges) != 0:
        raise ValueError("ELF must load at APROM/vector base zero")
    if not section_ranges or min(start for start, _ in section_ranges) != 0:
        raise ValueError("ELF must contain allocated sections starting at vector base zero")
    if max(end for _, end in ranges) != size or max(end for _, end in section_ranges) != size:
        raise ValueError("ELF and binary extents differ")
    # GNU objcopy --gap-fill 0xFF fills section gaps, including inside PT_LOAD.
    if binary != expected:
        raise ValueError("ELF and binary contents differ (including padding)")
    sp = int.from_bytes(binary[:4], "little")
    pc = int.from_bytes(binary[4:8], "little")
    if not (SRAM_BASE < sp <= SRAM_BASE + SRAM_SIZE and sp % 8 == 0):
        raise ValueError("Initial stack pointer is outside/aligned incorrectly for 128 KiB SRAM")
    if not (pc & 1 and (pc & ~1) >= 8
            and any(start <= (pc & ~1) and (pc & ~1) + 2 <= end
                    for start, end in executable)):
        raise ValueError("Reset vector must be Thumb code within executable APROM")
    if (entry & ~1) != (pc & ~1):
        raise ValueError("ELF entry point differs from reset vector")
    return binary


def resolve_pack(explicit=None, workspace=WORKSPACE):
    """Prefer the workspace pin; never download or consult the global pack index."""
    supplied = explicit if explicit is not None else os.environ.get("NUVOTON_DFP")
    if supplied is not None:
        path = Path(supplied).expanduser().resolve()
        if not supplied or not path.is_file() or path.suffix.lower() != ".pack":
            raise ValueError("--pack/NUVOTON_DFP must name an existing local .pack file")
        return path
    local = Path(workspace) / ".deps/packs" / PACK_NAME
    if local.is_file():
        return local.resolve()
    matches = sorted({p.resolve() for p in (Path.home() / ".embedder/downloads").rglob(PACK_NAME)
                      if p.is_file()})
    if len(matches) != 1:
        raise ValueError("Supply --pack: expected exactly one cached official DFP; no downloads")
    return matches[0]


def validate_pack(path):
    """Pin actual content, not just a plausible file name or version label."""
    content = Path(path).read_bytes()
    if hashlib.sha256(content).hexdigest() != PACK_SHA256:
        raise ValueError("DFP hash differs from the audited 1.0.6 pack")
    with zipfile.ZipFile(path) as pack:
        if hashlib.sha256(pack.read(FLM_NAME)).hexdigest() != FLM_SHA256:
            raise ValueError("KJ flash algorithm hash differs from the audited FLM")
        root = ET.fromstring(pack.read("Nuvoton.NuMicroM33_DFP.pdsc"))
    device = root.find(f'.//device[@Dname="{DEVICE}"]')
    if device is None:
        raise ValueError("Pack has no exact KJ device")
    memory = device.find('memory[@id="IROM1"]')
    algorithm = device.find(f'algorithm[@name="{FLM_NAME}"]')
    if (memory is None or algorithm is None
            or int(memory.get("start"), 0) != 0 or int(memory.get("size"), 0) != FLASH_SIZE
            or int(algorithm.get("start"), 0) != 0 or int(algorithm.get("size"), 0) != FLASH_SIZE
            or int(algorithm.get("RAMstart"), 0) != SRAM_BASE
            or int(algorithm.get("RAMsize"), 0) != 0x4000):
        raise ValueError("Pack geometry differs from the audited KJ device")


def write_plan(binary, baseline):
    """Return whole-sector data with original trailing bytes, never FF padding."""
    if len(baseline) != FLASH_SIZE or not 8 <= len(binary) <= FLASH_SIZE:
        raise ValueError("Requires a full 1 MiB current backup and a bounded image")
    expected = bytearray(baseline)
    expected[:len(binary)] = binary
    end = (len(binary) + SECTOR_SIZE - 1) // SECTOR_SIZE * SECTOR_SIZE
    return bytes(expected[:end]), bytes(expected)


def backup_region(image, directory, name):
    """Keep content-addressed, private backups, including incomplete current images."""
    digest = hashlib.sha256(image).hexdigest()
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    path = directory / f"m3351kjcae-{name}-{digest}.bin"
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError:
        if path.is_symlink() or not path.is_file():
            raise RuntimeError("Backup path is not a regular file")
    else:
        with os.fdopen(fd, "wb") as stream:
            stream.write(image)
            stream.flush()
            os.fsync(stream.fileno())
    if path.read_bytes() != image:
        raise RuntimeError("Backup readback/collision check failed")
    return path


def backup_aprom(image, directory):
    if len(image) != FLASH_SIZE:
        raise ValueError("Current APROM backup must be exactly 1 MiB, not the historical 512 KiB file")
    return backup_region(image, directory, "aprom")


def verify_aprom(actual, expected):
    if len(actual) != FLASH_SIZE or len(expected) != FLASH_SIZE:
        raise RuntimeError("Full APROM verification requires exactly 1 MiB")
    if actual != expected:
        address = next(i for i, (a, b) in enumerate(zip(actual, expected)) if a != b)
        raise RuntimeError(f"Full APROM verification failed at {address:#x}")


def select_probe(probes, unique_id):
    if not unique_id:
        raise ValueError("--program requires --probe with the full unique ID")
    matches = [p for p in probes if p.unique_id.casefold() == unique_id.casefold()]
    if len(matches) != 1:
        raise ValueError("Expected exactly one probe matching the full unique ID")
    return matches[0]


def check_connection(session):
    from pyocd.coresight.dap import DP_CTRL_STAT, CDBGPWRUPACK, CSYSPWRUPACK

    ack = CDBGPWRUPACK | CSYSPWRUPACK
    if session.target.dp.read_reg(DP_CTRL_STAT) & ack != ack:
        raise RuntimeError("Debug/system power-up not acknowledged")
    if session.probe.is_reset_asserted():
        raise RuntimeError("Reset is asserted; no automatic recovery will be attempted")


class AttachDelegate:
    def __init__(self, session):
        self.session = session

    def will_init_target(self, target, init_sequence):
        # Returning False selects generic DP power-up, not the DFP reset pulse.
        target.dp.enable_debug_port_hook = lambda: False
        # Leave debug power alone: the vendor stop sequence disables core debug.
        target.dp.disable_debug_port_hook = lambda: True
        init_sequence.insert_after("dp_init", ("check_power_and_reset",
                                               lambda: check_connection(self.session)))


def read_config(ap, flush):
    """FMC READ only; this still writes volatile controller/REGLOCK registers."""
    if ap.read32(FMC + 0x10) & 1 or ap.read32(FMC + 0x40) & (1 << 6):
        raise RuntimeError("FMC busy or ISPFF set; refusing configuration reads")
    saved_lock = ap.read32(REGLOCK) & 1
    saved = {offset: ap.read32(FMC + offset) for offset in (0, 4, 8, 12)}
    try:
        if not saved_lock:
            for key in (0x59, 0x16, 0x88):
                ap.write32(REGLOCK, key)
        ap.write32(FMC, saved[0] | 1)
        flush()
        result = {}
        for address in CONFIG_WORDS:
            ap.write32(FMC + 0x0C, 0)  # FMC_ISPCMD_READ, never erase/program.
            ap.write32(FMC + 0x04, address)
            ap.write32(FMC + 0x10, 1)
            deadline = monotonic() + 1.0
            while ap.read32(FMC + 0x10) & 1:
                if monotonic() >= deadline:
                    raise RuntimeError("FMC configuration read timed out")
            if ap.read32(FMC + 0x40) & (1 << 6):
                raise RuntimeError("FMC configuration read reported ISPFF")
            result[address] = ap.read32(FMC + 0x08)
        return result
    finally:
        if ap.read32(FMC + 0x10) & 1:
            raise RuntimeError("FMC still busy; unable to restore read setup")
        for offset in (12, 4, 8, 0):
            ap.write32(FMC + offset, saved[offset])
        if not saved_lock:
            ap.write32(REGLOCK, 0)
        flush()
        if (any(ap.read32(FMC + offset) != value for offset, value in saved.items())
                or ap.read32(REGLOCK) & 1 != saved_lock):
            raise RuntimeError("FMC controller/register-lock restoration mismatch")


def check_flash_guards(ap, config):
    if config[0x0F30002C] & 0xFF != 0x5A or config[0x0F300034] & 0xFF != 0x5A:
        raise RuntimeError("SCRLOCK/ARLOCK active; refusing programming")
    if ap.read32(FNSADDR) != FLASH_SIZE:
        raise RuntimeError("Active secure flash boundary is not the full 1 MiB KJ APROM")
    if ap.read32(FMC + 0x40) & 0x4FFFFC00:
        raise RuntimeError("Unexpected bank/vector mapping")
    if any(ap.read32(address) != 0 for address in PROTECTION_REGS):
        raise RuntimeError("APWPROT/SCACT/XOM protection active; refusing programming")


def check_sram(ap, flush):
    """Test and restore the supplied flasher's 16-byte algorithm-RAM scratch."""
    address = SRAM_BASE + 0x3C00
    saved = ap.read_memory_block32(address, 4)
    if len(saved) != 4:
        raise RuntimeError("Incomplete SRAM scratch read; refusing writes")
    pattern = [0x01234567, 0x89ABCDEF, 0x55AA55AA, 0xAA55AA55]
    try:
        ap.write_memory_block32(address, pattern)
        flush()
        if ap.read_memory_block32(address, 4) != pattern:
            raise RuntimeError("Flash algorithm SRAM write/read mismatch")
    finally:
        ap.write_memory_block32(address, saved)
        flush()
        if ap.read_memory_block32(address, 4) != saved:
            raise RuntimeError("Failed to restore SRAM scratch data")


def check_algorithm_stack(target, ap):
    """Reject inherited M33 stack contexts that the FLM cannot safely use.

    The vendor's stackless Init/EraseSector do not test ProgramPage's push.
    No limit, security state or fault status is modified to pass this check.
    """
    from pyocd.core.target import Target

    if target.selected_core.get_security_state() != Target.SecurityState.SECURE:
        raise RuntimeError("Flash algorithm requires confirmed Secure execution state")
    dscsr = ap.read32(DSCSR)
    # SBRSELEN overrides the register bank without changing the executing domain.
    # Reject it rather than checking one bank and preparing another.
    if dscsr & 1 or not dscsr & (1 << 16):
        raise RuntimeError("Ambiguous Secure debug register bank; no selector changed")
    control = target.read_core_register("control")
    xpsr = target.read_core_register("xpsr")
    if (control & 3 or control != target.read_core_register("control_s") or
            target.read_core_register("ipsr") != 0 or xpsr & 0x1FF or
            not xpsr & (1 << 24)):
        raise RuntimeError("Flash algorithm requires privileged Thumb Thread mode on MSP")
    region = target.memory_map.get_region_for_address(0)
    algorithm = region.flash.flash_algo
    low, high = algorithm.get("end_stack"), algorithm.get("begin_stack")
    if (type(low) is not int or type(high) is not int or low % 8 or high % 8 or
            not SRAM_BASE <= low < high <= SRAM_BASE + SRAM_SIZE):
        raise RuntimeError("Unknown or invalid flash algorithm stack allocation")
    limit = target.read_core_register("msplim_s")
    if type(limit) is not int or not 0 <= limit <= low:
        raise RuntimeError("Secure MSPLIM is incompatible with the flash algorithm stack; no limit changed")
    if ap.read32(0xE000ED28) & 0x00100000:
        raise RuntimeError("Existing STKOF fault; refusing flash without reviewed recovery")


@contextmanager
def flash_execution_context(target, ap):
    """Mask interrupts and permit SRAM execution; never perform a core reset."""
    from pyocd.core.target import Target

    if target.get_state() != Target.State.HALTED:
        raise RuntimeError("Target must be halted")
    if target.read_core_register("ipsr") != 0 or target.read_core_register("control") & 1:
        raise RuntimeError("Requires privileged Thread mode; no recovery/reset will be attempted")
    check_algorithm_stack(target, ap)
    primask, mpu_ctrl = target.read_core_register("primask"), ap.read32(MPU_CTRL)
    try:
        target.write_core_register("primask", 1)
        ap.write32(MPU_CTRL, 0)
        target.flush()
        if target.read_core_register("primask") != 1 or ap.read32(MPU_CTRL) != 0:
            raise RuntimeError("Failed to prepare MPU/interrupt state")
        yield
    finally:
        target.halt()
        target.flush()
        if target.get_state() != Target.State.HALTED:
            raise RuntimeError("Cannot restore MPU/interrupt state: core is not halted")
        ap.write32(MPU_CTRL, mpu_ctrl)
        target.write_core_register("primask", primask)
        target.flush()
        if ap.read32(MPU_CTRL) != mpu_ctrl or target.read_core_register("primask") != primask:
            raise RuntimeError("Failed to restore MPU/interrupt state")


def program(session, binary, progress, backup_dir):
    from pyocd.core.target import Target
    from pyocd.flash.loader import MemoryLoader

    check_connection(session)
    target = session.target
    ap = target.selected_core.ap
    with ap.hnonsec_lock(0):
        if ap.read32(DAUTHSTATUS) & 0xFF != 0xFF:
            raise RuntimeError("Full secure debug authentication required; no unlock attempted")
        if ap.read32(0x40000000) != PDID:
            raise RuntimeError("Target is not the confirmed M3351KJCAE (PDID 0x03302140)")
        target.halt()
        target.flush()
        if target.get_state() != Target.State.HALTED:
            raise RuntimeError("Target did not halt; refusing programming")
        # Check the core context before borrowing RAM or accessing FMC commands.
        if target.read_core_register("ipsr") != 0 or target.read_core_register("control") & 1:
            raise RuntimeError("Core is not in privileged Thread mode; stop for reviewed recovery")
        region = target.memory_map.get_region_for_address(0)
        if (region is None or not region.is_flash or region.start != 0
                or region.length != FLASH_SIZE or region.flash is None
                or region.blocksize != SECTOR_SIZE):
            raise RuntimeError("Pack must provide 1 MiB APROM with 8192-byte erase sectors")
        check_algorithm_stack(target, ap)
        baseline = bytes(ap.read_memory_block8(0, FLASH_SIZE))
        verify_aprom(bytes(ap.read_memory_block8(0, FLASH_SIZE)), baseline)
        print(f"Current 1 MiB APROM backup: {backup_aprom(baseline, backup_dir)}", flush=True)
        preserved = {}
        for name, (address, size) in PRESERVED_REGIONS.items():
            data = bytes(ap.read_memory_block8(address, size))
            if len(data) != size or bytes(ap.read_memory_block8(address, size)) != data:
                raise RuntimeError(f"Cannot obtain stable {name} backup")
            backup_region(data, backup_dir, name)
            preserved[address] = data
        config = read_config(ap, session.probe.flush)
        backup_region(json.dumps(config, sort_keys=True).encode(), backup_dir, "config")
        check_flash_guards(ap, config)
        check_sram(ap, session.probe.flush)
        payload, expected = write_plan(binary, baseline)
        with flash_execution_context(target, ap):
            algorithm = region.flash
            try:
                progress["algorithm_attempted"] = True
                algorithm.init(algorithm.Operation.VERIFY, reset=False)
                algorithm.uninit()
            finally:
                try:
                    algorithm.cleanup()
                finally:
                    target.halt()
            verify_aprom(bytes(ap.read_memory_block8(0, FLASH_SIZE)), baseline)
            if read_config(ap, session.probe.flush) != config:
                raise RuntimeError("Configuration changed during algorithm initialization")
            check_connection(session)
            if ap.read32(DAUTHSTATUS) & 0xFF != 0xFF:
                raise RuntimeError("Secure debug authentication changed")
            check_flash_guards(ap, config)
            loader = MemoryLoader(session, chip_erase="sector", smart_flash=False,
                                  trust_crc=False, keep_unwritten=True)
            loader.add_data(0, payload)
            print(f"Sector erase/program interval: [0x00000000, {len(payload):#010x})", flush=True)
            progress["programming_attempted"] = True
            try:
                loader.commit()
            finally:
                target.halt()
                target.flush()
            verify_aprom(bytes(ap.read_memory_block8(0, FLASH_SIZE)), expected)
            if read_config(ap, session.probe.flush) != config:
                raise RuntimeError("Configuration changed during programming")
            for address, data in preserved.items():
                if bytes(ap.read_memory_block8(address, len(data))) != data:
                    raise RuntimeError(f"Preserved region changed at {address:#x}")
            check_flash_guards(ap, config)


def session_options(pack, directory):
    return dict(target_override=TARGET, pack=str(pack), auto_unlock=False,
                connect_mode="attach", frequency=1000000, resume_on_disconnect=False,
                no_config=True, user_script=os.devnull, project_dir=str(directory),
                options={"pack.debug_sequences.enable": False,
                         "pack.debug_sequences.disabled_sequences": ["DebugPortStart", "DebugPortStop"],
                         "load.pre_reset": "off", "load.post_reset": "off",
                         "cache.enable_memory": False, "cache.enable_register": False,
                         "cache.read_code_from_elf": False})


DHCSR = 0xE000EDF0
DCRSR = 0xE000EDF4
DCRDR = 0xE000EDF8
DEMCR = 0xE000EDFC
FP_CTRL = 0xE0002000
FP_COMP0 = 0xE0002008
DHCSR_KEY = 0xA05F0000


@contextmanager
def raw_debug_port(probe):
    """Bare DP/MEM-AP access without target discovery, pack sequences or reset."""
    from pyocd.core.session import Session
    from pyocd.coresight.ap import AccessPort, APv1Address
    from pyocd.coresight.dap import DebugPort
    from pyocd.probe.debug_probe import DebugProbe

    session = Session(probe, auto_open=False, options={
        "no_config": True, "target_override": "cortex_m", "auto_unlock": False,
        "frequency": 1000000, "resume_on_disconnect": False})
    probe.open()
    try:
        probe.connect(DebugProbe.Protocol.SWD)
        dp = DebugPort(probe, session.target)
        dp.connect()

        def mem_ap():
            ap = AccessPort.create(dp, APv1Address(0))
            ap.init()
            return ap

        yield dp, mem_ap
    finally:
        probe.disconnect()
        probe.close()


def pulse_reset_with_debug_down(probe, dp, settle_seconds):
    """Pin reset while the DP is powered down so the Secure Bootloader sees no debugger."""
    from pyocd.coresight.dap import DP_CTRL_STAT, CDBGPWRUPACK, CSYSPWRUPACK

    dp.power_down_debug()
    if dp.read_reg(DP_CTRL_STAT) & (CDBGPWRUPACK | CSYSPWRUPACK):
        raise RuntimeError("Debug port did not power down before the reset pulse")
    probe.assert_reset(True)
    sleep(0.02)
    probe.assert_reset(False)
    sleep(settle_seconds)


def halt_at_reset_vector(probe):
    """Established M3351 entry: FPB breakpoint on the APROM Reset_Handler, C_DEBUGEN,
    DP powered down during one nRESET pulse, DP up afterwards. The core stops at the
    first application instruction in Secure privileged Thread mode on MSP with VECMAP 0,
    which is exactly the state the algorithm guards require. Debug-register writes
    and a pin reset only; no flash, CONFIG, security or RAM writes."""
    with raw_debug_port(probe) as (dp, mem_ap):
        ap = mem_ap()
        if (ap.read32(FMC + 0x40) >> 10) & 0x3FFFF:
            raise RuntimeError("VECMAP is not 0; address 0 is not APROM page 0, not arming")
        sp0, reset_handler = ap.read_memory_block32(0, 2)
        if (not reset_handler & 1 or not 2 <= reset_handler < FLASH_SIZE
                or not SRAM_BASE < sp0 <= SRAM_BASE + SRAM_SIZE):
            raise RuntimeError("APROM vector table is not a valid application; use the ROM-halt case scripts")
        breakpoint_address = reset_handler & ~1
        ap.write32(DEMCR, 0)
        ap.write32(DHCSR, DHCSR_KEY | 1)
        ap.write32(FP_CTRL, 0x3)
        ap.write32(FP_COMP0, breakpoint_address | 1)
        probe.flush()
        if ap.read32(FP_COMP0) != (breakpoint_address | 1) or not ap.read32(FP_CTRL) & 1:
            raise RuntimeError("FPB comparator did not arm")
        pulse_reset_with_debug_down(probe, dp, 0.05)
        dp.connect()
        ap = mem_ap()
        ap.read32(DHCSR)
        dhcsr = ap.read32(DHCSR)
        halted, lockup, sde = dhcsr & (1 << 17), dhcsr & (1 << 19), dhcsr & (1 << 20)
        ap.write32(DCRSR, 15)
        probe.flush()
        pc = ap.read32(DCRDR) if ap.read32(DHCSR) & (1 << 16) else None
        ap.write32(FP_COMP0, 0)
        ap.write32(FP_CTRL, 0x2)
        probe.flush()
        if lockup or not halted or not sde or pc != breakpoint_address:
            raise RuntimeError(f"Reset-vector halt failed: DHCSR={dhcsr:#x} pc={pc}; core left as is")
        print(f"Halted at Reset_Handler {breakpoint_address:#x} (DHCSR={dhcsr:#x})", flush=True)


def release_to_boot(probe):
    """Clear debug enables, power the DP down and pulse nRESET once; never reconnect."""
    with raw_debug_port(probe) as (dp, mem_ap):
        ap = mem_ap()
        ap.write32(DEMCR, 0)
        ap.write32(DHCSR, DHCSR_KEY)
        probe.flush()
        # DEMCR[20] SDME is read-only on Armv8-M.
        if ap.read32(DEMCR) & ~(1 << 20) or ap.read32(DHCSR) & 0x3:
            raise RuntimeError("Debug enables did not clear; target not released")
        pulse_reset_with_debug_down(probe, dp, 0.0)
    print("Debug released and nRESET pulsed; boot is not verified by this tool.", flush=True)


def flash(binary, pack, probe_id, progress, backup_dir, halt_first=False, boot_after=False):
    """Explicit live path. Must be run via an arbitrated hardware tool, not shell."""
    validate_pack(pack)
    if importlib.metadata.version("pyocd") != "0.46.0":
        raise RuntimeError("This session adapter requires audited pyOCD 0.46.0")
    if any(name == "pyocd" or name.startswith("pyocd.") for name in sys.modules):
        raise RuntimeError("Run as a fresh process: pyOCD was imported before cache isolation")
    saved = {key: os.environ.get(key) for key in ("HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME")}
    previous_cwd = Path.cwd()
    try:
        with tempfile.TemporaryDirectory(prefix="m3351-pyocd-") as home:
            os.environ.update(HOME=home, XDG_DATA_HOME=str(Path(home) / "data"),
                              XDG_CACHE_HOME=str(Path(home) / "cache"))
            from pyocd.core.helpers import ConnectHelper
            from pyocd.core.session import Session

            probe = select_probe(ConnectHelper.get_all_connected_probes(blocking=False), probe_id)
            if halt_first:
                halt_at_reset_vector(probe)
            directory = Path(home) / "project"
            directory.mkdir()
            session = Session(probe, **session_options(pack, directory))
            session.delegate = AttachDelegate(session)
            try:
                session.open()
                program(session, binary, progress, backup_dir)
            finally:
                session.close()
            if boot_after:
                release_to_boot(probe)
    finally:
        for key, value in saved.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
        os.chdir(previous_cwd)


def parse_usb_tree(nodes):
    """Extract OS-reported USB identities and their descendant serial nodes."""
    devices = {}

    def visit(node, owner=None):
        if (node.get("IOObjectClass") == "IOUSBHostDevice"
                and "idVendor" in node and "idProduct" in node):
            key = node.get("IORegistryEntryID", (node.get("locationID"), node.get("USB Serial Number")))
            owner = devices.setdefault(key, {
                "vid": node["idVendor"], "pid": node["idProduct"],
                "product": node.get("USB Product Name", node.get("IORegistryEntryName")),
                "serial": node.get("USB Serial Number"),
                "location": node.get("locationID"), "interfaces": [], "ports": []})
        if owner is not None:
            if node.get("IOObjectClass") == "IOUSBHostInterface" and "bInterfaceClass" in node:
                interface = {k: node[k] for k in ("bInterfaceNumber", "bInterfaceClass",
                             "bInterfaceSubClass", "bInterfaceProtocol") if k in node}
                if interface not in owner["interfaces"]:
                    owner["interfaces"].append(interface)
            if "IOCalloutDevice" in node and node["IOCalloutDevice"] not in owner["ports"]:
                owner["ports"].append(node["IOCalloutDevice"])
        for child in node.get("IORegistryEntryChildren", []):
            visit(child, owner)

    for node in nodes:
        visit(node)
    return list(devices.values())


def passive_usb_inventory():
    """IORegistry only; never open a probe, serial device or USB interface."""
    if sys.platform != "darwin":
        raise RuntimeError("--list-usb uses macOS IORegistry; offline image validation is portable")
    result = subprocess.run(["/usr/sbin/ioreg", "-a", "-l", "-r", "-c", "IOUSBHostDevice"],
                            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
    # ioreg exits successfully with empty output when no class instances match.
    nodes = []
    if result.stdout.strip():
        try:
            nodes = plistlib.loads(result.stdout)
        except (plistlib.InvalidFileException, ExpatError, ValueError) as exc:
            raise RuntimeError(f"Invalid IORegistry plist: {exc}") from exc
        if not isinstance(nodes, list) or any(not isinstance(node, dict) for node in nodes):
            raise RuntimeError("Invalid IORegistry plist: expected an array of registry nodes")
    return {"method": "macOS IORegistry only; no device opened",
            "devices": parse_usb_tree(nodes)}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-dir", type=Path, help="required explicit build containing zephyr/ELF+bin")
    parser.add_argument("--pack", help="audited local CMSIS pack, or NUVOTON_DFP")
    parser.add_argument("--probe", help="full unique probe ID, required for --program")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="offline validation (also the default)")
    mode.add_argument("--program", action="store_true", help="live diagnostic programmer, NOT recovery")
    mode.add_argument("--list-usb", action="store_true", help="macOS OS-level inventory only")
    parser.add_argument("--halt-at-reset-vector", action="store_true",
                        help="with --program: FPB halt at the current APROM Reset_Handler via one "
                             "nRESET pulse with the DP powered down (established M3351 entry)")
    parser.add_argument("--boot", action="store_true",
                        help="with --program: after verified programming, clear debug enables "
                             "and pulse nRESET once so the new image boots")
    args = parser.parse_args(argv)
    if not args.list_usb and args.build_dir is None:
        parser.error("--build-dir is required; no implicit Hello World or stale build")
    if args.program and not args.probe:
        parser.error("--program requires the full --probe ID")
    if (args.halt_at_reset_vector or args.boot) and not args.program:
        parser.error("--halt-at-reset-vector and --boot are only meaningful with --program")
    progress = {"algorithm_attempted": False, "programming_attempted": False}
    try:
        if args.list_usb:
            print(json.dumps(passive_usb_inventory(), indent=2))
            return 0
        binary = validate_image(args.build_dir)
        pack = resolve_pack(args.pack)
        validate_pack(pack)
        end = (len(binary) + SECTOR_SIZE - 1) // SECTOR_SIZE * SECTOR_SIZE
        print(json.dumps({"target": TARGET, "pdid": hex(PDID), "aprom_bytes": FLASH_SIZE,
                          "image_bytes": len(binary), "image_sha256": hashlib.sha256(binary).hexdigest(),
                          "pack": str(pack), "pack_sha256": PACK_SHA256, "flm_sha256": FLM_SHA256,
                          "planned_erase_interval_exclusive": [0, end],
                          "trailing_sector_bytes_require_current_backup": end - len(binary),
                          "hardware_verified": False}, indent=2))
        if not args.program:
            print("Offline validation passed; no pyOCD import or hardware access. NOT HIL acceptance.")
            return 0
        flash(binary, pack, args.probe, progress, WORKSPACE / ".embedder/backups",
              halt_first=args.halt_at_reset_vector, boot_after=args.boot)
    except (Exception, KeyboardInterrupt) as exc:
        print(f"Validation/programming failed: {exc}", file=sys.stderr)
        if progress["programming_attempted"]:
            print("APROM may be partially modified. Preserve backups; do not retry blindly.", file=sys.stderr)
        elif progress["algorithm_attempted"]:
            print("A RAM algorithm was attempted. Target state is not verified.", file=sys.stderr)
        print("No verified success; no automatic reset, unlock or resume requested.", file=sys.stderr)
        return 1
    print("Verified current 1 MiB APROM, documented configuration words, LDROM and Data Flash.")
    if not args.boot:
        print("No reset/resume requested. Debug disconnect does not establish a bootable/running target.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
