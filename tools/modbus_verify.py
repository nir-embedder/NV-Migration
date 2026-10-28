#!/usr/bin/env python3
"""Host Modbus interoperability checks; live traffic requires a hardware lease.

Only the zeroed demonstration memory maps are supported. No network configuration,
flashing, terminal text, peripheral actuation, or USB identity assignment is done.
"""
from __future__ import annotations

import argparse
import asyncio
from collections import Counter, deque
from contextlib import ExitStack
from dataclasses import dataclass
import json
import logging
import socket
import struct
import sys
import time
from typing import Callable

import pymodbus
from pymodbus.client import ModbusSerialClient, ModbusTcpClient
from pymodbus.pdu.bit_message import WriteSingleCoilRequest
from pymodbus.server import ModbusSerialServer, ModbusTcpServer
from pymodbus.simulator import DataType, SimData, SimDevice
import serial
from serial.tools import list_ports


FUNCTIONS = (1, 2, 3, 4, 5, 6, 15, 16)
DEMO_ORDER = (5, 1, 15, 2, 6, 3, 16, 4)
DEMO_WORDS = [1, 0x1234, 0x5678, 0xABCD]
METHODS = {
    1: "read_coils", 2: "read_discrete_inputs", 3: "read_holding_registers",
    4: "read_input_registers", 5: "write_coil", 6: "write_register",
    15: "write_coils", 16: "write_registers",
}
MANUAL_CASES = (
    ("usb_unplug_replug", "Requires physical cable disconnect/reconnect and rediscovery."),
    ("no_terminal_cold_boot", "Requires cold boot without opening a CDC terminal; verify ECM independently."),
    ("board_client_result_buffers", "PC responses do not prove board-side response consumption; inspect independent board logs."),
)


class CheckFailure(Exception):
    """A measured result did not meet the protocol contract."""


def require(condition, message):
    if not condition:
        raise CheckFailure(message)


def equal(actual, expected, label):
    require(actual == expected, f"{label}: expected {expected!r}, got {actual!r}")


@dataclass(frozen=True)
class Profile:
    name: str

    def region(self, fc):
        kind = 1 if fc in (1, 5, 15) else 3 if fc in (3, 6, 16) else fc
        if self.name in ("shared", "large"):
            words = 128 if self.name == "large" else 16
            return (0, words * 16 if kind in (1, 2) else words)
        return {1: (0, 32), 2: (100, 32), 3: (200, 4), 4: (300, 4)}[kind]

    def simdevice(self, unit):
        """Public PyModbus 3.16 API; addresses are literal protocol offsets."""
        if self.name in ("shared", "large"):
            return SimDevice(unit, [SimData(0, count=self.region(3)[1], values=0, datatype=DataType.REGISTERS)],
                             use_bit_addressing=True)
        return SimDevice(unit, (
            [SimData(0, values=[False] * 32, datatype=DataType.BITS)],
            [SimData(100, values=[False] * 32, datatype=DataType.BITS)],
            [SimData(200, count=4, values=0, datatype=DataType.REGISTERS)],
            [SimData(300, count=4, values=0, datatype=DataType.REGISTERS)],
        ))


class Bank:
    """Independent protocol oracle: bit zero is the LSB of shared word zero."""

    def __init__(self, profile):
        self.profile = profile
        self.words = [0] * profile.region(3)[1]
        self.coils = [False] * 32
        self.inputs = [False] * 32
        self.holding = [0] * 4
        self.registers = [0] * 4

    def read(self, fc, address, count):
        start, size = self.profile.region(fc)
        require(count > 0 and start <= address and address + count <= start + size,
                f"FC{fc} outside {self.profile.name} map: {address}+{count}")
        offset = address - start
        if self.profile.name in ("shared", "large"):
            if fc in (1, 2, 5, 15):
                return [bool(self.words[i // 16] & (1 << (i % 16)))
                        for i in range(offset, offset + count)]
            return self.words[offset:offset + count]
        data = self.coils if fc in (1, 5, 15) else self.inputs if fc == 2 else self.registers if fc == 4 else self.holding
        return data[offset:offset + count]

    def write(self, fc, address, values):
        self.read(fc, address, len(values))
        start, _ = self.profile.region(fc)
        offset = address - start
        if self.profile.name in ("shared", "large"):
            if fc in (5, 15):
                for i, value in enumerate(values, offset):
                    mask = 1 << (i % 16)
                    self.words[i // 16] = (self.words[i // 16] & ~mask) | (mask if value else 0)
            else:
                self.words[offset:offset + len(values)] = values
        else:
            data = self.coils if fc in (5, 15) else self.holding
            data[offset:offset + len(values)] = values


def adu_capacity(args):
    """The nominal RTU size gains four bytes for TCP's larger transport header."""
    return args.buffer_size + (4 if args.transport == "tcp" else 0)


def transfer_limit(fc, args):
    """Bound a single transaction by protocol quantity and complete ADU capacity."""
    if fc in (5, 6):
        return 1
    protocol_limit = {1: 2000, 2: 2000, 3: 125, 4: 125, 15: 1968, 16: 123}[fc]
    overhead = (5 if args.transport == "rtu" else 9) if fc <= 4 else (9 if args.transport == "rtu" else 13)
    payload = adu_capacity(args) - overhead
    capacity = payload * 8 if fc in (1, 2, 15) else payload // 2
    return min(protocol_limit, capacity)


def adu_sizes(fc, count, transport):
    fixed = 8 if transport == "rtu" else 12
    if fc in (5, 6):
        request, response = fixed, fixed
    elif fc in (15, 16):
        request = (9 if transport == "rtu" else 13) + ((count + 7) // 8 if fc == 15 else count * 2)
        response = fixed
    else:
        request = fixed
        response = (5 if transport == "rtu" else 9) + ((count + 7) // 8 if fc in (1, 2) else count * 2)
    return {"request_adu_bytes": request, "response_adu_bytes": response}


def crc16(data):
    crc = 0xFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            crc = (crc >> 1) ^ (0xA001 if crc & 1 else 0)
    return crc


def rtu_frame(unit, pdu):
    body = bytes([unit]) + pdu
    return body + struct.pack("<H", crc16(body))


def tcp_frame(unit, pdu, tid=1, protocol=0, length=None):
    return struct.pack(">HHHB", tid, protocol, len(pdu) + 1 if length is None else length, unit) + pdu


def read_pdu(fc, address, count):
    return struct.pack(">BHH", fc, address, count)


def pack_bits(values):
    data = bytearray((len(values) + 7) // 8)
    for i, value in enumerate(values):
        if value:
            data[i // 8] |= 1 << (i % 8)
    return bytes(data)


def read_reply(fc, values):
    payload = pack_bits(values) if fc in (1, 2) else struct.pack(f">{len(values)}H", *values)
    return bytes([fc, len(payload)]) + payload


class Results:
    def __init__(self, args):
        self.args = args
        self.cases = []
        self.coverage = Counter()
        self.latencies = []

    def run(self, name: str, action: Callable, **details):
        start = time.monotonic()
        try:
            extra = action()
            if isinstance(extra, dict):
                details.update(extra)
            self.cases.append({"name": name, "status": "pass", "details": details,
                               "elapsed_ms": round((time.monotonic() - start) * 1000, 3)})
            return True
        except Exception as exc:  # Case boundary: retain failure and emit the remaining evidence.
            self.cases.append({"name": name, "status": "fail", "details": details,
                               "error": f"{type(exc).__name__}: {exc}"})
            return False

    def skip(self, name, reason):
        self.cases.append({"name": name, "status": "skip", "reason": reason})

    def document(self):
        cases = list(self.cases)
        for name, reason in MANUAL_CASES:
            if name != "board_client_result_buffers" or self.args.role == "board-client":
                cases.append({"name": name, "status": "manual_pending", "reason": reason})
        counts = Counter(case["status"] for case in cases)
        success = counts["fail"] == 0 and counts["pass"] > 0
        latencies = self.latencies
        return {
            "schema_version": 1, "success": success,
            "acceptance_complete": False, "role": self.args.role,
            "transport": self.args.transport, "profile": self.args.profile,
            "buffer_size": self.args.buffer_size, "unit": self.args.unit,
            "adu_capacity": adu_capacity(self.args), "pdu_capacity": self.args.buffer_size - 3,
            "endpoint": self.args.serial_port if self.args.transport == "rtu" else
                {"host": self.args.host if self.args.role == "board-server" else self.args.listen_host,
                 "port": self.args.port if self.args.role == "board-server" else self.args.listen_port},
            "dependencies": {"python": sys.version.split()[0], "pymodbus": pymodbus.__version__,
                             "pyserial": serial.__version__},
            "parameters": {"iterations": self.args.iterations, "cycles": self.args.cycles,
                           "timeout": self.args.timeout, "duration": self.args.duration},
            "coverage": {str(fc): self.coverage[fc] for fc in FUNCTIONS},
            "transactions": len(latencies),
            "latency_scope": "PC server request-to-response processing" if self.args.role == "board-client" else
                "PyModbus round trips only; raw cases are listed separately",
            "latency_ms": {"min": round(min(latencies), 3), "max": round(max(latencies), 3),
                           "mean": round(sum(latencies) / len(latencies), 3)} if latencies else None,
            "counts": dict(counts), "cases": cases,
        }


class Master:
    def __init__(self, client, args, results, bank):
        self.client, self.args, self.results, self.bank = client, args, results, bank

    def call(self, fc, address, values=None, count=None):
        kwargs = {"device_id": self.args.unit}
        if count is not None:
            kwargs["count"] = count
        start = time.monotonic()
        method = getattr(self.client, METHODS[fc])
        response = method(address, values, **kwargs) if values is not None else method(address, **kwargs)
        self.results.latencies.append((time.monotonic() - start) * 1000)
        self.results.coverage[fc] += 1
        require(not response.isError(), f"FC{fc}: {response}")
        equal(response.function_code, fc, "response function")
        equal(response.dev_id, self.args.unit, "response unit")
        return response

    def read(self, fc, address, count):
        response = self.call(fc, address, count=count)
        actual = response.bits[:count] if fc in (1, 2) else response.registers
        equal(actual, self.bank.read(fc, address, count), f"FC{fc} address {address} count {count}")
        if fc in (1, 2):
            equal(response.bits[count:], [False] * ((-count) % 8), "padding bits")

    def write(self, fc, address, values):
        response = self.call(fc, address, values[0] if fc in (5, 6) else values)
        equal(response.address, address, f"FC{fc} write address echo")
        if fc == 5:
            equal(response.bits, [bool(values[0])], "FC5 value echo")
        elif fc == 6:
            equal(response.registers, values, "FC6 value echo")
        else:
            equal(response.count, len(values), f"FC{fc} quantity echo")
        self.bank.write(fc, address, values)

    def write_chunks(self, fc, address, values):
        per_request = transfer_limit(fc, self.args)
        for offset in range(0, len(values), per_request):
            self.write(fc, address + offset, values[offset:offset + per_request])

    def verify_map(self):
        for fc in (1, 2, 3, 4):
            start, count = self.bank.profile.region(fc)
            per_request = transfer_limit(fc, self.args)
            for offset in range(0, count, per_request):
                self.read(fc, start + offset, min(per_request, count - offset))


def make_client(args):
    if args.transport == "tcp":
        return ModbusTcpClient(args.host, port=args.port, timeout=args.timeout, retries=0)
    return ModbusSerialClient(args.serial_port, baudrate=args.baudrate, parity=args.parity,
                              stopbits=args.stopbits, timeout=args.timeout, retries=0)


def positive_tests(args, results, client=None):
    profile = Profile(args.profile)
    bank = Bank(profile)
    client = make_client(args) if client is None else client
    try:
        require(client.connect(), "PyModbus connection failed")
        master = Master(client, args, results, bank)
        co, coils = profile.region(1)
        hr, regs = profile.region(3)

        def reset():
            master.write_chunks(16, hr, [0] * regs)
            master.write_chunks(15, co, [False] * coils)
            master.verify_map()

        results.run("initialize_zeroed_demo_map", reset)
        for iteration in range(args.iterations):
            def write_check(fc, address, values):
                master.write(fc, address, values)
                master.verify_map()

            for fc, address, values in (
                (5, co + coils - 1, [True]),
                (15, co, [True, False, True, False]),
                (6, hr + regs - 1, [0xA55A ^ (iteration & 0xFFFF)]),
                (16, hr, [(0x1234 + 0x1111 * i + iteration) & 0xFFFF
                          for i in range(min(regs, transfer_limit(16, args)))]),
            ):
                results.run(f"iteration_{iteration}_fc{fc}_write_and_all_read_views",
                            lambda fc=fc, address=address, values=values: write_check(fc, address, values),
                            address=address, quantity=len(values),
                            **adu_sizes(fc, len(values), args.transport))
            for fc in (1, 2, 3, 4):
                start, count = profile.region(fc)
                results.run(f"iteration_{iteration}_fc{fc}_first_last",
                            lambda fc=fc, start=start, count=count:
                                (master.read(fc, start, 1), master.read(fc, start + count - 1, 1)))
        if coils >= 128:
            def coils128():
                master.write(15, co, [i % 3 == 0 for i in range(128)])
                master.verify_map()
            results.run("fc15_128_coils", coils128, quantity=128,
                        request_adu_bytes=25 if args.transport == "rtu" else 29,
                        larger_than_usb_packet=False)
        else:
            results.skip("fc15_128_coils", "Separate profile has only 32 coils; request would be out of range.")
        if profile.name == "large":
            def large_write(fc, address, values):
                master.write(fc, address, values)
                master.verify_map()

            results.run("valid_single_adu_over_64_bytes",
                        lambda: large_write(16, hr, [(0x1357 + i) & 0xFFFF for i in range(32)]),
                        function=16, address=hr, quantity=32, valid_map_payload=True,
                        **adu_sizes(16, 32, args.transport))
            for fc in (16, 15, 1, 2, 3, 4):
                start, size = profile.region(fc)
                count = min(size, transfer_limit(fc, args))
                address = start + size - count
                if fc in (15, 16):
                    values = [i % 3 == 0 for i in range(count)] if fc == 15 else [
                        (0xA55A ^ (i * 257)) & 0xFFFF for i in range(count)]
                    action = lambda fc=fc, address=address, values=values: large_write(fc, address, values)
                else:
                    action = lambda fc=fc, address=address, count=count: master.read(fc, address, count)
                results.run(f"large_fc{fc}_capacity_boundary", action,
                            function=fc, address=address, quantity=count, valid_map_payload=True,
                            **adu_sizes(fc, count, args.transport))
        else:
            results.skip("valid_single_adu_over_64_bytes",
                         "Selected map has only 16 shared words or 4 separate words. Use the opt-in large test map, not just a larger buffer.")
        results.run("restore_writable_zero_map", reset)
    finally:
        client.close()


def recv_exact(sock, size):
    """Receive one field; timeout/EOF after a prefix is an error, not silence."""
    data = bytearray()
    while len(data) < size:
        chunk = sock.recv(size - len(data))
        if not chunk:
            raise EOFError(f"connection closed after {len(data)}/{size} bytes")
        data.extend(chunk)
    return bytes(data)


class RawTCP:
    def __init__(self, args):
        self.args, self.tid = args, 0
        self.sock = socket.create_connection((args.host, args.port), timeout=args.timeout)
        self.sock.settimeout(args.timeout)
        self.sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.sock.close()

    def send(self, pdu, unit=None):
        self.tid = self.tid % 65535 + 1
        self.sock.sendall(tcp_frame(self.args.unit if unit is None else unit, pdu, self.tid))
        return self.tid

    def receive(self, tid, unit=None):
        # A wholly silent peer is different from a truncated/malformed reply.
        try:
            first = self.sock.recv(1)
        except socket.timeout:
            return None
        if not first:
            raise EOFError("connection closed before response")
        try:
            header = first + recv_exact(self.sock, 6)
        except (TimeoutError, EOFError, ConnectionResetError) as exc:
            raise CheckFailure("partial MBAP response header") from exc
        got_tid, protocol, length, got_unit = struct.unpack(">HHHB", header)
        equal(got_tid, tid, "MBAP transaction")
        equal(protocol, 0, "MBAP protocol")
        equal(got_unit, self.args.unit if unit is None else unit, "MBAP unit")
        require(2 <= length <= min(254, adu_capacity(self.args) - 6), f"invalid MBAP length {length}")
        try:
            return recv_exact(self.sock, length - 1)
        except (TimeoutError, EOFError, ConnectionResetError) as exc:
            raise CheckFailure("partial MBAP response body") from exc

    def request(self, pdu, unit=None):
        return self.receive(self.send(pdu, unit), unit)

    def rejection(self, frame):
        self.sock.sendall(frame)
        try:
            data = self.sock.recv(1)
        except (socket.timeout, ConnectionResetError):
            return
        require(not data, f"rejected MBAP produced data: {data.hex()}")


class RawRTU:
    def __init__(self, args, port=None):
        self.args = args
        self.port = port if port is not None else serial.Serial(
            args.serial_port, baudrate=args.baudrate, parity=args.parity,
            stopbits=args.stopbits, timeout=args.timeout, write_timeout=args.timeout)

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.port.close()

    def send_bytes(self, data):
        # Binary write only: never use a terminal helper or append a line ending.
        equal(self.port.write(data), len(data), "serial write length")
        self.port.flush()

    def exact(self, count):
        data = bytearray()
        deadline = time.monotonic() + self.args.timeout
        while len(data) < count:
            self.port.timeout = max(0, deadline - time.monotonic())
            chunk = self.port.read(count - len(data))
            if not chunk:
                raise CheckFailure(f"partial RTU response: {len(data)}/{count} bytes")
            data.extend(chunk)
        return bytes(data)

    def receive(self, unit):
        self.port.timeout = self.args.timeout
        first = self.port.read(1)
        if not first:
            return None
        prefix = first + self.exact(2)
        fc = prefix[1]
        if fc & 0x80:
            frame = prefix + self.exact(2)
        elif fc in (1, 2, 3, 4):
            require(prefix[2] <= min(250, adu_capacity(self.args) - 5), "oversize RTU byte count")
            frame = prefix + self.exact(prefix[2] + 2)
        elif fc in (5, 6, 15, 16):
            frame = prefix + self.exact(5)
        else:
            raise CheckFailure(f"unexpected RTU response FC{fc}")
        equal(frame[0], unit, "RTU response unit")
        equal(crc16(frame[:-2]), int.from_bytes(frame[-2:], "little"), "RTU response CRC")
        return frame[1:-2]

    def request(self, pdu, unit=None):
        unit = self.args.unit if unit is None else unit
        self.send_bytes(rtu_frame(unit, pdu))
        return self.receive(unit)

    def silence(self, frame):
        self.send_bytes(frame)
        self.port.timeout = self.args.timeout
        equal(self.port.read(1), b"", "RTU silence")


def raw_connection(args):
    return RawTCP(args) if args.transport == "tcp" else RawRTU(args)


def raw_map(raw, profile, args):
    values = []
    for fc in (1, 2, 3, 4):
        start, size = profile.region(fc)
        per_request = transfer_limit(fc, args)
        for offset in range(0, size, per_request):
            count = min(per_request, size - offset)
            response = raw.request(read_pdu(fc, start + offset, count))
            require(response is not None and response[:1] == bytes([fc]), f"FC{fc} map read failed: {response!r}")
            expected_bytes = (count + 7) // 8 if fc < 3 else count * 2
            equal(len(response), expected_bytes + 2, "map response size")
            equal(response[1], expected_bytes, "map response byte count")
            values.append(response)
    return values


def negative_tests(args, results):
    profile = Profile(args.profile)
    # Use a separate connection for each malformed case: TCP may reject by closing.
    def invalid(pdu, code, allow_silence=False):
        with raw_connection(args) as raw:
            before = raw_map(raw, profile, args)
            try:
                response = raw.request(pdu)
            except (EOFError, ConnectionResetError):
                if not allow_silence:
                    raise
                response = None
            if response is None:
                require(allow_silence, "required exception response missing")
            else:
                equal(response, bytes([pdu[0] | 0x80, code]), "exception response")
        with raw_connection(args) as raw:
            equal(raw_map(raw, profile, args), before, "rejected request must not mutate any view")
        return {"rejection": "silent_or_closed" if response is None else "exception", "exception_code": code}

    for fc in (1, 2, 3, 4):
        start, count = profile.region(fc)
        results.run(f"fc{fc}_out_of_range", lambda fc=fc, start=start, count=count:
                    invalid(read_pdu(fc, start + count, 1), 2))
        results.run(f"fc{fc}_zero_quantity", lambda fc=fc, start=start:
                    invalid(read_pdu(fc, start, 0), 3))
    results.run("unsupported_fc_0x45", lambda: invalid(read_pdu(0x45, 0, 1), 1))
    co, coils = profile.region(1)
    hr, regs = profile.region(3)
    for name, pdu, code in (
        ("fc5_invalid_value", read_pdu(5, co, 0x1234), 3),
        ("fc5_out_of_range", read_pdu(5, co + coils, 0xFF00), 2),
        ("fc6_out_of_range", read_pdu(6, hr + regs, 0x1234), 2),
        ("fc15_bad_byte_count", read_pdu(15, co, 9) + b"\x01\xff", 3),
        ("fc16_bad_byte_count", read_pdu(16, hr, 2) + b"\x02\x12\x34", 3),
        ("fc15_out_of_range", read_pdu(15, co + coils - 1, 2) + b"\x01\x03", 2),
        ("fc16_out_of_range", read_pdu(16, hr + regs - 1, 2) + b"\x04\x12\x34\x56\x78", 2),
    ):
        results.run(name, lambda pdu=pdu, code=code: invalid(pdu, code, "bad_byte_count" in name),
                    request_pdu_hex=pdu.hex())
    overhead = 3 if args.transport == "rtu" else 7
    capacity = adu_capacity(args)
    for size in (75 if args.transport == "rtu" else 79, capacity, capacity + 1):
        byte_count = size - overhead - 6
        pdu = read_pdu(16, hr, 1) + bytes([byte_count]) + bytes([0xA5]) * byte_count
        results.run(f"malformed_fc16_adu_{size}_bytes", lambda pdu=pdu: invalid(pdu, 3, True),
                    request_adu_bytes=size, declared_quantity=1, declared_byte_count=byte_count,
                    larger_than_usb_packet=True, valid_map_payload=False)
    if args.transport == "rtu":
        def silent_write(kind):
            with RawRTU(args) as raw:
                before = raw_map(raw, profile, args)
                unit = (args.unit % 247) + 1 if kind == "wrong_unit" else args.unit
                frame = rtu_frame(unit, read_pdu(6, hr, 0xBEEF))
                if kind == "bad_crc":
                    frame = frame[:-1] + bytes([frame[-1] ^ 0x80])
                raw.silence(frame)
                equal(raw_map(raw, profile, args), before, "silent write must not mutate")
        for kind in ("wrong_unit", "bad_crc"):
            results.run(f"rtu_{kind}_silent_and_unchanged", lambda kind=kind: silent_write(kind))

        def broadcast():
            with RawRTU(args) as raw:
                raw.silence(rtu_frame(0, read_pdu(6, hr, 0xBEEF)))
                equal(raw.request(read_pdu(3, hr, 1)), read_reply(3, [0xBEEF]), "broadcast readback")
                before = raw.request(read_pdu(1, co, 1))
                require(before in (read_reply(1, [False]), read_reply(1, [True])), "initial broadcast coil read")
                desired = not bool(before[2] & 1)
                raw.silence(rtu_frame(0, read_pdu(5, co, 0xFF00 if desired else 0)))
                equal(raw.request(read_pdu(1, co, 1)), read_reply(1, [desired]), "broadcast coil readback")
                return {"fc6_value": 0xBEEF, "fc5_value": desired}
        results.run("rtu_broadcast_fc6_fc5_silent_then_readback", broadcast)


def tcp_stream_tests(args, results):
    start, _ = Profile(args.profile).region(3)
    pdu = read_pdu(3, start, 1)
    with RawTCP(args) as raw:
        expected = raw.request(pdu)
        require(expected is not None and len(expected) == 4 and expected[:2] == b"\x03\x02", "FC3 baseline response")
    for split in range(1, 12):
        def fragmented(split=split):
            with RawTCP(args) as raw:
                frame = tcp_frame(args.unit, pdu, 100 + split)
                raw.sock.sendall(frame[:split])
                raw.sock.settimeout(args.fragment_timeout)
                try:
                    data = raw.sock.recv(1)
                except socket.timeout:
                    data = None
                require(data is None, f"premature reply/close for incomplete ADU: {data!r}")
                raw.sock.settimeout(args.timeout)
                raw.sock.sendall(frame[split:])
                equal(raw.receive(100 + split), expected, "split FC3 response")
        results.run(f"tcp_split_fc3_at_{split}", fragmented, request_adu_bytes=12)

    for count in (2, 6):
        def coalesced(count=count):
            with RawTCP(args) as raw:
                raw.sock.sendall(b"".join(tcp_frame(args.unit, pdu, 200 + i) for i in range(count)))
                for i in range(count):
                    equal(raw.receive(200 + i), expected, "coalesced FC3 response")
        results.run(f"tcp_coalesced_{count}_fc3_adus", coalesced, aggregate_bytes=12 * count,
                    individual_adu_bytes=12)

    for protocol, length in ((1, 6), (256, 6), (0, 0), (0, 1), (0, adu_capacity(args) - 5)):
        def rejected(protocol=protocol, length=length):
            with RawTCP(args) as raw:
                raw.rejection(tcp_frame(args.unit, pdu, 300, protocol, length))
            with RawTCP(args) as raw:
                equal(raw.request(pdu), expected, "recovery after invalid MBAP")
        results.run(f"tcp_mbap_protocol_{protocol}_length_{length}_rejected", rejected)

    def connection_pool():
        with ExitStack() as stack:
            clients = [stack.enter_context(RawTCP(args)) for _ in range(4)]
            tids = [client.send(pdu) for client in clients]
            for client, tid in zip(clients, tids):
                equal(client.receive(tid), expected, "four concurrent clients")
            fifth_outcome = ""
            try:
                with RawTCP(args) as fifth:
                    fifth.send(pdu)
                    try:
                        data = fifth.sock.recv(1)
                        require(not data, "fifth client received data despite four live slots")
                        fifth_outcome = "closed"
                    except (socket.timeout, ConnectionResetError):
                        fifth_outcome = "silent_or_reset"
            except (ConnectionRefusedError, ConnectionResetError, socket.timeout):
                fifth_outcome = "refused_reset_or_timeout"
            for client in clients:
                equal(client.request(pdu), expected, "original client survives fifth connection")
        with RawTCP(args) as replacement:
            equal(replacement.request(pdu), expected, "slot reuse after clients close")
        return {"simultaneous_clients": 4, "fifth": fifth_outcome}
    results.run("tcp_four_clients_fifth_rejected_and_slot_reused", connection_pool)


class ObservedCoilRequest(WriteSingleCoilRequest):
    """Keep FC5's wire value: PyModbus otherwise normalizes any nonzero to True."""

    def decode(self, data):
        super().decode(data)
        self.wire_value = int.from_bytes(data[2:4], "big")


class DemoObserver:
    """Check actual decoded requests and outgoing PyModbus response PDUs."""

    def __init__(self, args, results):
        self.args, self.results = args, results
        self.bank = Bank(Profile(args.profile))
        self.requests, self.responses = Counter(), Counter()
        self.pending = deque()
        self.errors = []
        self.previous = None
        self.done = asyncio.Event()

    def trace(self, sending, pdu):
        try:
            wire = bytes([pdu.function_code]) + pdu.encode()
            if sending:
                require(bool(self.pending), "unsolicited response")
                unit, tid, fc, expected, started = self.pending.popleft()
                equal(pdu.dev_id, unit, "server response unit")
                equal(pdu.transaction_id, tid, "server response transaction")
                equal(wire, expected, f"server FC{fc} emitted response")
                self.responses[fc] += 1
                self.results.latencies.append((time.monotonic() - started) * 1000)
                if all(self.responses[fc] >= self.args.cycles for fc in FUNCTIONS):
                    self.done.set()
                return pdu
            fc = pdu.function_code
            self.requests[fc] += 1
            self.results.coverage[fc] += 1
            equal(pdu.dev_id, self.args.unit, "demo unit")
            require(fc in FUNCTIONS, f"unexpected demo FC{fc}")
            if self.previous is not None:
                equal(fc, DEMO_ORDER[(DEMO_ORDER.index(self.previous) + 1) % len(DEMO_ORDER)], "demo FC order")
            self.previous = fc
            address, _ = self.bank.profile.region(fc)
            equal(pdu.address, address, f"demo FC{fc} address")
            count = 1 if fc in (5, 6) else 4
            if fc in (1, 2, 3, 4):
                equal(pdu.count, count, "demo read quantity")
                expected = read_reply(fc, self.bank.read(fc, address, count))
            else:
                values = [True] if fc == 5 else [1] if fc == 6 else [True, False, False, False] if fc == 15 else DEMO_WORDS
                if fc == 5:
                    equal(pdu.wire_value, 0xFF00, "demo FC5 on-wire ON value")
                if fc in (5, 15):
                    equal(pdu.bits, values, f"demo FC{fc} packed bits")
                else:
                    equal(pdu.registers, values, f"demo FC{fc} words")
                if fc in (15, 16):
                    equal(pdu.count, count, "demo write quantity")
                self.bank.write(fc, address, values)
                expected = wire if fc in (5, 6) else read_pdu(fc, address, count)
            self.pending.append((pdu.dev_id, pdu.transaction_id, fc, expected, time.monotonic()))
        except Exception as exc:  # Do not let a trace-hook exception disappear inside the server task.
            if len(self.errors) < 32:
                self.errors.append(f"{type(exc).__name__}: {exc}")
            self.done.set()
        return pdu

    def finish(self):
        require(not self.errors, "; ".join(self.errors))
        require(not self.pending, f"{len(self.pending)} requests have no emitted response")
        for fc in FUNCTIONS:
            require(self.responses[fc] >= self.args.cycles,
                    f"FC{fc}: {self.responses[fc]}/{self.args.cycles} verified responses before deadline")
        return {"requests": {str(fc): self.requests[fc] for fc in FUNCTIONS},
                "verified_responses": {str(fc): self.responses[fc] for fc in FUNCTIONS},
                "board_consumption_verified": False}


def make_server(args, observer):
    kwargs = {"context": Profile(args.profile).simdevice(args.unit), "trace_pdu": observer.trace,
              "ignore_missing_devices": True, "custom_pdu": [ObservedCoilRequest]}
    if args.transport == "tcp":
        return ModbusTcpServer(address=(args.listen_host, args.listen_port), **kwargs)
    return ModbusSerialServer(port=args.serial_port, baudrate=args.baudrate, parity=args.parity,
                              stopbits=args.stopbits, timeout=args.timeout, **kwargs)


async def board_client(args, results):
    observer = DemoObserver(args, results)
    server = make_server(args, observer)
    try:
        await server.serve_forever(background=True)
        try:
            await asyncio.wait_for(observer.done.wait(), args.duration)
        except TimeoutError:
            pass  # finish() records the exact missing FC counts as a failure.
        results.run("board_client_demo_request_and_response_coverage", observer.finish,
                    requests={str(fc): observer.requests[fc] for fc in FUNCTIONS},
                    verified_responses={str(fc): observer.responses[fc] for fc in FUNCTIONS},
                    board_consumption_verified=False)
    finally:
        await server.shutdown()


def discover_serial(args, ports=None):
    if args.serial_port:
        require(not any((args.vid is not None, args.pid is not None, args.usb_serial, args.usb_location)),
                "choose explicit --serial-port OR identity discovery, not both")
        return args.serial_port
    require((args.vid is not None and args.pid is not None) or args.usb_serial or args.usb_location,
            "RTU requires --serial-port or USB identity (--vid and --pid, --usb-serial, or --usb-location)")
    require((args.vid is None) == (args.pid is None), "--vid and --pid must be supplied together")
    ports = list_ports.comports() if ports is None else ports
    matches = [p for p in ports if (args.vid is None or p.vid == args.vid)
               and (args.pid is None or p.pid == args.pid)
               and (not args.usb_serial or p.serial_number == args.usb_serial)
               and (not args.usb_location or p.location == args.usb_location)]
    require(len(matches) == 1, f"identity matched {len(matches)} serial ports; require exactly one native CDC interface")
    return matches[0].device


class JsonParser(argparse.ArgumentParser):
    def error(self, message):
        self.exit(2, json.dumps({"schema_version": 1, "success": False, "error": message}) + "\n")


def positive_number(text):
    value = float(text)
    if not 0 < value < float("inf"):
        raise argparse.ArgumentTypeError("must be positive and finite")
    return value


def positive_int(text):
    value = int(text)
    if value < 1:
        raise argparse.ArgumentTypeError("must be at least 1")
    return value


def parse_args(argv=None):
    parser = JsonParser(description=__doc__)
    parser.add_argument("role", choices=("board-server", "board-client"))
    parser.add_argument("--transport", required=True, choices=("rtu", "tcp"))
    parser.add_argument("--profile", required=True, choices=("shared", "separate", "large"))
    parser.add_argument("--buffer-size", required=True, type=int, choices=(128, 256),
                        help="nominal RTU ADU bytes; TCP capacity is this value + 4, PDU capacity is value - 3")
    parser.add_argument("--unit", type=int)
    parser.add_argument("--host", default="192.168.77.2")
    parser.add_argument("--port", type=int, default=502)
    parser.add_argument("--listen-host", default="192.168.77.1")
    parser.add_argument("--listen-port", type=int, default=1502)
    parser.add_argument("--serial-port")
    parser.add_argument("--vid", type=lambda s: int(s, 0))
    parser.add_argument("--pid", type=lambda s: int(s, 0))
    parser.add_argument("--usb-serial")
    parser.add_argument("--usb-location")
    parser.add_argument("--baudrate", type=positive_int, default=115200)
    parser.add_argument("--parity", choices=("N", "E", "O"), default="N")
    parser.add_argument("--stopbits", type=int, choices=(1, 2), default=1)
    parser.add_argument("--timeout", type=positive_number, default=1.5)
    parser.add_argument("--fragment-timeout", type=positive_number, default=0.03)
    parser.add_argument("--duration", type=positive_number, default=60)
    parser.add_argument("--iterations", type=positive_int, default=1,
                        help="board-server deterministic positive-test repeats (40 exceeds 1000 transactions)")
    parser.add_argument("--cycles", type=positive_int, default=1,
                        help="board-client minimum verified responses for each FC (125 = 1000 total)")
    parser.add_argument("--json", dest="json_path", help="also save result JSON to this file")
    args = parser.parse_args(argv)
    if args.unit is None:
        args.unit = 10 if args.transport == "rtu" else 1
    if not 1 <= args.unit <= 247:
        parser.error("--unit must be 1..247; broadcast tests explicitly use zero")
    if not 1 <= args.port <= 65535 or not 1 <= args.listen_port <= 65535:
        parser.error("TCP ports must be 1..65535")
    if args.role == "board-client" and args.transport == "tcp" and args.listen_port < 1024:
        parser.error("PC listener must use an unprivileged port >=1024")
    if args.fragment_timeout >= args.timeout:
        parser.error("--fragment-timeout must be less than --timeout")
    return args


def main(argv=None):
    args = parse_args(argv)
    logging.basicConfig(level=logging.WARNING, stream=sys.stderr)
    results = Results(args)
    try:
        require(pymodbus.__version__ == "3.16.1" and serial.__version__ == "3.5",
                "use the pinned requirements-test.txt versions; other APIs are unverified")
        if args.transport == "rtu":
            args.serial_port = discover_serial(args)
        if args.role == "board-client":
            asyncio.run(board_client(args, results))
        else:
            positive_tests(args, results)
            negative_tests(args, results)
            if args.transport == "tcp":
                tcp_stream_tests(args, results)
    except KeyboardInterrupt:
        results.cases.append({"name": "interrupted", "status": "fail", "error": "user interrupted"})
    except Exception as exc:  # CLI boundary: setup/transport failures must still produce JSON and exit nonzero.
        results.cases.append({"name": "setup_or_transport", "status": "fail", "error": f"{type(exc).__name__}: {exc}"})
    document = results.document()
    if args.json_path:
        try:
            with open(args.json_path, "w", encoding="utf-8") as output:
                json.dump(document, output, indent=2, sort_keys=True)
                output.write("\n")
        except OSError as exc:
            document["success"] = False
            document["output_error"] = str(exc)
    print(json.dumps(document, indent=2, sort_keys=True))
    return 0 if document["success"] else 1


if __name__ == "__main__":
    sys.exit(main())
