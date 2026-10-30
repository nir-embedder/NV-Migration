# NV-Migration: M3351 / Zephyr

## Workspace and target

This workspace is the standalone Zephyr application at the repository root:
`src/`, `lib/modbus/`, `tools/`, `tests/`, and `west.yml`. Dependencies are in
`.deps/`, the Python environment in `.venv/`, and SDK in
`.toolchains/zephyr-sdk-1.0.1`. Do not reinitialize west or substitute paths from
the separate `Modbus-STM32-HAL-FreeRTOS/Zephyr` workspace described in the supplied
reference instructions.

- Board: `numaker_m3351ki/m335xxx`.
- Confirmed fitted MCU: **M3351KJCAE**, PDID **0x03302140**, **1 MiB APROM** and
  **128 KiB SRAM**. Historical KI/512-KiB selection was incorrect for this board.
- Native J3 USB: composite CDC ACM (binary Modbus RTU) and CDC ECM (Modbus TCP).
- Diagnostics: UART0 through the separate Nu-Link VCOM, never binary RTU.
- Server defaults: RTU unit **10**, TCP unit **1**, independent 16-word shared
  banks. Do not substitute the attachment's unit-1/eight-word map.
- Current hardware status (2026-10-29): programming access is recovered and
  `build/server` is programmed, verified and boots (UART0 `Modbus server ready`,
  J3 enumerates `0416:B002`). 2026-10-30: macOS creates `/dev/cu.usbmodem1101`
  for J3 and binary RTU works (26/33 acceptance cases) but certain long IN
  replies wedge the ACM endpoint: untrimmed HIRC as USB clock (the SoC DTS never
  enables HXT and the UDC driver does not trim). Fix in `src/usb.c`
  (`hirc_trim_arm`, USB-SOF HIRC trim re-armed on reset/configured/resume) is
  built but **not yet programmed**: the Nu-Link2-Me stopped enumerating; re-seat
  its USB cable, then program and re-run `rtu_scenarios.py`/`rtu_acceptance.py`.
  TCP/ECM acceptance is still open. See `docs/validation.md` and the
  flash-lockup case; do not overwrite historical evidence or import
  physical-test claims from the attachment.

## Build and software checks

Run from the workspace root:

```sh
sh tools/build.sh server
sh tools/build.sh client
sh tools/build.sh separate
sh tools/build.sh large
PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -m pytest -q -p no:cacheprovider tests/tools
cmake --build tests/protocol/build
ctest --test-dir tests/protocol/build --output-on-failure
sh tests/cdc/run.sh
```

`tools/build.sh` applies the pinned CDC session-isolation patch. See the test
READMEs for QEMU commands. Host emulation is not physical USB validation.

## Supplied flasher, adapted for this Mac and KJ target

The adapted file is **`tools/flash.py`**. Always supply the intended build:

```sh
.venv/bin/python tools/flash.py --build-dir build/server --dry-run
.venv/bin/python tools/flash.py --list-usb
```

The first command (also the default mode without `--dry-run`) validates the
ARM ELF, section-derived binary, 1-MiB bounds, vectors, and pinned local pack/FLM.
It imports no pyOCD and does not open hardware. The second queries macOS
IORegistry only: enumeration does not prove probe access, firmware readiness,
or an operational CDC link. Port paths must be rediscovered, not hardcoded.

The established live programming command (2026-10-29, see the resolution
section of `docs/validation.md` and the case record) is:

```sh
.venv/bin/python tools/flash.py --build-dir build/server --program \
    --probe 13010000003800F1047546CF0000065D --halt-at-reset-vector --boot
```

Always run it through the server-arbitrated flash tool with the explicit build
and the full probe ID, never as an ordinary shell command. It requires pyOCD
0.46.0, the pinned Nuvoton NuMicroM33 DFP 1.0.6 and `Flash/M3351_AP_1M.FLM`.
`--halt-at-reset-vector` halts at the application `Reset_Handler` with the DP
powered down during the nRESET pulse (the only entry that does not strand this
part in the inaccessible Secure Bootloader state); `--boot` releases debug and
pulses nRESET once after verification. Do not use generic `west flash`,
`pyocd load`, under-reset/reset-halt connects or the pack `DebugPortStart`
sequence: they keep the DP powered across reset and reproduce the historical
lockup. If APROM page 0 is ever invalid again, use the ROM-halt case scripts
(`rom_window_timing.py` → `halted_sde_check.py` → `preflight_config.py` →
`vecmap_restore_backup.py`) before `--program`. Do not weaken preservation
checks. An attached older `flash.py` or another workspace's `EMBEDDER.md` does
not qualify this board for programming.

Preservation requirements:

- No mass erase, automatic unlock, configuration/security writes, LDROM writes,
  probe-firmware changes, or automatic reset/resume fallback.
- The historical 512-KiB backup covers only `0x00000000–0x0007FFFF`. Full 1-MiB
  APROM, LDROM, Data Flash and CONFIG backups now live in `.embedder/backups/`
  (one per programming run); keep them.
- Obtain stable fresh full-1-MiB APROM, LDROM, Data Flash and documented CONFIG
  snapshots before the RAM algorithm. Stop if any guard or read fails.
- Require confirmed Secure privileged Thumb Thread execution on MSP, compatible
  `msplim_s` and verified algorithm stack bounds, with no pre-existing STKOF.
  DSCSR must not override the debug register bank; `control_s` and xPSR must agree
  with the accepted current Secure MSP/Thread state. Do not change selectors,
  limits, clear faults or switch execution state to bypass the guard.
  See `docs/bootloader-protocol.md` for the offline EXE/FLM audit; it is not HIL.
- Only the new image's 8-KiB-rounded sectors may be erased; preserve their trailing
  bytes from the fresh backup and verify all APROM plus preserved regions after
  programming. The operation is not atomic: interrupted programming can damage
  the selected application sectors.
- Attach is not passive. Even without reset, pyOCD initializes debug hardware;
  configuration reads temporarily write FMC/REGLOCK; programming masks IRQs,
  disables MPU temporarily and executes the vendor algorithm in SRAM. The
  original reversible 16-byte SRAM write/read/restore check is retained; failure
  or incomplete read stops programming.
- Private pyOCD home/cache, empty project and explicit empty user script avoid
  unrelated configuration and scripts. All pack debug sequences are disabled;
  session-local startup/stop hooks avoid the vendor reset/stop actions. The FLM
  still changes volatile clocks, register-lock state, RAM and core registers;
  only PRIMASK and MPU_CTRL are restored. Never resume the old application
  context after replacement or claim full volatile-state preservation.
  Disconnect still does not prove runtime readiness.

## Physical acceptance

Keep software tests, programming/readback, and physical USB results separate.
Do not claim success from enumeration or a dry run. The Embedder serial provider
does not enumerate the Nu-Link VCOM; capture UART0 boot logs with
`.embedder/hardware/cases/m3351-flash-lockup/boot_and_observe.py`. Test the
actual J3 ACM port with raw binary
RTU, all supported function codes, fragmentation, repeat traffic and close/reopen
without stale bytes. Verify ECM/TCP independently, then simultaneous operation,
unplug/replug, no-terminal boot and cold boot as described in `docs/validation.md`
and `docs/pc-tests.md`. Do not substitute Nu-Link VCOM for target USB.
