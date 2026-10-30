"""Offline flasher regressions: synthetic ARM ELFs/packs, never a live backend."""
import builtins
from contextlib import contextmanager
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import stat
import struct
from types import SimpleNamespace
import xml.etree.ElementTree as ET
import zipfile

import pytest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("flash_script", ROOT / "tools/flash.py")
f = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(f)
REAL_PROGRAM = f.program  # Exercised only with the in-memory targets below.

# Independent board/format expectations, not values derived from the code under test.
APROM = 0x100000
SRAM = 0x20000000
SECTOR = 0x2000
FLM = "Flash/M3351_AP_1M.FLM"
FAKE_FLM = b"synthetic offline flash algorithm; not executable"
CFSR = 0xE000ED28
STACK_END = SRAM + 0x3000
STACK_BEGIN = SRAM + 0x3800


def forbidden(*args, **kwargs):
    pytest.fail("Offline regression attempted a hardware/backend or external process call")


@pytest.fixture(autouse=True)
def offline_only(monkeypatch):
    original_import = builtins.__import__

    def guarded_import(name, *args, **kwargs):
        if name.split(".")[0] in {"pyocd", "serial", "usb"}:
            forbidden(name)
        return original_import(name, *args, **kwargs)

    monkeypatch.setattr(builtins, "__import__", guarded_import)
    monkeypatch.setattr(f.subprocess, "run", forbidden)
    monkeypatch.setattr(f.subprocess, "Popen", forbidden)
    monkeypatch.setattr(f, "program", forbidden)


def boot_image(size=16, sp=0x20020000, pc=9):
    return struct.pack("<II", sp, pc) + b"\x00\xbf" * ((size - 8) // 2) + b"\x00" * (size % 2)


@pytest.fixture
def image(tmp_path):
    def make(segments=None, sections=None, binary=None, entry=9, bits=32, endian="<", machine=40,
             elf_type=2, truncate=0):
        """Emit real ELF/program/section headers without a compiler or mocked parser."""
        segments = [{"data": boot_image()}] if segments is None else segments
        if sections is None:
            sections = []
            for index, segment in enumerate(segments):
                allocated = segment.get("type", 1) == 1
                payload = segment.get("data", b"")
                if payload:
                    sections.append({"segment": index, "size": len(payload),
                                     "flags": (2 | (4 if segment.get("flags", 5) & 1 else 0)) if allocated else 0})
                elif allocated and segment.get("memsz", 0):
                    sections.append({"segment": index, "size": segment["memsz"], "type": 8})
        header_size, ph_size, sh_size = (52, 32, 40) if bits == 32 else (64, 56, 64)
        sh_offset = header_size + ph_size * len(segments)
        ident = b"\x7fELF" + bytes([1 if bits == 32 else 2, 1 if endian == "<" else 2, 1]) + bytes(9)
        header_format = "16sHHIIIIIHHHHHH" if bits == 32 else "16sHHIQQQIHHHHHH"
        header = struct.pack(endian + header_format, ident, elf_type, machine, 1, entry,
                             header_size, sh_offset, 0, header_size, ph_size, len(segments),
                             sh_size, len(sections) + 1, 0)
        headers, data = bytearray(), bytearray()
        offset = sh_offset + sh_size * (len(sections) + 1)
        loads, file_offsets = [], []
        for segment in segments:
            payload = segment.get("data", b"")
            physical = segment.get("paddr", 0)
            virtual = segment.get("vaddr", physical)
            filesz = segment.get("filesz", len(payload))
            memsz = segment.get("memsz", filesz)
            kind, flags = segment.get("type", 1), segment.get("flags", 5)
            if bits == 32:
                fields = (kind, offset, virtual, physical, filesz, memsz, flags, 4)
                headers.extend(struct.pack(endian + "IIIIIIII", *fields))
            else:
                fields = (kind, flags, offset, virtual, physical, filesz, memsz, 4)
                headers.extend(struct.pack(endian + "IIQQQQQQ", *fields))
            file_offsets.append(offset)
            data.extend(payload)
            offset += len(payload)
            if kind == 1 and payload:
                loads.append((physical, len(payload)))
        section_headers, section_loads = bytearray(sh_size), []  # ELF section zero is SHT_NULL.
        for section in sections:
            index = section.get("segment", 0)
            segment = segments[index]
            relative = section.get("offset", 0)
            payload = segment.get("data", b"")
            size = section.get("size", len(payload) - relative)
            physical = segment.get("paddr", 0)
            address = section.get("address", segment.get("vaddr", physical) + relative)
            flags = section.get("flags", 2 | (4 if segment.get("flags", 5) & 1 else 0))
            kind = section.get("type", 1)
            section_offset = file_offsets[index] + relative + section.get("file_offset_delta", 0)
            fields = (0, kind, flags, address, section_offset, size, 0, 0, 1, 0)
            section_headers.extend(struct.pack(endian + ("IIIIIIIIII" if bits == 32 else "IIQQQQIIQQ"),
                                               *fields))
            if flags & 2 and kind != 8:
                section_loads.append((physical + relative, payload[relative:relative + size]))
        if binary is None:
            length = max((address + size for address, size in loads), default=0)
            binary = bytearray(b"\xff" * length)
            for address, payload in section_loads:
                binary[address:address + len(payload)] = payload
            binary = bytes(binary)
        directory = tmp_path / "build" / "zephyr"
        directory.mkdir(parents=True, exist_ok=True)
        # Data follows both header tables so truncation removes payload, not section metadata.
        elf = bytes(header + headers + section_headers + data)
        (directory / "zephyr.elf").write_bytes(elf[:-truncate] if truncate else elf)
        (directory / "zephyr.bin").write_bytes(binary)
        return directory.parent, binary

    return make


@pytest.fixture
def pack(tmp_path, monkeypatch):
    # Only these generated, non-executable archives have synthetic trust pins.
    monkeypatch.setattr(f, "FLM_SHA256", hashlib.sha256(FAKE_FLM).hexdigest())

    def make(device="M3351KJCAE", memory=None, algorithm=None, omit=None, flm=FAKE_FLM):
        root = ET.Element("package")
        target = ET.SubElement(root, "device", Dname=device)
        mem = {"id": "IROM1", "start": "0x0", "size": "0x100000"}
        alg = {"name": FLM, "start": "0x0", "size": "0x100000",
               "RAMstart": "0x20000000", "RAMsize": "0x4000"}
        mem.update(memory or {})
        alg.update(algorithm or {})
        if omit != "memory":
            ET.SubElement(target, "memory", mem)
        if omit != "algorithm":
            ET.SubElement(target, "algorithm", alg)
        path = tmp_path / "synthetic.pack"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr(FLM, flm)
            archive.writestr("Nuvoton.NuMicroM33_DFP.pdsc", ET.tostring(root))
        monkeypatch.setattr(f, "PACK_SHA256", hashlib.sha256(path.read_bytes()).hexdigest())
        return path

    return make


def test_confirmed_kj_identity_and_audited_pins():
    assert (f.TARGET, f.DEVICE, f.PDID) == ("m3351kjcae", "M3351KJCAE", 0x03302140)
    assert (f.FLASH_SIZE, f.SECTOR_SIZE, f.SRAM_BASE, f.SRAM_SIZE) == (APROM, SECTOR, SRAM, 0x20000)
    assert f.PACK_NAME == "Nuvoton.NuMicroM33_DFP.1.0.6.pack"
    assert f.PACK_SHA256 == "0aae782356a261b976169fb677a5785c8647b5e0a0a93fa1632fb71a04b2dde2"
    assert f.FLM_NAME == FLM
    assert f.FLM_SHA256 == "6ad56e7e085dae4ed3f61abd6bcc2edde2ffd53424ca28a6fedc6d743b369717"


@pytest.mark.parametrize("size", [16, 0x80001, APROM])
@pytest.mark.parametrize("entry", [8, 9])
def test_image_real_arm_elf_and_kj_upper_half_are_valid(image, size, entry):
    directory, binary = image(segments=[{"data": boot_image(size)}], entry=entry)
    assert len(binary) == size
    assert f.validate_image(directory) == binary


def test_image_accepts_ff_gaps_relocated_data_and_ram_bss(image):
    directory, binary = image(segments=[
        {"data": boot_image()},
        {"paddr": 32, "vaddr": SRAM, "data": b"data", "flags": 6},
        {"paddr": APROM, "vaddr": SRAM + 4, "memsz": 0x1FFFC, "flags": 6},
        {"type": 4, "data": b"non-load metadata"},
    ])
    assert binary[16:32] == b"\xff" * 16
    assert f.validate_image(directory) == binary


@pytest.mark.parametrize("size", [0, 7, APROM + 1])
def test_image_rejects_binary_bounds(image, size):
    directory, _ = image(binary=bytes(size))
    with pytest.raises(ValueError, match="1 MiB KJ APROM"):
        f.validate_image(directory)


@pytest.mark.parametrize("options", [
    {"bits": 64}, {"endian": ">"}, {"machine": 3}, {"elf_type": 3},
])
def test_image_rejects_wrong_elf_architecture(image, options):
    directory, _ = image(**options)
    with pytest.raises(ValueError, match="little-endian ARM32 executable"):
        f.validate_image(directory)


@pytest.mark.parametrize("sp", [SRAM, SRAM - 8, SRAM + 0x20008, SRAM + 4, SRAM + 0x1FFFF])
def test_image_rejects_invalid_or_unaligned_stack(image, sp):
    directory, _ = image(segments=[{"data": boot_image(sp=sp)}])
    with pytest.raises(ValueError, match="stack pointer"):
        f.validate_image(directory)


@pytest.mark.parametrize("pc", [0, 1, 7, 8, 17, 0x20000009])
def test_image_rejects_non_thumb_or_out_of_code_reset_vector(image, pc):
    directory, _ = image(segments=[{"data": boot_image(pc=pc)}])
    with pytest.raises(ValueError, match="Reset vector"):
        f.validate_image(directory)


@pytest.mark.parametrize("segment", [{"flags": 6}, {"vaddr": SRAM}])
def test_image_reset_must_be_executable_in_place_not_relocated(image, segment):
    directory, _ = image(segments=[{"data": boot_image(), **segment}])
    with pytest.raises(ValueError, match="Reset vector"):
        f.validate_image(directory)


def test_image_entry_must_match_reset_vector(image):
    directory, _ = image(entry=11)
    with pytest.raises(ValueError, match="entry point differs"):
        f.validate_image(directory)


@pytest.mark.parametrize("segment,match", [
    ({"memsz": 15}, "file size exceeds"),
    ({"vaddr": APROM - 8}, "runtime segment"),
    ({"vaddr": SRAM + 0x20000 - 8}, "runtime segment"),
    ({"vaddr": 0x10000000}, "runtime segment"),
    ({"paddr": 1}, "load segment exceeds"),
    ({"paddr": APROM - 8, "vaddr": SRAM}, "load segment exceeds"),
])
def test_image_rejects_invalid_segment_ranges(image, segment, match):
    directory, _ = image(segments=[{"data": boot_image(), **segment}], binary=boot_image())
    with pytest.raises(ValueError, match=match):
        f.validate_image(directory)


def test_image_checks_zero_file_size_ram_runtime_bounds(image):
    directory, _ = image(segments=[{"data": boot_image()},
                                   {"vaddr": SRAM + 0x1FFF8, "memsz": 16}])
    with pytest.raises(ValueError, match="runtime segment"):
        f.validate_image(directory)


def test_image_rejects_overlapping_physical_loads(image):
    directory, _ = image(segments=[{"data": boot_image()}, {"paddr": 8, "data": b"overlap"}],
                         binary=boot_image())
    with pytest.raises(ValueError, match="overlap"):
        f.validate_image(directory)


@pytest.mark.parametrize("segments", [[], [{"type": 4, "data": b"notes"}],
                                      [{"paddr": 8, "data": boot_image()}]])
def test_image_requires_a_load_at_vector_base_zero(image, segments):
    directory, _ = image(segments=segments, binary=boot_image(24))
    with pytest.raises(ValueError, match="base zero"):
        f.validate_image(directory)


def test_image_rejects_unaccounted_binary_tail(image):
    directory, _ = image(binary=boot_image() + b"\0")
    with pytest.raises(ValueError, match="extents differ"):
        f.validate_image(directory)


@pytest.mark.parametrize("offset", [8, 20, 32])
def test_image_compares_payload_and_ff_padding(image, offset):
    binary = bytearray(boot_image() + b"\xff" * 16 + b"data")
    binary[offset] ^= 1
    directory, _ = image(segments=[{"data": boot_image()}, {"paddr": 32, "data": b"data"}],
                         binary=bytes(binary))
    with pytest.raises(ValueError, match="contents differ"):
        f.validate_image(directory)


@pytest.fixture
def within_segment_gap(image):
    # objcopy fills this hole between allocated sections, not just between PT_LOADs.
    return image(segments=[{"data": boot_image() + bytes(4) + b"tail"}],
                 sections=[{"offset": 0, "size": 16}, {"offset": 20, "size": 4}])


def test_image_reconstructs_ff_gap_inside_one_load_segment(within_segment_gap):
    from elftools.elf.elffile import ELFFile

    directory, binary = within_segment_gap
    with (directory / "zephyr/zephyr.elf").open("rb") as stream:
        elf = ELFFile(stream)
        assert elf.num_segments() == 1
        assert elf.get_segment(0).data()[16:20] == bytes(4)
        assert [section["sh_size"] for section in elf.iter_sections()] == [0, 16, 4]
    assert binary == boot_image() + b"\xff" * 4 + b"tail"
    assert f.validate_image(directory) == binary


@pytest.mark.parametrize("pc", [17, 19])
@pytest.mark.parametrize("entry_thumb", [False, True])
def test_image_rejects_reset_and_entry_in_executable_segment_padding(image, pc, entry_thumb):
    entry = (pc & ~1) | int(entry_thumb)
    directory, binary = image(segments=[{"data": boot_image(pc=pc) + bytes(4) + b"\x00\xbf" * 2}],
                              sections=[{"size": 16, "flags": 6},
                                        {"offset": 20, "size": 4, "flags": 6}], entry=entry)
    assert binary[16:20] == b"\xff" * 4
    assert int.from_bytes(binary[4:8], "little") & ~1 in (16, 18)
    with pytest.raises(ValueError, match="Reset vector"):
        f.validate_image(directory)


@pytest.mark.parametrize("entry", [20, 21])
def test_image_accepts_boot_in_allocated_code_after_within_segment_padding(image, entry):
    directory, binary = image(segments=[{"data": boot_image(pc=21) + bytes(4) + b"\x00\xbf" * 2}],
                              sections=[{"size": 16, "flags": 6},
                                        {"offset": 20, "size": 4, "flags": 6}], entry=entry)
    assert binary[16:20] == b"\xff" * 4
    assert f.validate_image(directory) == binary


def test_image_rejects_reset_into_nonexecutable_allocated_section(image):
    directory, binary = image(sections=[{"size": 8, "flags": 2},
                                        {"offset": 8, "size": 8, "flags": 2}])
    assert binary[8:10] == b"\x00\xbf"
    with pytest.raises(ValueError, match="Reset vector"):
        f.validate_image(directory)


@pytest.mark.parametrize("offset,value", [(8, 0xFF), (16, 0), (19, 0xFE), (20, 0xFF)])
def test_image_rejects_corrupt_section_or_within_segment_gap(within_segment_gap, offset, value):
    directory, binary = within_segment_gap
    corrupt = bytearray(binary)
    assert corrupt[offset] != value
    corrupt[offset] = value
    (directory / "zephyr/zephyr.bin").write_bytes(corrupt)
    with pytest.raises(ValueError, match="contents differ"):
        f.validate_image(directory)


@pytest.mark.parametrize("sections", [[], [{"flags": 0}], [{"type": 8}]])
def test_image_requires_allocated_file_backed_payload_sections(image, sections):
    directory, _ = image(sections=sections, binary=boot_image())
    with pytest.raises(ValueError, match="allocated|payload"):
        f.validate_image(directory)


@pytest.mark.parametrize("address", [0x1000, SRAM, SRAM + 0x20000])
def test_image_rejects_allocated_section_outside_load_segment(image, address):
    directory, _ = image(sections=[{"address": address}], binary=boot_image())
    with pytest.raises(ValueError, match="section.*(PT_LOAD|segment|outside)"):
        f.validate_image(directory)


def test_image_rejects_section_file_offset_disagreeing_with_runtime_offset(image):
    directory, _ = image(sections=[{"size": 8, "file_offset_delta": 4}], binary=boot_image())
    with pytest.raises(ValueError, match="section.*(disagrees|segment)"):
        f.validate_image(directory)


def test_image_rejects_overlapping_allocated_payload_sections(image):
    directory, _ = image(sections=[{"size": 16}, {"offset": 8, "size": 8}])
    with pytest.raises(ValueError, match="section.*overlap|overlap.*section"):
        f.validate_image(directory)


def test_image_ignores_nonallocated_and_nobits_sections_inside_gap(image):
    directory, binary = image(segments=[{"data": boot_image() + b"metadata" + b"tail"}],
                              sections=[{"size": 16}, {"offset": 16, "size": 4, "flags": 0},
                                        {"offset": 20, "size": 4, "type": 8},
                                        {"offset": 24, "size": 4}])
    assert binary == boot_image() + b"\xff" * 8 + b"tail"
    assert f.validate_image(directory) == binary


@pytest.mark.parametrize("fill", [0x00, 0x7F])
def test_image_rejects_wrong_intersegment_gap_fill(image, fill):
    directory, _ = image(segments=[{"data": boot_image()}, {"paddr": 32, "data": b"tail"}],
                         binary=boot_image() + bytes([fill]) * 16 + b"tail")
    with pytest.raises(ValueError, match="contents differ"):
        f.validate_image(directory)


def test_image_rejects_truly_sectionless_elf(image):
    directory, _ = image()
    path = directory / "zephyr/zephyr.elf"
    content = bytearray(path.read_bytes())
    struct.pack_into("<I", content, 32, 0)  # e_shoff
    struct.pack_into("<HHH", content, 46, 0, 0, 0)  # e_shentsize, e_shnum, e_shstrndx
    path.write_bytes(content)
    with pytest.raises(ValueError, match="allocated sections"):
        f.validate_image(directory)


def test_image_rejects_nonempty_load_without_allocated_payload_section(image):
    directory, _ = image(segments=[{"data": boot_image()},
                                   {"paddr": 32, "data": b"unrepresented"},
                                   {"paddr": 64, "data": b"tail"}],
                         sections=[{"segment": 0}, {"segment": 2}])
    with pytest.raises(ValueError, match="section|payload|cover"):
        f.validate_image(directory)


def test_image_rejects_truncated_elf_segment(image):
    directory, _ = image(truncate=1)
    with pytest.raises(ValueError, match="segment is truncated"):
        f.validate_image(directory)


def test_image_rejects_binary_changing_after_stat(image, monkeypatch):
    directory, _ = image()
    original = Path.read_bytes
    binary_path = directory / "zephyr/zephyr.bin"
    monkeypatch.setattr(Path, "read_bytes", lambda path: b"short" if path == binary_path else original(path))
    with pytest.raises(ValueError, match="changed during validation"):
        f.validate_image(directory)


def test_pack_validates_synthetic_trusted_container_and_flm(pack):
    assert f.validate_pack(pack()) is None


def test_pack_rejects_container_corruption_before_zip_parsing(pack):
    path = pack()
    path.write_bytes(path.read_bytes() + b"changed")
    with pytest.raises(ValueError, match="DFP hash differs"):
        f.validate_pack(path)


def test_pack_rejects_algorithm_corruption_even_with_trusted_container(pack):
    with pytest.raises(ValueError, match="algorithm hash differs"):
        f.validate_pack(pack(flm=FAKE_FLM + b"changed"))


@pytest.mark.parametrize("device", ["M3351KICAE", "m3351kjcae", "M3351KJCAE-extra"])
def test_pack_requires_exact_kj_device(pack, device):
    with pytest.raises(ValueError, match="exact KJ device"):
        f.validate_pack(pack(device=device))


@pytest.mark.parametrize("options", [
    {"omit": "memory"}, {"omit": "algorithm"},
    {"memory": {"id": "IROM2"}}, {"memory": {"start": "0x1000"}},
    {"memory": {"size": "0x80000"}}, {"memory": {"size": "0x100001"}},
    {"algorithm": {"name": "Flash/M3351_AP_512.FLM"}},
    {"algorithm": {"start": "0x1000"}}, {"algorithm": {"size": "0x80000"}},
    {"algorithm": {"RAMstart": "0x20000004"}}, {"algorithm": {"RAMsize": "0x8000"}},
])
def test_pack_rejects_wrong_memory_algorithm_or_scratch_geometry(pack, options):
    with pytest.raises(ValueError, match="Pack geometry differs"):
        f.validate_pack(pack(**options))


def test_resolve_pack_explicit_overrides_environment_and_workspace(tmp_path, monkeypatch):
    explicit = tmp_path / "explicit.PACK"
    explicit.write_bytes(b"not yet validated")
    monkeypatch.setenv("NUVOTON_DFP", str(tmp_path / "invalid.pack"))
    assert f.resolve_pack(str(explicit), tmp_path) == explicit.resolve()
    monkeypatch.setenv("NUVOTON_DFP", str(explicit))
    assert f.resolve_pack(workspace=tmp_path) == explicit.resolve()


@pytest.mark.parametrize("name", ["", "missing.pack", "wrong.zip", "directory.pack"])
def test_resolve_pack_rejects_invalid_explicit_path(tmp_path, name):
    (tmp_path / "wrong.zip").write_bytes(b"not a pack")
    (tmp_path / "directory.pack").mkdir()
    with pytest.raises(ValueError, match="existing local .pack"):
        f.resolve_pack(str(tmp_path / name) if name else "", tmp_path)


@pytest.mark.parametrize("cached_count", [0, 1, 2])
def test_resolve_pack_uses_exactly_one_offline_cache_candidate(tmp_path, monkeypatch, cached_count):
    monkeypatch.delenv("NUVOTON_DFP", raising=False)
    home = tmp_path / "home"
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: home))
    paths = []
    for index in range(cached_count):
        candidate = home / ".embedder/downloads" / str(index) / f.PACK_NAME
        candidate.parent.mkdir(parents=True)
        candidate.write_bytes(b"cached")
        paths.append(candidate)
    if cached_count == 1:
        assert f.resolve_pack(workspace=tmp_path) == paths[0]
    else:
        with pytest.raises(ValueError, match="exactly one cached official DFP; no downloads"):
            f.resolve_pack(workspace=tmp_path)
    local = tmp_path / ".deps/packs" / f.PACK_NAME
    local.parent.mkdir(parents=True)
    local.write_bytes(b"workspace wins even over ambiguous cache")
    assert f.resolve_pack(workspace=tmp_path) == local


@pytest.fixture
def baseline():
    return bytes(range(256)) * 4096


@pytest.mark.parametrize("size,end", [(8, SECTOR), (SECTOR - 1, SECTOR), (SECTOR, SECTOR),
                                     (SECTOR + 1, 2 * SECTOR), (0x80001, 0x82000), (APROM, APROM)])
def test_write_plan_preserves_sector_tail_and_entire_unwritten_aprom(baseline, size, end):
    binary = b"\xa5" * size
    payload, expected = f.write_plan(binary, baseline)
    assert len(payload) == end
    assert len(expected) == APROM
    assert payload == binary + baseline[size:end]
    assert expected == binary + baseline[size:]
    assert expected[end:] == baseline[end:]
    assert baseline == bytes(range(256)) * 4096


@pytest.mark.parametrize("binary_size,backup_size", [(7, APROM), (APROM + 1, APROM),
                                                   (8, 0x80000), (8, APROM - 1), (8, APROM + 1)])
def test_write_plan_rejects_partial_backups_and_unbounded_images(binary_size, backup_size):
    with pytest.raises(ValueError, match="full 1 MiB current backup"):
        f.write_plan(bytes(binary_size), bytes(backup_size))


def test_backup_is_private_content_addressed_and_idempotent(tmp_path):
    image = b"incomplete current image is still valuable"
    directory = tmp_path / "private"
    path = f.backup_region(image, directory, "ldrom")
    assert path.name == f"m3351kjcae-ldrom-{hashlib.sha256(image).hexdigest()}.bin"
    assert path.read_bytes() == image
    assert stat.S_IMODE(path.stat().st_mode) == 0o600
    assert stat.S_IMODE(directory.stat().st_mode) == 0o700
    before = path.stat()
    assert f.backup_region(image, directory, "ldrom") == path
    assert (path.stat().st_ino, path.stat().st_mtime_ns) == (before.st_ino, before.st_mtime_ns)


@pytest.mark.parametrize("collision", ["content", "symlink", "dangling-symlink", "directory"])
def test_backup_rejects_collision_and_nonregular_existing_path(tmp_path, collision):
    image = b"current APROM bytes"
    path = tmp_path / f"m3351kjcae-aprom-{hashlib.sha256(image).hexdigest()}.bin"
    if collision == "content":
        path.write_bytes(b"wrong bytes at correct hash filename")
    elif collision in {"symlink", "dangling-symlink"}:
        destination = tmp_path / "destination"
        if collision == "symlink":
            destination.write_bytes(image)
        path.symlink_to(destination)
    else:
        path.mkdir()
    with pytest.raises(RuntimeError, match="collision check failed|not a regular file"):
        f.backup_region(image, tmp_path, "aprom")
    if collision == "content":
        assert path.read_bytes() == b"wrong bytes at correct hash filename"
    elif collision == "symlink":
        assert destination.read_bytes() == image


@pytest.mark.parametrize("size", [0x80000, APROM - 1, APROM + 1])
def test_backup_aprom_rejects_historical_or_partial_size(tmp_path, size):
    with pytest.raises(ValueError, match="exactly 1 MiB"):
        f.backup_aprom(bytes(size), tmp_path)
    assert list(tmp_path.iterdir()) == []


def test_backup_aprom_and_full_verification_include_upper_half(tmp_path, baseline):
    path = f.backup_aprom(baseline, tmp_path)
    assert path.read_bytes() == baseline
    assert f.verify_aprom(baseline, baseline) is None
    changed = bytearray(baseline)
    changed[0x80000] ^= 1
    with pytest.raises(RuntimeError, match="failed at 0x80000"):
        f.verify_aprom(bytes(changed), baseline)


@pytest.mark.parametrize("actual_size,expected_size", [(0x80000, APROM), (APROM, 0x80000),
                                                     (APROM + 1, APROM)])
def test_verification_never_accepts_a_partial_or_oversized_comparison(actual_size, expected_size):
    with pytest.raises(RuntimeError, match="exactly 1 MiB"):
        f.verify_aprom(bytes(actual_size), bytes(expected_size))


@pytest.fixture
def usb_tree():
    port = {"IOObjectClass": "IOSerialBSDClient", "IORegistryEntryID": 103,
            "idVendor": 0xCAFE, "idProduct": 1, "IOCalloutDevice": "/dev/cu.fake-console"}
    nested = {"IOObjectClass": "IOUSBHostDevice", "idVendor": 0xCAFE, "idProduct": 2,
              "IORegistryEntryID": 200, "IORegistryEntryName": "Nested probe", "locationID": 12,
              "IORegistryEntryChildren": [{"IOObjectClass": "IOSerialBSDClient",
                                           "IOCalloutDevice": "/dev/cu.fake-probe"}]}
    descriptor = {"bInterfaceNumber": 2, "bInterfaceClass": 2,
                  "bInterfaceSubClass": 2, "bInterfaceProtocol": 1}
    driver = {"IOObjectClass": "AppleUSBACMData", "IORegistryEntryID": 102,
              "idVendor": 0xCAFE, "idProduct": 1, **descriptor,
              "IORegistryEntryChildren": [port, dict(port), nested]}
    interface = {"IOObjectClass": "IOUSBHostInterface", "IORegistryEntryID": 101,
                 "idVendor": 0xCAFE, "idProduct": 1, **descriptor,
                 "IORegistryEntryChildren": [driver]}
    storage = {"IOObjectClass": "IOUSBMassStorageInterfaceNub", "IORegistryEntryID": 104,
               "idVendor": 0xCAFE, "idProduct": 1, "bInterfaceClass": 8, "bInterfaceNumber": 99}
    device = {"IOObjectClass": "IOUSBHostDevice", "idVendor": 0xCAFE, "idProduct": 1,
              "IORegistryEntryID": 100, "USB Product Name": "Composite application", "USB Serial Number": "ABC",
              "locationID": 11, "IORegistryEntryChildren": [interface, interface, storage]}
    fallback = {"IOObjectClass": "IOUSBHostDevice", "idVendor": 0x1234, "idProduct": 3,
                "locationID": 13, "USB Serial Number": "FALLBACK", "IORegistryEntryName": "Fallback"}
    return [{"IOObjectClass": "AppleUSBXHCI",
             "IORegistryEntryChildren": [port, device, dict(device), fallback]}]


def test_usb_tree_uses_os_identity_deduplicates_and_keeps_nested_owners(usb_tree):
    assert f.parse_usb_tree(usb_tree) == [
        {"vid": 0xCAFE, "pid": 1, "product": "Composite application", "serial": "ABC",
         "location": 11, "interfaces": [{"bInterfaceNumber": 2, "bInterfaceClass": 2,
                                         "bInterfaceSubClass": 2, "bInterfaceProtocol": 1}],
         "ports": ["/dev/cu.fake-console"]},
        {"vid": 0xCAFE, "pid": 2, "product": "Nested probe", "serial": None,
         "location": 12, "interfaces": [], "ports": ["/dev/cu.fake-probe"]},
        {"vid": 0x1234, "pid": 3, "product": "Fallback", "serial": "FALLBACK",
         "location": 13, "interfaces": [], "ports": []},
    ]
    assert f.parse_usb_tree([]) == []
    assert f.parse_usb_tree([{"IOCalloutDevice": "/dev/cu.orphan", "idVendor": 1}]) == []


@pytest.mark.parametrize("node_class", ["IOUSBHostInterface", "AppleUSBACMData",
                                      "IOUSBMassStorageInterfaceNub", "IOSerialBSDClient"])
def test_usb_inherited_vid_pid_never_creates_owner_or_fake_interface(node_class):
    descriptor = {"bInterfaceNumber": 2, "bInterfaceClass": 2,
                  "bInterfaceSubClass": 2, "bInterfaceProtocol": 1}
    inherited = {"IOObjectClass": node_class, "IORegistryEntryID": 101,
                 "idVendor": 0xCAFE, "idProduct": 1, "USB Product Name": "Not another device",
                 "USB Serial Number": "INHERITED", **descriptor,
                 "IORegistryEntryChildren": [{"IOObjectClass": "IOSerialBSDClient",
                                              "IOCalloutDevice": "/dev/cu.inherited"}]}
    device = {"IOObjectClass": "IOUSBHostDevice", "IORegistryEntryID": 100,
              "idVendor": 0xCAFE, "idProduct": 1, "USB Product Name": "Actual device",
              "USB Serial Number": "ACTUAL", "locationID": 11,
              "IORegistryEntryChildren": [inherited, dict(inherited)]}
    assert f.parse_usb_tree([device, dict(device)]) == [
        {"vid": 0xCAFE, "pid": 1, "product": "Actual device", "serial": "ACTUAL",
         "location": 11, "interfaces": [descriptor] if node_class == "IOUSBHostInterface" else [],
         "ports": ["/dev/cu.inherited"]}]
    assert f.parse_usb_tree([inherited]) == []


def test_passive_inventory_runs_only_os_ioreg_and_never_imports_backends(monkeypatch, usb_tree):
    monkeypatch.setattr(f.sys, "platform", "darwin")
    calls = []

    def run(command, **options):
        calls.append((command, options))
        return SimpleNamespace(stdout=plistlib.dumps(usb_tree))

    monkeypatch.setattr(f.subprocess, "run", run)
    result = f.passive_usb_inventory()
    assert result == {"method": "macOS IORegistry only; no device opened",
                      "devices": f.parse_usb_tree(usb_tree)}
    assert calls == [(["/usr/sbin/ioreg", "-a", "-l", "-r", "-c", "IOUSBHostDevice"],
                      {"check": True, "stdout": f.subprocess.PIPE,
                       "stderr": f.subprocess.PIPE, "timeout": 30})]


@pytest.mark.parametrize("output", [b"", b"\n", plistlib.dumps([])])
def test_passive_inventory_handles_no_matching_usb_nodes(monkeypatch, output):
    monkeypatch.setattr(f.sys, "platform", "darwin")
    monkeypatch.setattr(f.subprocess, "run", lambda *args, **kwargs: SimpleNamespace(stdout=output))
    assert f.passive_usb_inventory() == {
        "method": "macOS IORegistry only; no device opened", "devices": []}


def test_passive_inventory_does_not_hide_malformed_nonempty_output(monkeypatch):
    monkeypatch.setattr(f.sys, "platform", "darwin")
    monkeypatch.setattr(f.subprocess, "run",
                        lambda *args, **kwargs: SimpleNamespace(stdout=b"<plist>broken"))
    with pytest.raises(RuntimeError, match="Invalid IORegistry plist"):
        f.passive_usb_inventory()


def test_passive_inventory_rejects_other_os_without_spawning_anything(monkeypatch):
    monkeypatch.setattr(f.sys, "platform", "linux")
    with pytest.raises(RuntimeError, match="macOS IORegistry"):
        f.passive_usb_inventory()


@pytest.mark.parametrize("mode", [[], ["--dry-run"]])
def test_cli_defaults_to_real_offline_validation_not_programming(image, pack, monkeypatch, capsys, mode):
    directory, binary = image()
    archive = pack()
    monkeypatch.setattr(f, "flash", forbidden)
    assert f.main(["--build-dir", str(directory), "--pack", str(archive), *mode]) == 0
    output = capsys.readouterr()
    report, end = json.JSONDecoder().raw_decode(output.out)
    assert report["target"] == "m3351kjcae"
    assert report["pdid"] == "0x3302140"
    assert report["aprom_bytes"] == APROM
    assert report["image_bytes"] == len(binary)
    assert report["image_sha256"] == hashlib.sha256(binary).hexdigest()
    assert report["pack"] == str(archive)
    assert report["planned_erase_interval_exclusive"] == [0, SECTOR]
    assert report["trailing_sector_bytes_require_current_backup"] == SECTOR - len(binary)
    assert report["hardware_verified"] is False
    assert "Offline validation passed" in output.out[end:]
    assert "NOT HIL acceptance" in output.out[end:]
    assert not output.err


def test_cli_never_selects_or_builds_an_implicit_image(image, monkeypatch, capsys):
    directory, _ = image()
    monkeypatch.chdir(directory.parent)
    monkeypatch.setattr(f, "WORKSPACE", directory.parent)
    monkeypatch.setattr(f, "validate_image", forbidden)
    monkeypatch.setattr(f, "resolve_pack", forbidden)
    with pytest.raises(SystemExit) as error:
        f.main([])
    assert error.value.code == 2
    assert "--build-dir is required; no implicit" in capsys.readouterr().err


def test_cli_rejects_programming_without_explicit_probe_before_validation(monkeypatch, capsys):
    monkeypatch.setattr(f, "validate_image", forbidden)
    monkeypatch.setattr(f, "flash", forbidden)
    with pytest.raises(SystemExit) as error:
        f.main(["--program", "--build-dir", "unused"])
    assert error.value.code == 2
    assert "requires the full --probe ID" in capsys.readouterr().err


@pytest.mark.parametrize("modes", [["--dry-run", "--program"], ["--list-usb", "--program"],
                                  ["--list-usb", "--dry-run"]])
def test_cli_modes_are_mutually_exclusive(modes):
    with pytest.raises(SystemExit) as error:
        f.main(modes)
    assert error.value.code == 2


def test_cli_usb_inventory_needs_no_image_pack_or_pyocd(monkeypatch, capsys):
    monkeypatch.setattr(f, "validate_image", forbidden)
    monkeypatch.setattr(f, "resolve_pack", forbidden)
    monkeypatch.setattr(f, "flash", forbidden)
    monkeypatch.setattr(f, "passive_usb_inventory", lambda: {"devices": []})
    assert f.main(["--list-usb"]) == 0
    assert json.loads(capsys.readouterr().out) == {"devices": []}


@pytest.mark.parametrize("stage", ["image", "pack"])
def test_cli_validation_failure_is_nonzero_and_never_dispatches_hardware(
        image, pack, monkeypatch, capsys, stage):
    directory, _ = image(binary=b"short" if stage == "image" else None)
    archive = pack()
    if stage == "pack":
        archive.write_bytes(b"bad archive")
    monkeypatch.setattr(f, "flash", forbidden)
    assert f.main(["--program", "--probe", "EXACT-ID", "--build-dir", str(directory),
                   "--pack", str(archive)]) == 1
    output = capsys.readouterr()
    assert "Validation/programming failed" in output.err
    assert "No verified success" in output.err
    assert "Verified current" not in output.out


@pytest.mark.parametrize("stage,warning", [
    (None, None), ("algorithm_attempted", "A RAM algorithm was attempted"),
    ("programming_attempted", "APROM may be partially modified"),
])
def test_cli_mocked_live_failure_reports_last_attempt_without_claiming_success(
        image, pack, monkeypatch, capsys, stage, warning):
    directory, binary = image()
    archive = pack()
    calls = []

    def fake_flash(data, selected_pack, probe_id, progress, backup_dir, halt_first, boot_after):
        calls.append((data, selected_pack, probe_id, backup_dir, halt_first, boot_after))
        assert progress == {"algorithm_attempted": False, "programming_attempted": False}
        if stage:
            progress[stage] = True
        raise RuntimeError("synthetic lifecycle failure")

    monkeypatch.setattr(f, "flash", fake_flash)
    assert f.main(["--program", "--probe", "FULL-ID", "--build-dir", str(directory),
                   "--pack", str(archive)]) == 1
    assert calls == [(binary, archive, "FULL-ID", f.WORKSPACE / ".embedder/backups", False, False)]
    output = capsys.readouterr()
    assert "synthetic lifecycle failure" in output.err
    assert "No verified success" in output.err
    assert "Verified current" not in output.out
    if warning:
        assert warning in output.err
    else:
        assert "RAM algorithm" not in output.err and "partially modified" not in output.err


def test_cli_entry_and_boot_flags_are_explicit_and_program_only(image, pack, monkeypatch, capsys):
    directory, binary = image()
    archive = pack()
    calls = []

    def fake_flash(data, selected_pack, probe_id, progress, backup_dir, halt_first, boot_after):
        calls.append((halt_first, boot_after))

    monkeypatch.setattr(f, "flash", fake_flash)
    for flags in (["--halt-at-reset-vector"], ["--boot"], ["--dry-run", "--boot"]):
        with pytest.raises(SystemExit):
            f.main([*flags, "--build-dir", str(directory), "--pack", str(archive)])
    assert calls == []
    assert f.main(["--program", "--probe", "FULL-ID", "--build-dir", str(directory),
                   "--pack", str(archive)]) == 0
    assert "No reset/resume requested" in capsys.readouterr().out
    assert f.main(["--program", "--probe", "FULL-ID", "--build-dir", str(directory),
                   "--pack", str(archive), "--halt-at-reset-vector", "--boot"]) == 0
    assert "No reset/resume requested" not in capsys.readouterr().out
    assert calls == [(False, False), (True, True)]


def test_probe_selection_is_exact_case_insensitive_and_unambiguous():
    probe = SimpleNamespace(unique_id="ABC-123-full")
    assert f.select_probe([SimpleNamespace(unique_id="other"), probe], "abc-123-FULL") is probe
    for selector, candidates in [(None, [probe]), ("", [probe]), ("ABC", [probe]),
                                 ("ABC-123-full", []), ("ABC-123-full", [probe, probe])]:
        with pytest.raises(ValueError, match="full unique ID|exactly one probe"):
            f.select_probe(candidates, selector)


def test_session_options_disable_reset_resume_unlock_scripts_and_caches(tmp_path):
    archive, directory = tmp_path / "local.pack", tmp_path / "private-project"
    assert f.session_options(archive, directory) == {
        "target_override": "m3351kjcae", "pack": str(archive), "auto_unlock": False,
        "connect_mode": "attach", "frequency": 1000000, "resume_on_disconnect": False,
        "no_config": True, "user_script": os.devnull, "project_dir": str(directory),
        "options": {"pack.debug_sequences.enable": False,
                    "pack.debug_sequences.disabled_sequences": ["DebugPortStart", "DebugPortStop"],
                    "load.pre_reset": "off", "load.post_reset": "off",
                    "cache.enable_memory": False, "cache.enable_register": False,
                    "cache.read_code_from_elf": False},
    }


def test_attach_delegate_overrides_vendor_start_stop_and_checks_connection(monkeypatch):
    session = object()
    target = SimpleNamespace(dp=SimpleNamespace())
    steps, checked = [], []
    sequence = SimpleNamespace(insert_after=lambda name, step: steps.append((name, step)))
    monkeypatch.setattr(f, "check_connection", lambda actual: checked.append(actual))
    f.AttachDelegate(session).will_init_target(target, sequence)
    assert target.dp.enable_debug_port_hook() is False
    assert target.dp.disable_debug_port_hook() is True
    assert steps[0][0] == "dp_init"
    assert steps[0][1][0] == "check_power_and_reset"
    steps[0][1][1]()
    assert checked == [session]


@pytest.mark.parametrize("version,modules,match", [
    ("0.45.0", {}, "audited pyOCD 0.46.0"),
    ("0.46.0", {"pyocd": object()}, "fresh process"),
    ("0.46.0", {"pyocd.core.session": object()}, "fresh process"),
])
def test_flash_rejects_unaudited_or_preimported_backend_before_opening(
        monkeypatch, tmp_path, version, modules, match):
    monkeypatch.setattr(f, "validate_pack", lambda _: None)
    monkeypatch.setattr(f.importlib.metadata, "version", lambda _: version)
    monkeypatch.setattr(f, "sys", SimpleNamespace(modules=modules))
    with pytest.raises(RuntimeError, match=match):
        f.flash(b"unused", tmp_path / "fake.pack", "FULL-ID", {}, tmp_path)


@pytest.mark.parametrize("failure", [None, "open", "program", "close"])
def test_mocked_session_closes_and_restores_environment_and_cwd_on_all_paths(
        monkeypatch, tmp_path, failure):
    # Imports resolve exclusively to in-memory fakes; no real pyOCD module is loaded.
    monkeypatch.setattr(f, "validate_pack", lambda _: None)
    monkeypatch.setattr(f.importlib.metadata, "version", lambda _: "0.46.0")
    monkeypatch.setattr(f, "sys", SimpleNamespace(modules={}))
    monkeypatch.setenv("HOME", str(tmp_path / "old-home"))
    monkeypatch.delenv("XDG_DATA_HOME", raising=False)
    monkeypatch.setenv("XDG_CACHE_HOME", str(tmp_path / "old-cache"))
    keys = ("HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME")
    saved = {key: os.environ.get(key) for key in keys}
    cwd = Path.cwd()
    events, homes = [], []
    probe = SimpleNamespace(unique_id="FULL-ID")
    archive = tmp_path / "fake.pack"
    real_import = builtins.__import__

    def enumerate_probes(**options):
        assert options == {"blocking": False}
        home = Path(os.environ["HOME"])
        homes.append(home)
        assert home.is_dir() and home != Path(saved["HOME"])
        assert os.environ["XDG_DATA_HOME"] == str(home / "data")
        assert os.environ["XDG_CACHE_HOME"] == str(home / "cache")
        events.append("enumerate")
        return [probe]

    class FakeSession:
        def __init__(self, actual_probe, **options):
            assert actual_probe is probe
            assert options == f.session_options(archive, homes[0] / "project")
            self.directory = Path(options["project_dir"])
            assert self.directory.is_dir()
            events.append("construct")

        def open(self):
            assert isinstance(self.delegate, f.AttachDelegate)
            assert self.delegate.session is self
            events.append("open")
            os.chdir(self.directory)
            if failure == "open":
                raise RuntimeError("open failed")

        def close(self):
            events.append("close")
            if failure == "close":
                raise RuntimeError("close failed")

    def fake_import(name, *args, **kwargs):
        if name == "pyocd.core.helpers":
            return SimpleNamespace(ConnectHelper=SimpleNamespace(get_all_connected_probes=enumerate_probes))
        if name == "pyocd.core.session":
            return SimpleNamespace(Session=FakeSession)
        return real_import(name, *args, **kwargs)

    def fake_program(session, binary, progress, backup_dir):
        assert isinstance(session, FakeSession)
        assert (binary, progress, backup_dir) == (b"offline payload", {}, tmp_path / "backups")
        events.append("program")
        if failure == "program":
            raise RuntimeError("program failed")

    monkeypatch.setattr(builtins, "__import__", fake_import)
    monkeypatch.setattr(f, "program", fake_program)
    if failure:
        with pytest.raises(RuntimeError, match=f"{failure} failed"):
            f.flash(b"offline payload", archive, "full-id", {}, tmp_path / "backups")
    else:
        f.flash(b"offline payload", archive, "full-id", {}, tmp_path / "backups")
    assert events == ["enumerate", "construct", "open", *([] if failure == "open" else ["program"]), "close"]
    assert {key: os.environ.get(key) for key in keys} == saved
    assert Path.cwd() == cwd
    assert len(homes) == 1 and not homes[0].exists()


@pytest.fixture
def fake_pyocd(monkeypatch):
    """Resolve only explicit fake modules; all other backend imports stay forbidden."""
    target_type = SimpleNamespace(State=SimpleNamespace(HALTED="halted", RUNNING="running"),
                                  SecurityState=SimpleNamespace(SECURE="secure", NONSECURE="nonsecure"))
    modules = {
        "pyocd.core.target": SimpleNamespace(Target=target_type),
        "pyocd.coresight.dap": SimpleNamespace(DP_CTRL_STAT=4, CDBGPWRUPACK=1 << 29,
                                               CSYSPWRUPACK=1 << 31),
    }
    previous_import = builtins.__import__

    def import_fake(name, *args, **kwargs):
        return modules[name] if name in modules else previous_import(name, *args, **kwargs)

    monkeypatch.setattr(builtins, "__import__", import_fake)
    return modules


class MemoryAccessPort:
    def __init__(self, baseline):
        self.regs = {f.DAUTHSTATUS: 0xFF, 0x40000000: 0x03302140,
                     f.FNSADDR: APROM, f.FMC + 0x40: 0, f.MPU_CTRL: 5, CFSR: 0,
                     f.DSCSR: 0x10000,
                     **{address: 0 for address in f.PROTECTION_REGS}}
        self.memory = {0: bytearray(baseline), 0x0F100000: bytearray(b"L" * 0x4000),
                       0x0F200000: bytearray(b"D" * 0x4000)}
        self.events, self.block_reads = [], []
        self.locked = False
        self.unstable = None
        self.short = None
        self.scratch = [0x13579BDF, 0x2468ACE0, 0x10203040, 0x50607080]
        self.scratch_fault = None
        self.scratch_reads = 0
        self.scratch_writes = []

    def read_memory_block32(self, address, count):
        assert (address, count) == (0x20003C00, 4)
        self.scratch_reads += 1
        if self.scratch_fault == "read-error" and self.scratch_reads == 2:
            raise RuntimeError("synthetic scratch read failure")
        result = list(self.scratch)
        if ((self.scratch_fault == "mismatch" and self.scratch_reads == 2)
                or (self.scratch_fault == "restore-mismatch" and self.scratch_reads == 3)):
            result[0] ^= 1
        return result

    def write_memory_block32(self, address, words):
        assert address == 0x20003C00 and len(words) == 4
        self.scratch_writes.append(list(words))
        self.scratch = list(words)
        if self.scratch_fault == "write-error" and len(self.scratch_writes) == 1:
            raise RuntimeError("synthetic scratch write failure")

    @contextmanager
    def hnonsec_lock(self, value):
        assert value == 0 and not self.locked
        self.locked = True
        self.events.append(("secure-lock",))
        try:
            yield
        finally:
            self.locked = False
            self.events.append(("secure-unlock",))

    def read32(self, address):
        return self.regs[address]

    def write32(self, address, value):
        assert address == f.MPU_CTRL, "Only MPU writes are expected in this mock"
        self.events.append(("write32", address, value))
        self.regs[address] = value

    def read_memory_block8(self, address, size):
        assert self.locked
        self.block_reads.append((address, size))
        result = bytes(self.memory[address][:size])
        count = sum(start == address for start, _ in self.block_reads)
        if address == self.short and count == 1:
            return result[:-1]
        if address == self.unstable and count == 2:
            return bytes([result[0] ^ 1]) + result[1:]
        return result


class MemoryTarget:
    def __init__(self, ap):
        self.ap = ap
        self.selected_core = SimpleNamespace(ap=ap, get_security_state=self.get_security_state)
        self.state = "halted"
        self.security_state = "secure"
        self.registers = {"ipsr": 0, "control": 0, "control_s": 0, "primask": 0,
                          "xpsr": 0x01000000, "msplim_s": 0}
        self.register_reads = []
        algorithm = SimpleNamespace(flash_algo={"end_stack": STACK_END, "begin_stack": STACK_BEGIN})
        region = SimpleNamespace(flash=algorithm)
        self.memory_map = SimpleNamespace(get_region_for_address=lambda address: region if address == 0 else None)
        self.refuse_halt = False
        self.drop_primask = False
        self.dp = SimpleNamespace(read_reg=self.read_dp)

    def get_security_state(self):
        if isinstance(self.security_state, Exception):
            raise self.security_state
        return self.security_state

    def read_dp(self, address):
        assert address == 4
        return (1 << 29) | (1 << 31)

    def get_state(self):
        return self.state

    def halt(self):
        self.ap.events.append(("halt",))
        if not self.refuse_halt:
            self.state = "halted"

    def flush(self):
        self.ap.events.append(("flush",))

    def read_core_register(self, name):
        self.register_reads.append(name)
        value = self.registers[name]
        if isinstance(value, Exception):
            raise value
        return value

    def write_core_register(self, name, value):
        assert name == "primask"
        self.ap.events.append(("core-register", name, value))
        if not (self.drop_primask and value == 1):
            self.registers[name] = value


@pytest.fixture
def program_target(monkeypatch, fake_pyocd, baseline):
    ap = MemoryAccessPort(baseline)
    target = MemoryTarget(ap)
    session = SimpleNamespace(target=target,
                              probe=SimpleNamespace(is_reset_asserted=lambda: False, flush=target.flush))
    state = SimpleNamespace(ap=ap, target=target, session=session, baseline=baseline,
                            progress={"algorithm_attempted": False, "programming_attempted": False},
                            algorithm_calls=[], loaders=[], after_init=None, after_commit=None,
                            config={address: 0xA5A5005A for address in f.CONFIG_WORDS})

    def guarded_context():
        assert ap.locked and target.state == "halted"
        assert target.registers["primask"] == 1 and ap.regs[f.MPU_CTRL] == 0

    class Algorithm:
        Operation = SimpleNamespace(VERIFY="verify")

        def __init__(self):
            self.flash_algo = {"end_stack": STACK_END, "begin_stack": STACK_BEGIN}

        def init(self, operation, **options):
            guarded_context()
            assert operation == "verify" and options == {"reset": False}
            state.algorithm_calls.append("init")
            if state.after_init:
                state.after_init()

        def uninit(self):
            state.algorithm_calls.append("uninit")

        def cleanup(self):
            state.algorithm_calls.append("cleanup")

    region = SimpleNamespace(is_flash=True, start=0, length=APROM, blocksize=SECTOR,
                             flash=Algorithm())
    state.region = region
    target.memory_map = SimpleNamespace(get_region_for_address=lambda address: region if address == 0 else None)

    class Loader:
        def __init__(self, actual_session, **options):
            guarded_context()
            assert actual_session is session
            self.options, self.blocks, self.committed = options, [], False
            state.loaders.append(self)

        def add_data(self, address, data):
            assert address == 0
            self.blocks.append((address, bytes(data)))

        def commit(self):
            guarded_context()
            self.committed = True
            for address, data in self.blocks:
                assert address == 0 and len(data) % SECTOR == 0
                ap.memory[0][:len(data)] = data
            if state.after_commit:
                state.after_commit()

    def configuration(actual_ap, flush):
        assert actual_ap is ap and ap.locked
        return dict(state.config)

    fake_pyocd["pyocd.flash.loader"] = SimpleNamespace(MemoryLoader=Loader)
    monkeypatch.setattr(f, "read_config", configuration)
    return state


def assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase,
                                            error=RuntimeError):
    saved_registers = dict(state.target.registers)
    saved_mmio = dict(state.ap.regs)
    for name in ("backup_aprom", "backup_region", "read_config", "check_sram"):
        monkeypatch.setattr(f, name, forbidden)
    with pytest.raises(error):
        if phase == "program":
            REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
        else:
            with f.flash_execution_context(state.target, state.ap):
                pytest.fail("Unsafe stack context must not be entered")
    assert state.target.registers == saved_registers
    assert state.ap.regs == saved_mmio
    assert not state.ap.block_reads and not state.ap.scratch_reads and not state.ap.scratch_writes
    assert not state.algorithm_calls and not state.loaders and not any(state.progress.values())
    assert all(event[0] in {"secure-lock", "secure-unlock", "halt", "flush"}
               for event in state.ap.events)
    assert not state.ap.locked
    assert list(tmp_path.iterdir()) == []


@pytest.mark.parametrize("phase", ["program", "context"])
@pytest.mark.parametrize("limit", [STACK_END + 8, SRAM + 0x1FFF8, 0xFFFFFFFF,
                                   -1, 0x100000000, None, True, 0.0, "0"])
def test_stack_guard_rejects_incompatible_or_unknown_msplim_before_writes(
        program_target, tmp_path, monkeypatch, phase, limit):
    state = program_target
    state.target.registers["msplim_s"] = limit
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase)


@pytest.mark.parametrize("phase", ["program", "context"])
@pytest.mark.parametrize("register,value", [
    ("control", 1), ("control", 2), ("control", 3),
    ("ipsr", 3), ("xpsr", 0), ("xpsr", 1),
])
def test_stack_guard_rejects_psp_unprivileged_handler_or_non_thumb_before_writes(
        program_target, tmp_path, monkeypatch, phase, register, value):
    state = program_target
    state.target.registers[register] = value
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase)


@pytest.mark.parametrize("phase", ["program", "context"])
@pytest.mark.parametrize("dscsr", [0, 2, 0x10001, 0x10003, 0x30001])
def test_stack_guard_rejects_overridden_or_nonsecure_bank_before_writes(
        program_target, tmp_path, monkeypatch, phase, dscsr):
    state = program_target
    state.ap.regs[f.DSCSR] = dscsr
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase)


@pytest.mark.parametrize("phase", ["program", "context"])
@pytest.mark.parametrize("register,value", [("control_s", 2), ("control_s", 4),
                                             ("xpsr", 0x01000003)])
def test_stack_guard_rejects_inconsistent_explicit_bank_and_exception_state(
        program_target, tmp_path, monkeypatch, phase, register, value):
    state = program_target
    state.target.registers[register] = value
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase)


@pytest.mark.parametrize("phase", ["program", "context"])
def test_stack_guard_rejects_unreadable_bank_selector_before_writes(
        program_target, tmp_path, monkeypatch, phase):
    state = program_target
    original = state.ap.read32

    def read32(address):
        if address == f.DSCSR:
            raise OSError("bank selector unreadable")
        return original(address)

    monkeypatch.setattr(state.ap, "read32", read32)
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase,
                                             error=OSError)


@pytest.mark.parametrize("phase", ["program", "context"])
@pytest.mark.parametrize("security", ["nonsecure", None, "unknown", 0, 1])
def test_stack_guard_requires_confirmed_secure_state_before_writes(
        program_target, tmp_path, monkeypatch, phase, security):
    state = program_target
    state.target.security_state = security
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase)


@pytest.mark.parametrize("phase", ["program", "context"])
@pytest.mark.parametrize("source", ["msplim_s", "control", "ipsr", "xpsr", "security", "cfsr"])
def test_stack_guard_rejects_unreadable_state_without_repair_or_backup(
        program_target, tmp_path, monkeypatch, phase, source):
    state = program_target
    failure = OSError("synthetic unreadable stack context")
    if source == "security":
        state.target.security_state = failure
    elif source == "cfsr":
        original = state.ap.read32

        def read32(address):
            if address == CFSR:
                raise failure
            return original(address)

        monkeypatch.setattr(state.ap, "read32", read32)
    else:
        state.target.registers[source] = failure
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase,
                                            error=(RuntimeError, OSError))


@pytest.mark.parametrize("phase", ["program", "context"])
@pytest.mark.parametrize("source", ["msplim_s", "control", "control_s", "ipsr", "xpsr"])
def test_stack_guard_rejects_missing_register_without_writes(
        program_target, tmp_path, monkeypatch, phase, source):
    state = program_target
    del state.target.registers[source]
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase,
                                            error=(RuntimeError, KeyError))


@pytest.mark.parametrize("phase", ["program", "context"])
@pytest.mark.parametrize("field,value", [
    ("end_stack", None), ("begin_stack", None),
    ("end_stack", True), ("begin_stack", False),
    ("end_stack", float(STACK_END)), ("begin_stack", str(STACK_BEGIN)),
    ("end_stack", STACK_END + 4), ("begin_stack", STACK_BEGIN + 4),
    ("end_stack", SRAM - 8), ("end_stack", -8),
    ("begin_stack", SRAM + 0x20008), ("begin_stack", 0x100000000),
    ("end_stack", STACK_BEGIN), ("begin_stack", STACK_END),
    ("end_stack", STACK_BEGIN + 8), ("begin_stack", STACK_END - 8),
])
def test_stack_guard_rejects_invalid_algorithm_stack_layout_before_writes(
        program_target, tmp_path, monkeypatch, phase, field, value):
    state = program_target
    state.region.flash.flash_algo[field] = value
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase)


@pytest.mark.parametrize("phase", ["program", "context"])
@pytest.mark.parametrize("field", ["end_stack", "begin_stack"])
def test_stack_guard_requires_both_stack_bounds_before_writes(
        program_target, tmp_path, monkeypatch, phase, field):
    state = program_target
    del state.region.flash.flash_algo[field]
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase)


@pytest.mark.parametrize("phase", ["program", "context"])
@pytest.mark.parametrize("cfsr", [0x00100000, 0x00108200, 0xFFFFFFFF])
def test_stack_guard_refuses_preexisting_stkof_without_clearing_it(
        program_target, tmp_path, monkeypatch, phase, cfsr):
    state = program_target
    state.ap.regs[CFSR] = cfsr
    assert_stack_guard_refuses_before_writes(state, tmp_path, monkeypatch, phase)
    assert state.ap.regs[CFSR] == cfsr


@pytest.mark.parametrize("limit", [0, STACK_END - 8, STACK_END])
@pytest.mark.parametrize("control", [0, 4])
def test_compatible_secure_msp_stack_is_accepted_without_stack_or_fault_writes(
        program_target, limit, control):
    state = program_target
    state.target.registers.update(msplim_s=limit, control=control, control_s=control,
                                  xpsr=0xA1000000)
    state.ap.regs[CFSR] = 0x00008200  # Unrelated fault bits are not this stack guard's policy.
    saved_registers = dict(state.target.registers)
    assert f.check_algorithm_stack(state.target, state.ap) is None
    assert not state.ap.events
    with f.flash_execution_context(state.target, state.ap):
        assert state.target.registers["primask"] == 1
        assert state.ap.regs[f.MPU_CTRL] == 0
    assert state.target.registers == saved_registers
    assert state.ap.regs[CFSR] == 0x00008200
    assert not state.ap.scratch_writes and not state.ap.block_reads
    assert state.target.register_reads.count("msplim_s") >= 2
    assert all(event[1] == "primask" for event in state.ap.events if event[0] == "core-register")
    assert all(event[1] == f.MPU_CTRL for event in state.ap.events if event[0] == "write32")


def test_program_checks_compatible_stack_twice_without_changing_stack_state(program_target, tmp_path):
    state = program_target
    state.target.registers["msplim_s"] = STACK_END
    saved_registers = dict(state.target.registers)
    REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
    assert state.target.register_reads.count("msplim_s") >= 2
    assert state.target.registers == saved_registers
    assert state.ap.regs[CFSR] == 0
    assert state.algorithm_calls == ["init", "uninit", "cleanup"]
    assert state.loaders[0].committed and all(state.progress.values())
    assert all(event[1] == "primask" for event in state.ap.events if event[0] == "core-register")
    assert all(event[1] == f.MPU_CTRL for event in state.ap.events if event[0] == "write32")


@pytest.mark.parametrize("register,value,match", [
    (0x40000000, 0x03301140, "not the confirmed M3351KJCAE"),
    (0xE000EFB8, 0x7F, "Full secure debug authentication"),
])
def test_program_rejects_wrong_identity_or_authentication_before_backups(
        program_target, tmp_path, register, value, match):
    state = program_target
    state.ap.regs[register] = value
    with pytest.raises(RuntimeError, match=match):
        REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
    assert state.progress == {"algorithm_attempted": False, "programming_attempted": False}
    assert not state.ap.block_reads and not state.algorithm_calls and not state.loaders
    assert list(tmp_path.iterdir()) == []
    assert not state.ap.locked


@pytest.mark.parametrize("register,value", [("ipsr", 3), ("control", 1)])
def test_program_rejects_handler_or_unprivileged_mode_before_any_backup(
        program_target, tmp_path, register, value):
    state = program_target
    state.target.registers[register] = value
    with pytest.raises(RuntimeError, match="not in privileged Thread mode"):
        REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
    assert not state.ap.block_reads and not state.algorithm_calls and not state.loaders
    assert not any(state.progress.values())
    assert list(tmp_path.iterdir()) == []


def test_program_rejects_failure_to_halt_without_reading_flash(program_target, tmp_path):
    state = program_target
    state.target.state = "running"
    state.target.refuse_halt = True
    with pytest.raises(RuntimeError, match="Target did not halt"):
        REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
    assert not state.ap.block_reads and not state.algorithm_calls and not state.loaders
    assert not any(state.progress.values()) and not state.ap.locked


@pytest.mark.parametrize("address", [0, 0x0F100000, 0x0F200000])
@pytest.mark.parametrize("fault", ["unstable", "short"])
def test_program_rejects_unstable_or_partial_backups_before_algorithm(
        program_target, tmp_path, address, fault):
    state = program_target
    setattr(state.ap, fault, address)
    with pytest.raises(RuntimeError, match="APROM verification|stable .* backup"):
        REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
    assert not state.algorithm_calls and not state.loaders
    assert not any(state.progress.values()) and not state.ap.locked
    assert bytes(state.ap.memory[0]) == state.baseline


@pytest.mark.parametrize("length,blocksize", [(0x80000, SECTOR), (APROM, 0x1000)])
def test_program_rejects_wrong_flash_geometry_before_backups(program_target, tmp_path, length, blocksize):
    state = program_target
    state.region.length, state.region.blocksize = length, blocksize
    with pytest.raises(RuntimeError, match="1 MiB APROM with 8192-byte erase sectors"):
        REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
    assert not state.ap.block_reads and not state.algorithm_calls and not state.loaders


@pytest.mark.parametrize("size,end", [(SECTOR + 3, 2 * SECTOR), (0x80001, 0x82000)])
def test_program_mock_preserves_last_sector_upper_aprom_and_other_regions(
        program_target, tmp_path, size, end):
    state = program_target
    image = b"\xa5" * size
    preserved = {address: bytes(data) for address, data in state.ap.memory.items() if address}
    REAL_PROGRAM(state.session, image, state.progress, tmp_path)
    assert len(state.loaders) == 1
    loader = state.loaders[0]
    assert loader.options == {"chip_erase": "sector", "smart_flash": False,
                              "trust_crc": False, "keep_unwritten": True}
    assert loader.committed
    assert loader.blocks == [(0, image + state.baseline[size:end])]
    assert bytes(state.ap.memory[0]) == image + state.baseline[size:]
    assert bytes(state.ap.memory[0][end:]) == state.baseline[end:]
    for address, data in preserved.items():
        assert bytes(state.ap.memory[address]) == data
    assert state.algorithm_calls == ["init", "uninit", "cleanup"]
    assert all(state.progress.values())
    assert state.target.registers["primask"] == 0 and state.ap.regs[f.MPU_CTRL] == 5
    assert state.target.state == "halted" and not state.ap.locked
    assert state.ap.scratch == [0x13579BDF, 0x2468ACE0, 0x10203040, 0x50607080]
    assert len(state.ap.scratch_writes) == 2
    backups = list(tmp_path.glob("*.bin"))
    assert len(backups) == 4
    aprom_backup = next(path for path in backups if "-aprom-" in path.name)
    assert aprom_backup.read_bytes() == state.baseline


@pytest.mark.parametrize("address", [0x80000, APROM - 1])
def test_program_detects_algorithm_preflight_mutation_before_loader(program_target, tmp_path, address):
    state = program_target
    state.after_init = lambda: state.ap.memory[0].__setitem__(address, state.baseline[address] ^ 1)
    with pytest.raises(RuntimeError, match=f"failed at {address:#x}"):
        REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
    assert state.progress == {"algorithm_attempted": True, "programming_attempted": False}
    assert state.algorithm_calls == ["init", "uninit", "cleanup"]
    assert not state.loaders
    assert state.target.registers["primask"] == 0 and state.ap.regs[f.MPU_CTRL] == 5
    assert not state.ap.locked


@pytest.mark.parametrize("address", [19, 0x80000, APROM - 1])
def test_program_full_readback_detects_tail_or_upper_half_corruption(program_target, tmp_path, address):
    state = program_target
    state.after_commit = lambda: state.ap.memory[0].__setitem__(address, state.ap.memory[0][address] ^ 1)
    with pytest.raises(RuntimeError, match=f"failed at {address:#x}"):
        REAL_PROGRAM(state.session, b"\xa5" * 19, state.progress, tmp_path)
    assert all(state.progress.values())
    assert state.target.registers["primask"] == 0 and state.ap.regs[f.MPU_CTRL] == 5
    assert state.target.state == "halted" and not state.ap.locked


@pytest.mark.parametrize("region", ["ldrom", "data-flash", "config"])
def test_program_detects_post_commit_preserved_region_changes(program_target, tmp_path, region):
    state = program_target

    def corrupt():
        if region == "config":
            state.config[0x0F300000] ^= 0x100
        else:
            address = {"ldrom": 0x0F100000, "data-flash": 0x0F200000}[region]
            state.ap.memory[address][0] ^= 1

    state.after_commit = corrupt
    with pytest.raises(RuntimeError, match="Preserved region changed|Configuration changed"):
        REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
    assert all(state.progress.values()) and not state.ap.locked
    assert state.target.registers["primask"] == 0 and state.ap.regs[f.MPU_CTRL] == 5


def test_program_commit_exception_still_halts_and_restores_controls(program_target, tmp_path):
    state = program_target

    def fail_commit():
        state.target.state = "running"
        raise RuntimeError("synthetic commit failure")

    state.after_commit = fail_commit
    with pytest.raises(RuntimeError, match="synthetic commit failure"):
        REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
    assert all(state.progress.values()) and state.loaders[0].committed
    assert state.target.state == "halted" and not state.ap.locked
    assert state.target.registers["primask"] == 0 and state.ap.regs[f.MPU_CTRL] == 5


@pytest.mark.parametrize("body_error", [False, True])
@pytest.mark.parametrize("primask", [0, 1])
def test_execution_context_masks_irq_disables_mpu_and_restores_on_exit(fake_pyocd, body_error, primask):
    ap = MemoryAccessPort(bytes(APROM))
    target = MemoryTarget(ap)
    target.registers["primask"] = primask

    def run():
        with f.flash_execution_context(target, ap):
            assert target.registers["primask"] == 1 and ap.regs[f.MPU_CTRL] == 0
            assert ap.events[:3] == [("core-register", "primask", 1),
                                     ("write32", f.MPU_CTRL, 0), ("flush",)]
            target.state = "running"
            if body_error:
                raise RuntimeError("synthetic body failure")

    if body_error:
        with pytest.raises(RuntimeError, match="synthetic body failure"):
            run()
    else:
        run()
    assert target.state == "halted"
    assert target.registers["primask"] == primask and ap.regs[f.MPU_CTRL] == 5
    assert ap.events[-3:] == [("write32", f.MPU_CTRL, 5),
                             ("core-register", "primask", primask), ("flush",)]


def test_execution_context_restores_after_failed_prepare(fake_pyocd):
    ap = MemoryAccessPort(bytes(APROM))
    target = MemoryTarget(ap)
    target.drop_primask = True
    with pytest.raises(RuntimeError, match="Failed to prepare"):
        with f.flash_execution_context(target, ap):
            pytest.fail("Unmasked context must not be entered")
    assert target.registers["primask"] == 0 and ap.regs[f.MPU_CTRL] == 5
    assert target.state == "halted"


def test_execution_context_reports_mpu_restoration_failure(fake_pyocd, monkeypatch):
    ap = MemoryAccessPort(bytes(APROM))
    target = MemoryTarget(ap)
    original = ap.write32
    monkeypatch.setattr(ap, "write32", lambda address, value: original(address, value) if value != 5 else None)
    with pytest.raises(RuntimeError, match="Failed to restore MPU/interrupt state"):
        with f.flash_execution_context(target, ap):
            assert ap.regs[f.MPU_CTRL] == 0
    assert target.registers["primask"] == 0 and target.state == "halted"


@pytest.mark.parametrize("register,value", [("state", "running"), ("ipsr", 1), ("control", 1)])
def test_execution_context_rejects_unsafe_entry_without_writes(fake_pyocd, register, value):
    ap = MemoryAccessPort(bytes(APROM))
    target = MemoryTarget(ap)
    if register == "state":
        target.state = value
    else:
        target.registers[register] = value
    with pytest.raises(RuntimeError, match="halted|privileged Thread mode"):
        with f.flash_execution_context(target, ap):
            pytest.fail("Unsafe context must not be entered")
    assert not ap.events


@pytest.mark.parametrize("fault,match", [
    (None, None), ("mismatch", "SRAM write/read mismatch"),
    ("read-error", "synthetic scratch read failure"),
    ("write-error", "synthetic scratch write failure"),
])
def test_check_sram_restores_original_words_on_success_and_error(fault, match):
    ap = MemoryAccessPort(bytes(APROM))
    ap.scratch_fault = fault
    saved, flushes = list(ap.scratch), []
    if match:
        with pytest.raises(RuntimeError, match=match):
            f.check_sram(ap, lambda: flushes.append(True))
    else:
        assert f.check_sram(ap, lambda: flushes.append(True)) is None
    assert ap.scratch == saved
    assert ap.scratch_writes == [[0x01234567, 0x89ABCDEF, 0x55AA55AA, 0xAA55AA55], saved]
    assert flushes


@pytest.mark.parametrize("words", [0, 3, 5])
def test_check_sram_requires_exactly_four_snapshot_words_without_writes(words):
    ap = MemoryAccessPort(bytes(APROM))
    ap.scratch = [0x11223344] * words
    with pytest.raises(RuntimeError, match="Incomplete SRAM scratch read"):
        f.check_sram(ap, forbidden)
    assert not ap.scratch_writes


def test_check_sram_reports_failed_restoration():
    ap = MemoryAccessPort(bytes(APROM))
    ap.scratch_fault = "restore-mismatch"
    with pytest.raises(RuntimeError, match="Failed to restore SRAM scratch"):
        f.check_sram(ap, lambda: None)
    assert len(ap.scratch_writes) == 2


def test_program_sram_mismatch_stops_before_algorithm_and_loader(program_target, tmp_path):
    state = program_target
    saved = list(state.ap.scratch)
    state.ap.scratch_fault = "mismatch"
    with pytest.raises(RuntimeError, match="SRAM write/read mismatch"):
        REAL_PROGRAM(state.session, boot_image(), state.progress, tmp_path)
    assert state.ap.scratch == saved
    assert not any(state.progress.values())
    assert not state.algorithm_calls and not state.loaders and not state.ap.locked


class FmcAccessPort:
    def __init__(self, locked=0, failure=None):
        self.failure = failure
        self.regs = {f.FMC: 0x20, f.FMC + 4: 0x11112222, f.FMC + 8: 0x33334444,
                     f.FMC + 12: 0x60, f.FMC + 0x10: 0, f.FMC + 0x40: 0, f.REGLOCK: locked}
        self.saved = dict(self.regs)
        self.values = {address: address ^ 0xA55AA55A for address in f.CONFIG_WORDS}
        self.writes, self.commands = [], []
        self.keys, self.flushes = [], 0

    def read32(self, address):
        if address == f.FMC + 8 and self.commands and self.failure == "read-error":
            self.failure = None
            raise RuntimeError("synthetic read failure")
        return self.regs[address]

    def write32(self, address, value):
        self.writes.append((address, value))
        if address == f.REGLOCK:
            if value:
                self.keys.append(value)
                if self.keys[-3:] == [0x59, 0x16, 0x88]:
                    self.regs[address] = 1
            else:
                self.regs[address] = 0
            return
        self.regs[address] = value
        if address == f.FMC + 0x10:
            assert value == 1
            command, config_address = self.regs[f.FMC + 12], self.regs[f.FMC + 4]
            self.commands.append((command, config_address))
            assert command == 0, "Only FMC READ may be triggered"
            self.regs[f.FMC + 8] = self.values[config_address]
            if self.failure != "busy":
                self.regs[address] = 0
            if self.failure == "ispff":
                self.regs[f.FMC + 0x40] = 1 << 6

    def flush(self):
        self.flushes += 1


@pytest.mark.parametrize("locked", [0, 1])
def test_read_config_triggers_only_read_and_restores_every_saved_register(locked):
    ap = FmcAccessPort(locked)
    assert f.read_config(ap, ap.flush) == ap.values
    addresses = [0x0F300000 + 4 * index for index in (*range(7), *range(8, 15), 32, 33, 34)]
    assert ap.commands == [(0, address) for address in addresses]
    assert ap.regs == ap.saved
    assert ap.flushes == 2
    assert ap.keys == ([0x59, 0x16, 0x88] if not locked else [])
    assert {address for address, _ in ap.writes} <= {
        f.FMC, f.FMC + 4, f.FMC + 8, f.FMC + 12, f.FMC + 0x10, f.REGLOCK}


@pytest.mark.parametrize("locked", [0, 1])
@pytest.mark.parametrize("failure,match", [("read-error", "synthetic read failure"),
                                           ("ispff", "reported ISPFF")])
def test_read_config_restores_setup_on_recoverable_error(locked, failure, match):
    ap = FmcAccessPort(locked, failure)
    with pytest.raises(RuntimeError, match=match):
        f.read_config(ap, ap.flush)
    assert ap.commands == [(0, 0x0F300000)]
    for address in (f.FMC, f.FMC + 4, f.FMC + 8, f.FMC + 12, f.REGLOCK):
        assert ap.regs[address] == ap.saved[address]
    assert ap.flushes == 2


@pytest.mark.parametrize("register,value", [(0x4000C010, 1), (0x4000C040, 1 << 6)])
def test_read_config_rejects_busy_or_failed_controller_without_writes(register, value):
    ap = FmcAccessPort()
    ap.regs[register] = value
    with pytest.raises(RuntimeError, match="FMC busy or ISPFF"):
        f.read_config(ap, ap.flush)
    assert not ap.writes and not ap.commands and not ap.flushes


def test_read_config_reports_restore_readback_failure(monkeypatch):
    ap = FmcAccessPort()
    original = ap.write32

    def drop_restore(address, value):
        if address != f.FMC or value != ap.saved[f.FMC]:
            original(address, value)

    monkeypatch.setattr(ap, "write32", drop_restore)
    with pytest.raises(RuntimeError, match="restoration mismatch"):
        f.read_config(ap, ap.flush)
    assert ap.regs[f.REGLOCK] == ap.saved[f.REGLOCK]
    assert ap.regs[f.FMC] != ap.saved[f.FMC]


def test_read_config_never_restores_registers_while_controller_remains_busy(monkeypatch):
    ap = FmcAccessPort(failure="busy")
    clock = iter([0.0, 2.0])
    monkeypatch.setattr(f, "monotonic", lambda: next(clock))
    with pytest.raises(RuntimeError, match="FMC still busy; unable to restore"):
        f.read_config(ap, ap.flush)
    assert ap.commands == [(0, 0x0F300000)]
    assert ap.writes[-1] == (f.FMC + 0x10, 1)
