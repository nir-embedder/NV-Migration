"""Host-only tests: fake serial and TCP loopback, never a board or USB device."""
import asyncio
from contextlib import contextmanager
import importlib.util
import json
from pathlib import Path
import socket
import subprocess
import sys
import threading
from types import SimpleNamespace

import pytest
from pymodbus.client import ModbusTcpClient
from pymodbus.server import ModbusSerialServer, ModbusTcpServer

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("modbus_verify", ROOT / "tools/modbus_verify.py")
v = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = v
SPEC.loader.exec_module(v)


def arguments(profile="shared", transport="tcp", role="board-server", buffer=128):
    return v.parse_args([role, "--transport", transport, "--profile", profile,
                         "--buffer-size", str(buffer), "--host", "127.0.0.1",
                         "--listen-host", "127.0.0.1", "--timeout", "0.3",
                         "--fragment-timeout", "0.005"])


@contextmanager
def pymodbus_peer(args, observer=None):
    """Use the pinned real server API on an ephemeral loopback port."""
    ready = threading.Event()
    state = {}

    async def run():
        state["loop"] = asyncio.get_running_loop()
        state["stop"] = asyncio.Event()
        kwargs = {"context": v.Profile(args.profile).simdevice(args.unit),
                  "trace_pdu": observer.trace if observer else None, "ignore_missing_devices": True,
                  "custom_pdu": [v.ObservedCoilRequest]}
        server = ModbusTcpServer(address=("127.0.0.1", 0), **kwargs) if args.transport == "tcp" else ModbusSerialServer(
            port=args.serial_port, baudrate=args.baudrate, timeout=args.timeout, **kwargs)
        try:
            await server.serve_forever(background=True)
            state["port"] = server.transport.sockets[0].getsockname()[1] if args.transport == "tcp" else None
            ready.set()
            await state["stop"].wait()
        finally:
            await server.shutdown()

    def worker():
        try:
            asyncio.run(run())
        except BaseException as exc:
            state["error"] = exc
            ready.set()

    thread = threading.Thread(target=worker, daemon=True)
    thread.start()
    assert ready.wait(3), "local server failed to start"
    if "error" in state:
        raise state["error"]
    if args.transport == "tcp":
        args.port = state["port"]
    try:
        yield
    finally:
        state["loop"].call_soon_threadsafe(state["stop"].set)
        thread.join(3)
        assert not thread.is_alive()
        if "error" in state:
            raise state["error"]


@contextmanager
def raw_peer(handler):
    ready = threading.Event()
    state = {}

    def run():
        try:
            with socket.socket() as listener:
                listener.bind(("127.0.0.1", 0))
                listener.listen(1)
                listener.settimeout(2)
                state["port"] = listener.getsockname()[1]
                ready.set()
                conn, _ = listener.accept()
                with conn:
                    conn.settimeout(1)
                    handler(conn)
        except BaseException as exc:
            state["error"] = exc
            ready.set()

    thread = threading.Thread(target=run, daemon=True)
    thread.start()
    assert ready.wait(2)
    if "error" in state:
        raise state["error"]
    args = arguments()
    args.port = state["port"]
    try:
        yield args
    finally:
        thread.join(3)
        assert not thread.is_alive()
        if "error" in state:
            raise state["error"]


class FakeSerial:
    def __init__(self, incoming=b"", chunk=999):
        self.incoming = bytearray(incoming)
        self.writes = []
        self.chunk = chunk
        self.timeout = 0.1
        self.closed = False

    def write(self, data):
        self.writes.append(data)
        return len(data)

    def flush(self):
        pass

    def close(self):
        self.closed = True

    def read(self, count):
        count = min(count, self.chunk)
        result = bytes(self.incoming[:count])
        del self.incoming[:count]
        return result


def failures(results):
    return [case for case in results.cases if case["status"] == "fail"]


@pytest.mark.parametrize("profile", ["shared", "separate", "large"])
@pytest.mark.parametrize("buffer", [128, 256])
def test_actual_pymodbus_positive_suite(profile, buffer):
    args = arguments(profile, buffer=buffer)
    results = v.Results(args)
    with pymodbus_peer(args):
        v.positive_tests(args, results)
    assert failures(results) == []
    assert all(results.coverage[fc] for fc in v.FUNCTIONS)
    document = results.document()
    assert document["success"]
    assert not document["acceptance_complete"]
    assert document["buffer_size"] == buffer
    assert document["adu_capacity"] == buffer + 4
    assert document["pdu_capacity"] == buffer - 3
    large = next(case for case in results.cases if case["name"] == "fc15_128_coils")
    assert large["status"] == ("skip" if profile == "separate" else "pass")
    if profile != "separate":
        assert large["details"]["request_adu_bytes"] == 29
        assert not large["details"]["larger_than_usb_packet"]


def test_shared_alias_oracle_and_zero_address():
    bank = v.Bank(v.Profile("shared"))
    assert bank.read(3, 0, 16) == [0] * 16
    bank.write(6, 0, [0x8001])
    assert bank.read(1, 0, 16) == [True] + [False] * 14 + [True]
    assert bank.read(2, 0, 16) == bank.read(1, 0, 16)
    bank.write(5, 16, [True])
    assert bank.read(4, 1, 1) == [1]
    bank.write(15, 15, [False, False, True])
    assert bank.read(3, 0, 2) == [1, 2]
    with pytest.raises(v.CheckFailure):
        bank.read(1, 255, 2)


def test_large_map_is_opt_in_and_preserves_tail_aliasing():
    profile = v.Profile("large")
    assert profile.region(1) == profile.region(2) == (0, 2048)
    assert profile.region(3) == profile.region(4) == (0, 128)
    assert v.Profile("shared").region(3) == (0, 16)
    assert v.Profile("separate").region(3) == (200, 4)
    bank = v.Bank(profile)
    bank.write(6, 127, [0x8001])
    assert bank.read(1, 2032, 16) == [True] + [False] * 14 + [True]
    bank.write(5, 2047, [False])
    assert bank.read(4, 127, 1) == [1]
    with pytest.raises(v.CheckFailure):
        bank.read(3, 128, 1)


@pytest.mark.parametrize("buffer,fc,count,adu_size", [
    (128, 1, 984, 132), (128, 2, 984, 132), (128, 3, 61, 131),
    (128, 4, 61, 131), (128, 15, 952, 132), (128, 16, 59, 131),
    (256, 1, 2000, 259), (256, 2, 2000, 259), (256, 3, 125, 259),
    (256, 4, 125, 259), (256, 15, 1968, 259), (256, 16, 123, 259),
])
def test_tcp_nominal_buffer_preserves_pdu_capacity(buffer, fc, count, adu_size):
    args = arguments("large", buffer=buffer)
    assert v.adu_capacity(args) == buffer + 4
    assert v.transfer_limit(fc, args) == count

    def largest_frame(quantity):
        size = (quantity + 7) // 8 if fc in (1, 2, 15) else quantity * 2
        header = bytes([fc]) if fc <= 4 else v.read_pdu(fc, 0, quantity)
        return v.tcp_frame(args.unit, header + bytes([size]) + bytes(size))

    frame = largest_frame(count)
    assert len(frame) == adu_size <= buffer + 4
    assert len(frame[7:]) <= buffer - 3
    assert int.from_bytes(frame[4:6], "big") == len(frame) - 6 <= buffer - 2
    sizes = v.adu_sizes(fc, count, "tcp")
    assert sizes["response_adu_bytes" if fc <= 4 else "request_adu_bytes"] == len(frame)
    assert count + 1 <= (2048 if fc in (1, 2, 15) else 128)
    next_frame = largest_frame(count + 1)
    if buffer == 128:
        assert len(next_frame) == 133  # Capacity, not map size, bounds this profile.
    else:
        # Protocol quantity limits apply even if the next bit still fits in 260 bytes.
        assert count == {1: 2000, 2: 2000, 3: 125, 4: 125, 15: 1968, 16: 123}[fc]
        assert len(next_frame) == (260 if fc in (1, 2, 15) else 261)


def test_large_raw_snapshot_reads_all_chunks_including_last_word():
    args = arguments("large", buffer=256)
    with pymodbus_peer(args):
        with ModbusTcpClient(args.host, port=args.port, timeout=0.5, retries=0) as client:
            assert not client.write_register(127, 0x8001, device_id=args.unit).isError()
        with v.RawTCP(args) as raw:
            snapshot = v.raw_map(raw, v.Profile("large"), args)
    assert len(snapshot) == 8
    assert snapshot[1][-2:] == snapshot[3][-2:] == b"\x01\x80"
    assert snapshot[5][-2:] == snapshot[7][-2:] == b"\x80\x01"


def test_separate_oracle_does_not_alias():
    bank = v.Bank(v.Profile("separate"))
    bank.write(6, 200, [0xFFFF])
    bank.write(5, 0, [True])
    assert bank.read(4, 300, 4) == [0] * 4
    assert bank.read(2, 100, 32) == [False] * 32
    assert bank.read(1, 0, 2) == [True, False]
    with pytest.raises(v.CheckFailure):
        bank.read(3, 0, 1)


def test_rtu_golden_crc_binary_write_and_fragmented_response():
    # Modbus standard example: unit 1 read holding address 0, quantity 10.
    request = bytes.fromhex("01 03 00 00 00 0a c5 cd")
    assert v.rtu_frame(1, v.read_pdu(3, 0, 10)) == request
    args = arguments(transport="rtu")
    args.unit = 1
    serial = FakeSerial(bytes.fromhex("01 03 02 12 34 b5 33"), chunk=1)
    with v.RawRTU(args, port=serial) as raw:
        assert raw.request(v.read_pdu(3, 0, 10)) == bytes.fromhex("03 02 12 34")
    assert serial.writes == [request]
    assert not serial.writes[0].endswith(b"\n")
    assert serial.closed


@pytest.mark.parametrize("reply", [b"\x01\x03", bytes.fromhex("01 03 02 12 34 b5 32")])
def test_rtu_partial_and_corrupt_responses_are_not_success(reply):
    args = arguments(transport="rtu")
    with v.RawRTU(args, port=FakeSerial(reply)) as raw:
        with pytest.raises((TimeoutError, v.CheckFailure)):
            raw.request(v.read_pdu(3, 0, 1), unit=1)


def test_rtu_silence_rejects_any_reply_byte():
    args = arguments(transport="rtu")
    with v.RawRTU(args, port=FakeSerial(b"\x00")) as raw:
        with pytest.raises(v.CheckFailure, match="silence"):
            raw.silence(v.rtu_frame(0, v.read_pdu(6, 0, 1)))
    with v.RawRTU(args, port=FakeSerial()) as raw:
        assert raw.request(v.read_pdu(3, 0, 1)) is None
        raw.silence(v.rtu_frame(0, v.read_pdu(6, 0, 1)))


def test_tcp_framing_split_and_coalesced_response():
    def handler(conn):
        request = v.recv_exact(conn, 24)
        assert request[:7] == bytes.fromhex("00010000000601")
        replies = v.tcp_frame(1, bytes.fromhex("03 02 12 34"), 1) + v.tcp_frame(1, bytes.fromhex("03 02 ab cd"), 2)
        conn.sendall(replies[:3])
        conn.sendall(replies[3:])

    with raw_peer(handler) as args, v.RawTCP(args) as raw:
        first = raw.send(v.read_pdu(3, 0, 1))
        second = raw.send(v.read_pdu(3, 0, 1))
        assert raw.receive(first) == bytes.fromhex("03 02 12 34")
        assert raw.receive(second) == bytes.fromhex("03 02 ab cd")


@pytest.mark.parametrize("tid,protocol,unit,length", [(2, 0, 1, 5), (1, 1, 1, 5), (1, 0, 10, 5), (1, 0, 1, 255), (1, 0, 1, 1)])
def test_tcp_rejects_bad_response_header(tid, protocol, unit, length):
    def handler(conn):
        v.recv_exact(conn, 12)
        conn.sendall(v.tcp_frame(unit, b"\x03\x02\x00\x00", tid, protocol, length))

    with raw_peer(handler) as args, v.RawTCP(args) as raw:
        with pytest.raises(v.CheckFailure):
            raw.request(v.read_pdu(3, 0, 1))


@pytest.mark.parametrize("buffer,count", [(128, 61), (256, 125)])
@pytest.mark.parametrize("oversized", [False, True])
def test_raw_tcp_response_respects_nominal_buffer(buffer, count, oversized):
    response = v.read_reply(3, [0xA55A] * count)

    def handler(conn):
        v.recv_exact(conn, 12)
        if oversized:
            # MBAP Length includes unit ID, so nominal - 1 means capacity + 1.
            conn.sendall(v.tcp_frame(1, b"", length=buffer - 1))
        else:
            conn.sendall(v.tcp_frame(1, response))

    with raw_peer(handler) as args:
        args.buffer_size = buffer
        with v.RawTCP(args) as raw:
            if oversized:
                with pytest.raises(v.CheckFailure, match="invalid MBAP length"):
                    raw.request(v.read_pdu(3, 0, count))
            else:
                assert raw.request(v.read_pdu(3, 0, count)) == response


@pytest.mark.parametrize("buffer,count", [(128, 61), (256, 125)])
@pytest.mark.parametrize("oversized", [False, True])
def test_raw_rtu_response_respects_nominal_buffer(buffer, count, oversized):
    args = arguments(transport="rtu", buffer=buffer)
    response = v.read_reply(3, [0xA55A] * (count + int(oversized)))
    with v.RawRTU(args, port=FakeSerial(v.rtu_frame(args.unit, response))) as raw:
        if oversized:
            with pytest.raises(v.CheckFailure, match="oversize RTU byte count"):
                raw.request(v.read_pdu(3, 0, count + 1))
        else:
            assert raw.request(v.read_pdu(3, 0, count)) == response


def test_tcp_truncated_response_is_failure():
    def handler(conn):
        v.recv_exact(conn, 12)
        conn.sendall(v.tcp_frame(1, b"\x03\x02\x00\x00")[:-1])

    with raw_peer(handler) as args, v.RawTCP(args) as raw:
        with pytest.raises(v.CheckFailure, match="partial MBAP response body"):
            raw.request(v.read_pdu(3, 0, 1))


class BrokenClient:
    def connect(self):
        return True

    def close(self):
        pass

    def write_registers(self, address, values, **kwargs):
        return SimpleNamespace(isError=lambda: False, function_code=16, dev_id=kwargs["device_id"],
                               address=address, count=len(values) + 1)

    def read_holding_registers(self, address, count, **kwargs):
        return SimpleNamespace(isError=lambda: False, function_code=3, dev_id=kwargs["device_id"],
                               registers=[123] * count)


def test_master_detects_wrong_echo_and_wrong_read_data():
    args = arguments()
    results = v.Results(args)
    master = v.Master(BrokenClient(), args, results, v.Bank(v.Profile("shared")))
    assert not results.run("bad_echo", lambda: master.write(16, 0, [1, 2]))
    assert not results.run("bad_read", lambda: master.read(3, 0, 1))
    document = results.document()
    assert not document["success"]
    assert document["counts"]["fail"] == 2
    assert json.loads(json.dumps(document))["cases"][0]["name"] == "bad_echo"


def demo_cycle(client, args, wrong_fc=None):
    # Independent approved-demo vectors, not the observer's own constants/map.
    addresses = {2: 100, 3: 200, 4: 300, 6: 200, 16: 200} if args.profile == "separate" else {}
    for fc in (5, 1, 15, 2, 6, 3, 16, 4):
        address = addresses.get(fc, 0)
        method = getattr(client, v.METHODS[fc])
        if fc in (1, 2, 3, 4):
            response = method(address, count=4, device_id=args.unit)
        else:
            values = {5: True, 6: 1, 15: [True, False, False, False],
                      16: [1, 0x1234, 0x5678, 0xABCD]}[fc]
            if fc == wrong_fc:
                values = 2
            response = method(address, values, device_id=args.unit)
        assert not response.isError()


@pytest.mark.parametrize("profile", ["shared", "separate", "large"])
@pytest.mark.parametrize("transport,unit", [("rtu", 10), ("tcp", 1)])
def test_approved_client_demo_defaults(profile, transport, unit):
    args = v.parse_args(["board-client", "--transport", transport, "--profile", profile,
                         "--buffer-size", "256" if profile == "large" else "128"])
    assert args.unit == unit
    assert (args.listen_host, args.listen_port) == ("192.168.77.1", 1502)
    assert v.DEMO_ORDER == (5, 1, 15, 2, 6, 3, 16, 4)
    assert v.DEMO_WORDS == [1, 0x1234, 0x5678, 0xABCD]
    expected = {2: 100, 3: 200, 4: 300, 6: 200, 16: 200} if profile == "separate" else {}
    for fc in (5, 1, 15, 2, 6, 3, 16, 4):
        assert v.Profile(profile).region(fc)[0] == expected.get(fc, 0)


@pytest.mark.parametrize("profile", ["shared", "separate", "large"])
def test_real_server_observer_verifies_demo_request_and_response(profile):
    args = arguments(profile, role="board-client")
    args.cycles = 2
    results = v.Results(args)
    observer = v.DemoObserver(args, results)
    with pymodbus_peer(args, observer):
        with ModbusTcpClient(args.host, port=args.port, timeout=0.5, retries=0) as client:
            demo_cycle(client, args)
            demo_cycle(client, args)
    detail = observer.finish()
    assert all(count == 2 for count in detail["requests"].values())
    assert all(count == 2 for count in detail["verified_responses"].values())
    assert observer.done.is_set()
    assert not detail["board_consumption_verified"]


def test_demo_observer_detects_wrong_write_payload():
    args = arguments(role="board-client")
    results = v.Results(args)
    observer = v.DemoObserver(args, results)
    with pymodbus_peer(args, observer):
        with ModbusTcpClient(args.host, port=args.port, timeout=0.5, retries=0) as client:
            demo_cycle(client, args, wrong_fc=6)
    assert observer.done.is_set()
    with pytest.raises(v.CheckFailure, match="demo FC6 words"):
        observer.finish()


def test_demo_observer_rejects_noncanonical_fc5_wire_value():
    args = arguments(role="board-client")
    results = v.Results(args)
    observer = v.DemoObserver(args, results)
    with pymodbus_peer(args, observer):
        with v.RawTCP(args) as raw:
            raw.request(v.read_pdu(5, 0, 1))
    with pytest.raises(v.CheckFailure, match="FC5 on-wire ON value"):
        observer.finish()


def test_board_client_success_lifecycle_uses_real_server(monkeypatch):
    args = arguments(role="board-client")
    args.listen_port = 0
    results = v.Results(args)
    original_factory = v.make_server

    async def scenario():
        started = asyncio.Event()

        def factory(args, observer):
            server = original_factory(args, observer)
            original_serve = server.serve_forever

            async def serve(**kwargs):
                await original_serve(**kwargs)
                args.port = server.transport.sockets[0].getsockname()[1]
                started.set()
            server.serve_forever = serve
            return server

        monkeypatch.setattr(v, "make_server", factory)
        task = asyncio.create_task(v.board_client(args, results))
        try:
            await asyncio.wait_for(started.wait(), 1)

            def emit():
                with ModbusTcpClient(args.host, port=args.port, timeout=0.5, retries=0) as client:
                    demo_cycle(client, args)
            await asyncio.to_thread(emit)
            await asyncio.wait_for(task, 1)
        finally:
            if not task.done():
                task.cancel()
                with pytest.raises(asyncio.CancelledError):
                    await task

    asyncio.run(scenario())
    document = results.document()
    assert document["success"]
    assert document["transactions"] == 8
    assert all(count == 1 for count in document["cases"][0]["details"]["verified_responses"].values())


def test_demo_observer_detects_missing_fc_coverage():
    args = arguments(role="board-client")
    results = v.Results(args)
    observer = v.DemoObserver(args, results)
    with pytest.raises(v.CheckFailure, match="verified responses before deadline"):
        observer.finish()


def test_board_client_no_traffic_deadline_fails_and_closes():
    args = arguments(role="board-client")
    args.listen_port = 0
    args.duration = 0.01
    results = v.Results(args)
    asyncio.run(v.board_client(args, results))
    assert not results.document()["success"]
    assert "FC1: 0/1" in failures(results)[0]["error"]


def test_serial_identity_is_explicit_and_unambiguous():
    args = arguments(transport="rtu")
    ports = [SimpleNamespace(device="/fake/native", vid=0x1234, pid=0xABCD,
                             serial_number="example", location="1-2")]
    with pytest.raises(v.CheckFailure, match="requires"):
        v.discover_serial(args, ports)
    args.usb_serial = "example"
    assert v.discover_serial(args, ports) == "/fake/native"
    with pytest.raises(v.CheckFailure, match="2 serial ports"):
        v.discover_serial(args, ports * 2)
    args.serial_port = "/explicit/device"
    with pytest.raises(v.CheckFailure, match="not both"):
        v.discover_serial(args, ports)
    args.usb_serial = None
    assert v.discover_serial(args, ports) == "/explicit/device"


def test_cli_defaults_and_required_profile_and_buffer(capsys):
    args = v.parse_args(["board-server", "--transport", "tcp", "--profile", "shared", "--buffer-size", "128"])
    assert (args.host, args.port, args.unit) == ("192.168.77.2", 502, 1)
    assert (args.listen_host, args.listen_port) == ("192.168.77.1", 1502)
    assert arguments(transport="rtu").unit == 10
    with pytest.raises(SystemExit) as exc:
        v.parse_args(["board-server", "--transport", "tcp"])
    assert exc.value.code == 2
    assert json.loads(capsys.readouterr().err)["success"] is False


def test_cli_connection_failure_exit_json_and_file(tmp_path):
    # A bound, non-listening socket reserves an unavailable local endpoint.
    with socket.socket() as reserved:
        reserved.bind(("127.0.0.1", 0))
        port = reserved.getsockname()[1]
        output = tmp_path / "result.json"
        process = subprocess.run([sys.executable, str(ROOT / "tools/modbus_verify.py"),
                                  "board-server", "--transport", "tcp", "--profile", "shared",
                                  "--buffer-size", "128", "--host", "127.0.0.1", "--port", str(port),
                                  "--timeout", "0.1", "--json", str(output)],
                                 capture_output=True, text=True, timeout=5)
    assert process.returncode == 1
    doc = json.loads(process.stdout)
    assert not doc["success"]
    assert doc == json.loads(output.read_text())
    assert doc["counts"]["fail"] >= 1
    assert doc["counts"]["manual_pending"] == 2


def test_cli_serial_missing_identity_never_opens_port(capsys, monkeypatch):
    def forbidden(*args, **kwargs):
        pytest.fail("serial must not be opened without identity")
    monkeypatch.setattr(v.serial, "Serial", forbidden)
    code = v.main(["board-server", "--transport", "rtu", "--profile", "separate", "--buffer-size", "256"])
    assert code == 1
    assert not json.loads(capsys.readouterr().out)["success"]


def test_json_output_write_failure_is_nonzero(capsys, monkeypatch, tmp_path):
    def positive(args, results):
        results.run("fake_only", lambda: None)
    monkeypatch.setattr(v, "positive_tests", positive)
    monkeypatch.setattr(v, "negative_tests", lambda *_: None)
    monkeypatch.setattr(v, "tcp_stream_tests", lambda *_: None)
    code = v.main(["board-server", "--transport", "tcp", "--profile", "shared", "--buffer-size", "128",
                   "--json", str(tmp_path)])
    assert code == 1
    doc = json.loads(capsys.readouterr().out)
    assert not doc["success"] and "output_error" in doc
