#!/usr/bin/env python3
"""Offline PE32 inspection of the official Boot Loader ISP ZIP. Never executes it.

Usage: .venv/bin/python <this-file> [start-VA end-VA | xrefs VA | exports]
Requires the workspace's capstone package for disassembly only.
"""
import hashlib
import os
from pathlib import Path
import re
import struct
import sys
import zipfile

ARCHIVE = Path(os.environ.get('NUVOTON_BOOTLOADER_ZIP',
    str(Path.home() / '.embedder/downloads/d98951d347462720/en-us--NuvoISP_BL_V1.04.zip'))).expanduser()
with zipfile.ZipFile(ARCHIVE) as archive:
    data = archive.read('NuvoISP_BL_V1.04.exe')
if hashlib.sha256(data).hexdigest() != 'aed05e31a6a73c760076218dcfbd038e94e579b0287bb86bb2add7ba8daa35f0':
    raise ValueError('Executable hash differs from the audited NuvoISP_BL V1.04')

def u32(offset):
    return struct.unpack_from('<I', data, offset)[0]

pe = u32(0x3c)
optional = pe + 24
base = u32(optional + 28)
sections = []
for index in range(struct.unpack_from('<H', data, pe + 6)[0]):
    offset = optional + struct.unpack_from('<H', data, pe + 20)[0] + index * 40
    sections.append((u32(offset + 12), u32(offset + 16), u32(offset + 20)))

def file_offset(address):
    for rva, size, raw in sections:
        if rva <= address - base < rva + size:
            return raw + address - base - rva
    raise ValueError(f'Address outside file-backed sections: {address:#x}')

def address_of(offset):
    for rva, size, raw in sections:
        if raw <= offset < raw + size:
            return base + rva + offset - raw
    raise ValueError(f'Offset outside sections: {offset:#x}')

def cstring(address):
    offset = file_offset(address)
    return data[offset:data.index(0, offset)].decode('ascii')

imports = {}
address = base + u32(optional + 104)
while address:
    offset = file_offset(address)
    original, timestamp, forward, name, thunk = struct.unpack_from('<IIIII', data, offset)
    if not name:
        break
    dll = cstring(base + name)
    index = 0
    while True:
        value = u32(file_offset(base + (original or thunk) + index * 4))
        if not value:
            break
        label = f'ordinal_{value & 0xffff}' if value & 0x80000000 else cstring(base + value + 2)
        imports[base + thunk + index * 4] = f'{dll}!{label}'
        index += 1
    address += 20

exports = {}
offset = file_offset(base + u32(optional + 96))
functions = file_offset(base + u32(offset + 28))
names = file_offset(base + u32(offset + 32))
ordinals = file_offset(base + u32(offset + 36))
for index in range(u32(offset + 24)):
    name = cstring(base + u32(names + 4 * index))
    ordinal = struct.unpack_from('<H', data, ordinals + index * 2)[0]
    exports[base + u32(functions + 4 * ordinal)] = name

def emulate_encoder(command, payload=b'', sequence=0x12, mode=1, send_ok=True,
                    *, config_call=False, repair_failed_send_in_memory=False):
    """Run only the PE packet routine with memory-only libc and transport stubs.

    This is a CPU emulator, not a Windows loader. No PE imports, host HID,
    serial APIs, reset routines, or native machine code are executed.
    """
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
    from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_ECX, UC_X86_REG_ESP, UC_X86_REG_EIP

    mu = Uc(UC_ARCH_X86, UC_MODE_32)
    image_size = (u32(optional + 56) + 0xfff) & ~0xfff
    mu.mem_map(base, image_size)
    for rva, size, raw in sections:
        mu.mem_write(base + rva, data[raw:raw + size])
    obj, stack, stop = 0x1000000, 0x2000000, 0x3000000
    mu.mem_map(obj, 0x10000)
    mu.mem_map(stack, 0x10000)
    mu.mem_map(stop, 0x1000)
    source = obj + 0x1000
    mu.mem_write(source, payload or b'\0')
    if config_call and send_ok:
        raise ValueError('Configuration wrapper emulation permits failed sends only')
    if repair_failed_send_in_memory:
        if not config_call or mu.mem_read(0x40a4d8, 2) != b'\x74\x5a':
            raise ValueError('Unexpected branch or unsupported patch target')
        # Change only emulated RAM: failed send branches to existing failure path.
        mu.mem_write(0x40a4d9, b'\x4f')
    for offset, value in ((0xb0, 1), (0x88, sequence), (0x90, mode)):
        mu.mem_write(obj + offset, struct.pack('<I', value))
    sp = stack + 0xf000
    entry = 0x40a490 if config_call else 0x40a040
    arguments = (stop, 0x0f300000, 0x5a) if config_call else (stop, command, source, len(payload), 20)
    mu.mem_write(sp, struct.pack('<' + 'I' * len(arguments), *arguments))
    mu.reg_write(UC_X86_REG_ESP, sp)
    mu.reg_write(UC_X86_REG_ECX, obj)
    captured = []
    closed = []

    def words(address, count):
        return struct.unpack('<' + 'I' * count, mu.mem_read(address, count * 4))

    def finish(return_value, popped=0):
        esp = mu.reg_read(UC_X86_REG_ESP)
        ret, = words(esp, 1)
        mu.reg_write(UC_X86_REG_EAX, return_value)
        mu.reg_write(UC_X86_REG_ESP, esp + 4 + popped)
        mu.reg_write(UC_X86_REG_EIP, ret)

    def hook(_mu, address, _size, _user):
        esp = mu.reg_read(UC_X86_REG_ESP)
        if address == 0x50c310:  # memset, cdecl
            dest, value, size = words(esp + 4, 3)
            if size > 65:
                raise RuntimeError('Unexpected memset extent')
            mu.mem_write(dest, bytes([value & 0xff]) * size)
            finish(dest)
        elif address == 0x50ad10:  # memcpy, cdecl
            dest, src, size = words(esp + 4, 3)
            if size > 56:
                raise RuntimeError('Unexpected memcpy extent')
            mu.mem_write(dest, bytes(mu.mem_read(src, size)))
            finish(dest)
        elif address in (0x4139a0, 0x415d40):  # HID/serial transport sink
            src, size, size_out, timeout = words(esp + 4, 4)
            if size not in (64, 65) or timeout != 20:
                raise RuntimeError('Unexpected transport call')
            captured.append(bytes(mu.mem_read(src, size)).hex())
            mu.mem_write(size_out, struct.pack('<I', size if send_ok else 0))
            finish(int(send_ok), 16)
        elif address == 0x409e30:
            closed.append(True)
            finish(0)
        elif not (0x40a040 <= address < 0x40a190 or
                  config_call and 0x40a490 <= address < 0x40a53c):
            raise RuntimeError(f'Unexpected execution outside audited routine: {address:#x}')

    mu.hook_add(UC_HOOK_CODE, hook)
    mu.emu_start(entry, stop, timeout=1000000, count=10000)
    if mu.reg_read(UC_X86_REG_EIP) != stop:
        raise RuntimeError('Emulated encoder did not return within its budget')
    return {'command': command, 'payload_hex': payload.hex(), 'sequence': sequence,
            'mode': mode, 'send_ok': send_ok, 'transfers': captured,
            'next_sequence': words(obj + 0x88, 1)[0],
            'result': mu.reg_read(UC_X86_REG_EAX), 'closed': bool(closed)}


def emulate_receiver(response, requested=52, sequence=20, check_sequence=False):
    """Emulate the vendor HID reader and payload parser, with hid_read stubbed."""
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
    from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_ECX, UC_X86_REG_ESP, UC_X86_REG_EIP

    if not 0 <= requested <= 52 or len(response) > 65:
        raise ValueError('Invalid bounded emulator input')
    mu = Uc(UC_ARCH_X86, UC_MODE_32)
    mu.mem_map(base, (u32(optional + 56) + 0xfff) & ~0xfff)
    for rva, size, raw in sections:
        mu.mem_write(base + rva, data[raw:raw + size])
    obj, stack, stop = 0x1000000, 0x2000000, 0x3000000
    mu.mem_map(obj, 0x10000)
    mu.mem_map(stack, 0x10000)
    mu.mem_map(stop, 0x1000)
    dest = obj + 0x1000
    mu.mem_write(dest, b'\xcc' * 52)
    for offset, value in ((0xb0, 1), (0x88, sequence), (0x90, 1)):
        mu.mem_write(obj + offset, struct.pack('<I', value))
    sp = stack + 0xf000
    mu.mem_write(sp, struct.pack('<IIIII', stop, dest, requested, 5000, int(check_sequence)))
    mu.reg_write(UC_X86_REG_ESP, sp)
    mu.reg_write(UC_X86_REG_ECX, obj)

    def words(address, count):
        return struct.unpack('<' + 'I' * count, mu.mem_read(address, count * 4))

    def finish(value, popped=0):
        esp = mu.reg_read(UC_X86_REG_ESP)
        ret, = words(esp, 1)
        mu.reg_write(UC_X86_REG_EAX, value)
        mu.reg_write(UC_X86_REG_ESP, esp + 4 + popped)
        mu.reg_write(UC_X86_REG_EIP, ret)

    def hook(_mu, address, _size, _user):
        esp = mu.reg_read(UC_X86_REG_ESP)
        if address == 0x416b40:  # hid_read_timeout, cdecl; HIDAPI excludes absent report ID
            handle, buffer, capacity, timeout = words(esp + 4, 4)
            if len(response) > capacity:
                raise RuntimeError('Response exceeds requested HID capacity')
            if response:
                mu.mem_write(buffer, response)
            finish(len(response))
        elif address == 0x50ad10:
            out, src, size = words(esp + 4, 3)
            if size > 65:
                raise RuntimeError('Unexpected memcpy extent')
            if size:
                mu.mem_write(out, bytes(mu.mem_read(src, size)))
            finish(out)
        elif address == 0x50bc27:  # compiler security-cookie check, no host dispatch
            if mu.reg_read(UC_X86_REG_ECX) != words(0x588250, 1)[0]:
                raise RuntimeError('Emulated stack cookie changed')
            finish(mu.reg_read(UC_X86_REG_EAX))
        elif not (0x4098d0 <= address < 0x4099bc or 0x413920 <= address < 0x41399e):
            raise RuntimeError(f'Unexpected execution outside audited reader: {address:#x}')

    mu.hook_add(UC_HOOK_CODE, hook)
    mu.emu_start(0x4098d0, stop, timeout=1000000, count=10000)
    if mu.reg_read(UC_X86_REG_EIP) != stop:
        raise RuntimeError('Emulated reader did not return within budget')
    return {'result': mu.reg_read(UC_X86_REG_EAX),
            'payload_hex': bytes(mu.mem_read(dest, requested)).hex()}


def verify_codec():
    """Differential checks against x86 instructions, never against hardware."""
    import json
    import random
    sys.path.insert(0, str(Path(__file__).resolve().parents[4]))
    from tools import bootloader_protocol as codec

    rng = random.Random(0x3351)
    golden = []
    count = 0
    for command in range(256):
        length = (0, 1, 2, 4, 8, 20, 55, 56)[command % 8]
        payload = bytes(rng.randrange(256) for _ in range(length))
        sequence = (0, 1, 18, 0xffffffff, rng.randrange(1 << 32))[command % 5]
        for mode in range(1, 6):
            actual = emulate_encoder(command, payload, sequence, mode)
            packet = codec.encode_packet(command, payload, sequence=sequence, mode=mode)
            expected = codec.hid_output_report(packet) if mode != 2 else packet
            if (actual['transfers'] != [expected.hex()] or actual['result'] != 1 or
                    actual['next_sequence'] != (sequence + 2) & 0xffffffff or actual['closed']):
                raise AssertionError(actual)
            count += 1
            if command in (0, 0x5a, 0xa0, 0xd2, 255):
                golden.append(actual)
    errors = []
    for mode in range(1, 6):
        actual = emulate_encoder(0xa0, mode=mode, send_ok=False)
        if actual['result'] != 0 or not actual['closed'] or actual['next_sequence'] != 18:
            raise AssertionError(actual)
        errors.append(actual)
    false_success = []
    for mode in range(1, 6):
        original = emulate_encoder(0xd1, mode=mode, send_ok=False, config_call=True)
        repaired = emulate_encoder(0xd1, mode=mode, send_ok=False, config_call=True,
                                   repair_failed_send_in_memory=True)
        if (original['result'] != 1 or repaired['result'] != 0 or
                original['transfers'] != repaired['transfers'] or
                not original['closed'] or not repaired['closed']):
            raise AssertionError('Configuration failure control-flow result changed')
        false_success.append({'mode': mode, 'original': original,
                              'repaired_in_emulator_only': repaired})
    reader_count = 0
    for _ in range(100):
        sequence = rng.randrange(1 << 32)
        payload = bytes(rng.randrange(256) for _ in range(52))
        response = struct.pack('<III', rng.randrange(1 << 32), (sequence - 1) & 0xffffffff,
                               rng.randrange(1 << 32)) + payload
        actual = emulate_receiver(response, sequence=sequence, check_sequence=True)
        expected = codec.decode_response(response, expected_sequence=(sequence - 1) & 0xffffffff)
        if actual['result'] != 1 or actual['payload_hex'] != expected.payload.hex():
            raise AssertionError(actual)
        reader_count += 1
    packet = struct.pack('<III', 0, 19, 0) + bytes(range(52))
    boundaries = {str(size): emulate_receiver(packet[:size]) for size in (0, 1, 12, 63, 64)}
    if [boundaries[str(n)]['result'] for n in (0, 1, 12, 63, 64)] != [0, 0, 0, 0, 1]:
        raise AssertionError(boundaries)
    stale = packet[:4] + struct.pack('<I', 18) + packet[8:]
    if emulate_receiver(stale, check_sequence=False)['result'] != 1:
        raise AssertionError('Vendor permissive path changed')
    if emulate_receiver(stale, check_sequence=True)['result'] != 0:
        raise AssertionError('Vendor checked path changed')
    for payload in (b'\xff' * 56, bytes(range(56)), bytes(56)):
        if emulate_encoder(0xd2, payload)['transfers'] != [codec.hid_output_report(codec.encode_packet(0xd2, payload)).hex()]:
            raise AssertionError('Boundary payload mismatch')
    return {'executable_sha256': hashlib.sha256(data).hexdigest(),
            'scope': 'Offline x86 emulation with memory-only libc/HID/serial stubs; no native execution or device I/O',
            'encode_cases': count + 3, 'reader_cases': reader_count,
            'reader_length_boundaries': boundaries, 'send_failures': errors,
            'vendor_stale_unchecked_accepted': True, 'vendor_stale_checked_rejected': True,
            'configuration_false_success_cases': false_success,
            'golden_vectors': golden}


if __name__ == '__main__':
    if sys.argv[1:] == ['verify-codec']:
        import json
        report = verify_codec()
        destination = Path(__file__).with_name('codec-differential.json')
        destination.write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps({key: value for key, value in report.items() if key not in ('golden_vectors', 'send_failures', 'reader_length_boundaries', 'configuration_false_success_cases')}, indent=2))
        print(destination)
        raise SystemExit(0)
    if sys.argv[1:] == ['emulate-encoder']:
        import json
        print(json.dumps([emulate_encoder(0xa0, mode=mode) for mode in range(1, 6)], indent=2))
        raise SystemExit(0)
    from capstone import Cs, CS_ARCH_X86, CS_MODE_32
    from capstone.x86 import X86_OP_IMM, X86_OP_MEM
    decoder = Cs(CS_ARCH_X86, CS_MODE_32)
    decoder.detail = True
    decoder.skipdata = True
    args = sys.argv[1:]
    if args == ['exports']:
        for address, name in exports.items():
            print(f'{address:#x} {name}')
    elif len(args) == 2 and args[0] == 'xrefs':
        target = int(args[1], 0)
        for insn in decoder.disasm(data[file_offset(0x401000):file_offset(0x537814)], 0x401000):
            if insn.id != 0 and any((op.type == X86_OP_IMM and op.imm == target)
                   or (op.type == X86_OP_MEM and op.mem.disp == target) for op in insn.operands):
                print(f'{insn.address:#x}: {insn.mnemonic} {insn.op_str}')
        for match in re.finditer(re.escape(struct.pack('<I', target)), data):
            print(f'raw_pointer {address_of(match.start()):#x}')
    elif len(args) == 2:
        start, end = (int(value, 0) for value in args)
        for insn in decoder.disasm(data[file_offset(start):file_offset(end)], start):
            labels = []
            for op in (insn.operands if insn.id != 0 else ()):
                value = op.imm if op.type == X86_OP_IMM else op.mem.disp if op.type == X86_OP_MEM else None
                if value in imports or value in exports:
                    labels.append(imports.get(value, exports.get(value)))
            print(f'{insn.address:08x}  {insn.mnemonic:8} {insn.op_str}' + (' ; ' + ', '.join(labels) if labels else ''))
    else:
        raise SystemExit(__doc__)
