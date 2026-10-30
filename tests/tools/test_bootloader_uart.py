"""Offline UART contract: independent wire vectors and an already-open handle."""
import builtins
from collections import deque
import importlib.util
from pathlib import Path
import struct
import sys
import time

import pytest

ROOT = Path(__file__).resolve().parents[2]
PDID = 0x03302140
CONFIG_BASE = 0x0F300000
PROTOCOL_ERROR = (RuntimeError, ValueError, OSError, TypeError)
SYNC = b"a" * 62

# These literal vectors also appear in test_bootloader_protocol.py. No production
# encoder/decoder is used to generate expected traffic or synthetic responses.
CONNECT_PACKET = bytes.fromhex("a000b20012000000") + bytes(56)
CONFIG0_PACKET = bytes.fromhex("d2001801030000000000300f04000000") + bytes(48)
CONFIG8_NEXT_PACKET = bytes.fromhex("d2003a01050000002000300f04000000") + bytes(48)
IDENTITY_WORDS = (
    0x03302140, 0, 1, 0xFFFFFFFF, 0x10203040, 0x55667788, 0x89ABCDEF,
    0x13579BDF, 0x2468ACE0, 0x00080000, 0x00010000, 0xDEADBEEF, 0x13572468,
)
IDENTITY_REPORT = bytes.fromhex(
    "0042dead9d785634aabbccdd"
    "40213003 00000000 01000000 ffffffff 40302010 88776655 efcdab89"
    "df9b5713 e0ac6824 00000800 00000100 efbeadde 68245713"
)
CONFIG_REPORT = bytes.fromhex("00ffdead04000000aabbccdd78563412") + bytes(range(48))
NEXT_CONFIG_REPORT = bytes.fromhex("00ffbeef0600000011223344efcdab89") + bytes(48)
CONFIG_VECTORS = (
    (0, "d2001801030000000000300f04000000"),
    (1, "d2001c01030000000400300f04000000"),
    (2, "d2002001030000000800300f04000000"),
    (3, "d2002401030000000c00300f04000000"),
    (4, "d2002801030000001000300f04000000"),
    (5, "d2002c01030000001400300f04000000"),
    (6, "d2003001030000001800300f04000000"),
    (8, "d2003801030000002000300f04000000"),
    (9, "d2003c01030000002400300f04000000"),
    (10, "d2004001030000002800300f04000000"),
    (11, "d2004401030000002c00300f04000000"),
    (12, "d2004801030000003000300f04000000"),
    (13, "d2004c01030000003400300f04000000"),
    (14, "d2005001030000003800300f04000000"),
    (32, "d2009801030000008000300f04000000"),
    (33, "d2009c01030000008400300f04000000"),
    (34, "d200a001030000008800300f04000000"),
)


class Clock:
    def __init__(self):
        self.now = 100.0

    def __call__(self):
        return self.now


@pytest.fixture
def protocol(monkeypatch):
    original_import = builtins.__import__

    def offline_import(name, *args, **kwargs):
        if name.split(".")[0] in {"hid", "hidapi", "serial", "usb", "pyocd"}:
            pytest.fail(f"Protocol module attempted a hardware backend import: {name}")
        return original_import(name, *args, **kwargs)

    monkeypatch.setattr(builtins, "__import__", offline_import)
    spec = importlib.util.spec_from_file_location(
        "bootloader_uart_under_test", ROOT / "tools/bootloader_protocol.py"
    )
    module = importlib.util.module_from_spec(spec)
    monkeypatch.setitem(sys.modules, spec.name, module)
    spec.loader.exec_module(module)
    return module


@pytest.fixture
def clock(protocol, monkeypatch):
    clock = Clock()
    monkeypatch.setattr(time, "monotonic", clock)
    # Support either standard import spelling without coupling to private helpers.
    if hasattr(protocol, "monotonic"):
        monkeypatch.setattr(protocol, "monotonic", clock)
    return clock


class AlreadyOpenUart:
    """Only timeout properties and byte read/write exist; no port lifecycle API."""
    __slots__ = (
        "_timeout", "_write_timeout", "reads", "write_results", "events",
        "clock", "read_delays", "write_delays", "property_faults",
    )

    def __init__(self, clock, reads=(), *, timeout=7.5, write_timeout=None):
        self._timeout = timeout
        self._write_timeout = write_timeout
        self.reads = deque(reads)
        self.write_results = deque()
        self.events = []
        self.clock = clock
        self.read_delays = deque()
        self.write_delays = deque()
        self.property_faults = {}

    def _property_fault(self, operation, name):
        failure = self.property_faults.pop((operation, name), None)
        if failure is not None:
            raise failure

    @property
    def timeout(self):
        self._property_fault("get", "timeout")
        return self._timeout

    @timeout.setter
    def timeout(self, value):
        self._property_fault("set", "timeout")
        self._timeout = value

    @property
    def write_timeout(self):
        self._property_fault("get", "write_timeout")
        return self._write_timeout

    @write_timeout.setter
    def write_timeout(self, value):
        self._property_fault("set", "write_timeout")
        self._write_timeout = value

    def write(self, data):
        assert type(data) is bytes, "UART writes must use raw bytes"
        self.events.append(("write", data, self._write_timeout))
        assert isinstance(self._write_timeout, (int, float))
        assert 0 < self._write_timeout <= 1.0, "Unbounded UART write"
        if self.write_delays:
            self.clock.now += self.write_delays.popleft()
        result = self.write_results.popleft() if self.write_results else len(data)
        if isinstance(result, BaseException):
            raise result
        return result

    def read(self, size):
        self.events.append(("read", size, self._timeout))
        assert type(size) is int and size > 0
        assert isinstance(self._timeout, (int, float))
        assert 0 < self._timeout <= 5.0, "Unbounded UART read"
        assert self.reads, "Unexpected read or implicit retry"
        if self.read_delays:
            self.clock.now += self.read_delays.popleft()
        result = self.reads.popleft()
        if isinstance(result, BaseException):
            raise result
        return result

    def __getattr__(self, name):
        raise AssertionError(f"Forbidden UART lifecycle/control operation: {name}")


def invoke(session, stage):
    if stage == "sync":
        return session.synchronize()
    if stage == "connect":
        return session.connect()
    return session.read_config_word(CONFIG_BASE)


def ready(protocol, clock, stage):
    handle = AlreadyOpenUart(clock, [b"A", IDENTITY_REPORT, CONFIG_REPORT])
    session = protocol.BootloaderUartSession(handle, expected_pdid=PDID)
    if stage != "sync":
        session.synchronize()
    if stage == "config":
        session.connect()
    handle.events.clear()
    return session, handle


def wire(stage):
    return {"sync": SYNC, "connect": CONNECT_PACKET, "config": CONFIG0_PACKET}[stage]


def reply(stage):
    return {"sync": b"A", "connect": IDENTITY_REPORT, "config": CONFIG_REPORT}[stage]


def assert_restored(handle, original=(7.5, None)):
    assert (handle.timeout, handle.write_timeout) == original


def assert_invalidated(session, handle):
    before = list(handle.events)
    for stage in ("sync", "connect", "config"):
        with pytest.raises(RuntimeError):
            invoke(session, stage)
    assert handle.events == before, "An invalidated session performed more I/O"


def changed_word(report, index, value):
    offset = 12 + index * 4
    return report[:offset] + struct.pack("<I", value) + report[offset + 4:]


def test_constructor_and_preconditions_have_no_io(protocol, clock):
    handle = AlreadyOpenUart(clock, [b"A", IDENTITY_REPORT])
    session = protocol.BootloaderUartSession(handle, expected_pdid=PDID)
    assert handle.events == []
    for stage in ("connect", "config"):
        with pytest.raises(RuntimeError):
            invoke(session, stage)
    assert handle.events == []
    assert_restored(handle)
    session.synchronize()
    assert session.connect().pdid == PDID


@pytest.mark.parametrize("pdid", [-1, 0x100000000, None, "0x03302140", 1.0, True, False])
def test_constructor_rejects_invalid_pdid_without_io(protocol, clock, pdid):
    handle = AlreadyOpenUart(clock)
    with pytest.raises(ValueError):
        protocol.BootloaderUartSession(handle, expected_pdid=pdid)
    assert handle.events == []
    assert_restored(handle)


def test_constructor_requires_keyword_only_explicit_pdid(protocol, clock):
    handle = AlreadyOpenUart(clock)
    with pytest.raises(TypeError):
        protocol.BootloaderUartSession(handle)
    with pytest.raises(TypeError):
        protocol.BootloaderUartSession(handle, PDID)
    assert handle.events == []


def test_raw_uart_sync_connect_and_reads_match_literal_vectors(protocol, clock):
    handle = AlreadyOpenUart(clock, [b"A", IDENTITY_REPORT, CONFIG_REPORT, NEXT_CONFIG_REPORT])
    session = protocol.BootloaderUartSession(handle, expected_pdid=PDID)
    session.synchronize()
    identity = session.connect()
    assert isinstance(identity, protocol.Identity)
    assert identity.pdid == PDID and identity.words == IDENTITY_WORDS
    assert session.read_config_word(CONFIG_BASE) == 0x12345678
    assert session.read_config_word(CONFIG_BASE + 32) == 0x89ABCDEF
    assert handle.events == [
        ("write", SYNC, 1.0), ("read", 1, 1.0),
        ("write", CONNECT_PACKET, 1.0), ("read", 64, 5.0),
        ("write", CONFIG0_PACKET, 1.0), ("read", 64, 5.0),
        ("write", CONFIG8_NEXT_PACKET, 1.0), ("read", 64, 5.0),
    ]
    assert not handle.reads
    assert_restored(handle)


@pytest.mark.parametrize("connected", [False, True])
def test_synchronize_cannot_repeat_or_run_after_connect(protocol, clock, connected):
    session, handle = ready(protocol, clock, "connect")
    if connected:
        session.connect()
    before = list(handle.events)
    with pytest.raises(RuntimeError):
        session.synchronize()
    assert handle.events == before
    assert_restored(handle)


def test_config_needs_identity_not_only_synchronization(protocol, clock):
    session, handle = ready(protocol, clock, "connect")
    with pytest.raises(RuntimeError):
        session.read_config_word(CONFIG_BASE)
    assert handle.events == []


def test_double_connect_fails_without_io(protocol, clock):
    session, handle = ready(protocol, clock, "config")
    with pytest.raises(RuntimeError):
        session.connect()
    assert handle.events == []
    assert session.read_config_word(CONFIG_BASE) == 0x12345678


@pytest.mark.parametrize("index,prefix", CONFIG_VECTORS)
def test_all_documented_config_words_use_exact_raw_packets(protocol, clock, index, prefix):
    session, handle = ready(protocol, clock, "config")
    assert session.read_config_word(CONFIG_BASE + 4 * index) == 0x12345678
    assert handle.events == [("write", bytes.fromhex(prefix) + bytes(48), 1.0),
                             ("read", 64, 5.0)]
    assert_restored(handle)


@pytest.mark.parametrize("address", [
    *(CONFIG_BASE + 4 * i for i in [7, *range(15, 32), 35, 36, 63, 255]),
    -1, 0, 0xFFFFFFFF, 0x100000000, CONFIG_BASE - 4,
    CONFIG_BASE + 1, CONFIG_BASE + 2, CONFIG_BASE + 3,
    0x0F000000, 0x0F100000, 0x0F200000,
    None, "0x0F300000", float(CONFIG_BASE), True, False,
])
def test_invalid_config_is_rejected_pre_io_without_poisoning_session(protocol, clock, address):
    session, handle = ready(protocol, clock, "config")
    with pytest.raises(ValueError):
        session.read_config_word(address)
    assert handle.events == []
    assert_restored(handle)
    assert session.read_config_word(CONFIG_BASE) == 0x12345678


@pytest.mark.parametrize("stage,split", [
    *(("sync", split) for split in range(1, 62)),
    *((stage, split) for stage in ("connect", "config") for split in range(1, 64)),
])
def test_each_transmit_split_accumulates_only_unwritten_suffix(protocol, clock, stage, split):
    session, handle = ready(protocol, clock, stage)
    packet = wire(stage)
    handle.write_results.extend([split, len(packet) - split])
    invoke(session, stage)
    assert handle.events == [("write", packet, 1.0),
                             ("write", packet[split:], 1.0),
                             ("read", len(reply(stage)), 1.0 if stage == "sync" else 5.0)]
    assert_restored(handle)


@pytest.mark.parametrize("stage", ["connect", "config"])
@pytest.mark.parametrize("split", range(1, 64))
def test_each_receive_split_accumulates_without_stripping_leading_zero(protocol, clock, stage, split):
    session, handle = ready(protocol, clock, stage)
    report = reply(stage)
    handle.reads = deque([report[:split], report[split:]])
    result = invoke(session, stage)
    if stage == "connect":
        assert result.words == IDENTITY_WORDS
    else:
        assert result == 0x12345678
    assert handle.events == [("write", wire(stage), 1.0),
                             ("read", 64, 5.0), ("read", 64 - split, 5.0)]
    assert_restored(handle)


@pytest.mark.parametrize("stage", ["sync", "connect", "config"])
def test_single_byte_fragments_accumulate_on_both_directions(protocol, clock, stage):
    session, handle = ready(protocol, clock, stage)
    packet, report = wire(stage), reply(stage)
    handle.write_results = deque([1] * len(packet))
    handle.reads = deque(report[i:i + 1] for i in range(len(report)))
    invoke(session, stage)
    assert handle.events == [*(('write', packet[i:], 1.0) for i in range(len(packet))),
                             *(("read", len(report) - i, 1.0 if stage == "sync" else 5.0)
                               for i in range(len(report)))]
    assert_restored(handle)


@pytest.mark.parametrize("bad_reply", [b"a", b"\0", b"B", b"\xff", b"AA"])
def test_sync_ack_must_be_exact_capital_a(protocol, clock, bad_reply):
    session, handle = ready(protocol, clock, "sync")
    handle.reads = deque([bad_reply, b"A"])
    with pytest.raises(PROTOCOL_ERROR):
        session.synchronize()
    assert handle.events == [("write", SYNC, 1.0), ("read", 1, 1.0)]
    assert list(handle.reads) == [b"A"]
    assert_restored(handle)
    assert_invalidated(session, handle)


@pytest.mark.parametrize("word,value", [
    (0, 0), (0, 0xFFFFFFFF), (0, 0x03302130), (0, 0x12345678),
    (12, 0), (12, 0xFFFFFFFF), (12, 0x68245713), (12, 0x13572469),
])
def test_wrong_identity_or_marker_invalidates_without_retry(protocol, clock, word, value):
    session, handle = ready(protocol, clock, "connect")
    handle.reads = deque([changed_word(IDENTITY_REPORT, word, value), IDENTITY_REPORT])
    with pytest.raises(PROTOCOL_ERROR):
        session.connect()
    assert handle.events == [("write", CONNECT_PACKET, 1.0), ("read", 64, 5.0)]
    assert list(handle.reads) == [IDENTITY_REPORT]
    assert_restored(handle)
    assert_invalidated(session, handle)


def test_marker_in_wrong_word_is_not_accepted(protocol, clock):
    session, handle = ready(protocol, clock, "connect")
    handle.reads = deque([changed_word(changed_word(IDENTITY_REPORT, 12, 0), 11, 0x13572468)])
    with pytest.raises(PROTOCOL_ERROR):
        session.connect()
    assert_restored(handle)
    assert_invalidated(session, handle)


@pytest.mark.parametrize("pdid", [0, 0xFFFFFFFF])
def test_expected_pdid_is_exact_caller_supplied_value(protocol, clock, pdid):
    handle = AlreadyOpenUart(clock, [b"A", changed_word(IDENTITY_REPORT, 0, pdid)])
    session = protocol.BootloaderUartSession(handle, expected_pdid=pdid)
    session.synchronize()
    assert session.connect().pdid == pdid
    assert_restored(handle)


@pytest.mark.parametrize("sequence", [0, 1, 2, 3, 5, 6, 18, 19, 0xFFFFFFFF])
def test_config_response_requires_sequence_four_after_bootstrap(protocol, clock, sequence):
    session, handle = ready(protocol, clock, "config")
    handle.reads = deque([CONFIG_REPORT[:4] + struct.pack("<I", sequence) + CONFIG_REPORT[8:],
                         CONFIG_REPORT])
    with pytest.raises(PROTOCOL_ERROR):
        session.read_config_word(CONFIG_BASE)
    assert handle.events == [("write", CONFIG0_PACKET, 1.0), ("read", 64, 5.0)]
    assert list(handle.reads) == [CONFIG_REPORT]
    assert_restored(handle)
    assert_invalidated(session, handle)


def test_second_config_response_cannot_reuse_sequence_four(protocol, clock):
    session, handle = ready(protocol, clock, "config")
    handle.reads.append(CONFIG_REPORT)
    session.read_config_word(CONFIG_BASE)
    with pytest.raises(PROTOCOL_ERROR):
        session.read_config_word(CONFIG_BASE + 32)
    assert handle.events[-2:] == [("write", CONFIG8_NEXT_PACKET, 1.0), ("read", 64, 5.0)]
    assert_restored(handle)
    assert_invalidated(session, handle)


@pytest.mark.parametrize("stage", ["sync", "connect", "config"])
@pytest.mark.parametrize("written", [-1, 0, None, True, False, 1.0, "1", b"1", "oversize"])
def test_invalid_write_progress_fails_without_read_or_retry(protocol, clock, stage, written):
    session, handle = ready(protocol, clock, stage)
    handle.write_results = deque([len(wire(stage)) + 1 if written == "oversize" else written,
                                  len(wire(stage))])
    with pytest.raises(PROTOCOL_ERROR):
        invoke(session, stage)
    assert handle.events == [("write", wire(stage), 1.0)]
    assert len(handle.write_results) == 1
    assert_restored(handle)
    assert_invalidated(session, handle)


@pytest.mark.parametrize("stage", ["sync", "connect", "config"])
@pytest.mark.parametrize("received", [b"", None, "A", [65], 0, True, "oversize"])
def test_invalid_read_progress_fails_without_retry(protocol, clock, stage, received):
    session, handle = ready(protocol, clock, stage)
    bad = reply(stage) + b"\0" if received == "oversize" else received
    handle.reads = deque([bad, reply(stage)])
    with pytest.raises(PROTOCOL_ERROR):
        invoke(session, stage)
    assert handle.events == [("write", wire(stage), 1.0),
                             ("read", len(reply(stage)), 1.0 if stage == "sync" else 5.0)]
    assert list(handle.reads) == [reply(stage)]
    assert_restored(handle)
    assert_invalidated(session, handle)


@pytest.mark.parametrize("stage", ["connect", "config"])
@pytest.mark.parametrize("size", [1, 12, 52, 63])
def test_truncated_response_is_not_a_52_byte_payload_or_an_implicit_retry(protocol, clock, stage, size):
    session, handle = ready(protocol, clock, stage)
    handle.reads = deque([reply(stage)[:size], b"", reply(stage)])
    with pytest.raises(PROTOCOL_ERROR):
        invoke(session, stage)
    assert handle.events == [("write", wire(stage), 1.0),
                             ("read", 64, 5.0), ("read", 64 - size, 5.0)]
    assert list(handle.reads) == [reply(stage)]
    assert_restored(handle)
    assert_invalidated(session, handle)


@pytest.mark.parametrize("stage", ["connect", "config"])
def test_hid_report_id_prefix_is_not_accepted_on_uart(protocol, clock, stage):
    session, handle = ready(protocol, clock, stage)
    handle.reads = deque([b"\0" + reply(stage)])
    with pytest.raises(PROTOCOL_ERROR):
        invoke(session, stage)
    assert_restored(handle)
    assert_invalidated(session, handle)


@pytest.mark.parametrize("stage", ["sync", "connect", "config"])
def test_fragment_deadlines_use_monotonic_remaining_not_a_fresh_timeout(protocol, clock, stage):
    session, handle = ready(protocol, clock, stage)
    packet, report = wire(stage), reply(stage)
    handle.write_results = deque([1, 1, len(packet) - 2])
    handle.write_delays = deque([0.2, 0.2, 0.2])
    handle.reads = deque([report] if stage == "sync" else [report[:1], report[1:2], report[2:]])
    handle.read_delays = deque([0.3, 0.3, 0.3])
    invoke(session, stage)
    writes = [event for event in handle.events if event[0] == "write"]
    reads = [event for event in handle.events if event[0] == "read"]
    assert [event[2] for event in writes] == pytest.approx([1.0, 0.8, 0.6])
    budget = 1.0 if stage == "sync" else 5.0
    expected = [budget] if stage == "sync" else [budget, budget - 0.3, budget - 0.6]
    assert [event[2] for event in reads] == pytest.approx(expected)
    assert_restored(handle)


@pytest.mark.parametrize("stage", ["sync", "connect", "config"])
@pytest.mark.parametrize("operation", ["read", "write"])
def test_expired_fragment_deadline_stops_before_another_io(protocol, clock, stage, operation):
    session, handle = ready(protocol, clock, stage)
    if operation == "write":
        handle.write_results = deque([1, len(wire(stage)) - 1])
        handle.write_delays = deque([1.01])
    elif stage == "sync":
        # A transport returning beyond its supplied deadline cannot count as success.
        handle.read_delays = deque([1.01])
    else:
        handle.reads = deque([reply(stage)[:1], reply(stage)[1:]])
        handle.read_delays = deque([5.01])
    with pytest.raises(PROTOCOL_ERROR):
        invoke(session, stage)
    assert len(handle.events) == (1 if operation == "write" else 2)
    assert_restored(handle)
    assert_invalidated(session, handle)


@pytest.mark.parametrize("stage", ["sync", "connect", "config"])
@pytest.mark.parametrize("operation", ["read", "write"])
@pytest.mark.parametrize("exception_type", [OSError, LookupError, TypeError, KeyboardInterrupt])
def test_transport_exception_is_preserved_and_invalidates(protocol, clock, stage, operation, exception_type):
    session, handle = ready(protocol, clock, stage)
    failure = exception_type("synthetic transport failure")
    if operation == "write":
        handle.write_results = deque([failure, len(wire(stage))])
    else:
        handle.reads = deque([failure, reply(stage)])
    with pytest.raises(exception_type) as raised:
        invoke(session, stage)
    assert raised.value is failure
    assert len(handle.events) == (1 if operation == "write" else 2)
    assert_restored(handle)
    assert_invalidated(session, handle)


@pytest.mark.parametrize("stage", ["sync", "connect", "config"])
@pytest.mark.parametrize("property_name", ["timeout", "write_timeout"])
@pytest.mark.parametrize("operation", ["get", "set"])
def test_timeout_property_exception_is_preserved_and_invalidates(protocol, clock, stage, property_name, operation):
    session, handle = ready(protocol, clock, stage)
    failure = LookupError("synthetic timeout property failure")
    handle.property_faults[(operation, property_name)] = failure
    with pytest.raises(LookupError) as raised:
        invoke(session, stage)
    assert raised.value is failure
    assert_restored(handle)
    assert_invalidated(session, handle)


@pytest.mark.parametrize("stage", ["sync", "connect", "config"])
@pytest.mark.parametrize("original", [(None, None), (0.0, 0.0), (2.75, 9.25)])
@pytest.mark.parametrize("failure", [False, True])
def test_original_timeout_values_are_restored_on_success_and_failure(protocol, clock, stage, original, failure):
    session, handle = ready(protocol, clock, stage)
    handle.timeout, handle.write_timeout = original
    if failure:
        handle.reads = deque([OSError("synthetic timeout")])
        with pytest.raises(OSError):
            invoke(session, stage)
        assert_invalidated(session, handle)
    else:
        invoke(session, stage)
    assert_restored(handle, original)


def test_no_port_lifecycle_control_or_programming_entrypoints(protocol, clock):
    session = protocol.BootloaderUartSession(AlreadyOpenUart(clock), expected_pdid=PDID)
    for name in (
        "open", "close", "reset", "flush", "flushInput", "flushOutput",
        "reset_input_buffer", "reset_output_buffer", "setDTR", "setRTS",
        "set_dtr", "set_rts", "dtr", "rts", "break_condition", "send_break",
        "erase", "erase_all", "mass_erase", "erase_page", "erase_sector",
        "write", "write_memory", "write_config_word", "program", "program_flash",
        "read_memory", "send_feature_report", "get_feature_report",
    ):
        assert not hasattr(session, name), f"Unsafe public session entrypoint: {name}"


@pytest.mark.skipif(sys.platform == "win32", reason="POSIX pseudo-terminals required")
def test_native_pyserial_pseudoterminal_round_trip():
    """Exercise the host serial backend, never a physical USB/serial device."""
    import concurrent.futures
    import os
    import pty
    import select
    import serial

    spec = importlib.util.spec_from_file_location(
        "bootloader_uart_native_test", ROOT / "tools/bootloader_protocol.py"
    )
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    master, slave = pty.openpty()
    port = None
    try:
        spec.loader.exec_module(module)
        port = serial.Serial(os.ttyname(slave), 115200, timeout=2.5,
                             write_timeout=2.5, exclusive=True)

        def receive(size):
            data = bytearray()
            deadline = time.monotonic() + 2.0
            while len(data) < size:
                left = deadline - time.monotonic()
                assert left > 0 and select.select([master], [], [], left)[0]
                part = os.read(master, size - len(data))
                assert part
                data.extend(part)
            return bytes(data)

        def send(data):
            for offset in range(0, len(data), 3):
                fragment = data[offset:offset + 3]
                assert os.write(master, fragment) == len(fragment)

        def peer():
            assert receive(62) == SYNC
            send(b"A")
            assert receive(64) == CONNECT_PACKET
            send(IDENTITY_REPORT)
            assert receive(64) == CONFIG0_PACKET
            send(CONFIG_REPORT)

        with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(peer)
            session = module.BootloaderUartSession(port, expected_pdid=PDID)
            session.synchronize()
            assert session.connect().pdid == PDID
            assert session.read_config_word(CONFIG_BASE) == 0x12345678
            future.result(timeout=3.0)
        assert port.timeout == 2.5
        assert port.write_timeout == 2.5
    finally:
        if port is not None:
            port.close()
        os.close(slave)
        os.close(master)
        sys.modules.pop(spec.name, None)
