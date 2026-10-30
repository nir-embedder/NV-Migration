"""Transport adapter for the Nuvoton MaskROM ISP identification protocol.

Interoperability derived from NuvoISP_BL V1.04's packet routines, verified in an
isolated CPU emulator; see docs/validation.md. This is not the LDROM protocol.
No platform library is imported and no device is opened here. A caller must
supply an already-open HIDAPI-compatible or UART handle after establishing that
device access is authorized and appropriate. Identification/configuration reads
are active traffic, not passive inventory; target-side effects remain unqualified.

There is deliberately no erase, programming, reset, bridge setup, modem-line
control, or unknown-device fallback. Successful parsing does not establish a
safe recovery path or qualify any particular MCU's ROM implementation.
"""

from dataclasses import dataclass
import struct
from time import monotonic

PACKET_SIZE = 64
PAYLOAD_SIZE = 56
RESPONSE_HEADER_SIZE = 12
INITIAL_SEQUENCE = 0x12
CONNECT_MAGIC = 0x13572468
CONFIG_BASE = 0x0F300000
CONFIG_ADDRESSES = frozenset(CONFIG_BASE + 4 * i for i in (*range(7), *range(8, 15), 32, 33, 34))


def _integer(value, maximum, name):
    if type(value) is not int or not 0 <= value <= maximum:
        raise ValueError(f"{name} must be an integer in 0..{maximum}")
    return value


def encode_packet(command, payload=b"", *, sequence=INITIAL_SEQUENCE, mode=1):
    """Encode one packet without the host HID report-ID placeholder.

    Modes: USB=1, UART=2, SPI=3, I2C=4, CAN=5. Encoding bridge routing does not
    establish its hardware behavior. This low-level function performs no I/O.
    The vendor silently truncates oversized payloads; this implementation refuses.
    """
    _integer(command, 0xFF, "command")
    _integer(sequence, 0xFFFFFFFF, "sequence")
    _integer(mode, 5, "mode")
    if mode == 0:
        raise ValueError("mode must be in 1..5")
    if not isinstance(payload, bytes):
        raise ValueError("payload must be bytes")
    if len(payload) > PAYLOAD_SIZE:
        raise ValueError("payload exceeds the 56-byte packet capacity")
    body = struct.pack("<I", sequence) + payload.ljust(PAYLOAD_SIZE, b"\0")
    checksum = (command + sum(body)) & 0xFFFF
    packet = bytearray(struct.pack("<HH", command, checksum) + body)
    if mode >= 3:
        packet[1] = mode
    return bytes(packet)


def hid_output_report(packet):
    """HIDAPI requires a zero report ID for this unnumbered output report."""
    if not isinstance(packet, bytes) or len(packet) != PACKET_SIZE:
        raise ValueError("output packet must be exactly 64 bytes")
    return b"\0" + packet


def hid_input_report(report):
    """HIDAPI interrupt reads omit an absent report ID on macOS and Windows.

    Do not use feature-report APIs or guess by stripping a leading zero: it can
    be actual packet data. The list form supports the Python hidapi binding.
    """
    if not isinstance(report, (bytes, bytearray, list)):
        raise ValueError("input report must be bytes or a HIDAPI byte list")
    if len(report) != PACKET_SIZE:
        raise ValueError("input report must be exactly 64 bytes without a report-ID prefix")
    if isinstance(report, list) and any(type(x) is not int or not 0 <= x <= 255 for x in report):
        raise ValueError("invalid HIDAPI input byte")
    return bytes(report)


@dataclass(frozen=True)
class Response:
    sequence: int
    header: bytes
    payload: bytes


@dataclass(frozen=True)
class Identity:
    pdid: int
    words: tuple


def decode_response(report, *, expected_sequence, payload_length=52):
    """Validate framing and correlation; retain undocumented header bytes.

    The exact EXE does not verify a response checksum. Its format is not inferred
    from the request checksum; header contents are retained for future analysis.
    """
    raw = hid_input_report(report)
    _integer(payload_length, PACKET_SIZE - RESPONSE_HEADER_SIZE, "payload_length")
    sequence = struct.unpack_from("<I", raw, 4)[0]
    if expected_sequence is not None:
        _integer(expected_sequence, 0xFFFFFFFF, "expected_sequence")
        if sequence != expected_sequence:
            raise ValueError("response sequence mismatch")
    return Response(sequence, raw[:RESPONSE_HEADER_SIZE], raw[12:12 + payload_length])


def decode_identity(report, *, expected_pdid):
    """Parse A0's thirteen words without assigning unverified memory geometry."""
    _integer(expected_pdid, 0xFFFFFFFF, "expected_pdid")
    response = decode_response(report, expected_sequence=None)
    words = struct.unpack("<13I", response.payload)
    if words[12] != CONNECT_MAGIC:
        raise ValueError("invalid bootloader identification marker")
    if words[0] != expected_pdid:
        raise ValueError("unexpected device ID; no fallback geometry is permitted")
    return Identity(words[0], words)


class BootloaderHidSession:
    """Bounded, explicit identification/read traffic on an already-open handle.

    No implicit retry/reopen/reset, no transport probing, and no handle ownership.
    The first I/O error invalidates the session to avoid consuming stale replies.
    A0 bootstrap sequence handling follows the vendor EXE; subsequent reads use
    the stricter sequence-checking path present in that same EXE.
    """

    def __init__(self, handle, *, expected_pdid):
        self._expected_pdid = _integer(expected_pdid, 0xFFFFFFFF, "expected_pdid")
        self._handle = handle
        self._sequence = INITIAL_SEQUENCE
        self._connected = False
        self._failed = False

    def _exchange(self, command, payload=b"", *, bootstrap=False, payload_length=52):
        if self._failed:
            raise RuntimeError("session invalid after previous failure; no automatic retry")
        packet = encode_packet(command, payload, sequence=self._sequence)
        try:
            if self._handle.write(hid_output_report(packet)) != PACKET_SIZE + 1:
                raise OSError("short HID write; expected 65 bytes including report ID")
            self._sequence = (self._sequence + 2) & 0xFFFFFFFF
            raw = self._handle.read(PACKET_SIZE, 5000)
            return decode_response(raw,
                                   expected_sequence=None if bootstrap else (self._sequence - 1) & 0xFFFFFFFF,
                                   payload_length=payload_length)
        except (Exception, KeyboardInterrupt):
            self._failed = True
            self._connected = False
            raise

    def connect(self):
        if self._connected:
            raise RuntimeError("session is already identified")
        response = self._exchange(0xA0, bootstrap=True)
        try:
            identity = decode_identity(response.header + response.payload,
                                       expected_pdid=self._expected_pdid)
        except ValueError:
            self._failed = True
            raise
        self._sequence = 3
        self._connected = True
        return identity

    def read_config_word(self, address):
        if not self._connected:
            raise RuntimeError("successful identification is required before configuration reads")
        if type(address) is not int or address not in CONFIG_ADDRESSES:
            raise ValueError("address is not a documented M3351 CONFIG word")
        response = self._exchange(0xD2, struct.pack("<II", address, 4), payload_length=4)
        return struct.unpack("<I", response.payload)[0]


class BootloaderUartSession(BootloaderHidSession):
    """The same protocol over an already-open, exclusively owned UART handle.

    UART carries 64 raw bytes, not HIDAPI's 65-byte output report. A caller
    selects baud/line controls and any authorized reset before synchronize().
    No BREAK, DTR/RTS, port lifecycle, reset or programming operation is provided.
    Unlike the vendor GUI, this adapter never closes/reopens the port between
    synchronization and identification, and rejects short or stale replies.
    """

    def __init__(self, handle, *, expected_pdid):
        super().__init__(handle, expected_pdid=expected_pdid)
        self._synchronized = False

    def _write_all(self, data):
        previous = self._handle.write_timeout
        deadline = monotonic() + 1.0
        offset = 0
        try:
            while offset < len(data):
                remaining = deadline - monotonic()
                if remaining <= 0:
                    raise TimeoutError("UART write deadline exceeded")
                self._handle.write_timeout = remaining
                count = self._handle.write(data[offset:])
                if monotonic() > deadline:
                    raise TimeoutError("UART write deadline exceeded")
                if type(count) is not int or not 0 < count <= len(data) - offset:
                    raise OSError("invalid or zero-progress UART write")
                offset += count
        finally:
            self._handle.write_timeout = previous

    def _read_exact(self, size, timeout):
        previous = self._handle.timeout
        deadline = monotonic() + timeout
        data = bytearray()
        try:
            while len(data) < size:
                remaining = deadline - monotonic()
                if remaining <= 0:
                    raise TimeoutError("UART response deadline exceeded")
                self._handle.timeout = remaining
                part = self._handle.read(size - len(data))
                if monotonic() > deadline:
                    raise TimeoutError("UART response deadline exceeded")
                if not isinstance(part, (bytes, bytearray)) or len(part) > size - len(data):
                    raise OSError("invalid UART read result")
                if not part:
                    raise TimeoutError("incomplete UART response")
                data.extend(part)
        finally:
            self._handle.timeout = previous
        return bytes(data)

    def synchronize(self):
        """One bounded 62-byte synchronization attempt, without a reset pulse."""
        if self._failed:
            raise RuntimeError("session invalid after previous failure; no automatic retry")
        if self._synchronized or self._connected:
            raise RuntimeError("session is already synchronized")
        try:
            self._write_all(b"a" * 62)
            if self._read_exact(1, 1.0) != b"A":
                raise ValueError("invalid UART synchronization response")
            self._synchronized = True
        except (Exception, KeyboardInterrupt):
            self._failed = True
            self._connected = False
            raise

    def connect(self):
        if not self._synchronized:
            raise RuntimeError("UART synchronization is required before identification")
        return super().connect()

    def _exchange(self, command, payload=b"", *, bootstrap=False, payload_length=52):
        if self._failed:
            raise RuntimeError("session invalid after previous failure; no automatic retry")
        packet = encode_packet(command, payload, sequence=self._sequence, mode=2)
        try:
            self._write_all(packet)
            self._sequence = (self._sequence + 2) & 0xFFFFFFFF
            raw = self._read_exact(PACKET_SIZE, 5.0)
            return decode_response(raw,
                                   expected_sequence=None if bootstrap else (self._sequence - 1) & 0xFFFFFFFF,
                                   payload_length=payload_length)
        except (Exception, KeyboardInterrupt):
            self._failed = True
            self._connected = False
            raise
