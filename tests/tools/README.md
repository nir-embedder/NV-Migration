# Modbus PC harness: usage and host self-tests

The harness is [`tools/modbus_verify.py`](../../tools/modbus_verify.py).
The complete case list, exact packet limits, result schema and leased hardware
wrapper example are in [`docs/pc-tests.md`](../../docs/pc-tests.md).

## Host-only checks

From the project root, using the existing Python 3.12 environment:

```sh
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -m pytest -q -p no:cacheprovider tests/tools
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python tools/modbus_verify.py --help
```

No installation, root access or network configuration is required. Dependencies
are pinned in [`requirements-test.txt`](../../requirements-test.txt): PyModbus
3.16.1, pyserial 3.5 and pytest 9.2.0.

The tests open only loopback TCP sockets and host pseudo-terminals. They do not
open a physical serial device, USB interface, debugger or ECM interface.

- `test_modbus_verify.py`: maps/aliasing, binary framing/CRC, approved demo
  defaults, real PyModbus TCP interoperability, observer failure detection,
  serial identity selection, JSON output and exit codes.
- `test_stream_integration.py`: real PyModbus RTU over paired pseudo-terminals,
  split/coalesced TCP streams, connection limits, malformed-write mutation,
  broadcasts, 1,000+ exchange loopback runs and large-map ADU boundaries.
- `test_flash_script.py`: offline ELF/pack/USB-inventory validation and in-memory
  programmer tests, including failure-before-write stack-limit checks. These
  mocks do not qualify the real programming path.
- `test_bootloader_protocol.py`: independent packet vectors and already-open HID
  fakes for the MaskROM identification/read adapter. Tests exercise no physical
  transport. See [the EXE audit](../../docs/bootloader-protocol.md) for separate
  differential emulation, active-I/O boundaries and unresolved recovery gates.
- `test_bootloader_uart.py`: raw UART framing, synchronization, fragmented
  transfers, finite deadlines, timeout restoration and failure invalidation.
  Includes a real pySerial exchange through a host-created POSIX pseudo-terminal
  on macOS/Linux; it never selects a physical serial port. Mocked tests remain
  independent of pySerial and the live hardware scripts.

Demo generators use independent approved function/address/data vectors rather
than reusing the observer's own expected constants. Deliberately faulty peers
must fail; an all-green happy-path loopback alone is not sufficient evidence.

## Cortex-M33 execution-context reproduction (offline)

With the existing SDK compiler, QEMU and the pinned local DFP:

```sh
.venv/bin/python tests/tools/run_flash_context.py \
  --pack "$NUVOTON_DFP" \
  --compiler .toolchains/zephyr-sdk-1.0.1/gnu/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc \
  --qemu /opt/homebrew/bin/qemu-system-arm \
  --build-dir build/flash-context
```

`NUVOTON_DFP` must name the exact local `Nuvoton.NuMicroM33_DFP.1.0.6.pack`;
no download or hardware access occurs. The runner hash-checks the pack, extracts
the two-byte `ProgramPage` push, and tests compatible-limit, incompatible-limit
and guarded controls on QEMU's Cortex-M33 AN505 model. It writes generated sources,
ELFs and `results.json` to the explicit build directory. The model's high limit
is synthetic; no historical limit was captured. The remaining FLM instructions
and M3351 peripheral hardware are not executed. The simulated fault handler's
stack repair exists only to print the result, not in the live flasher. This is
mechanism evidence, not a complete programming or USB HIL qualification.

## Roles and required arguments

| Role | PC behavior | Target firmware |
| --- | --- | --- |
| `board-server` | Master/client runs positive and negative checks | Board server |
| `board-client` | Server counts and validates demo requests/replies | Board client |

Every invocation requires `--transport rtu|tcp`,
`--profile shared|separate|large` and `--buffer-size 128|256`.
`--buffer-size` matches the firmware's **nominal RTU ADU size**, including unit
and CRC. TCP capacity is that value **plus four** (132 or 260 bytes); both
transports have a PDU capacity of nominal size **minus three** (125 or 253 bytes).
The nominal CLI value remains 128 or 256 for both transports.

- `shared`: zero-based 16-word bank; coils/DI alias its 256 bits.
- `separate`: coils 0..31, DI 100..131, HR 200..203, IR 300..303.
- `large`: opt-in, zero-based 128-word/2,048-bit shared test map. Use
  `--buffer-size 256` with `config/large-buffer.conf`. It does not change default
  maps. Large single-ADU cases are limited by both protocol and complete ADU size.
  Nominal 256 supports the same protocol maxima on **RTU and TCP**: 125 read
  registers, 123 written registers, 2,000 read bits and 1,968 written coils.
  Each largest transaction is 255 bytes over RTU or 259 bytes over TCP.
  Nominal 128 allows 61 read registers, 59 written registers, 984 read bits and
  952 written coils. Host regressions check real PyModbus exchanges, exact wire
  sizes, protocol limits, and malformed frames at/above each transport's capacity.

RTU defaults to unit 10 and requires an explicit native CDC port or an unambiguous
USB identity selector; no path or VID/PID is assumed. TCP defaults to unit 1,
board server `192.168.77.2:502`, PC listener `192.168.77.1:1502`.
The isolated ECM interface must already be configured; this harness changes no
host addresses or routes.

## Live invocation requires a hardware lease

Do **not** launch the harness against a connected board directly from a shell.
Use an approved `.embedder/hardware/` wrapper through `hardware_script_run`, with
bounded subprocesses and the hardware lease retained until they exit. See the
[wrapper example and argument lists](../../docs/pc-tests.md#running-against-a-board-arbiter-required).
No live wrapper is created by this test directory. The harness targets the
composite **Modbus application**, not the upstream CDC echo or ECM connectivity
baselines; those require their own baseline checks before running this suite.

For the dual-transport board-client demo, run the RTU and TCP PC servers
concurrently under the same lease. The expected sequence is:

```text
FC:       5, 1, 15, 2, 6, 3, 16, 4
Quantity: 1, 4,  4, 4, 1, 4,  4, 4
Data:     [1, 0x1234, 0x5678, 0xabcd]
```

FC5 encodes ON as `0xff00`; FC15 uses the four low bits of the first data word,
namely `[1, 0, 0, 0]`. FC6 writes `1`; FC16 writes all four words. Addresses follow
the selected profile. Increasing the map does not change the client demo's
four-element quantities.

Parent firmware diagnostics use:

```text
client cycle=%u transport=%s fc=%u result=%d data0=%u
```

Capture those diagnostics separately from binary CDC traffic and correlate them
with the PC result when verifying board-side completion. The PC observer checks
requests and responses it emits; it does not parse this log or prove the MCU
consumed a reply.

## Reading results and remaining gates

The harness prints JSON, optionally also saved with `--json <path>`.
`buffer_size` records the nominal setting; `adu_capacity` and `pdu_capacity`
record the derived transport/PDU limits. Exit codes
are 0 for automatic success, 1 for test/setup/output failure and 2 for invalid
CLI input. `--iterations 40` runs 1,000+ positive exchanges in PC-master mode;
`--cycles 125` requires 1,000 verified replies in PC-server mode. Extend deadlines
for the firmware's query interval before a soak.

`acceptance_complete` remains false even when automatic cases pass. Cable
unplug/replug, no-terminal cold boot and board-side reply consumption remain
manual-pending gates. Host pseudo-terminal tests are not physical USB evidence.
For an approved sample-development build, record the exact documented USB
identity selected for that firmware and confirm the enumerated native CDC
interface before testing. The harness does not choose or hard-code sample IDs;
those development identities are not production allocations.
