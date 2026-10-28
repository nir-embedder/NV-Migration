"""Local stream fixtures exercise both transports without touching hardware."""
from contextlib import ExitStack, contextmanager
import os
import pty
import selectors
import socket
import struct
import threading
import tty

import pytest
from pymodbus.client import ModbusSerialClient

from test_modbus_verify import arguments, demo_cycle, failures, pymodbus_peer, v


@contextmanager
def virtual_serial_wire():
    """Two host PTYs forwarded by an event-driven byte bridge, not USB/UART."""
    pairs = [pty.openpty(), pty.openpty()]
    stop_read, stop_write = socket.socketpair()
    errors = []
    for _, slave in pairs:
        tty.setraw(slave)

    def forward():
        try:
            with selectors.DefaultSelector() as selector:
                selector.register(stop_read, selectors.EVENT_READ, None)
                selector.register(pairs[0][0], selectors.EVENT_READ, pairs[1][0])
                selector.register(pairs[1][0], selectors.EVENT_READ, pairs[0][0])
                while True:
                    for key, _ in selector.select():
                        if key.data is None:
                            return
                        data = os.read(key.fd, 4096)
                        while data:
                            data = data[os.write(key.data, data):]
        except BaseException as exc:
            errors.append(exc)

    thread = threading.Thread(target=forward, daemon=True)
    thread.start()
    try:
        yield [os.ttyname(slave) for _, slave in pairs]
    finally:
        stop_write.sendall(b"x")
        thread.join(3)
        assert not thread.is_alive()
        for pair in pairs:
            for fd in pair:
                os.close(fd)
        stop_read.close()
        stop_write.close()
        assert not errors


@pytest.mark.parametrize("profile", ["shared", "separate", "large"])
@pytest.mark.parametrize("buffer", [128, 256])
def test_actual_pymodbus_rtu_positive_suite_over_virtual_wire(profile, buffer):
    args = arguments(profile, transport="rtu", buffer=buffer)
    args.timeout = 1
    results = v.Results(args)
    with virtual_serial_wire() as (server_port, client_port):
        args.serial_port = server_port
        with pymodbus_peer(args):
            args.serial_port = client_port
            v.positive_tests(args, results)
    assert failures(results) == []
    assert all(results.coverage[fc] for fc in v.FUNCTIONS)


@pytest.mark.parametrize("profile", ["shared", "separate", "large"])
def test_actual_pymodbus_rtu_demo_observer_over_virtual_wire(profile):
    args = arguments(profile, transport="rtu", role="board-client")
    results = v.Results(args)
    observer = v.DemoObserver(args, results)
    with virtual_serial_wire() as (server_port, client_port):
        args.serial_port = server_port
        with pymodbus_peer(args, observer):
            with ModbusSerialClient(client_port, baudrate=args.baudrate, timeout=1, retries=0) as client:
                demo_cycle(client, args)
    assert not observer.finish()["board_consumption_verified"]
    assert observer.done.is_set()


@pytest.mark.parametrize("transport,buffer,limits", [
    ("rtu", 128, {1: 984, 2: 984, 3: 61, 4: 61, 15: 952, 16: 59}),
    ("tcp", 128, {1: 984, 2: 984, 3: 61, 4: 61, 15: 952, 16: 59}),
    ("rtu", 256, {1: 2000, 2: 2000, 3: 125, 4: 125, 15: 1968, 16: 123}),
    ("tcp", 256, {1: 2000, 2: 2000, 3: 125, 4: 125, 15: 1968, 16: 123}),
])
def test_large_profile_real_wire_sizes_and_boundaries(transport, buffer, limits):
    args = arguments("large", transport=transport, buffer=buffer)
    args.timeout = 1
    results = v.Results(args)
    frames = []

    class ObserveSizes:
        def trace(self, sending, pdu):
            quantity = len(pdu.bits) if pdu.function_code == 15 else pdu.count
            size = 1 + len(pdu.encode()) + (3 if transport == "rtu" else 7)
            frames.append((sending, pdu.function_code, quantity, size))
            return pdu

    with ExitStack() as stack:
        if transport == "rtu":
            server_port, client_port = stack.enter_context(virtual_serial_wire())
            args.serial_port = server_port
        stack.enter_context(pymodbus_peer(args, ObserveSizes()))
        if transport == "rtu":
            args.serial_port = client_port
        v.positive_tests(args, results)
    assert failures(results) == []
    capacity = buffer + (4 if transport == "tcp" else 0)
    assert v.adu_capacity(args) == capacity
    assert all(size <= capacity for _, _, _, size in frames)
    assert results.document()["buffer_size"] == buffer
    assert results.document()["adu_capacity"] == capacity
    assert results.document()["pdu_capacity"] == buffer - 3
    cases = {case["name"]: case for case in results.cases}
    crossing = cases["valid_single_adu_over_64_bytes"]
    assert crossing["status"] == "pass"
    assert crossing["details"]["quantity"] == 32
    assert crossing["details"]["request_adu_bytes"] == (73 if transport == "rtu" else 77)
    assert any(not sending and fc == 16 and quantity == 32 and size > 64
               for sending, fc, quantity, size in frames)
    for fc, limit in limits.items():
        assert v.transfer_limit(fc, args) == limit
        requests = [quantity for sending, function, quantity, _ in frames if not sending and function == fc]
        assert max(requests) == limit
        boundary = cases[f"large_fc{fc}_capacity_boundary"]
        assert boundary["status"] == "pass"
        assert boundary["details"]["quantity"] == limit
        assert max(boundary["details"][key] for key in ("request_adu_bytes", "response_adu_bytes")) > 64
        size = 2048 if fc in (1, 2, 15) else 128
        assert boundary["details"]["address"] + limit == size


@contextmanager
def bounded_tcp_peer(args, capacity=4):
    """Independent minimal FC3 peer: stream parsing and bounded connection slots."""
    ready = threading.Event()
    stop_read, stop_write = socket.socketpair()
    state = {}

    def run():
        clients = {}
        try:
            with socket.socket() as listener, selectors.DefaultSelector() as selector:
                listener.bind(("127.0.0.1", 0))
                listener.listen(8)
                state["port"] = listener.getsockname()[1]
                selector.register(listener, selectors.EVENT_READ, "listener")
                selector.register(stop_read, selectors.EVENT_READ, "stop")
                ready.set()

                def close(conn):
                    selector.unregister(conn)
                    clients.pop(conn)
                    conn.close()

                while True:
                    for key, _ in selector.select():
                        if key.data == "stop":
                            return
                        if key.data == "listener":
                            conn, _ = listener.accept()
                            if len(clients) >= capacity:
                                conn.close()
                            else:
                                conn.settimeout(0.3)
                                clients[conn] = bytearray()
                                selector.register(conn, selectors.EVENT_READ, "client")
                            continue
                        conn = key.fileobj
                        try:
                            incoming = conn.recv(4096)
                        except ConnectionResetError:
                            incoming = b""
                        if not incoming:
                            close(conn)
                            continue
                        data = clients[conn]
                        data.extend(incoming)
                        while len(data) >= 7:
                            tid, pid, length, unit = struct.unpack(">HHHB", data[:7])
                            if pid or not 2 <= length <= args.buffer_size - 2:
                                close(conn)
                                break
                            if len(data) < length + 6:
                                break
                            pdu = bytes(data[7:length + 6])
                            del data[:length + 6]
                            if len(pdu) == 5 and pdu[0] == 3:
                                response = b"\x03\x02\x00\x00"
                            else:
                                response = bytes([pdu[0] | 0x80, 1])
                            conn.sendall(struct.pack(">HHHB", tid, 0, len(response) + 1, unit) + response)
        except BaseException as exc:
            state["error"] = exc
            ready.set()
        finally:
            for conn in clients:
                conn.close()

    thread = threading.Thread(target=run, daemon=True)
    thread.start()
    assert ready.wait(2)
    if "error" in state:
        raise state["error"]
    args.port = state["port"]
    try:
        yield
    finally:
        stop_write.sendall(b"x")
        thread.join(3)
        assert not thread.is_alive()
        stop_read.close()
        stop_write.close()
        if "error" in state:
            raise state["error"]


@pytest.mark.parametrize("buffer", [128, 256])
def test_complete_tcp_stream_suite_with_bounded_loopback_peer(buffer):
    args = arguments(buffer=buffer)
    results = v.Results(args)
    with bounded_tcp_peer(args):
        v.tcp_stream_tests(args, results)
    assert failures(results) == []
    assert len(results.cases) == 19
    assert any(case["name"] == f"tcp_mbap_protocol_0_length_{buffer - 1}_rejected"
               for case in results.cases)


def test_stream_suite_detects_fifth_client_not_rejected():
    args = arguments()
    results = v.Results(args)
    with bounded_tcp_peer(args, capacity=5):
        v.tcp_stream_tests(args, results)
    bad = failures(results)
    assert len(bad) == 1
    assert bad[0]["name"] == "tcp_four_clients_fifth_rejected_and_slot_reused"
    assert "fifth client received data" in bad[0]["error"]


@pytest.mark.parametrize("profile", ["shared", "separate"])
@pytest.mark.parametrize("ignore_coil_write", [False, True])
def test_rtu_broadcast_fc5_requires_a_real_value_change(monkeypatch, profile, ignore_coil_write):
    args = arguments(profile, transport="rtu")

    class OnlyBroadcast(v.Results):
        def run(self, name, action, **details):
            if name == "rtu_broadcast_fc6_fc5_silent_then_readback":
                return super().run(name, action, **details)

    class BroadcastPeer:
        def __init__(self, args):
            self.word, self.coil = 0, False

        def __enter__(self):
            return self

        def __exit__(self, *_):
            pass

        def request(self, pdu):
            fc, _, _ = struct.unpack(">BHH", pdu)
            value = bool(self.word & 1) if profile == "shared" else self.coil
            return v.read_reply(fc, [self.word] if fc == 3 else [value])

        def silence(self, frame):
            assert len(frame) == 8 and frame[0] == 0
            assert v.crc16(frame[:-2]) == int.from_bytes(frame[-2:], "little")
            fc, _, value = struct.unpack(">BHH", frame[1:-2])
            if fc == 6:
                self.word = value
            elif not ignore_coil_write:
                if profile == "shared":
                    self.word = (self.word & ~1) | bool(value)
                else:
                    self.coil = bool(value)

    monkeypatch.setattr(v, "RawRTU", BroadcastPeer)
    results = OnlyBroadcast(args)
    v.negative_tests(args, results)
    assert len(results.cases) == 1
    assert results.document()["success"] is not ignore_coil_write


@pytest.mark.parametrize("profile", ["shared", "separate"])
def test_documented_thousand_transaction_setting(profile):
    args = arguments(profile)
    args.iterations = 40
    results = v.Results(args)
    with pymodbus_peer(args):
        v.positive_tests(args, results)
    assert failures(results) == []
    assert results.document()["transactions"] == (1137 if profile == "shared" else 1132)


@pytest.mark.parametrize("mutate", [False, True])
@pytest.mark.parametrize("profile", ["shared", "large"])
def test_malformed_write_checks_detect_mutation(monkeypatch, mutate, profile):
    args = arguments(profile, buffer=256 if profile == "large" else 128)
    results = v.Results(args)
    words = [0] * (128 if profile == "large" else 16)

    class FakeRaw:
        def __enter__(self):
            return self

        def __exit__(self, *_):
            pass

        def request(self, pdu):
            fc, address, count = struct.unpack(">BHH", pdu[:5])
            if fc in (1, 2, 3, 4):
                limit = len(words) * 16 if fc < 3 else len(words)
                if address + count > limit:
                    return bytes([fc | 128, 2])
                if not count:
                    return bytes([fc | 128, 3])
                if fc < 3:
                    values = [bool(words[i // 16] & (1 << (i % 16))) for i in range(address, address + count)]
                else:
                    values = words[address:address + count]
                return v.read_reply(fc, values)
            if fc == 0x45:
                return b"\xc5\x01"
            if fc in (5, 6):
                return bytes([fc | 128, 2 if address >= (len(words) * 16 if fc == 5 else len(words)) else 3])
            if fc in (15, 16):
                expected = (count + 7) // 8 if fc == 15 else count * 2
                if pdu[5] != expected:
                    if mutate:
                        words[-1] ^= 1
                    return bytes([fc | 128, 3])
                return bytes([fc | 128, 2])
            raise AssertionError("unexpected request")

    monkeypatch.setattr(v, "raw_connection", lambda args: FakeRaw())
    v.negative_tests(args, results)
    boundary_cases = [case for case in results.cases if case["name"].startswith("malformed_fc16_adu_")]
    expected_sizes = [79, 260, 261] if profile == "large" else [79, 132, 133]
    assert [case["details"]["request_adu_bytes"] for case in boundary_cases] == expected_sizes
    assert [case["name"] for case in boundary_cases] == [
        f"malformed_fc16_adu_{size}_bytes" for size in expected_sizes]
    bad = failures(results)
    if mutate:
        assert len(bad) == 5  # FC15, FC16 count mismatch + all three large boundaries.
        assert all("must not mutate" in case["error"] for case in bad)
    else:
        assert bad == []
