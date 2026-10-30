# Validation record — 2026-10-28

## Acceptance status

**Software implementation is present; programming access is recovered and
verified (2026-10-29); physical USB acceptance is still pending.**
The board is accessed through a verified Nu-Link2 CMSIS-DAP probe. The user has
confirmed **M3351KJCAE (1 MiB APROM)**. Earlier operations incorrectly selected
M3351KICAE and an interrupted programming left APROM page 0 erased, which is what
made the part appear locked (see the 2026-10-29 resolution section at the end).
The full 1 MiB APROM, LDROM, Data Flash and CONFIG words have since been backed
up, `build/server` has been sector-programmed and verified with
`tools/flash.py --program --halt-at-reset-vector --boot`, and the board boots it
(UART0 `Modbus server ready: RTU id10, TCP id1 port502`; J3 enumerates as
`0416:B002`). Native ACM/ECM port creation on macOS, RTU/TCP board
interoperability, reconnect, cold boot, 1,000-transaction runs and measured
stack/pool headroom remain pending. Do not interpret host/QEMU results as HIL.

## Inputs and host dependencies

- Host: macOS arm64, Python 3.12.16 in project `.venv` (not Embedder's environment).
- Zephyr: `5c71a733110403a2e01f6cabd922b5f0198e9981` (reports 4.5.0-rc3).
- CMSIS: `512cc7e895e8491696b61f7ba8066b4a182569b8`.
- CMSIS 6: `1c1840af7a7e757d6e2fec3ddb0e5ce0dfcc93c8`.
- Nuvoton HAL: `0f411a85da7d17a612d54450f608f4d30cdb971f`.
- Modbus upstream: `9c022fd2538edb5b53e2e07c98ebbe9a4685546c`.
- SDK: Zephyr 1.0.1 macOS-aarch64; ARM GCC 14.3.0, GDB 16.2 execute successfully.
- west 1.5.0, pyOCD 0.46.0; vendor NuMicroM33_DFP 1.0.6.
- CMake 4.4.4, Ninja 1.13.2, dtc 1.8.1; Homebrew gperf/QEMU installed.
- PyModbus 3.16.1, pyserial 3.5, pytest 9.2.0. `pip check` found no broken requirements.
- Exact source locks: `west.yml`; PC requirements: `requirements-test.txt`;
  build requirements: `tools/requirements-build.txt`. Zephyr Python requirements
  use ranges; a complete transitive environment is not implied.

The original root-owned managed GDB cache prevented hardware-script startup.
After the user-approved ownership repair, server-arbitrated scripts execute.
No CMSIS-DAP serial/COM interface is required for programming; no diagnostics
UART was exposed in the observed serial inventory.

## Software checks

### Portable core

Parent reran `cmake --build tests/protocol/build` and
`ctest --test-dir tests/protocol/build --output-on-failure`: **10/10 passed**.
This build enables AddressSanitizer and UndefinedBehaviorSanitizer with Apple
Clang. The suite includes all supported FCs, maps, capacities, malformed shapes,
CRC/bit-order vectors, exhaustive bit ranges and randomized transactions.
See `tests/protocol/README.md` for commands and the upstream derivation report.

### PC harness

Parent reran `.venv/bin/python -m pytest tests/tools -q`: **87/87 passed**.
Tests include actual PyModbus TCP loopback and RTU pseudo-terminal exchanges,
raw framing checks, both roles, all maps and the opt-in >64-byte cases. They
verify the test harness on the host, not physical target behavior.
See `tests/tools/README.md` and `docs/pc-tests.md`.

### Zephyr emulation

`tests/zephyr/run_qemu.py` executes real Zephyr on `qemu_cortex_m3` with an
interrupt-UART test device and actual IPv4 loopback for TCP. Final profiles
contain **13** RTU cases or **19** combined TCP+RTU cases at each nominal buffer
size, including real 125-register TCP reads in the enlarged profile. The expiry
test now waits for bounded, observed worker-state transitions rather than
assuming a fixed sleep completes them; a new delayed-worker test covers arrivals
just before and exactly at the assembly deadline. Timeout/CRC/data assertions
remain enforced. No runtime algorithm change or proven historical root cause
is claimed for the earlier intermittent failure. Parent independently rebuilt
and ran all four final configurations: **13/13 RTU**, **13/13 enlarged RTU**,
**19/19 TCP+RTU**, **19/19 enlarged TCP+RTU** — **64/64 passed**. Default RTU
also passed **20 consecutive full-suite runs (260/260 cases)**. Final run logs
and repeat evidence are under `tests/zephyr/build-*/final-*.log`.
Twister was not the runner used: optional `junitparser` was missing. No analyzer
configuration was weakened to hide this. The bounded standard-library runner
uses the actual ztest success/failure banners.

### CDC reconnect isolation

The SDK correction is now implemented in `patches/zephyr-cdc-session-isolation.patch`
and integrated by `src/usb.c`. It blocks new UART admission at a session boundary,
purges retained FIFOs, cancels old endpoint transfers and waits for all owned
buffers to return before reopening. A synchronous driver boundary callback avoids
losing a rapid DTR close/reopen through asynchronous line-state messages. DTR
closure resets RTU only; it does not require a terminal for TCP startup.

Parent reran `sh tests/cdc/run.sh`: **20/20 passed on each of system and dedicated
workqueues**. Tests compile the actual patched CDC driver with a fake UDC; they
cover delayed successful completion of in-flight payloads, queued/partly consumed
RX, rapid DTR transitions, submission races, failures and repeated reconnects.
These are software ownership tests, not physical USB qualification. See
`tests/cdc/README.md` and the session contract in `docs/migration.md`.

### M3351 target builds

Upstream hello-world, CDC ACM sample and zperf CDC ECM sample all compiled and
linked in separate baseline directories. The first ECM configuration attempt
failed because its overlay file had not yet been written; rerunning with the
existing file succeeded. These are **compile-only** driver baselines.

Application server, client, separate-region and large-buffer profiles have all
linked for `numaker_m3351ki/m335xxx`. Following the user's KJ chip confirmation,
the incorrect 512 KiB override is removed: builds retain the upstream 1 MiB
APROM/128 KiB RAM map, remove unused MCUboot partitions, and link directly at
address zero. UART0 remains the console;
ACM carries no application log output. Final merged config/DTS checks, footprints,
source hashes, firmware hashes and software-test evidence are recorded in
`build/validation.json`.

Final ELF inspection confirmed these static footprints (not runtime stack/pool
measurements):

| Profile | Flash bytes / 1,048,576 | RAM bytes / 131,072 |
|---|---:|---:|
| server | 115,064 | 73,452 |
| client | 115,936 | 73,452 |
| separate | 115,116 | 73,452 |
| large | 115,064 | 77,484 |

`build/validation.json` records firmware/config/DTS hashes and the resolved
configuration checks, including both USB classes, UART0 console, direct APROM
linking, both Modbus transports and disabled Zephyr Modbus subsystem. The server
also passed a complete `cmake --build build/server --clean-first` rebuild.
Nominal RTU capacity is 128 bytes (256 for large); TCP reserves four extra bytes
for equivalent PDU capacity, giving 132/260-byte TCP buffers.

Clean-build integration exposed and fixed missing generated-header ordering and
application-side static-library linking; Ethernet L2 had to be explicitly enabled.
The application uses Zephyr's test RNG because the pinned M3351 integration has
no entropy driver; the NOT_SECURE warning is expected and documented. It is an
isolated bench demo, **not a production-security configuration**.

## Probe, backup and failed programming evidence

| Item | Observation |
|---|---|
| Probe | Nu-Link2 CMSIS-DAP, USB `0416:2004` |
| Probe serial | `13010000003800F1047546CF0000065D` |
| Confirmed physical device | User-confirmed `M3351KJCAE`, 1 MiB APROM |
| Current configured target | `m3351kjcae`, Nuvoton NuMicroM33_DFP 1.0.6, `M3351_AP_1M.FLM`; connection-only hardware check failed before programming |
| Earlier incorrect target | `m3351kicae`, `M3351_AP_512.FLM`; both historical programming attempts used this selection |
| SYS_PDID | Captured `0x03302140`; Nuvoton's pinned OpenOCD table maps this to **M3351KJCAE** (KICAE is `0x03302141`) |
| CPUID | `0x411fd210`, Cortex-M33 |
| APROM backup | 524,288 bytes; SP `0x20020000`, reset vector `0x289` |
| Backup SHA256 | `cdc14f595cf29c2877cc9b11bc564df62b66e3338a0a77ea35ba533aba0b93d3` |
| Backup path | `.embedder/hardware/results/backup-20261028T201055Z/aprom.bin` |
| Backup scope | Lower 512 KiB of 1 MiB APROM only; upper half, option words, LDROM, data flash and security settings were not backed up |

Two CDC-reference baseline programming attempts were made; neither programmed a
working image. Both used the incorrectly selected KI target and 512 KiB FLM on
the now-confirmed KJ chip. The mismatch is established, but its causal role in
the timeout has not been isolated. The commands and observations below are
historical, not instructions to repeat them. No composite Modbus image has been
submitted to the programmer.

1. Original command: `.venv/bin/pyocd load --target m3351kicae --uid
   13010000003800F1047546CF0000065D --erase sector -O auto_unlock=false
   build/cdc-baseline/zephyr/zephyr.elf`. It reported reset/halt LOCKUP followed by
   `Memory transfer fault ... @ 0x20003c00-0x20003fff`. Full 512 KiB comparison
   afterward matched the original backup. This fact applies only to that attempt.
2. After a confirmed cold start, raw attach read **DAUTHSTATUS=0xFF** and halted
   successfully. The exact DFP `DebugPortStart` sequence pulses nRESET even in
   attach mode and then waits 72.8 ms. A pyOCD user-script diagnostic replaced
   only that step with the standard debug-power handshake. Reset-free attach
   reached HALTED with the vendor's KICAE memory map and unchanged FLM.
3. The second command added `--script tools/pyocd_attach.py -M attach`,
   `-O load.pre_reset=off -O keep_unwritten=true -O resume_on_disconnect=false`,
   `-O cache.enable_memory=false`, and `--no-reset` to the same incorrectly selected KI-target,
   sector-only command. Output reached **Erasing...**, **Programming...**, then
   **flash program page timed out**. This erased application sectors; it did not
   leave the original image intact. Readback at address zero was all `FF`.
   The lower-512-KiB readback SHA256 became
   `043e238a765f7cfbc62596a50e53c8ffb6b188a99357b0ebede251725d67589f`.
4. Immediately afterward, **DAUTHSTATUS remained 0xFF** and the core was halted,
   but `CFSR=0x00100001`, `HFSR=0x40000000`, PC `0xEFFFFFFE`, xPSR `0x41000003`
   showed a HardFault. `FMC_ISPADDR=0xE000`, `ISPCMD=0x22`, `ISPTRG=0`,
   `ISPSTS=0x20000104`; SRAM/ECC status was zero. The attach path preserves old
   CPU/interrupt state, unlike reset-and-halt; a RAM-algorithm context problem is
   plausible, not a conclusively isolated cause. A later hook revision uses
   pyOCD's emulated core reset and masks interrupts, but **has not been validated**:
   subsequent attempts stopped at the access guard, before that code executed.
5. Booting/resuming the incomplete image now produces LOCKUP with `DAUTHSTATUS=0xAF`
   and inaccessible APROM/SRAM. Lower-clock under-reset, cold power cycle,
   hardware reset with vector catch and system reset with vector catch did not
    restore usable access. No further erase/program operation was attempted.
6. A final non-writing diagnostic used pyOCD's supported
   `pack.debug_sequences.disabled_sequences=[DebugPortStart]` with `under-reset`
   at 100 kHz. The log confirms that only that sequence was disabled. Core
   discovery succeeded, but the result remained `State.LOCKUP`, `DHCSR=0x80001`,
   `DAUTHSTATUS=0xAF`, with PDID/peripheral reads faulting. Removing that reset
   sequence alone did not recover the current incomplete-image state. Evidence:
   `.embedder/hardware/results/connect-under-reset-without-port-start.json`
   and the corresponding `.log`. This test did not invoke a flash algorithm.

### Corrected KJ follow-up — 21:42–21:45 UTC

- pyOCD 0.46.0 again enumerated the expected Nu-Link2 CMSIS-DAP serial.
- A passive MEM-AP snapshot, without reset or halt, still returned
  `DHCSR=0x80001`, `DAUTHSTATUS=0xAF`; APROM, SRAM and secure peripheral reads
  faulted. It could not obtain a new backup or configuration readback.
- One connection-only check used the corrected `m3351kjcae` target, vendor DFP
  sequences, standard under-reset at 100 kHz, and `auto_unlock=false`. The
  resolved map was 1 MiB APROM/128 KiB SRAM, but the core remained in LOCKUP with
  the same authentication status and memory faults. No flash algorithm was run,
  and no erase, programming or security changes were requested. Full log:
  `/Users/embedder/.embedder/hardware/f0d37af793f94e7b/script-call_rMGjY44HNBHbhOem7TUUobhZ.log`.
- Offline FLM comparison found identical 1,544-byte `PrgCode` sections in
  `M3351_AP_512.FLM` and `M3351_AP_1M.FLM` (SHA256
  `92fe8010b78cca2f21758e07a0bb184dfa12252f2a5b9493e60d6fabac06c14f`).
  Device descriptors differ. The wrong prior memory description is confirmed,
  but a different executable algorithm body does not explain the earlier fault.
- Connection diagnostic results now use timestamped KJ filenames to preserve
  the historical KI evidence. Physical baseline/composite programming remains
  blocked on establishing a safe, accessible target state.

### Non-secure transaction check — 21:51 UTC

A distinct passive check used pyOCD's `ap.hnonsec_lock(1)` and the non-secure
aliases documented in the M3351 memory map (datasheet §6.2.6–6.2.7):

| Requested read | Result |
|---|---|
| APROM_NS `0x10000000–0x1000000F` | `Memory transfer fault (SWD/JTAG communication failure (FAULT ACK))` |
| SRAM_NS `0x30000000–0x3000000F` | `Memory transfer fault (SWD/JTAG communication failure (FAULT ACK))` |

After each read, AP CSW was `0x43800052` (HNONSEC bit 30 set), and DP CTRL/STAT
was `0xf0000040`. This excludes merely using the wrong Secure transaction
attribute as the explanation for these two failed alias reads. It does not
identify the underlying device-state cause or prove a permanent security lock.
No reset, halt, memory write, flash algorithm, erase or security change was
requested. No new full-device backup could be obtained.

Evidence: `.embedder/hardware/results/nonsecure-alias-20261028T215125587559Z.json`.
The reproducible check is the `nonsecure` profile of
`.embedder/hardware/cases/m3351-flash-lockup/inspect_target.py`; it refuses a
profile combining this check with reset/halt options. Further target operations
remain blocked pending a reviewed recovery procedure.

**Security conclusion:** 0xAF describes a restricted state at that instant, but
neither a permanent security lock nor security as the original programming root
cause is established. Full 0xFF authorization, successful halt and sector erase
were observed without authentication or security changes. Before the timeout,
`APWPROT0=APWPROT1=0`, `XOMSTS=0`, `SCU_SRAMNSSET=0`, and `SCU_FNSADDR=0x100000`
were readable. The Nuvoton headers define zero APWPROT bits as unprotected and
zero XOM status as inactive. Direct reads of CONFIG0/CONFIG12 faulted; these do
**not** establish their values. Vendor `FMC_ReadConfig` reads configuration via
ISP READ commands, not ordinary memory dereference. A successful configuration
word readback was not obtained.

**Recovery boundary:** preserve the original APROM backup and remaining device
contents. No cited Nuvoton reference establishes a non-erasing recovery-entry
procedure through Nu-Link2 CMSIS-DAP for this current lockup state. Obtain a
written M3351-specific procedure from Nuvoton before further target operations;
blank-chip support alone does not prove that a tool will recover this condition.
The user confirms **NuMaker M3351KI V1.2** (board marking), **M3351KJCAE**
(MCU), and **macOS only**. The saved PDID is now independently matched to KJCAE by the manufacturer's device table; no repeat package-marking request is needed.
The prior KI target/algorithm selection was incorrect. Whether that mismatch
caused the timeout is unproven; correcting the configuration does not by itself
establish that the current lockup can be safely recovered.

If an appropriate vendor tool/host becomes available, require a reviewed
connection procedure before identifying the exact MCU and reading
configuration/status with automatic programming disabled. Request a precisely
range-limited restoration/programming procedure with readback and preservation
verification; "APROM-only" alone does not protect the unbacked upper APROM.
No mass erase, security change, option-word write, alternate-SKU FLM or
probe-firmware update is authorized or shown necessary. If vendor guidance
requires any such operation, stop and explain its exact memory/security effects
and backup/restore limitations first. The APROM-only backup cannot restore lost
option words, keys, OTP, LDROM or data flash.
The NuMicro ICP Programming Tool Guide V3.24 §1.1 explicitly supports blank
chips through Nu-Link; §2.1 requires Windows 7 or later. This is product support,
not proof of safe recovery in the current state. Once connection effects are
reviewed, save the identified part, all accessible memory and configuration
before selecting a verified range-limited operation. Decline any prompt to
unlock, erase the whole chip, change boot/security configuration or update the
probe until separately reviewed.
The Nu-Link Command Tool manual §2.3.3 describes distinct APROM write, verify and
readback operations, so a whole-chip erase is not inherently part of its example.

Detailed snapshots and full diagnostic logs are retained under
`.embedder/hardware/results/`; the open investigation is
`.embedder/hardware/cases/m3351-flash-lockup/CASE.md`. `tools/pyocd_attach.py` is an
explicit, guarded **diagnostic experiment, not a qualified programming procedure**.
Do not use stock OpenOCD's old Cortex-M0 `numicro.cfg` or blindly invoke the
board's `m3351kjcae` runner. That selector now matches the confirmed chip, but
successful recovery/programming through it is still unverified.

References: the selected Nuvoton DFP `DebugPortStart`/memory/FLM declarations,
pinned Nuvoton `fmc_reg.h` APWPROT/XOM descriptions, `StdDriver/src/fmc.c`
`FMC_ReadConfig`/`FMC_Read`, M3351 TRM security/flash sections, and
[Arm v8-M debug authentication](https://support.arm.com/documentation/100734/0100/Debug-for-ARMv8-M/Debug-registers/DAUTHSTATUS).
M2351 DPM details are not assumed to apply to M3351.

### Offline programming audit and support evidence

The installed distribution metadata identifies **pyOCD 0.46.0**, installed by
pip, with no `direct_url.json` identifying a Nuvoton fork checkout. This is not
proof of a vendor-qualified debugger distribution and must not be described as
one. The local pack and both FLMs were rehashed offline:

| Artifact | SHA-256 |
|---|---|
| `.deps/packs/Nuvoton.NuMicroM33_DFP.1.0.6.pack` | `0aae782356a261b976169fb677a5785c8647b5e0a0a93fa1632fb71a04b2dde2` |
| `Flash/M3351_AP_512.FLM` used in the failed attempts | `8729859484afaa838c46bc7094fdcd6f4f29f908cadac5b3d6d901cb6928d473` |
| `Flash/M3351_AP_1M.FLM` selected now, not executed | `6ad56e7e085dae4ed3f61abd6bcc2edde2ffd53424ca28a6fedc6d743b369717` |

Both FLMs have the same code section and image-local Thumb symbol values:
`Init=0x1`, `UnInit=0xCD`, `EraseSector=0x103`, `ProgramPage=0x2B5`.
These are **not runtime PC addresses**. The post-failure capture records
`PC=0xEFFFFFFE`, `LR=0xFFFFFFF9`, `xPSR=0x41000003`, and stack pointer
`0x2001FC00`; it does not identify an instruction inside the SRAM-resident FLM.
`LR=0xFFFFFFF9` is an exception-return value, not evidence that ProgramPage
returned normally. No instruction trace or verified stacked fault PC is available
in that capture, so an exact failing FLM source line cannot be assigned.

The complete saved stderr for the **second** programming attempt is:

```text
0000385 I Loading /Users/embedder/Desktop/Nuvoton/build/cdc-baseline/zephyr/zephyr.elf [load_cmd]
0000389 I Erasing... [loader]
0000558 I Programming... [loader]
0010681 C flash program page timed out [__main__]
```

The flash tool reported exit code 1. This is a **programming-stage timeout after
erase**, not a reported erase timeout. `FMC_ISPADDR=0xE000` and `ISPCMD=0x22`
are the subsequently sampled controller state; they do not by themselves identify
the timed-out page or prove that sector `0xE000` was the failing erase operation.
Do not promote the last controller address into a complete erase/write manifest.
The first attempt's unchanged-backup result in `post-failed-flash.json` must not
be applied to this later failed attempt.

Evidence locations:

- First attempt stderr: host log
  `/Users/embedder/.embedder/shell/f0d37af793f94e7b/task_mvslo8ow_57c5c3.log`.
- Saved second flash result/error and FLM audit: host log
  `/Users/embedder/.embedder/shell/f0d37af793f94e7b/task_mvsoup40_991221.log`
  (flash-result excerpt, not a new execution).
- Later halted register capture: host log
  `/Users/embedder/.embedder/hardware/f0d37af793f94e7b/script-call_9z2TSWBPtTpkGcA07qAXIoAW.log`.
- Offline pack/ELF/hash recheck: host log
  `/Users/embedder/.embedder/shell/f0d37af793f94e7b/task_mvspetpb_16c062.log`.

The pack's `DebugPortStart` asserts nRESET for 8 ms, releases it and delays
72.8 ms before continuing debug-port setup. Its `DebugPortStop` writes DP ABORT,
clears core debug through `DHCSR=0xA05F0000`, then powers down the debug port.
Thus neither `connect_mode=attach`, `auto_unlock=false`, nor `--no-reset` alone
makes the complete session free of target-side effects. The second attempt used
an explicit hook to replace connection-time debug-port startup; later hook
revisions must not be represented as the script executed in that attempt.
The subsequent under-reset test that disabled only `DebugPortStart` still failed,
so removing that pulse is not an established recovery procedure.

Current local `board.cmake`, generated runner YAML and `pyocd.yaml` select KJCAE.
That does not retroactively change the explicit `--target m3351kicae` passed in
both failed commands. The currently retained CDC baseline ELF has file-backed
physical load intervals `0x00000000–0x0000E04F`,
`0x0000E050–0x0000E613`, and `0x0000E614–0x0000E617`; the server ELF's
file-backed flash interval is `0x00000000–0x0001C177`.
These are **current artifact load ranges**, not verified historical erase
ranges or permission to program them. RAM-only segments have no file payload.
The current baseline ELF hash is
`d11d7bdfd41832dbdf13175b5a6869ecf06ac542fbef8afc033fcf40c738fa98`;
the current KJ server ELF hash is
`ab06cd87687aac3110255c68613e4439b774332ae20c1ae30a7fd39855aae79f`.
No inference of historical artifact identity is made without an execution-time
hash. The original backup was also rehashed offline and remains unchanged.

## USB identity investigation and selected local demo

- Live host inventory showed the debugger, hubs and an unrelated ASIX adapter;
  no native application USB device/serial/network interface was observed.
- An **offline heuristic** found an original APROM device descriptor at `0x4a6a`
  with `0416:B001`; a nearby single HID boot-mouse interface corroborates its class.
  This is not observed enumeration and is not reused for CDC.
- The pinned Zephyr samples use `2FE3:0001`, restricted to samples.
- M3351 BSP V3.00.002 `USBD_VCOM_SerialEmulator` uses `0416:B002`.
  After investigation, the user explicitly requested an existing development
  configuration for this local demo. `config/usb-identity.conf` selects that
  identity locally and is excluded from Git; zero defaults/guard remain in source.
- No VID ownership, manufacturer grant, production allocation or right to ship
  with sample IDs is asserted. Nuvoton advises customer applications to use their
  own IDs. The migrated composite is not the original vendor VCOM example.

Source: [M3351 BSP V3.00.002 VCOM header](https://gitlab.com/OpenNuvoton/NuMicro-M33-Family/M3351BSP/-/raw/V3.00.002/SampleCode/StdDriver/USBD_VCOM_SerialEmulator/vcom_serial.h).

## Passive host and identity audit — 2026-10-28, 22:16–22:18 UTC

Only macOS IORegistry queries, local file hashing and offline source inspection
were performed. No probe/serial handle was opened, serial control line changed,
or target reset/connection/program operation requested.

- Saved `SYS_PDID=0x03302140` matches `M3351KJCAE` in Nuvoton's
  [pinned device table, lines 336/341](https://github.com/OpenNuvoton/OpenOCD-Nuvoton-CMSIS-DAP/blob/ad7b6fa42ea38f93246429c72ee46918acae789b/src/flash/nor/numicro_dap.c#L336).
  KICAE has PDID `0x03302141`. This corroborates the user's package identification,
  correcting the earlier claim that the captured PDID could not distinguish them.
  The [KJ product specification](https://www.nuvoton.com/products/microcontrollers/arm-cortex-m33-mcus/m3351-series/m3351kjcae/index.html)
  lists 1024 KiB flash, 128 KiB ECC SRAM and Full-Speed USB.
- The only saved binary backup found under the recorded results is the original
  524,288-byte `aprom.bin`; its SHA256 remains
  `cdc14f595cf29c2877cc9b11bc564df62b66e3338a0a77ea35ba533aba0b93d3`.
  It covers **`0x00000000–0x0007FFFF` inclusive**. No original image is available
  for **`0x00080000–0x000FFFFF`**; never fill/pad this range and call it a restoration.
- The OS now exposes **`/dev/cu.usbmodem1102`**, under the same Nu-Link2
  `0416:2004`, serial `13010000003800F1047546CF0000065D`. IOService ancestry is
  Nu-Link2 → USB interface → AppleUSBACMData → IOSerialBSDClient. It is **probe
  VCOM**, not the target J3 CDC application. This supersedes the earlier
  no-serial-port observation; it does not prove UART wiring, switch positions,
  boot-ROM ISP enablement or a successful handshake.
- Probe interfaces are: vendor-specific debug interface 0; CDC ACM control/data
  1/2; HID 3; WebUSB 4; mass storage 5. Probe HID/MSC must not be mistaken for
  target MaskROM HID or used to copy a firmware image. No separate target CDC,
  HID or ECM device is present in the OS USB snapshot. Existing ASIX Ethernet
  belongs to a different device.
- OS `bcdDevice=0` is a descriptor field, **not a decoded probe firmware version**.
  No firmware query was issued in this passive audit.

Evidence: `.embedder/hardware/results/host-usb-passive-20261028T221626Z.json`
and `.embedder/hardware/results/host-interface-and-backup-audit.json`.

## MaskROM ISP candidate — supported device, recovery entry still blocked

### V1.04 evidence supersedes the earlier support uncertainty

The [official Boot Loader ISP Tool download](https://www.nuvoton.com/resource-download.jsp?tp_GUID=SW132022071806572776)
contains `NuvoISP_BL_V1.04.exe`, a user manual and a release-history PDF.
The release-history **Supported Microcontroller** table, page 4, explicitly lists
**M3351KJCAE**. The complete table was checked in magnified PDF tiles. This is
positive device-support evidence, not merely an inference from the existence of
MaskROM or the ordinary ISPTool v4.17 device list. It does not establish recovery
from this particular invalid-image/debug state or compatibility with every silicon
or ROM revision. The release history does not claim that M3351 support was newly
added in V1.04.

Offline executable inspection found PE machine `0x014c` (x86), PE32 optional header
`0x010b`, subsystem 2 (Windows GUI), Windows DLL references, and an M3351KJCAE
string. This shipped binary is **not a native macOS/arm64 executable**. No Wine,
VM, USB passthrough, installation or execution was attempted. A supported macOS
MaskROM client or protocol has not been identified.

| Offline artifact | SHA-256 |
|---|---|
| Official V1.04 ZIP | `4a7cfe5cd0207fa99f052ee1038b85c9110684cab9fb9fda2f594867c80ff5a7` |
| `NuvoISP_BL_V1.04.exe` | `aed05e31a6a73c760076218dcfbd038e94e579b0287bb86bb2add7ba8daa35f0` |
| V1.04 user manual | `9de17c166bb343a8f9b54104eb7ce14cd8ced67b829eb5390074c27a69e61f59` |
| V1.04 release history | `21d6e2ab3a4978ee35d371705671b3d1a11e368dda2515765dcf8375feb3126e` |

Evidence is in `.embedder/hardware/results/boot-loader-v1.04/`, including
`archive-audit.json`. PDFs were extracted for reading; the executable was not run.

### Connection and erase effects

The V1.04 user manual provides these constraints:

- Section 3 requires the relevant Boot Loader ISP mode to be enabled beforehand.
  CONFIG3 has not been read successfully. An invalid APROM is not documented here
  as guaranteed ISP entry. The M3351 USB ISP description previously found says
  HS-USBD while the device has Full-Speed USB; applicability to J3 remains a
  vendor question. M460/M55M1 examples are not M3351 configuration definitions.
- Section 4.3, pages 9–10, specifies **Connect first, then target reset** within
  the Boot Loader timeout. The optional **Reset before connecting** sends a pin
  reset request. Separate Connect/Start buttons are not a documented guarantee
  that connect, identify, configuration read, failure or retry has no persistent
  effects.
- Importantly, pages 9–10 warn that a NuMaker's onboard **Nu-Link2-Me may
  automatically connect and reset at power-up**, access FMC and temporarily
  enable/disable `ISPEN`, potentially interfering with the Boot Loader. The manual
  gives ICESW2-#4 ON as an example of disabling this behavior and explicitly
  requires checking the particular board schematic. **No switch change is
  instructed or performed here.** Neither the actual switch state nor this
  mechanism's role in the saved failure has been measured.
- Section 4.8, page 13, says APROM means **"Erase APROM and program APROM file data
  to the specified APROM address."** This specifies a write address, not an exact
  erase interval. It does not establish page-, bank- or image-limited erasure.
  Treat the whole `0x00000000–0x000FFFFF` as potentially at risk until clarified;
  the upper `0x00080000–0x000FFFFF` has no original backup.
- The same section defines **Erase All** as erasing whole APROM and LDROM, and
  **CONFIG** as updating configuration. These options are prohibited. Do not
  confuse this tool's Erase All wording with ICP's **Erase Whole Chip**, which
  explicitly includes APROM, LDROM, Data Flash and configuration. Neither wording
  supplies a preservation or rollback guarantee for the proposed operation.

The available macOS tools remain a different path:

- [NuISPTool-macOS](https://github.com/OpenNuvoton/NuISPTool-macOS) requires standard
  ISP code in LDROM and documents HID-only support in version 1.0.1.
- [ISPTool_Cross_Platform](https://github.com/OpenNuvoton/ISPTool_Cross_Platform)
  likewise requires booting LDROM ISP code. Cross-platform host support does not
  establish M3351 MaskROM compatibility.
- The pinned [macOS command-line implementation](https://github.com/OpenNuvoton/NuISPCmdLineTool-macOS/blob/f7a45abe3fbcc9fc949eb1c48f16324d31c082e8/Sources/NuISPTool/ISPManager.swift)
  has an unknown-device fallback of 128 KiB APROM and 8 KiB Data Flash. A handshake
  without verified identification and memory geometry must not authorize writes.

The latest saved passive OS inventory exposes Nu-Link2 VCOM at
`/dev/cu.usbmodem1102`, not target CDC. No port was opened, ROM handshake or
additional reset attempted during this offline review. A UART/USB ROM-ISP
handshake remains conditional on reviewed entry, routing and connection effects;
do not modify CONFIG3 or probe firmware to create an interface.

### Best-supported route and preservation gates — not commands to execute

The dedicated **Boot Loader ISP V1.04** has explicit KJCAE support; **ICP V3.24**
also documents M3351/Nu-Link support and requires Windows 7 or later. Neither is
currently a demonstrated recovery procedure on this macOS-only bench. Ask Nuvoton
for a reviewed route for the existing Nu-Link2-Me and current unreadable-CONFIG
state, preferably a supported macOS client/protocol; otherwise identify the native
Windows host and exact tool/probe revision required. Do not assume a new probe,
firmware update or VM is necessary or validated.

After that guidance, the proposed sequence is:

1. Review entry/reset and onboard ICE behavior first. In the vendor-confirmed
   client, keep **APROM, LDROM, CONFIG, Erase All, Reset, Speed and USBDISP** actions
   disabled, no image selected and no automatic Start. Use **Connect** only with
   the exact vendor-approved reset policy. This is a proposed restricted UI
   configuration, **not proof that Connect is read-only** and not authorization
   to try it before the remaining questions are answered.
2. Verify `M3351KJCAE`, 1 MiB geometry and ROM version; save configuration/status
   with successful-read flags. Read/preserve all accessible APROM, especially
   `0x00080000–0x000FFFFF`, plus LDROM and configuration where permitted. Determine
   Data Flash and bank/remap settings before choosing any application interval.
   Do not attempt to export protected secrets or bypass read restrictions.
3. Require a concrete erase/program manifest: exact start/end, sector granularity,
   bank mapping and preservation of every byte outside the explicitly approved
   application interval. Reject the generic Boot Loader **APROM** action unless
   its range is proven acceptable; do not restore the 512 KiB file as a 1 MiB image.
   No executable programming command can yet be supplied with these guarantees.
4. Verify the authorized interval by readback against the intended image and
   compare the preserved regions and configuration against fresh pre-write reads.
   Stop on read errors, unknown IDs, unexpected erase scope or any unlock/update
   prompt. No recovery success is claimed until these checks pass.
5. Only then boot the target and run the separate physical CDC/ECM acceptance
   below. The existing software test results do not substitute for this gate.

## Guarded flasher adaptation on macOS — 2026-10-29

The supplied `flash.py` has been adapted into `tools/flash.py`, not executed on
the target. The supplied `EMBEDDER.md` describes a different nested workspace,
KI/512-KiB device, unit-1/eight-word application and physical tests not reproduced
here. The root `EMBEDDER.md` now records this workspace's KJ/composite setup and
retains the recovery stop; the attachment's runtime claims are not validation
results for this project.

### Corrections and retained safety boundaries

- Root-relative paths and explicit `--build-dir`; offline validation is the
  default. Live operation additionally requires `--program` and a full probe ID.
- Select `m3351kjcae`, PDID `0x03302140`, 1 MiB APROM and the pinned
  `Flash/M3351_AP_1M.FLM`. Both pack and FLM are SHA-256 checked before connection.
  No global pack index update, user-script discovery or download is performed.
- Private pyOCD home/cache/project and explicit empty user script; require
  pyOCD 0.46.0. Attach mode, automatic unlock disabled, no load pre/post reset,
  no automatic resume and no ELF-backed target-read cache. The DP startup hook
  returns false to use generic power-up rather than the vendor reset pulse.
  The stop hook suppresses the vendor stop; `resume_on_disconnect=false` retains
  debug power/state. These are audited source-level controls, not a demonstrated
  recovery solution. Session initialization and teardown still affect debug
  hardware, even when no flash operation follows.
- Stable fresh full-1-MiB APROM backup, LDROM/Data Flash backups and documented
  CONFIG snapshots are required before the RAM algorithm. Configuration reads
  use FMC READ but still change volatile FMC/REGLOCK setup temporarily. Failed
  reads are errors, never interpreted as configuration values.
- Retain privileged Thread-mode, authentication, protection and bank guards;
  mask interrupts and temporarily disable MPU for SRAM algorithm execution.
  Only image-covering 8-KiB sectors are submitted, with their trailing bytes
  copied from the fresh backup. Compare the full 1 MiB and preserved regions
  after programming. This is not atomic and not permission to erase unbacked
  regions. The historical lower-half backup is not a full restoration image.

### Real-artifact incompatibility found and fixed

The attachment reconstructed the binary from whole PT_LOAD segments with zero
padding. The actual Zephyr GNU objcopy command uses **`--gap-fill 0xFF`** and
copies allocated sections: even alignment gaps *inside* a PT_LOAD can differ
from the ELF's bytes. The current server image had four such bytes at physical
`0x1C088–0x1C08B`; the initial validator rejected it as an ELF/binary mismatch.
The validator now checks section-to-segment mapping, bounds, overlap and exact
contents with `0xFF` gaps. It also rejects every nonempty PT_LOAD that has no
allocated payload section, and requires the reset vector's first Thumb halfword
to lie wholly within an executable allocated section of an executable APROM
segment. Segment padding and non-executable sections cannot be reset targets.
It does not ignore mismatches or just trust the binary.

`--list-usb` uses `/usr/sbin/ioreg` and plist parsing, without importing pyOCD or
opening a serial/USB interface. Testing on this Mac found that `ioreg -a -r -c
IOUSBHostDevice` omits child-node properties: it showed the Nu-Link device but
falsely produced empty interface/port lists. Adding **`-l`** exposes the child
properties. The corrected command is `ioreg -a -l -r -c IOUSBHostDevice`.

Current OS enumeration identifies the same Nu-Link2 `0416:2004` and serial, with
CMSIS-DAP (interface 0, vendor class), VCOM control/data (1/2), HID (3), WebUSB
(4) and MSC (5). **`/dev/cu.usbmodem102` belongs to Nu-Link VCOM**, not J3 Modbus.
No separate target CDC or target HID device appears in this snapshot. This is
OS-only evidence: neither VCOM nor the probe was opened. Earlier empty-port
output from the uncorrected query is not evidence that the VCOM was absent.
OS enumeration alone cannot qualify programming or native target USB operation.

All four retained ELF/bin pairs now pass offline validation: server **115064**,
client **115936**, separate **115116**, large **115064** bytes. Each proposes
`[0x00000000, 0x0001E000)` as its sector-aligned erase/write interval; **none was
executed**. The preservation tail must come from a fresh, successfully read
full-1-MiB backup, never from invented padding. The retained 16-byte SRAM
write/read/restore preflight also remains mandatory before algorithm execution.
Final host-only regression run: **288/288 passed** using
`PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -m pytest -q -p no:cacheprovider tests/tools`.
This includes synthetic ELF/pack and mocked programming/preservation failures,
plus the existing loopback/pseudo-terminal interoperability tests. `pip check`
reported no broken requirements. Mocked hardware calls do not qualify the real
programming path. The retained source, artifact hashes, final test log and passive
USB snapshot are recorded in
`.embedder/hardware/results/macos-flasher-validation-20261029.json`.

**Remaining HIL gate:** a reviewed, preserving recovery entry must first work for
the current incomplete APROM state. The attached KI script is not that procedure,
and changing its target to KJ is not evidence of recovery. Full current 1-MiB
APROM, LDROM, Data Flash and valid configuration snapshots must be obtained
before authorizing bounded programming; the unbacked upper APROM must not be
erased. The Nuvoton request below remains prepared but unsent. No probe/serial
connection, reset, programming or physical reconnect test was performed during
this macOS validation. These offline checks have not recovered the board.

## Offline vendor protocol and execution-context follow-up — 2026-10-29

The exact `NuvoISP_BL_V1.04.exe` packet encoder was executed in isolated x86
emulation, not as a native Windows application: **1,283** vectors agree byte for
byte with the new `tools/bootloader_protocol.py`, and **100** response comparisons
agree with the inspected reader. Explicit transport-failure injection reproduces
an independent vendor defect: the single-CONFIG-write wrapper returns success
when sending fails. An emulator-memory-only branch correction returns failure
for all five transport modes. Neither the vendor file nor a live device was
modified. The adapter contains identification and allowlisted CONFIG reads only;
it does not implement that write path, erase, reset or automatic retries.

A successful empty IORegistry result exposed a separate macOS host bug: the
inventory code attempted to parse absent plist bytes. It now reports an empty
device list, while malformed nonempty output remains an error. The current
OS-only query reports **no matching USB devices**; no probe/serial port was opened.
This is a current enumeration result, not proof of a particular cable state.

FLM analysis strengthens, but does not prove, the inherited-stack-limit
hypothesis. `CFSR=0x00100001` means **STKOF plus IACCVIOL**; `PC=0xEFFFFFFE` is the
architectural lockup address. Stackless erase can run before ProgramPage's first
20-byte push encounters a high inherited limit. The actual limit was never
successfully read in the failed session. The programmer now rejects incompatible
or unreadable Secure MSP limits, PSP-selected/non-Thumb/unconfirmed Secure state,
invalid algorithm stack metadata and existing STKOF before borrowing RAM or
running a flash algorithm. It does not change limits, clear faults or recover
the board. Details, reproducible checks and limitations:
[`docs/bootloader-protocol.md`](bootloader-protocol.md).

Final host-only check for this follow-up: **629 passed** (314 flasher cases,
228 bootloader-protocol cases, 87 existing Modbus host cases). All four retained
ELF/bin pairs still pass offline validation. `pip check` succeeds. The final
OS-only inventory is empty and no `/dev/cu.*` endpoints are present. No live
handshake, target recovery, programming or physical CDC/HIL test was run; the
existing stop and unbacked-region preservation requirements remain unchanged.

## Cortex-M33 mechanism reproduction and guard correction — 2026-10-29

This follow-up adds executed CPU-level evidence, not physical recovery. The
hash-checked vendor `ProgramPage` prologue (`f0 b5`) was executed at
`0x20003CA8` on QEMU Cortex-M33, with the historical algorithm SP `0x200019F0`.
The AN505 model has 32 KiB SRAM; the test's high limit is deliberately synthetic
(`0x20007C00`), not an inferred historical value.

- Limit zero: stackless control and vendor prologue return normally.
- High limit: stackless control returns, then the vendor push faults with
  CFSR `0x00100000` (STKOF), HFSR `0x40000000` (FORCED), and MSP set to the limit.
- Same high limit with rejection guard: execution stops before the vendor push.

All three simulations pass their expected-result assertions. The peripheral
programming body is not executed and no M3351 flash is modeled. Historical
IACCVIOL and the actual pre-fault stack limit remain unexplained. Thus this
reproduces a supported failure mechanism, **not the complete historical failure**.
Sources: `tests/tools/run_flash_context.py`; commands in `tests/tools/README.md`;
results and firmware hashes: `build/flash-context/results.json`.

A remaining preparation defect was corrected: the host guard now rejects a
DSCSR register-bank override, inconsistent Secure domain indications,
`control`/`control_s` disagreement and a non-Thread xPSR exception field before
backups, FMC operations, SRAM scratch writes or FLM execution. It never changes
bank selectors or stack limits. All CMSIS-Pack debug sequences are disabled,
not just the two current vendor startup/stop sequences; this also prevents
optional flash-done callbacks from introducing extra target actions.

The FLM still changes volatile RAM/core and peripheral-clock/register-lock
state; the tool restores PRIMASK/MPU_CTRL only and does not promise resumability
of the replaced application. Nonvolatile preservation requires successful
fresh backups, bounded writes and independent complete readback as documented
above. These requirements have not been established on the current board.

Latest host checks: **649 passed** (334 flasher, 228 protocol, 87 Modbus harness).
The three separate QEMU CPU controls passed. `tools/flash.py --list-usb` reports
no devices, and `ioreg -p IOUSB` lists host controllers but no device descendants.
The earlier empty `system_profiler SPUSBDataType -json` result is **not valid
corroboration**: on this macOS release the supported name is `SPUSBHostDataType`.
The corrected independent check is recorded below. No probe, serial endpoint,
HID handle, reset or programming operation was opened/run during this follow-up.
The missing endpoint, unreadable current configuration and unqualified recovery
entry still prevent physical USB HIL.

## Recovery-read and macOS enumeration audit — 2026-10-29

The current Mac lists `SPUSBHostDataType` in `system_profiler -listDataTypes`.
That query and the complete IOUSB registry plane both show **three built-in
XHCI controllers with no device descendants**. This corroborates the empty
class-filtered inventory without relying on the obsolete `SPUSBDataType` name,
which silently returns an empty array even when it is unsupported. It does not
establish why no device enumerates. The 649 host regressions passed again.
Evidence: `.embedder/hardware/results/recovery-passive-current.json`.
The original 524,288-byte backup hash was rechecked and remains
`cdc14f595cf29c2877cc9b11bc564df62b66e3338a0a77ea35ba533aba0b93d3`;
it still covers only `[0x00000000, 0x00080000)`.

A further offline EXE audit tested whether the known D2 command could supply the
missing full-APROM backup. It **cannot establish that capability**: both observed
D2 producers use fixed CONFIG-space addresses and request only four or eight
bytes. Neither accepts an arbitrary target address. The shared USB response
parser copies at most 52 bytes but can return success when the caller requested
more; that ceiling is not a documented APROM-read command limit. It also exposes
false-success branches in both CONFIG-read helpers when sending fails. The
portable adapter already rejects short writes and invalidates failed sessions;
no generalized APROM-read API or speculative device traffic was added.
All 25 new memory-only EXE emulation cases passed their expected assertions;
see `boot-loader-v1.04/read-audit/FINDINGS.md` and `emulation.json` under the local
results directory. These are additional offline audit cases, not HIL tests.

The public M3351 `ISP_DFU` example is firmware that must already run and uses
its own detect pin; it is not the MaskROM implementation and does not establish
recovery entry for incomplete APROM. No public, applicable ROM-entry/read
contract was found. Developing a different host driver does not resolve the
missing physical endpoint or supply that device-side contract. The next live
step remains gated on both endpoint availability and an applicable preserving
entry/read procedure; no reset, open, erase or security change was performed.

## Passive physical-link check — 2026-10-29

A subsequent OS-only check found zero `IOUSBHostDevice` and zero
`IOUSBHostInterface` instances. All three USB-C `IOAccessoryManager` entries
reported `ConnectionActive=false`, `TransportsActive=[]`,
`AuthorizationRequired=false`, and `UserAuthorizationStatusDescription="Not
Required"`. The only serial services were `/dev/cu.debug-console` and
`/dev/cu.Bluetooth-Incoming-Port`; neither is the Nu-Link VCOM or target CDC.
The refreshed serial/debugger inventory also detected no devices.

These observations locate the current blocker before CDC/HID driver binding:
there is no enumerated physical USB data path for the agent to open. They do not
identify a defective cable, prove the board is unpowered, or establish why the
connection disappeared. A 30-minute USB-related unified-log query contained no
relevant device event; absence from that log is not proof of an error-free link.
No macOS security setting was changed. Apple's accessory-approval guidance
(<https://support.apple.com/en-us/102282>) explains that charging alone does not
prove data access, but this snapshot contains no pending authorization evidence.

Evidence: `/Users/embedder/.embedder/shell/f0d37af793f94e7b/` logs
`task_mvu1eaew_79f67b.log` (USB tree and system profiler),
`task_mvu1efsa_db5bba.log` (unified-log query),
`task_mvu1empu_d6c648.log` (class counts), and
`task_mvu1eu6h_d22a69.log` (selected port state and serial identities).
No probe/serial/HID handle was opened, and no target reset or write was issued.

The next external prerequisite is restoration of the Nu-Link USB data connection
to this Mac, without treating a reconnect as a qualified target recovery. After
passive enumeration returns, the existing recovery stop still applies: establish
an applicable preserving entry/read procedure and obtain fresh complete backups
before any program operation. No additional host driver installation or blind
retry is justified by this snapshot. Physical CDC/ECM HIL remains unexecuted.

## Nuvoton support request

**Draft only — not sent.** Subject: **M3351KJCAE non-erasing recovery after
pyOCD program timeout; preserve unbacked APROM and security state**.

> Target: user-confirmed M3351KJCAE on NuMaker M3351KI V1.2, 1 MiB APROM,
> 128 KiB SRAM. Saved PDID 0x03302140 corroborates the package identification.
> Probe: Nu-Link2 CMSIS-DAP 0416:2004, serial
> 13010000003800F1047546CF0000065D; host: macOS arm64; pip-installed pyOCD 0.46.0,
> Nuvoton NuMicroM33_DFP 1.0.6. CMSIS-DAP protocol version 2.1.0 is recorded;
> the exact probe firmware version is not established by that number.
>
> Earlier programming mistakenly selected M3351KICAE. Reset-free attach could
> halt with DAUTHSTATUS=0xFF; sector erase succeeded, then programming timed out
> with CFSR=0x00100001, HFSR=0x40000000 and PC=0xEFFFFFFE. Lower APROM now lacks
> valid vectors. The preserved backup covers only the lower 512 KiB.
>
> Reproduction evidence (historical, not a command to repeat):
> `.venv/bin/pyocd load --target m3351kicae --uid 13010000003800F1047546CF0000065D --script tools/pyocd_attach.py -M attach --erase sector -O auto_unlock=false -O load.pre_reset=off -O keep_unwritten=true -O resume_on_disconnect=false -O cache.enable_memory=false --no-reset build/cdc-baseline/zephyr/zephyr.elf`.
> The hook replaced DebugPortStart's reset pulse with debug power-up; the pack
> memory map and algorithm were retained. Output progressed through Erasing and
> Programming before `flash program page timed out`; this was not an erase timeout.
> Pack SHA-256: `0aae782356a261b976169fb677a5785c8647b5e0a0a93fa1632fb71a04b2dde2`.
> Used FLM `Flash/M3351_AP_512.FLM` SHA-256:
> `8729859484afaa838c46bc7094fdcd6f4f29f908cadac5b3d6d901cb6928d473`.
> Correct KJ FLM `Flash/M3351_AP_1M.FLM` SHA-256:
> `6ad56e7e085dae4ed3f61abd6bcc2edde2ffd53424ca28a6fedc6d743b369717`.
> Post-failure LR was `0xFFFFFFF9` (exception return), and FMC_ISPADDR was
> `0xE000` with ISPCMD `0x22`. These are a later snapshot, not a trace establishing
> the faulting instruction or failing page. The original stacked fault PC was
> not captured. The wrong target selection is confirmed; causation is not.
>
> Current passive reads and a corrected-KJ standard under-reset connection at
> 100 kHz report DHCSR=0x80001 / DAUTHSTATUS=0xAF. CoreSight is accessible, but
> APROM/SRAM and secure peripheral reads fault. A separate passive test explicitly
> set HNONSEC=1: 16-byte reads at APROM_NS 0x10000000 and SRAM_NS 0x30000000 also
> faulted; CSW=0x43800052 and DP CTRL/STAT=0xf0000040 afterward. No configuration-word
> readback has succeeded. No mass erase, security change, or probe update was performed.
>
> We have now verified that Boot Loader ISP V1.04's supported-device table
> explicitly includes M3351KJCAE and its ZIP ships `NuvoISP_BL_V1.04.exe` (Windows
> PE32). The old question of whether the table lists this device is resolved.
> Please clarify the following before we attempt another connection or write:
>
> 1. Confirm the supported M3351KJCAE silicon/MaskROM revisions and exact tool
>    version. Is there a supported native macOS/arm64 MaskROM client or a published
>    protocol? The public macOS/cross-platform clients describe LDROM ISP; their
>    device-list support alone is not evidence of MaskROM compatibility. If a
>    native Windows host or a different probe is necessary, identify exactly which
>    versions and hardware are supported; do not assume Wine/VM passthrough.
> 2. Provide a recovery-entry method applicable when CONFIG0/CONFIG3 are
>    unreadable and the lower APROM has invalid vectors. Specify prerequisites,
>    security/boot settings, interface and pins, timeout and reset type. Does
>    incomplete APROM affect entry? Can UART0 PB12/PB13 via the existing VCOM or
>    J3 Full-Speed USB be used? Resolve the HS-USBD wording for this FS device.
>    Board UART routing is known; ROM pin selection/enablement must be confirmed.
> 3. Separately describe persistent and volatile effects of (a) power/reset/entry,
>    (b) the entire Connect/identify/config-read sequence, (c) failure/retry and
>    disconnect. Does any step write CONFIG, change security, erase flash, or run
>    recovery automatically? Provide safe UI selections or commands. Please also
>    address the V1.04 manual pp. 9–10 warning that onboard Nu-Link2-Me may
>    auto-connect/reset and toggle FMC ISPEN: what board-V1.2 switch/isolation
>    procedure prevents interference without changing target security/config?
> 4. Define the exact erase and write ranges of the Boot Loader APROM option:
>    whole 1 MiB, bank, sectors or image interval? Its manual only says "Erase
>    APROM and program APROM file data to the specified APROM address." Only
>    `0x00000000–0x0007FFFF` has an original backup; the upper half is unbacked.
>    Supply a read/backup method and a range-limited operation preserving the
>    upper APROM, LDROM, Data Flash, configuration, OTP, keys and security state.
>    Include bank/remap/Data Flash considerations, verification and interruption
>    recovery. A generic "APROM-only" assurance is insufficient.
> 5. For the saved SWD failure, explain whether the DFP DebugPortStart reset pulse,
>    old exception/interrupt context during reset-free FLM execution, or onboard
>    probe auto-connection could cause the observed HardFault. DAUTHSTATUS was FF
>    at the fault; no permanent security lock is established. The KI/KJ FLMs have
>    identical PrgCode but different descriptors. We can provide the exact logs,
>    hashes and register evidence privately; please specify any additional
>    non-writing evidence required before recommending another target operation.
>
> 6. Follow-up offline audit: the exact V1.04 EXE's single-CONFIG-write wrapper
>    at VA 0x0040A490 reports success if its encoder/send fails: the failed-send
>    branch at 0x0040A4D8 jumps to 0x0040A534 without clearing the true result.
>    This was reproduced for all five modes with transport stubs. Redirecting
>    only that edge to the existing failure path returns false in emulator
>    memory. Please fix failed-send propagation and verify configuration with
>    actual independent device readback, not desired-to-cache copies. No EXE or
>    live device was patched. This finding is separate from the pyOCD timeout.
> 7. The pyOCD timeout's CFSR includes STKOF. Init/EraseSector are stackless while
>    ProgramPage immediately pushes 20 bytes using initial SP 0x200019F0. No
>    actual MSPLIM_S was captured; old unsuffixed names were unsupported. Please
>    confirm required Secure MSP/limit preparation and a non-writing probe that
>    can validate it before erasure. The host now rejects unsafe or unknown
>    contexts rather than attempting a reset, changing limits or clearing faults.
> 8. A controlled Cortex-M33 QEMU experiment now executes the exact two-byte
>    ProgramPage push at 0x20003CA8 with initial SP 0x200019F0. A synthetic high
>    MSPLIM causes STKOF/FORCED after a stackless control returns; the compatible
>    limit returns normally and the guard rejects the bad limit before execution.
>    This does not establish the historical limit or reproduce IACCVIOL. Please
>    confirm the supported flash-call stack/exception context and how to inspect
>    it on this board without triggering reset or changing debug authentication.
> 9. Provide the actual M3351 MaskROM read contract for complete preserving
>    backups. The V1.04 EXE's observed D2 callers at 0x0040A810/0x0040A8A0 read
>    only CONFIG words/pairs; no APROM-read call was found. Is D2 valid for APROM,
>    LDROM and Data Flash, or is a different read command required? Specify
>    supported address ranges, aliases, alignment, maximum length, status/error
>    semantics and side effects. Its response parser returns Boolean success
>    after copying min(requested length, 52), so that result cannot prove a full
>    memory read. Both CONFIG-read helpers can also return true after a failed
>    send; please fix those paths and the ignored A0 failure in 0x0040A810.
>
> We do not authorize whole-chip erase, configuration/security changes, LDROM
> writes or probe-firmware changes. If any is required, explain why, every affected
> region/setting, reversibility, backup prerequisites and recovery procedure
> before proposing it. Please do not recommend a whole-APROM erase that would
> destroy the unbacked upper half. This request is prepared for user review and
> has not been sent.

Full command/error chronology and evidence paths are retained above. Share
firmware images or device secrets only through an approved private support
channel; this request does not require sending them initially.

## Pending physical acceptance

After resolving the programming/debug restriction without unapproved changes:

1. Establish a reviewed recovery connection for M3351KJCAE. Preserve/read all
   accessible 1 MiB APROM and configuration before programming; the historical
   backup covers only its lower half. Verify `M3351_AP_1M.FLM`, then perform
   authorized standalone CDC, ECM and composite programming/boot/descriptor checks.
2. Discover actual J3 ACM port and ECM interface. Check subnet conflicts; assign
   only the isolated approved /24 addresses with no gateway/default-route change.
   This session did **not** change host networking.
3. Run all eight FCs against board servers and PC servers for both transports;
   correlate board-client logs with PC replies. Demonstrate four TCP clients,
   bounded fifth-client handling, malformed/fragmented/coalesced frames,
   broadcast/CRC/exception behavior and packet/capacity boundaries.
4. Run at least 1,000 deterministic transactions per transport/role, measure
   latency and stack/pool high-water marks, then close/reopen, unplug/replug,
   no-terminal startup and cold boots. Record deliberate faults separately.
5. Validate the implemented CDC queue-isolation patch on physical USB. Its
   40 actual-driver emulation regressions pass; physical close/reopen and
   unplug/replug testing remains pending. Confirm no prior-session bytes appear
   after reopening and that both ACM and ECM remain usable.

Physical UART/RS-485 direction/electrical timing and DMA are not certified by
USB or QEMU tests. DMA is explicitly unsupported (`-ENOTSUP`).

## 2026-10-29: authorized access recovery and native Mac UART check

The user authorized opening interfaces, reset and necessary diagnostic writes.
This did not authorize mass erase, security/configuration changes, LDROM writes
or erasing unbacked APROM. No flash algorithm or persistent write ran here.

Current measurements, rather than the original attachment's physical-test
claims, remain authoritative for this workspace:

| Check | Observed result |
|---|---|
| MEM-AP status, no reset/halt | CPUID readable; DAUTHSTATUS `0xAF`, DHCSR `0x03080000`; APROM, SRAM and peripheral accesses fault |
| Debug-disable + hardware reset | Same access failure and lockup |
| KJ under-reset at 100 kHz, all pack sequences disabled | Discovery completes; LOCKUP, DAUTHSTATUS `0xAF`, peripheral reads fault |
| Native Mac Nu-Link VCOM open, 115200 8-N-1 | Succeeds on `/dev/cu.usbmodem1202`, matched to probe serial `13010000003800F1047546CF0000065D` / `0416:2004` |
| One 62-byte UART ROM synchronization, no reset | Times out before A0 |
| One VCOM-open-before-hardware-reset synchronization | Times out before A0 |
| Immediate synchronization, zero pyOCD post-reset delay, probe retained | Also times out before A0 |

VCOM used explicit DTR enabled and RTS disabled, no BREAK, no flow control.
All three UART attempts stopped at synchronization: no A0, configuration read
or programming command followed. A completed host write does not prove transmission
at the MCU pins; a completed probe-reset call does not measure reset delivery.
ROM UART enablement, entry state and ICESW2 routing are still unknown.

`tools/bootloader_protocol.py` now provides `BootloaderUartSession` for an
already-open handle. It sends raw 64-byte packets (no HID report-ID prefix),
handles partial reads/writes, enforces whole-transfer deadlines and invalidates
failed sessions. It does not open/close ports, pulse BREAK, reset, program or
change modem controls. See `docs/bootloader-protocol.md` for exact framing,
intentional differences from the EXE and evidence limits.

Software validation: 534 UART regressions passed, including a native macOS
pySerial/pseudo-terminal round trip. The 533 mocked cases include a discovered
late-final-response defect: a reply arriving after the absolute deadline must
be rejected even if it completes the last fragment. Both reads and writes now
check the deadline after each I/O call. Existing HID tests remain passing.
CDC session isolation still passes 20/20 with each workqueue; these use the
actual class driver with a fake UDC, not the connected board. Final full host
suite: **1,183 passed**. The actual server ELF/bin and pinned KJ pack pass the
offline flasher check; no programming is implied. Final IORegistry inventory
shows the Nu-Link and hubs, not a native target CDC/ECM/HID device. The complete
host-check output is `task_mvu2shgm_45da22.log` under Embedder's shell logs.

Hardware evidence: `.embedder/hardware/cases/m3351-flash-lockup/CASE.md`,
its timestamped results, and hardware tool logs
`script-call_b1OfG9MEZGLtih50kNu16dO6.log`,
`script-call_9W7Nz6ZviG3eSK4rqnOoVJMb.log`,
`script-call_wZ8SZaWHydC5uJBrwe77DQCq.log`.

**Not resolved at that point:** programming access, complete current-device
backup, flash/readback verification, native target CDC/ECM traffic and
reconnect HIL. The next section records how the first three were resolved later
the same day.

## 2026-10-29, 23:30–00:03 UTC: access recovered, programming verified

### Root cause

The part was never locked. The interrupted 2026-10-28 programming left APROM
page 0 erased (vectors `0xFFFFFFFF`, erased interval `0xE000–0x110F0` relative
to the 512 KiB backup). The 32 KiB Secure Bootloader then finds no valid
application and stays in ROM with `VECMAP=0x3E000`. While a debugger holds the
DP powered across reset, the ROM leaves `DAUTHSTATUS=0xAF` and every bus access
faults, which is the "LOCKUP / FAULT" picture every earlier under-reset connect,
halt and ROM-UART attempt produced. Powering the DP **down** during the nRESET
pulse and up a few milliseconds later lets the ROM complete; `DAUTHSTATUS`
becomes `0xFF`, the core halts in Secure state and memory is readable
(`rom-window-timing-…json`, `halted-sde-check-…json`).

Readable configuration confirmed no protection: all documented CONFIG words
`0xFFFFFFFF` except CONFIG11 SCRLOCK and CONFIG13 ARLOCK `0xFFFFFF5A`
(unlocked), `FNSADDR=0x100000`, APWPROT/SCACT/XOM zero
(`vecmap-restore-backup-20261029T234007594165Z.json`).

### Recovery and first verified programming

| Step | Action (no flash, CONFIG, security or LDROM write unless stated) | Evidence |
|---|---|---|
| 1 | DP down during nRESET, DP up after release; ROM completes, `DAUTHSTATUS=0xFF` | `rom-window-timing-20261029T233029758867Z.json` |
| 2 | Reset-catch halt in ROM: `DHCSR=0x130003`, `S_SDE=1`, Secure | `halted-sde-check-20261029T233134168582Z.json` |
| 3 | FMC READ of CONFIG words; only failing guard was VECMAP ≠ 0 | `preflight-config-20261029T233448218719Z.json` |
| 4 | Volatile FMC VECMAP (0x2E) to page 0; all guards pass; fresh full 1 MiB APROM, LDROM, Data Flash, CONFIG backups in `.embedder/backups/` | `vecmap-restore-backup-20261029T234007594165Z.json` |
| 5 | Arbitrated flash tool, `tools/flash.py --program` (KJ pack, `M3351_AP_1M.FLM`, attach, no reset): sector erase/program `[0, 0x1E000)` of `build/server`; full APROM, CONFIG, LDROM, Data Flash verified | flash tool log, backup `m3351kjcae-aprom-a501ba24…` |
| 6 | Clear DEMCR/DHCSR, DP down, one nRESET pulse: UART0 banner + `Modbus server ready: RTU id10, TCP id1 port502`; J3 enumerates `0416:B002` | `boot-release-20261029T234626730366Z.json`, `boot_and_observe` log |

### Repeatable programming procedure (now in `tools/flash.py`)

```sh
.venv/bin/python tools/flash.py --build-dir build/server --program \
    --probe 13010000003800F1047546CF0000065D --halt-at-reset-vector --boot
```

Run only through the server-arbitrated flash tool. `--halt-at-reset-vector`
arms an FPB comparator on the current APROM `Reset_Handler`, sets `C_DEBUGEN`,
powers the DP down for one nRESET pulse and reconnects 50 ms later; the core
halts at the first application instruction in Secure privileged Thread mode on
MSP with `MSPLIM=0` and `VECMAP=0`, satisfying every existing guard. It refuses
to arm if the vector table is not a valid application (then the ROM-halt case
scripts, steps 1–4, apply). `--boot` clears the debug enables, powers the DP
down and pulses nRESET once after verified programming; it does not reconnect
and does not itself prove the boot. All preservation guards, backups and
verification are unchanged. Standard `pyocd` under-reset/reset-halt and the pack
`DebugPortStart` sequence keep the DP powered through reset and therefore always
land in the inaccessible ROM state on this device; do not use them.

Verified runs with this procedure: `build/server-usbdbg` (USB debug logging,
`ecbfc52b…`), the upstream `samples/subsys/usb/cdc_acm` reference (`2FE3:0001`,
`da4e2a98…`), and finally `build/server` (`d5f161e7…`) restored with the single
integrated command (backup `m3351kjcae-aprom-f93feec5…`; 00:02:54 UTC boot log
shows the banner and `Modbus server ready`; J3 `0416:B002`). Host checks after
the `tools/flash.py` change: `tests/tools` **1,184 passed**.

### Superseded pending note

The earlier `!registered, !matched` observation did not persist: after the
`--boot` release at 00:02 UTC macOS created `/dev/cu.usbmodem1101` for the J3
CDC ACM interface (identity `0416:B002`, serial `00010031047B4B1F00000003`) and
binary RTU traffic worked (next section). The Embedder serial provider still
does not enumerate the Nu-Link VCOM; use
`.embedder/hardware/cases/m3351-flash-lockup/boot_and_observe.py` for UART0
boot captures.

