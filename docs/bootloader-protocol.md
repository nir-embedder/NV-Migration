# Nuvoton MaskROM ISP interoperability investigation

## Status and scope

This is an **offline-validated host implementation, not a recovered board or a
qualified programmer**. It addresses the supplied `flash.py` and the Windows
Boot Loader ISP tool. The current workspace uses the confirmed M3351KJCAE,
1 MiB APROM and `tools/flash.py`; the attachment's KI/512-KiB defaults must not
replace that selection. Existing data/security preservation requirements remain
in force. The initial codec/EXE investigation was offline. The 2026-10-29
follow-up below records explicit, authorized debug/reset and UART identification
attempts; none programmed flash or changed persistent configuration/security.

`tools/bootloader_protocol.py` implements the inspected packet format and bounded
identification/CONFIG-read adapters for **already-open** HIDAPI or UART handles.
It has no device discovery, handle-opening, erase, program, unlock,
reset, bridge-control, or automatic-retry operation. A caller must establish
that active traffic is appropriate before using it. Constructor/import are
I/O-free; `connect()` and `read_config_word()` are not passive operations.
Do not share the handle between concurrent callers.

## Exact executable and independently executed evidence

- Official archive: `en-us--NuvoISP_BL_V1.04.zip`, SHA-256
  `4a7cfe5cd0207fa99f052ee1038b85c9110684cab9fb9fda2f594867c80ff5a7`.
- PE32 member: `NuvoISP_BL_V1.04.exe`, SHA-256
  `aed05e31a6a73c760076218dcfbd038e94e579b0287bb86bb2add7ba8daa35f0`.
- Source retrieval for the exact-named public Boot Loader project returned 404;
  the ordinary LDROM ISP clients were **not** substituted as a protocol source.
- Packet encoder at VA `0x0040A040`; response parser at `0x004098D0`; HID wrappers
  at `0x00413920` / `0x004139A0`.
- Unicorn executes just the inspected x86 routines with bounded instruction/time
  budgets. Only memory-copy/fill helpers and HID/serial transport stubs are
  available. Unexpected execution fails. The native EXE, Windows loader and
  host device APIs are never executed.
- **1,283 encoding cases** match the portable encoder byte for byte, across all
  256 command-byte values, all five modes, payload boundaries and sequence wrap.
  Arbitrary command values are tested in memory only, not sent to a device.
- **100 response-parser comparisons**, length boundaries, failed sends and
  stale-sequence controls were exercised. `tests/tools/test_bootloader_protocol.py`
  separately tests literal vectors and in-memory HID handles, not the emulator's
  implementation of the codec.

Local evidence is in `.embedder/hardware/results/boot-loader-v1.04/`:
`codec-differential.json`, `connection-audit/`, and `audit_exe.py`. Run the existing
oracle with `NUVOTON_BOOTLOADER_ZIP` pointing at the official local archive:

```sh
.venv/bin/python .embedder/hardware/results/boot-loader-v1.04/audit_exe.py verify-codec
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -m pytest -q -p no:cacheprovider \
  tests/tools/test_bootloader_protocol.py
```

The previous host-only suite passed 649 cases (334 flasher, 228 HID protocol,
87 Modbus host). The 2026-10-29 follow-up adds 534 UART cases, including a native
pySerial exchange through a host pseudo-terminal. These are software/host-backend
tests, not physical target USB acceptance.

The oracle refuses a different executable hash. Unicorn 2.1.4 and Capstone 5.0.7
were used locally. These optional analysis dependencies are not needed by the
portable protocol module or its pytest suite. No vendor executable is bundled
with the module.

## Wire format versus host API

Requests have 64 bytes, with little-endian fields:

| Offset | Size | Meaning established by the encoder |
|---|---:|---|
| 0 | 2 | Command; high byte initially zero |
| 2 | 2 | `(command + sum(packet[4:64])) & 0xffff` |
| 4 | 4 | Sequence |
| 8 | 56 | Payload, zero padded |

For SPI/I2C/CAN the encoder replaces byte 1 with mode 3/4/5 **after** calculating
the checksum. USB and UART do not make that replacement. Successful send advances
sequence by two; failure closes the vendor handle without advancing it. The
portable codec rejects oversize payloads instead of silently truncating them.

For unnumbered HID reports, **HIDAPI output has 65 bytes: `0x00` then the packet**.
HIDAPI interrupt input has **64 bytes without a placeholder report ID**. A real
leading zero in input is retained, not stripped. This matches both the inspected
vendor wrapper and [HIDAPI's documented API](https://libusb.info/hidapi/group__API.html).
Do not use `hid_get_input_report`/feature-report conventions for `hid_read`.
The [macOS backend](https://github.com/libusb/hidapi/blob/master/mac/hid.c)
removes an output's zero placeholder before `IOHIDDeviceSetReport`, while returning
the caller's output length. This is distinct from the native IOKit convention;
no macOS-specific extra zero should be added or removed around HIDAPI.

The fresh USB connection request is:

```text
packet:       a0 00 b2 00 12 00 00 00 [56 zero bytes]
hidapi write: 00 a0 00 b2 00 12 00 00 00 [56 zero bytes]
```

Responses place sequence at offset 4, an opaque 12-byte header before payload,
and at most 52 payload bytes. Undocumented response-header/checksum fields are
retained rather than decoded using the request's checksum rules. Fixed report
length and sequence checks do not provide cryptographic integrity.

## Identification and read-only adapter boundaries

The vendor bootstraps with A0 at sequence 18, reads thirteen LE32 payload words,
and requires word 12 to be `0x13572468`. On successful bootstrap it resets its
sequence to 3. The adapter also requires an explicitly supplied expected PDID;
it never selects fallback flash geometry for an unknown device. The other A0
words are exposed without inventing capacity/ROM-version meanings.

D2 carries `{address, length}` as two LE32 words. The adapter permits only the
M3351 CONFIG addresses already documented in this workspace and length 4. It
requires the reply sequence to match request sequence plus one and invalidates
the session on any send/read/protocol error. It performs no retries, automatic
reopen or configuration writes. Parsing a CONFIG value does not prove the ROM
read has no side effects or that the device supports this entry route.

The follow-up `read-audit/FINDINGS.md` traces both observed D2 producers:
`0x0040A810` first sends A0, then four-byte CONFIG reads; `0x0040A8A0` sends
eight-byte CONFIG reads. Neither accepts an arbitrary memory address. **No
APROM-read contract is established**, even though the low-level encoder can
represent arbitrary bytes. The parser's 52-byte USB payload ceiling is not a
proven APROM read size; it silently truncates larger requested lengths while
returning true. Both CONFIG helpers can also return true when sending fails.
Twenty-five memory-only emulation controls reproduce the read addresses, sparse
output layout, truncation and failure branches. These findings rule out using
the vendor Boolean result as proof of a complete backup; they do not authorize
exploratory APROM reads, additional CONFIG addresses or a live ROM handshake.

## Vendor defects and proposed upstream fixes

### Confirmed false-success branch

The single-CONFIG-write wrapper at `0x0040A490` initializes its result true. At
`0x0040A4D8`, a failed encoder/send branches to `0x0040A534`, returning that true
value without acknowledgement or readback. This is **reproduced in isolated CPU
emulation on all five transport modes**, not just inferred from assembly.

Redirecting that branch in emulator memory to the existing failure path at
`0x0040A529` returns false under the same injected send failure. Original and
control runs produce identical outgoing bytes and handle-close behavior. The
archive and executable on disk are unchanged. This experiment validates only
this failure edge, not every success/failure branch or a release-ready EXE patch.

The source-level correction is to return failure immediately if sending fails,
then require a valid acknowledgement and independent device readback before
claiming that persistent configuration matches the requested value. The same
pattern occurs in other wrappers and needs a source-level audit. No production
binary patch or configuration-write API is supplied here.

### Other source-established weaknesses

- Normal GUI callers disable response sequence verification for A0/D2. Emulation
  accepts a stale sequence with that check off and rejects it with the check on.
  The adapter retains the vendor's bootstrap exception but checks subsequent D2
  replies and refuses unknown IDs, partial reads and short writes.
- Configuration verification in the GUI copies desired data into its host cache
  and compares cached values; that is not independent device readback.
- The serial-open routine requests DTR enabled even with the reset checkbox off;
  serial synchronization can assert BREAK. SPI/I2C/CAN use bridge-control 5A.
  Unchecking reset therefore does not establish a side-effect-free connection.
- Normal GUI Connect and Start are distinct, but an ownerless automation path
  can dispatch selected programming operations after identification. The new
  adapter does not reproduce that dispatcher.

None of these findings proves the cause of the earlier target flash timeout or
of another workspace's reported payload-dependent CDC failure.

## Flash failure: stronger mechanism, not proven root cause

The two APROM FLMs have identical 1,544-byte executable sections; KI versus KJ
changes geometry, not CPU initialization. The shared code has stackless Init and
EraseSector, but ProgramPage begins by pushing 20 bytes. pyOCD places its initial
stack at `0x200019F0` and its lower allocation at `0x20000000`.

The second-failure snapshot has `CFSR=0x00100001`: **STKOF plus IACCVIOL**.
`PC=0xEFFFFFFE` is the architecture's lockup address, not a recovered FLM faulting
instruction. An inherited high Secure MSP limit is a plausible explanation for
successful erase followed by a ProgramPage prologue fault. Historical limit
reads used unsupported names; no actual limit value was captured. Interrupt,
vector and MPU alternatives have not been eliminated.

`tools/flash.py` now rejects an unconfirmed/non-Secure state, PSP-selected or
non-Thumb execution, incompatible/unreadable Secure MSP limit, invalid algorithm
stack allocation, or existing STKOF **before any algorithm or erase**. It uses
pyOCD's actual register name `msplim_s`. It does not change stack limits, clear
faults, switch stack/security state, reset, or treat this guard as recovery.
Masking IRQs and disabling MPU alone do not disable stack-limit checking.
The guard also rejects DSCSR.SBRSELEN (an explicit debug register-bank override),
requires DSCSR.CDS to agree with the Secure execution-state report, checks
`control` against `control_s`, and checks xPSR's exception field against Thread
mode. It never writes the bank selector. All pack debug sequences are disabled,
including any optional flash-done callback; the pinned pack itself defines only
DebugPortStart and DebugPortStop.

### Executed Cortex-M33 stack reproduction

`tests/tools/run_flash_context.py` executes the exact two-byte ProgramPage
prologue (`f0 b5`, `push {r4-r7,lr}`) from the hash-checked KJ FLM in QEMU's
Cortex-M33 model. It uses the recorded algorithm SP `0x200019F0` and instruction
address `0x20003CA8`, but a **synthetic** high limit `0x20007C00`, within the
AN505 model's 32-KiB SRAM. That is not a measurement of this board's MSPLIM.

Executed controls with QEMU 11.1.2 and SDK GCC 14.3.0:

| Control | Result |
|---|---|
| Limit zero | Stackless control and vendor push return normally |
| High limit, no guard | Stackless control returns; vendor push triggers HardFault, CFSR `0x00100000`, HFSR `0x40000000`, MSP raised to the limit |
| Same high limit, guard | Rejected before the vendor push |

The model runs **only the prologue**, followed by a return; it never emulates
M3351 flash hardware, invokes the real erase/program body, or connects to USB.
The reproducer's fault handler resets its own simulated stack solely to print
results; that recovery code is not present in the flasher. This demonstrates a
mechanism for erase-before-program failure and validates the guard's purpose.
It does **not** reproduce the historical IACCVIOL bit, prove historical fault
chronology, recover the physical target, or qualify a complete flash operation.
Results and firmware hashes are in `build/flash-context/results.json`; invocation
is documented in `tests/tools/README.md`.

Detailed source/hash evidence: `flm-audit/FINDINGS.md` and
`.embedder/hardware/results/flm-comparison/findings.txt`.

## Native UART adapter and 2026-10-29 physical checks

`BootloaderUartSession` accepts an already-open pySerial-compatible handle. It
sends the vendor's 62 unframed `0x61` bytes and requires one `0x41` before the
64-byte A0 identification request. UART does not prepend a HID report ID. It
retains the verified A0/CONFIG framing, expected-PDID check and strict subsequent
sequence matching. There is no arbitrary-memory, erase or programming API.

Partial UART writes and reads are accumulated with absolute deadlines. A write
has a one-second budget; synchronization has a one-second read budget; framed
replies have a five-second read budget. The larger synchronization budget than
the EXE's nominal 10-ms argument accommodates host scheduling without sending
extra commands. Previous handle timeout settings are restored. Expired replies,
zero progress, malformed results and transport errors invalidate the session;
no retry, reopen or BREAK is generated. The adapter itself never changes
DTR/RTS. The caller owns those controls and must not describe open/close as
passive. Unlike the vendor GUI, it does not reopen between sync and A0.

The hardware-arbitrated diagnostic is
`.embedder/hardware/cases/m3351-flash-lockup/rom_uart_check.py`. It selects VCOM by
exact Nu-Link VID/PID and full serial, not a hardcoded port or a vendor ID alone.
It opens 115200 8-N-1, no flow control, DTR enabled, RTS disabled. Those explicit
line changes and optional hardware reset were authorized by the user. There is
no BREAK, config read, flash operation or fallback command in this diagnostic.

Observed on this Mac:

- Nu-Link `0416:2004`, serial `13010000003800F1047546CF0000065D`, exposes
  `/dev/cu.usbmodem1202`. Opening it succeeded; synchronization timed out.
- A second attempt opened VCOM first, issued one probe-controlled hardware
  reset and sent synchronization: also timed out. A third comparison removed
  pyOCD's post-reset wait and retained the probe connection until synchronization
  completed; it also timed out. None reached A0.
- These results prove port opening and executing a host write, not arrival at
  the MCU UART pins, enabled ROM ISP or a working return path. The physical
  ICESW2 routing, ROM-entry conditions, reset delivery and CONFIG3 enablement
  remain unresolved. A successful reset API call is not a measured reset pin.
- The separate MEM-AP snapshot still reports lockup and `DAUTHSTATUS=0xAF`;
  disabling debugging then hardware-resetting did not restore memory access.
- A standard 100-kHz under-reset connection with all pack sequences disabled and
  the correct KJ target also remained in lockup with unreadable peripherals.
  No RAM algorithm ran in any of these attempts.

Evidence: hardware tool logs `script-call_b1OfG9MEZGLtih50kNu16dO6.log`,
`script-call_9W7Nz6ZviG3eSK4rqnOoVJMb.log` and
`script-call_wZ8SZaWHydC5uJBrwe77DQCq.log`, plus timestamped `rom-uart-*.json`
under `.embedder/hardware/results/`. The native pseudo-terminal regression
validates pySerial framing and reply parsing on macOS; it does not substitute
for the failed physical ROM handshake.

## Physical validation remains pending

An earlier OS-only inventory had no `IOUSBHostDevice` instances; the Nu-Link
has since reappeared. Empty valid `ioreg` output is an empty inventory, not a
parser failure. Nonempty malformed output still fails explicitly.

No matching MaskROM interface, stable target access, full fresh 1-MiB backup or
preserving recovery entry has been demonstrated. A0/D2's target-side effects and
entry requirements remain unresolved. Do not send exploratory traffic to the
Nu-Link HID or VCOM merely because it shares a vendor ID with a bootloader.
Keep the original lower-half backup unchanged; do not erase unbacked upper
APROM, LDROM, Data Flash, CONFIG, OTP or security state.

After an applicable recovery is reviewed and succeeds, the separate HIL gates
in `docs/validation.md` still apply: verify all preserved bytes/configuration,
boot the intended image, then exercise native J3 CDC/ECM and repeated reconnects.
Offline codec tests, PE emulation and OS enumeration are not physical USB proof.
