#!/usr/bin/env python3
"""Offline DFP 1.0.6 FLM inspection. Never opens target/probe/serial devices."""
import hashlib
import io
import json
from importlib.metadata import version
from pathlib import Path
import zipfile

from capstone import Cs, CS_ARCH_ARM, CS_MODE_THUMB, CS_MODE_MCLASS
from elftools.elf.elffile import ELFFile
from pyocd.core.memory_map import RamRegion
from pyocd.target.pack.flash_algo import PackFlashAlgo

ROOT = Path(__file__).resolve().parents[5]
OUT = Path(__file__).resolve().parent
PACK = Path('/Users/embedder/.embedder/downloads/799943d72f89b55f/Nuvoton.NuMicroM33_DFP.1.0.6.pack')
NAMES = ['Flash/M3351_AP_512.FLM', 'Flash/M3351_AP_1M.FLM']


def sha(data):
    return hashlib.sha256(data).hexdigest()


def inspect(name, raw):
    elf = ELFFile(io.BytesIO(raw))
    pfa = PackFlashAlgo(io.BytesIO(raw))
    layout = pfa.get_pyocd_flash_algo(0x2000, RamRegion(start=0x20000000, length=0x4000))
    code_base = layout['load_address'] + 4
    symbols = [s for s in elf.get_section_by_name('.symtab').iter_symbols() if s['st_info']['type'] == 'STT_FUNC']
    dwarf = elf.get_dwarf_info()
    lines = {}
    source_files = []
    for cu in dwarf.iter_CUs():
        top = cu.get_top_DIE()
        source_files.append({key: str(attr.value) for key, attr in top.attributes.items() if key in ('DW_AT_name', 'DW_AT_comp_dir', 'DW_AT_producer')})
        lp = dwarf.line_program_for_CU(cu)
        if lp:
            files = lp['file_entry']
            for e in lp.get_entries():
                if e.state and not e.state.end_sequence:
                    st = e.state
                    lines[st.address] = f'{files[st.file - 1].name.decode()}:L{st.line}'
    code = elf.get_section_by_name('PrgCode').data()
    md = Cs(CS_ARCH_ARM, CS_MODE_THUMB | CS_MODE_MCLASS)
    text = ['# Offline Capstone disassembly; FLM image offsets and runtime address for saved pyOCD layout.',
            '# Source references are embedded DWARF line mappings, not recovered C source.',
            f'# {name} SHA256 {sha(raw)}', f'# code_base=0x{code_base:08x}, load_address=0x{layout["load_address"]:08x}']
    decoded_total = 0
    mnemonics = set()
    for sym in symbols:
        start = sym['st_value'] & ~1
        text.append(f'\n{sym.name}: image 0x{start:04x}, Thumb symbol 0x{sym["st_value"]:04x}, size {sym["st_size"]}')
        decoded = 0
        for insn in md.disasm(code[start:start + sym['st_size']], start):
            ref = (' ; ' + lines[insn.address]) if insn.address in lines else ''
            text.append(f'{insn.address:04x}  {code_base + insn.address:08x}  {insn.bytes.hex():<10} {insn.mnemonic:<9} {insn.op_str}{ref}')
            decoded += insn.size
            mnemonics.add(insn.mnemonic)
        assert decoded == sym['st_size'], (sym.name, decoded, sym['st_size'])
        decoded_total += decoded
    assert decoded_total == len(code) == 1544
    assert not (mnemonics & {'msr', 'cpsid', 'cpsie', 'bl', 'blx'})
    (OUT / (Path(name).stem + '.asm')).write_text('\n'.join(text) + '\n')
    return {
        'sha256': sha(raw), 'file_size': len(raw),
        'sections': {s.name: {'size': s['sh_size'], 'image_address': hex(s['sh_addr']), 'sha256': sha(s.data())} for s in elf.iter_sections()},
        'symbols': {s.name: {'image_thumb': hex(s['st_value']), 'size': s['st_size'], 'runtime_thumb': hex(code_base + s['st_value'])} for s in symbols},
        'geometry': {'start': hex(pfa.flash_start), 'size': hex(pfa.flash_size), 'page_size': hex(pfa.page_size), 'sector_sizes': pfa.sector_sizes, 'descriptor': str(pfa.flash_info)},
        'pyocd_layout': {k: (hex(v) if isinstance(v, int) and not isinstance(v, bool) else ([hex(x) for x in v] if isinstance(v, list) else v)) for k, v in layout.items() if k != 'instructions'},
        'loaded_blob_sha256': sha(b''.join(w.to_bytes(4, 'little') for w in layout['instructions'])),
        'embedded_source': source_files,
    }


def main():
    data = PACK.read_bytes()
    result = {'pack': {'path': str(PACK), 'sha256': sha(data)}, 'flms': {}}
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        for name in NAMES:
            result['flms'][name] = inspect(name, z.read(name))
        a, b = [ELFFile(io.BytesIO(z.read(n))) for n in NAMES]
        result['section_differences'] = {}
        for sa in a.iter_sections():
            sb = b.get_section_by_name(sa.name)
            da, db = sa.data(), sb.data()
            offsets = [i for i in range(min(len(da), len(db))) if da[i] != db[i]]
            result['section_differences'][sa.name] = {'equal': da == db, 'different_byte_offsets': [hex(i) for i in offsets]}
        assert a.get_section_by_name('PrgCode').data() == b.get_section_by_name('PrgCode').data()
        assert a.get_section_by_name('PrgData').data() == b.get_section_by_name('PrgData').data()
        excerpts = []
        prefix = 'Library/Device/Nuvoton/M3351/'
        sources = {
            'Include/fmc_reg.h': [(30, 82), (142, 203), (205, 224), (597, 608)],
            'Include/clk_reg.h': [(1388, 1396), (1420, 1424), (1441, 1445), (1609, 1611), (1711, 1713), (1837, 1841)],
            'Include/dfmc_reg.h': [(80, 103), (115, 154)],
            'StdDriver/inc/fmc.h': [(106, 123)],
        }
        for suffix, ranges in sources.items():
            name = prefix + suffix
            raw = z.read(name)
            excerpts.append(f'PACK MEMBER {name} SHA256 {sha(raw)}')
            lines = raw.decode(errors='replace').splitlines()
            for start, end in ranges:
                excerpts.extend(f'{n}: {lines[n - 1]}' for n in range(start, end + 1))
        (OUT / 'pack-source-excerpts.txt').write_text('\n'.join(excerpts) + '\n')
        result['snapshot_comparisons'] = {}
        for name in ('post-failed-flash.json', 'passive-snapshot-20261028T211754816957Z.json'):
            path = ROOT / '.embedder/hardware/results' / name
            raw = path.read_bytes()
            snap = json.loads(raw)
            sample = bytes.fromhex(snap['0x20003c00'])
            offset = a.get_section_by_name('PrgCode').data().find(sample)
            result['snapshot_comparisons'][name] = {'sha256': sha(raw), 'sample_0x20003c00': sample.hex(), 'PrgCode_match_offset': hex(offset) if offset >= 0 else None}
    result['source_hashes'] = {}
    for relative in ('tools/flash.py', 'tools/pyocd_attach.py', '.venv/lib/python3.12/site-packages/pyocd/flash/flash.py', '.venv/lib/python3.12/site-packages/pyocd/target/pack/flash_algo.py', '.venv/lib/python3.12/site-packages/pyocd/coresight/cortex_m.py'):
        result['source_hashes'][relative] = sha((ROOT / relative).read_bytes())
    result['tool_versions'] = {name: version(name) for name in ('pyocd', 'pyelftools', 'capstone')}
    result['checks'] = {'all_1544_code_bytes_disassembled': True, 'PrgCode_and_PrgData_identical': True, 'no_msr_cpsid_cpsie_bl_blx_instructions': True}
    (OUT / 'audit.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'pack_sha256': result['pack']['sha256'], 'flms': {k: {'sha256': v['sha256'], 'geometry': v['geometry'], 'layout': v['pyocd_layout']} for k, v in result['flms'].items()}}, indent=2))


if __name__ == '__main__':
    main()
