#!/usr/bin/env python3
"""Offline D2 evidence for the pinned EXE; never load/execute native code or use I/O APIs.

Run with PYTHONDONTWRITEBYTECODE=1 and the workspace Python. The only outputs
are analysis artifacts beside this script. Synthetic replies model host behavior,
not ROM support, memory content, or target-side effects.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import struct

from capstone import Cs, CS_ARCH_X86, CS_MODE_32
from capstone.x86 import X86_OP_IMM
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_ECX, UC_X86_REG_ESP, UC_X86_REG_EIP

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('pinned_audit', HERE.parent / 'audit_exe.py')
a = importlib.util.module_from_spec(spec)
spec.loader.exec_module(a)


def emulate(entry, count=1, *, requested=4, response_size=64, bad_a0=False,
            send_fail=False, stale=False, check_sequence=False):
    """Execute only allowlisted x86 routines; stub libc and HID in emulated RAM."""
    mu = Uc(UC_ARCH_X86, UC_MODE_32)
    mu.mem_map(a.base, (a.u32(a.optional + 56) + 0xfff) & ~0xfff)
    for rva, size, raw in a.sections:
        mu.mem_write(a.base + rva, a.data[raw:raw + size])
    obj, stack, stop = 0x1000000, 0x2000000, 0x3000000
    for address in (obj, stack, stop):
        mu.mem_map(address, 0x10000)
    dest = obj + 0x1000
    mu.mem_write(dest, b'\xcc' * 256)
    for off, value in ((0xb0, 1), (0x90, 1), (0x88, 18)):
        mu.mem_write(obj + off, struct.pack('<I', value))
    args = (dest, requested, 30000, int(check_sequence)) if entry == 0x4098d0 else (dest, count)
    sp = stack + 0xf000
    mu.mem_write(sp, struct.pack('<' + 'I' * (len(args) + 1), stop, *args))
    mu.reg_write(UC_X86_REG_ECX, obj)
    mu.reg_write(UC_X86_REG_ESP, sp)
    events, copies = [], []
    last_packet = None

    def words(address, count):
        return struct.unpack('<' + 'I' * count, mu.mem_read(address, 4 * count))

    def finish(value, popped=0):
        esp = mu.reg_read(UC_X86_REG_ESP)
        ret, = words(esp, 1)
        mu.reg_write(UC_X86_REG_EAX, value)
        mu.reg_write(UC_X86_REG_ESP, esp + 4 + popped)
        mu.reg_write(UC_X86_REG_EIP, ret)

    def hook(_mu, address, _size, _user):
        nonlocal last_packet
        esp = mu.reg_read(UC_X86_REG_ESP)
        if address == 0x50c310:
            out, value, size = words(esp + 4, 3)
            assert size <= 65
            mu.mem_write(out, bytes([value & 0xff]) * size)
            finish(out)
        elif address == 0x50ad10:
            out, src, size = words(esp + 4, 3)
            assert size <= 65
            if size:
                mu.mem_write(out, bytes(mu.mem_read(src, size)))
            if dest <= out < dest + 256:
                copies.append({'offset': out - dest, 'size': size})
            finish(out)
        elif address == 0x4139a0:
            src, size, _out_count, timeout = words(esp + 4, 4)
            assert size == 65 and timeout == 20
            last_packet = bytes(mu.mem_read(src + 1, 64))
            command = last_packet[0]
            assert command in (0xa0, 0xd2), 'Unexpected command'
            event = {'kind': 'send', 'command': hex(command), 'sequence': struct.unpack_from('<I', last_packet, 4)[0],
                     'timeout': timeout, 'packet_hex': last_packet.hex()}
            if command == 0xd2:
                address_arg, length_arg = struct.unpack_from('<II', last_packet, 8)
                event.update(address=hex(address_arg), length=length_arg)
            events.append(event)
            finish(int(not send_fail), 16)
        elif address == 0x416b40:
            _handle, buffer, capacity, timeout = words(esp + 4, 4)
            assert capacity == 65 and response_size <= capacity
            if last_packet:
                sequence = (struct.unpack_from('<I', last_packet, 4)[0] + 1) & 0xffffffff
            else:
                sequence = 17
            if stale:
                sequence ^= 1
            payload = bytes(range(52))
            if last_packet and last_packet[0] == 0xa0:
                payload = payload[:48] + struct.pack('<I', 0 if bad_a0 else 0x13572468)
            response = struct.pack('<III', 0x89abcdef, sequence, 0xfedcba98) + payload
            response = (response + b'\xff')[:response_size]
            mu.mem_write(buffer, response)
            events.append({'kind': 'receive', 'timeout': timeout, 'returned': len(response)})
            finish(len(response))
        elif address == 0x409e30:
            events.append({'kind': 'host_close_stub'})
            mu.mem_write(obj + 0xb0, struct.pack('<I', 0))
            finish(0)
        elif address == 0x50bc27:
            assert mu.reg_read(UC_X86_REG_ECX) == words(0x588250, 1)[0]
            finish(mu.reg_read(UC_X86_REG_EAX))
        elif not any(lo <= address < hi for lo, hi in (
                (0x4098d0, 0x4099bc), (0x40a040, 0x40a190),
                (0x40a6f0, 0x40a755), (0x40a810, 0x40a89d),
                (0x40a8a0, 0x40a924), (0x413920, 0x41399e))):
            raise RuntimeError(f'Execution outside allowlist: {address:#x}')

    mu.hook_add(UC_HOOK_CODE, hook)
    mu.emu_start(entry, stop, timeout=1000000, count=100000)
    assert mu.reg_read(UC_X86_REG_EIP) == stop
    return {'entry': hex(entry), 'count': count, 'requested': requested,
            'result': mu.reg_read(UC_X86_REG_EAX), 'events': events, 'destination_copies': copies,
            'destination_hex': bytes(mu.mem_read(dest, 192)).hex(),
            'final_sequence': words(obj + 0x88, 1)[0]}


def main():
    decoder = Cs(CS_ARCH_X86, CS_MODE_32)
    decoder.detail = True
    decoder.skipdata = True
    text = a.data[a.file_offset(0x401000):a.file_offset(0x537814)]
    relevant = (0xd2, 0x4098d0, 0x40a040, 0x40a810, 0x40a8a0)
    scan = []
    for insn in decoder.disasm(text, 0x401000):
        if insn.id and any(op.type == X86_OP_IMM and op.imm in relevant for op in insn.operands):
            scan.append(f'{insn.address:08x} {insn.mnemonic:8} {insn.op_str}')
    ptrs = [hex(a.address_of(i)) for i in range(len(a.data) - 3)
            if a.data[i:i + 4] == struct.pack('<I', 0x40a040)]
    raw_calls = []
    for offset in range(len(text) - 4):
        if text[offset] == 0xe8:
            target = 0x401000 + offset + 5 + struct.unpack_from('<i', text, offset + 1)[0]
            if target == 0x40a040:
                raw_calls.append(hex(0x401000 + offset))
    raw_d2_pushes = [hex(0x401000 + offset) for offset in range(len(text) - 4)
                     if text[offset:offset + 5] == bytes.fromhex('68d2000000')]
    assert raw_calls == [hex(int(s.split()[0], 16)) for s in scan if s.endswith('call     0x40a040')]
    assert raw_d2_pushes == ['0x40a851', '0x40a8e1']
    static = {'executable_sha256': hashlib.sha256(a.data).hexdigest(),
              'archive_sha256': hashlib.sha256(a.ARCHIVE.read_bytes()).hexdigest(),
              'raw_E8_calls_to_encoder': raw_calls, 'raw_D2_pushes': raw_d2_pushes,
              'linear_scan_range': ['0x401000', '0x537814'],
              'relevant_immediates_and_direct_calls': scan,
              'absolute_encoder_pointers_in_file': ptrs}
    assert [s.split()[0] for s in scan if 'push     0xd2' in s] == ['0040a851', '0040a8e1']
    assert not ptrs
    (HERE / 'static-scan.json').write_text(json.dumps(static, indent=2) + '\n')
    ranges = ((0x40a810, 0x40a89d), (0x40a8a0, 0x40a924), (0x4098d0, 0x4099bc),
              (0x413920, 0x41399e), (0x40a040, 0x40a18b), (0x40a6f0, 0x40a755),
              (0x40a1b0, 0x40a27d), (0x40a2a0, 0x40a2c8))
    asm = []
    for start, end in ranges:
        asm.append(f'\nFUNCTION RANGE {start:#x}..{end:#x} (end exclusive)')
        for i in decoder.disasm(a.data[a.file_offset(start):a.file_offset(end)], start):
            asm.append(f'{i.address:08x} {i.mnemonic:8} {i.op_str}')
    (HERE / 'read-routines.asm').write_text('\n'.join(asm) + '\n')
    cases = {}
    for entry, count in ((0x40a810, 1), (0x40a810, 14), (0x40a810, 18),
                         (0x40a8a0, 1), (0x40a8a0, 19), (0x40a8a0, 0)):
        result = emulate(entry, count)
        expected_commands = ([0xa0] if entry == 0x40a810 else []) + [0xd2] * (
            count if entry == 0x40a810 else (count + 1) // 2)
        assert [int(e['command'], 16) for e in result['events'] if e['kind'] == 'send'] == expected_commands
        assert result['result'] == 1
        step = 1 if entry == 0x40a810 else 2
        length = 4 * step
        indices = range(0, count, step)
        offsets = [4 * (i + (16 if i >= 16 else 0)) for i in indices]
        reads = [e for e in result['events'] if e.get('command') == '0xd2']
        assert [(int(e['address'], 16), e['length']) for e in reads] == [
            (0x0f300000 + offset, length) for offset in offsets]
        assert result['destination_copies'] == [{'offset': offset, 'size': length} for offset in offsets]
        output = bytes.fromhex(result['destination_hex'])
        for offset in offsets:
            assert output[offset:offset + length] == bytes(range(length))
        assert all(bytes.fromhex(e['packet_hex'])[16:] == bytes(48) for e in reads)
        cases[f'{entry:#x}_count_{count}'] = result
    cases['a0_failure_ignored'] = emulate(0x40a810, 1, bad_a0=True)
    assert cases['a0_failure_ignored']['result'] == 1
    cases['d2_send_failure_false_success'] = emulate(0x40a8a0, 1, send_fail=True)
    assert cases['d2_send_failure_false_success']['result'] == 1
    assert not cases['d2_send_failure_false_success']['destination_copies']
    cases['d2_short_response_failure'] = emulate(0x40a8a0, 1, response_size=63)
    assert cases['d2_short_response_failure']['result'] == 0
    for requested in (0, 1, 4, 8, 51, 52, 53, 56, 0xffffffff):
        result = emulate(0x4098d0, requested=requested)
        assert result['result'] == 1
        assert sum(c['size'] for c in result['destination_copies']) == min(requested, 52)
        cases[f'parser_requested_{requested}'] = result
    for size in (0, 1, 12, 63, 65):
        result = emulate(0x4098d0, response_size=size)
        assert result['result'] == 0
        cases[f'parser_response_size_{size}'] = result
    for checked in (False, True):
        result = emulate(0x4098d0, stale=True, check_sequence=checked)
        assert result['result'] == int(not checked)
        cases[f'parser_stale_checked_{checked}'] = result
    report = {'scope': 'Offline allowlisted x86 emulation, memory-only libc and HID stubs; no native execution or hardware',
              'executable_sha256': static['executable_sha256'], 'cases': cases,
              'passed_cases': len(cases), 'target_APROM_read_support_established': False}
    (HERE / 'emulation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'cases'}, indent=2))


if __name__ == '__main__':
    main()
