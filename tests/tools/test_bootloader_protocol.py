"""Offline bootloader protocol contract: fixed wire vectors and already-open fakes."""
import builtins
from collections import deque
from dataclasses import FrozenInstanceError
import importlib.util
from pathlib import Path
import struct
import sys

import pytest

ROOT = Path(__file__).resolve().parents[2]
PDID = 0x03302140
CONFIG_BASE = 0x0F300000
ALLOWED_CONFIG_INDICES = (*range(7), *range(8, 15), *range(32, 35))
BAD_INPUT = ValueError
PROTOCOL_ERROR = (RuntimeError, ValueError, OSError)

# Literal expectations are independent of both the implementation and its oracle.
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


@pytest.fixture
def protocol(monkeypatch):
    """Loading and using this module must not import a live transport backend."""
    original_import = builtins.__import__

    def offline_import(name, *args, **kwargs):
        if name.split(".")[0] in {"hid", "hidapi", "serial", "usb", "pyocd"}:
            pytest.fail(f"Protocol module attempted a hardware backend import: {name}")
        return original_import(name, *args, **kwargs)

    monkeypatch.setattr(builtins, "__import__", offline_import)
    spec = importlib.util.spec_from_file_location(
        "bootloader_protocol_under_test", ROOT / "tools/bootloader_protocol.py"
    )
    module = importlib.util.module_from_spec(spec)
    monkeypatch.setitem(sys.modules, spec.name, module)
    spec.loader.exec_module(module)
    return module


class AlreadyOpenHid:
    """Only hidapi read/write exist; lifecycle/control calls fail the test."""

    def __init__(self, reports=(), write_results=()):
        self.reports = deque(reports)
        self.write_results = deque(write_results)
        self.events = []

    def write(self, report):
        raw = bytes(report)
        self.events.append(("write", raw))
        assert len(raw) == 65 and raw[0] == 0
        result = self.write_results.popleft() if self.write_results else 65
        if isinstance(result, Exception):
            raise result
        return result

    def read(self, size, timeout_ms):
        self.events.append(("read", size, timeout_ms))
        assert (size, timeout_ms) == (64, 5000)
        assert self.reports, "Unexpected read or retry"
        result = self.reports.popleft()
        if isinstance(result, Exception):
            raise result
        return result

    def __getattr__(self, name):
        raise AssertionError(f"Forbidden HID lifecycle/control operation: {name}")


def config_reply(sequence=4, value=0x12345678):
    # A synthetic response, not a request encoder or a response checksum oracle.
    return b"\x00\xff\xde\xad" + struct.pack("<I", sequence) + b"\xaa\xbb\xcc\xdd" + (
        struct.pack("<I", value) + bytes(48)
    )


def changed_word(report, index, value):
    offset = 12 + index * 4
    return report[:offset] + struct.pack("<I", value) + report[offset + 4:]


def assert_invalidated(session, handle):
    before = list(handle.events)
    with pytest.raises(RuntimeError):
        session.read_config_word(CONFIG_BASE)
    with pytest.raises(RuntimeError):
        session.connect()
    assert handle.events == before, "An invalidated session performed more I/O"


def test_default_connect_packet_is_vendor_raw_vector(protocol):
    packet = protocol.encode_packet(0xA0)
    assert type(packet) is bytes
    assert packet == CONNECT_PACKET
    assert len(packet) == 64


@pytest.mark.parametrize("mode,command_high_byte", [(1, "00"), (2, "00"), (3, "03"),
                                                     (4, "04"), (5, "05")])
def test_mode_override_happens_after_checksum(protocol, mode, command_high_byte):
    expected = bytes.fromhex(f"a7{command_high_byte}20037856341200112233ff") + bytes(51)
    assert protocol.encode_packet(
        0xA7, bytes.fromhex("00112233ff"), sequence=0x12345678, mode=mode
    ) == expected


@pytest.mark.parametrize("command,sequence,payload,expected", [
    (0, 0, b"", bytes(64)),
    (0xFF, 0xFFFFFFFF, b"\xff" * 56,
     bytes.fromhex("ff00c33cffffffff") + b"\xff" * 56),
    (0xD2, 3, bytes.fromhex("0000300f04000000"), CONFIG0_PACKET),
])
def test_packet_boundaries_and_full_payload_vector(protocol, command, sequence, payload, expected):
    assert protocol.encode_packet(command, payload, sequence=sequence) == expected


@pytest.mark.parametrize("command", [-1, 256, 1.0, "160", None, True, False])
def test_encode_rejects_invalid_command(protocol, command):
    with pytest.raises(BAD_INPUT):
        protocol.encode_packet(command)


@pytest.mark.parametrize("sequence", [-1, 0x100000000, 1.0, "18", None, True, False])
def test_encode_rejects_invalid_sequence(protocol, sequence):
    with pytest.raises(BAD_INPUT):
        protocol.encode_packet(0xA0, sequence=sequence)


@pytest.mark.parametrize("mode", [-1, 0, 6, 256, 1.0, "1", None, True, False])
def test_encode_rejects_invalid_mode(protocol, mode):
    with pytest.raises(BAD_INPUT):
        protocol.encode_packet(0xA0, mode=mode)


@pytest.mark.parametrize("payload", [bytes(57), bytearray(4), memoryview(b"a"), [], "", None, 4])
def test_encode_rejects_oversize_or_non_bytes_payload(protocol, payload):
    with pytest.raises(BAD_INPUT):
        protocol.encode_packet(0xA0, payload)


def test_hid_output_adds_exactly_one_zero_report_id(protocol):
    assert protocol.hid_output_report(CONNECT_PACKET) == b"\0" + CONNECT_PACKET
    assert protocol.hid_output_report(bytes(64)) == bytes(65)
    assert type(protocol.hid_output_report(CONNECT_PACKET)) is bytes


@pytest.mark.parametrize("packet", [bytes(63), bytes(65), b"", [0] * 64, "x" * 64, None, 64])
def test_hid_output_rejects_not_exact_packet_bytes(protocol, packet):
    with pytest.raises(BAD_INPUT):
        protocol.hid_output_report(packet)


@pytest.mark.parametrize("container", [bytes, list])
def test_hid_input_preserves_all_64_bytes_including_leading_zero(protocol, container):
    raw = bytes(range(64))
    result = protocol.hid_input_report(container(raw))
    assert type(result) is bytes
    assert result == raw


@pytest.mark.parametrize("report", [b"", [], bytes(63), bytes(65), [0] * 63, [0] * 65,
                                    "x" * 64, None, 64, [-1] + [0] * 63,
                                    [256] + [0] * 63, [1.5] + [0] * 63])
def test_hid_input_rejects_invalid_size_type_or_octet(protocol, report):
    with pytest.raises(BAD_INPUT):
        protocol.hid_input_report(report)


def test_response_preserves_opaque_header_and_uses_offset_12_payload(protocol):
    response = protocol.decode_response(CONFIG_REPORT, expected_sequence=4)
    assert isinstance(response, protocol.Response)
    assert response.sequence == 4
    assert response.header == bytes.fromhex("00ffdead04000000aabbccdd")
    assert type(response.header) is bytes
    assert response.payload == bytes.fromhex("78563412") + bytes(range(48))
    assert type(response.payload) is bytes
    with pytest.raises(FrozenInstanceError):
        response.sequence = 99
    with pytest.raises(FrozenInstanceError):
        response.header = b"changed"
    with pytest.raises(FrozenInstanceError):
        response.payload = b"changed"


@pytest.mark.parametrize("length", [0, 1, 4, 51, 52])
def test_response_payload_length_is_exact_not_padded(protocol, length):
    response = protocol.decode_response(CONFIG_REPORT, expected_sequence=None, payload_length=length)
    assert response.payload == CONFIG_REPORT[12:12 + length]


@pytest.mark.parametrize("sequence", [0, 1, 3, 5, 0xFFFFFFFF])
def test_response_rejects_stale_or_wrong_sequence(protocol, sequence):
    with pytest.raises(PROTOCOL_ERROR):
        protocol.decode_response(CONFIG_REPORT, expected_sequence=sequence)


@pytest.mark.parametrize("sequence", [0, 0xFFFFFFFF])
def test_response_accepts_sequence_uint32_endpoints(protocol, sequence):
    result = protocol.decode_response(config_reply(sequence), expected_sequence=sequence)
    assert result.sequence == sequence


@pytest.mark.parametrize("sequence", [-1, 0x100000000, "4", 4.0, True, False])
def test_response_rejects_invalid_expected_sequence(protocol, sequence):
    with pytest.raises(BAD_INPUT):
        protocol.decode_response(CONFIG_REPORT, expected_sequence=sequence)


@pytest.mark.parametrize("length", [-1, 53, None, 4.0, "4", True, False])
def test_response_rejects_invalid_payload_length(protocol, length):
    with pytest.raises(BAD_INPUT):
        protocol.decode_response(CONFIG_REPORT, expected_sequence=4, payload_length=length)


@pytest.mark.parametrize("size", [0, 12, 63, 65])
def test_response_requires_exact_64_bytes(protocol, size):
    with pytest.raises(BAD_INPUT):
        protocol.decode_response(bytes(size), expected_sequence=None)


def test_response_requires_explicit_sequence_policy(protocol):
    with pytest.raises(TypeError):
        protocol.decode_response(CONFIG_REPORT)


def test_identity_preserves_all_thirteen_words_without_guessing_memory_sizes(protocol):
    identity = protocol.decode_identity(IDENTITY_REPORT, expected_pdid=PDID)
    assert isinstance(identity, protocol.Identity)
    assert identity.pdid == PDID
    assert type(identity.words) is tuple
    assert identity.words == IDENTITY_WORDS


@pytest.mark.parametrize("pdid", [0, 0xFFFFFFFF, 0x03302130, 0x12345678])
def test_identity_rejects_unknown_or_wrong_pdid_without_fallback(protocol, pdid):
    with pytest.raises(PROTOCOL_ERROR):
        protocol.decode_identity(changed_word(IDENTITY_REPORT, 0, pdid), expected_pdid=PDID)


@pytest.mark.parametrize("magic", [0, 0xFFFFFFFF, 0x68245713, 0x13572469])
def test_identity_requires_magic_at_word_twelve(protocol, magic):
    with pytest.raises(PROTOCOL_ERROR):
        protocol.decode_identity(changed_word(IDENTITY_REPORT, 12, magic), expected_pdid=PDID)


def test_identity_magic_in_another_word_cannot_replace_final_magic(protocol):
    report = changed_word(changed_word(IDENTITY_REPORT, 12, 0), 11, 0x13572468)
    with pytest.raises(PROTOCOL_ERROR):
        protocol.decode_identity(report, expected_pdid=PDID)


@pytest.mark.parametrize("size", [0, 12, 63, 65])
def test_identity_requires_exact_report_size(protocol, size):
    with pytest.raises(BAD_INPUT):
        protocol.decode_identity(bytes(size), expected_pdid=PDID)


@pytest.mark.parametrize("pdid", [-1, 0x100000000, None, "0x03302140", 1.0, True, False])
def test_identity_requires_explicit_uint32_pdid(protocol, pdid):
    with pytest.raises(BAD_INPUT):
        protocol.decode_identity(IDENTITY_REPORT, expected_pdid=pdid)


def test_identity_requires_expected_pdid_argument(protocol):
    with pytest.raises(TypeError):
        protocol.decode_identity(IDENTITY_REPORT)


def test_session_constructor_does_no_io_and_cannot_read_before_connect(protocol):
    handle = AlreadyOpenHid()
    session = protocol.BootloaderHidSession(handle, expected_pdid=PDID)
    assert handle.events == []
    with pytest.raises(PROTOCOL_ERROR):
        session.read_config_word(CONFIG_BASE)
    assert handle.events == []


@pytest.mark.parametrize("pdid", [-1, 0x100000000, None, "0x03302140", 1.0, True, False])
def test_session_rejects_invalid_expected_pdid_without_io(protocol, pdid):
    handle = AlreadyOpenHid()
    with pytest.raises(BAD_INPUT):
        protocol.BootloaderHidSession(handle, expected_pdid=pdid)
    assert handle.events == []


def test_session_requires_expected_pdid(protocol):
    with pytest.raises(TypeError):
        protocol.BootloaderHidSession(AlreadyOpenHid())


@pytest.mark.parametrize("container", [bytes, list])
def test_connect_bootstrap_and_config_transactions_match_raw_vectors(protocol, container):
    handle = AlreadyOpenHid(map(container, [IDENTITY_REPORT, CONFIG_REPORT, NEXT_CONFIG_REPORT]))
    session = protocol.BootloaderHidSession(handle, expected_pdid=PDID)
    identity = session.connect()
    assert isinstance(identity, protocol.Identity)
    assert identity.pdid == PDID and identity.words == IDENTITY_WORDS
    assert session.read_config_word(CONFIG_BASE) == 0x12345678
    assert session.read_config_word(CONFIG_BASE + 8 * 4) == 0x89ABCDEF
    assert handle.events == [
        ("write", b"\0" + CONNECT_PACKET), ("read", 64, 5000),
        ("write", b"\0" + CONFIG0_PACKET), ("read", 64, 5000),
        ("write", b"\0" + CONFIG8_NEXT_PACKET), ("read", 64, 5000),
    ]
    assert not handle.reports


@pytest.mark.parametrize("index", ALLOWED_CONFIG_INDICES)
def test_every_documented_config_word_is_readable(protocol, index):
    handle = AlreadyOpenHid([IDENTITY_REPORT, CONFIG_REPORT])
    session = protocol.BootloaderHidSession(handle, expected_pdid=PDID)
    session.connect()
    assert session.read_config_word(CONFIG_BASE + 4 * index) == 0x12345678
    # All permitted offsets fit one byte; these constants do not use encode_packet.
    expected = bytes.fromhex("d200") + (0x118 + 4 * index).to_bytes(2, "little") + (
        bytes.fromhex("03000000") + bytes([4 * index]) + bytes.fromhex("00300f04000000")
        + bytes(48)
    )
    assert handle.events[2:] == [("write", b"\0" + expected), ("read", 64, 5000)]


@pytest.mark.parametrize("index", [7, *range(15, 32), 35, 36, 63, 255])
def test_reserved_config_words_are_refused_before_io(protocol, index):
    handle = AlreadyOpenHid([IDENTITY_REPORT, CONFIG_REPORT])
    session = protocol.BootloaderHidSession(handle, expected_pdid=PDID)
    session.connect()
    before = list(handle.events)
    with pytest.raises(BAD_INPUT):
        session.read_config_word(CONFIG_BASE + 4 * index)
    assert handle.events == before


@pytest.mark.parametrize("address", [
    -1, 0, 0xFFFFFFFF, 0x100000000, CONFIG_BASE - 4, CONFIG_BASE + 1,
    CONFIG_BASE + 2, CONFIG_BASE + 3, 0x0F000000, 0x0F100000, 0x0F200000,
    None, "0x0F300000", float(CONFIG_BASE), True, False,
])
def test_invalid_or_arbitrary_memory_address_is_refused_before_io(protocol, address):
    handle = AlreadyOpenHid([IDENTITY_REPORT, CONFIG_REPORT])
    session = protocol.BootloaderHidSession(handle, expected_pdid=PDID)
    session.connect()
    before = list(handle.events)
    with pytest.raises(BAD_INPUT):
        session.read_config_word(address)
    assert handle.events == before


@pytest.mark.parametrize("bad_report", [
    b"", [], bytes(63), bytes(65), [0] * 63, [0] * 65,
    changed_word(IDENTITY_REPORT, 0, 0xFFFFFFFF),
    changed_word(IDENTITY_REPORT, 12, 0), OSError("synthetic read failure"),
])
def test_connect_failure_has_no_retry_and_leaves_session_unusable(protocol, bad_report):
    handle = AlreadyOpenHid([bad_report, IDENTITY_REPORT])
    session = protocol.BootloaderHidSession(handle, expected_pdid=PDID)
    with pytest.raises(PROTOCOL_ERROR):
        session.connect()
    assert handle.events == [("write", b"\0" + CONNECT_PACKET), ("read", 64, 5000)]
    assert len(handle.reports) == 1
    assert_invalidated(session, handle)


@pytest.mark.parametrize("bad_report", [
    b"", [], bytes(63), bytes(65), [0] * 63, [0] * 65,
    config_reply(2), config_reply(3), config_reply(5), config_reply(18),
    [256] + [0] * 63, OSError("synthetic read failure"),
])
def test_config_exchange_error_invalidates_connected_session_without_retry(protocol, bad_report):
    handle = AlreadyOpenHid([IDENTITY_REPORT, bad_report, CONFIG_REPORT])
    session = protocol.BootloaderHidSession(handle, expected_pdid=PDID)
    session.connect()
    with pytest.raises(PROTOCOL_ERROR):
        session.read_config_word(CONFIG_BASE)
    assert handle.events == [
        ("write", b"\0" + CONNECT_PACKET), ("read", 64, 5000),
        ("write", b"\0" + CONFIG0_PACKET), ("read", 64, 5000),
    ]
    assert len(handle.reports) == 1
    assert_invalidated(session, handle)


@pytest.mark.parametrize("written", [-1, 0, 1, 63, 64, 66, None, True, OSError("synthetic write failure")])
@pytest.mark.parametrize("stage", ["connect", "config"])
def test_write_must_report_65_actual_bytes_or_invalidate_without_read(protocol, written, stage):
    results = [written] if stage == "connect" else [65, written]
    handle = AlreadyOpenHid([IDENTITY_REPORT, CONFIG_REPORT], write_results=results)
    session = protocol.BootloaderHidSession(handle, expected_pdid=PDID)
    if stage == "config":
        session.connect()
    with pytest.raises(OSError):
        if stage == "connect":
            session.connect()
        else:
            session.read_config_word(CONFIG_BASE)
    expected = [("write", b"\0" + CONNECT_PACKET)]
    if stage == "config":
        expected += [("read", 64, 5000), ("write", b"\0" + CONFIG0_PACKET)]
    assert handle.events == expected
    assert_invalidated(session, handle)


@pytest.mark.parametrize("exception_type", [LookupError, TypeError])
@pytest.mark.parametrize("operation", ["read", "write"])
@pytest.mark.parametrize("stage", ["connect", "config"])
def test_arbitrary_transport_exception_propagates_and_invalidates(
        protocol, exception_type, operation, stage):
    failure = exception_type("synthetic transport failure")
    reports = [failure if operation == "read" else CONFIG_REPORT, CONFIG_REPORT]
    results = [failure] if operation == "write" else []
    if stage == "config":
        reports.insert(0, IDENTITY_REPORT)
        results.insert(0, 65)
    handle = AlreadyOpenHid(reports, write_results=results)
    session = protocol.BootloaderHidSession(handle, expected_pdid=PDID)
    expected = []
    if stage == "config":
        session.connect()
        expected = [("write", b"\0" + CONNECT_PACKET), ("read", 64, 5000)]
    with pytest.raises(exception_type) as raised:
        if stage == "connect":
            session.connect()
        else:
            session.read_config_word(CONFIG_BASE)
    assert raised.value is failure
    expected.append(("write", b"\0" + (CONNECT_PACKET if stage == "connect" else CONFIG0_PACKET)))
    if operation == "read":
        expected.append(("read", 64, 5000))
    assert handle.events == expected
    assert_invalidated(session, handle)


def test_session_has_no_arbitrary_memory_or_destructive_entrypoints(protocol):
    session = protocol.BootloaderHidSession(AlreadyOpenHid(), expected_pdid=PDID)
    for name in (
        "erase", "erase_all", "mass_erase", "erase_page", "erase_sector", "write",
        "write_memory", "write_config_word", "program", "program_flash", "read_memory",
        "reset", "set_dtr", "send_feature_report", "get_feature_report",
    ):
        assert not hasattr(session, name), f"Unsafe public session entrypoint: {name}"
