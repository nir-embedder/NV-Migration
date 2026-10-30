---
title: M3351 pyOCD flash algorithm RAM fault
status: open
opened: 2026-10-28
hardware: NuMaker M3351KI V1.2 / user-confirmed M3351KJCAE / Nu-Link2 CMSIS-DAP
tags: [flash, pyocd, cortex-m33]
---

## Symptom

First authorized baseline application programming via pyOCD 0.46.0 and Nuvoton NuMicroM33_DFP 1.0.6 failed. `pyocd load --target m3351kicae --uid 13010000003800F1047546CF0000065D --erase sector -O auto_unlock=false build/cdc-baseline/zephyr/zephyr.elf` reported reset halt timeout (LOCKUP), then memory transfer FAULT at algorithm RAM 0x20003c00–0x20003fff.

## Hypotheses

| Hypothesis | Verdict | Evidence |
|---|---|---|
| Probe absent | Not sufficient explanation | Managed attach identified CPUID 0x411fd210, SYS_PDID 0x03302140 and read lower 512 KiB APROM. |
| Wrong MCU/FLM selection caused the programming failure | Mismatch confirmed; causal role unproven | User confirms M3351KJCAE (1 MiB), but both earlier programming attempts selected m3351kicae and M3351_AP_512.FLM. Correct KJ connection-only under-reset check also remains in LOCKUP/0xAF. KI/KJ PrgCode is identical; only descriptors differ. No KJ algorithm was executed. |
| Default reset/halt startup differs from successful attach and induces inaccessible RAM | Confirmed symptom, underlying cause not fully established | Direct halt after attach also yielded LOCKUP, no HALTED state, and RAM/APROM read faults. |
| Flash attempt partially changed APROM | Eliminated for first attempt | Post-failure full 512 KiB read SHA256 matches original; zero different bytes. |
| Persistent secure-debug lock caused the programming failure | Not established; contradicted as a continuous condition | Cold attach and reset-free halt read DAUTHSTATUS=0xFF and succeeded without security changes. 0xAF appears with LOCKUP. |
| Vendor reset sequence contributes to failure | Supported interaction; not a sufficient explanation or recovery | DFP DebugPortStart pulses nRESET and delays 72.8 ms even in attach mode. Replacing only this step permitted halt and sector erase before the program timeout. A later standard under-reset connection disabling only DebugPortStart still ended in LOCKUP/0xAF with the incomplete image. |
| Old CPU/interrupt state disrupted RAM programming | Plausible, unproven | Reset-free programming erased sectors then timed out with CFSR=0x100001, HFSR=0x40000000, PC=0xEFFFFFFE, xPSR=0x41000003. No controlled successful comparison yet. |
| Inherited Secure stack limit causes a ProgramPage prologue fault | Reproduced on QEMU with synthetic limit; historical root cause unproven | Offline FLM disassembly shows stackless Init/EraseSector and a 20-byte initial ProgramPage push at 0x20003CA8 with SP 0x200019F0. CFSR 0x00100001 is STKOF plus IACCVIOL; historical msplim/psplim aliases were unsupported, so actual limits were not captured. Correct pyOCD names include msplim_s. New programmer guard rejects incompatible/unknown limits, PSP-selected state or existing STKOF without changing them. |
| Only the default Secure AP transaction attribute blocks reads | Eliminated for the tested aliases | At 21:51 UTC, HNONSEC=1 read attempts at APROM_NS 0x10000000 and SRAM_NS 0x30000000 both returned FAULT ACK. CSW=0x43800052 confirmed bit 30 set; DP CTRL/STAT=0xf0000040. No reset, halt or target writes were requested. |
| Latest programming attempt preserved original APROM | False | First vectors now FF; full hash changed to 043e238a765f7cfbc62596a50e53c8ffb6b188a99357b0ebede251725d67589f after sector erase/program timeout. Original backup is intact. |

## Findings

- 2026-10-29 continued preserving-recovery audit: corrected independent System Information query to `SPUSBHostDataType`, the type listed by this macOS release. The older `SPUSBDataType` silently produces an empty array and is not evidence of absence. The correct type and the full IOUSB plane both show three host controllers with no device descendants; class-filtered IORegistry also shows none. `results/recovery-passive-current.json` records the current evidence and reverified original lower-half backup hash. No device was opened or reset.
- Further exact-EXE D2 audit found only fixed CONFIG-space four/eight-byte reads, not an arbitrary APROM-read API. The parser can report true while copying only min(requested, 52) bytes, and both read helpers can falsely return true after send failure. Twenty-five memory-only emulation cases independently reproduce these host behaviors. No generalized APROM command was added or sent. `results/boot-loader-v1.04/read-audit/FINDINGS.md` records the missing device-side read contract. The existing portable session already rejects short writes/errors rather than duplicating those Boolean-success defects.
- Public M3351 `ISP_DFU` source is application/LDROM-style firmware with its own detect pin and flash routines; it is not the MaskROM handler or a recovery entry for this incomplete APROM. No new applicable preserving-entry procedure was found. The unsent support request now asks for exact ROM read/status/alignment/length semantics in addition to entry and erase boundaries.

- 2026-10-29 CPU-level follow-up: `tests/tools/run_flash_context.py` executed the exact vendor ProgramPage push at 0x20003CA8 with SP 0x200019F0 on QEMU Cortex-M33. Synthetic high MSPLIM 0x20007C00 caused STKOF/FORCED after a stackless control succeeded; zero-limit and guard-refusal controls behaved as expected. This is not a measured historical limit, an IACCVIOL reproduction or a complete M3351 FLM simulation. Evidence: `build/flash-context/results.json`.
- Closed a remaining host guard gap: reject DSCSR.SBRSELEN or domain inconsistency, control/control_s mismatch, and non-Thread xPSR before borrowing RAM or running an algorithm; disable all pack debug sequences. No selectors/limits are rewritten. Host suite: 649 passed. Volatile FLM RAM/core/clock side effects remain explicitly documented; do not resume replaced application context.
- Current independent OS-only checks agree: no USB devices in IORegistry or System Information. Host controllers are present. No new target operation or physical HIL result is available; root cause of missing enumeration is unknown.

- 2026-10-29 offline EXE/FLM follow-up: exact vendor encoding reproduced by 1,283 differential cases and 100 reader cases using isolated x86 emulation. A separate configuration-write wrapper false-success branch was reproduced and corrected only in emulator memory; no native EXE or target was patched. See `docs/bootloader-protocol.md` and `.embedder/hardware/results/boot-loader-v1.04/codec-differential.json`. This is not evidence that that wrapper caused the pyOCD failure.
- Current OS-only IORegistry query returns no matching USB device instances; no probe/serial connection or reset was attempted. The host tool now handles successful empty registry output without a plist error. No new physical acceptance evidence exists.
- `PC=0xEFFFFFFE` is the Armv8-M lockup address, not a recovered faulting FLM instruction. Exact FLM audit and correctly named stack-register analysis are in `.embedder/hardware/results/boot-loader-v1.04/flm-audit/FINDINGS.md`. The historical missing stack limits prevent a definitive causal finding; no automatic reset/stack rewrite is justified.

- Original APROM backup: `.embedder/hardware/results/backup-20261028T201055Z/aprom.bin`, 524288 bytes, SHA256 `cdc14f595cf29c2877cc9b11bc564df62b66e3338a0a77ea35ba533aba0b93d3`. No option/LDROM/security backup claimed.
- Original vector SP 0x20020000, reset vector 0x289. Offline descriptor at 0x4a6a suggests HID mouse VID/PID 0416:B001; nearby config has one HID boot mouse interface. It did not enumerate on host.
- User approved identify/backup, brief reset/halt, then baseline and demo application programming. No mass erase, unlock, option/security changes, or probe firmware changes authorized.

- Later non-halting attach read: DAUTHSTATUS=0xAF, DHCSR=0x80001, DSCSR=0x30001; AP HPROT=3/HNONSEC=0. Secure invasive/non-invasive functions report disabled; nonsecure enabled. This does not identify whether a temporary boot/debug configuration or persistent protection causes the restriction.
- Halt attempts did not reach HALTED. After those attempts APROM and both RAM aliases faulted, so no additional programming was attempted.
- A probe-only hardware reset pulse completed successfully afterward. It did not initialize a target or change flash, option words or authentication settings. Execution of the original application after the pulse is not yet independently verified.
- ARM references: https://support.arm.com/documentation/100734/0100/Debug-for-ARMv8-M/Debug-registers/DAUTHSTATUS and pinned CMSIS `core_cm33.h` debug masks/addresses.

### Follow-up evidence — 2026-10-28, approximately 21:12–21:22 UTC

- A confirmed power cycle with original APROM present gave DAUTHSTATUS=FF. Raw DHCSR halt succeeded (0x130003). SYS_PDID=0x03302140, APWPROT0/1=0, XOMSTS=0, SRAM ECC status=0, SCU_FNSADDR=0x100000, SCU_SRAMNSSET=0. No permanent security configuration was changed.
- The exact KICAE DFP supplies APROM 0x00000000/0x80000 and M3351_AP_512.FLM, with algorithm RAM 0x20000000/0x4000. Its DebugPortStart unconditionally pulses reset. The explicit `tools/pyocd_attach.py` hook retained the vendor map/algorithm and avoided that pulse; a non-programming check reached HALTED.
- Second flash command: `.venv/bin/pyocd load --target m3351kicae --uid 13010000003800F1047546CF0000065D --script tools/pyocd_attach.py -M attach --erase sector -O auto_unlock=false -O load.pre_reset=off -O keep_unwritten=true -O resume_on_disconnect=false -O cache.enable_memory=false --no-reset build/cdc-baseline/zephyr/zephyr.elf`.
- Output reached Erasing, then Programming, then `flash program page timed out` at about 10 s. APROM is now incomplete; restoration is required. No mass erase or security/option-word programming was performed. Both historical attempts used the KI algorithm; the user's later KJ confirmation establishes that this was the wrong SKU selection.
- Immediate passive snapshot: DAUTHSTATUS=FF, DHCSR=0x130003, CFSR=0x100001, HFSR=0x40000000, SFSR=0. FMC_ISPADDR=0xE000, ISPCMD=0x22, ISPTRG=0, ISPSTS=0x20000104. Halted register snapshot: PC=0xEFFFFFFE, LR=0xFFFFFFF9, MSP=0x2001FC00, xPSR=0x41000003, PRIMASK=0. This is a HardFault, not loss of debug authorization during programming.
- Subsequent resume/boot of the incomplete image and cold reset gave LOCKUP with DAUTHSTATUS=AF. Hardware and system reset-vector catch attempts did not recover readable APROM/RAM. Lower SWD clock and under-reset were also unsuccessful. No further programming/erase was attempted.
- The hook's later emulated-reset/PRIMASK revision is experimental and was NOT reached successfully: its PDID/access guard stopped it. Do not treat it as validated or automatically retry it.
- CONFIG0/12 direct reads faulted even while APROM was readable; no value is inferred. Vendor `FMC_ReadConfig` uses ISP READ. No successful configuration-word readback was obtained.
- Final supported diagnostic: standard under-reset at 100 kHz with only `DebugPortStart` disabled via `pack.debug_sequences.disabled_sequences`; no flash algorithm or security writes. Discovery completed, but state remained LOCKUP, DHCSR=0x80001, DAUTHSTATUS=0xAF and secure peripheral reads faulted. See `.embedder/hardware/results/connect-under-reset-without-port-start.json` and `.log`. Sequence conflict alone is not a sufficient explanation/recovery for the current condition.
- Final local integrity check confirms the original 524288-byte backup still has SHA256 `cdc14f595cf29c2877cc9b11bc564df62b66e3338a0a77ea35ba533aba0b93d3`. This is a host-file check, not a successful current target readback. It covers only the lower half of the confirmed KJ APROM; the upper half was not backed up.
- After KJ confirmation, all four application profiles rebuilt successfully with 1024 KiB flash, 128 KiB RAM and zero load offset, retaining ACM/ECM and both Modbus transports. The selected pack's KJ entry and `M3351_AP_1M.FLM` were verified offline. No hardware operations were performed during this correction; corrected build hashes are in `build/validation.json`.
- Detailed snapshots have timestamped filenames under `.embedder/hardware/results/`. Full tool logs include `script-call_iMVbYQOmNF5giNCyP8xQ7ttm.log` (working attach), `script-call_9z2TSWBPtTpkGcA07qAXIoAW.log` (post-timeout core), and `script-call_WdI22kdNIhIaGMhhzK7vTwz8.log` / `script-call_VAgknIHaoB7TFqyrrvQeJtr1.log` (failed reset catches) under the session hardware log directory.

### Corrected KJ follow-up — 2026-10-28, 21:42–21:45 UTC

- Probe-only enumeration confirms the expected Nu-Link2 is still present.
- Passive MEM-AP snapshot, with no reset/halt, still reports DHCSR=0x80001 and DAUTHSTATUS=0xAF; APROM/SRAM and peripheral reads fault. No fresh backup could be obtained.
- Standard under-reset connection at 100 kHz with m3351kjcae, normal vendor sequences and auto_unlock=false resolves the correct 1 MiB map but remains in LOCKUP with the same faults. No flash algorithm was run. Full log: `/Users/embedder/.embedder/hardware/f0d37af793f94e7b/script-call_rMGjY44HNBHbhOem7TUUobhZ.log`.
- Offline executable-code comparison: both FLMs have identical 1544-byte PrgCode SHA256 `92fe8010b78cca2f21758e07a0bb184dfa12252f2a5b9493e60d6fabac06c14f`; device descriptors differ. This does not prove a root cause, but an altered executable algorithm body is not the explanation for the KI/KJ difference.
- Manufacturer-document review has not established a supported non-mass-erase recovery entry for this state via the available macOS/Nu-Link2 path. No further resets/programming or security changes were performed.

### Non-secure alias check — 2026-10-28, 21:51 UTC

- Used the documented pyOCD `hnonsec_lock(1)` context with a raw MEM-AP connection, no pack/core initialization, reset, halt, memory write, or flash algorithm. Both 16-byte reads at APROM_NS 0x10000000 and SRAM_NS 0x30000000 failed with FAULT ACK; CSW after each was 0x43800052 and DP CTRL/STAT was 0xf0000040. No fresh backup was obtained.
- Evidence: `.embedder/hardware/results/nonsecure-alias-20261028T215125587559Z.json`; implementation: `inspect_target.py` profile `nonsecure=true`. Alias addresses are from the M3351 datasheet memory map; HNONSEC selects bus transaction security and does not change target security policy.
- The available documented passive path is exhausted. This is not evidence that mass erase or a security change is required. The next action is a vendor-reviewed connection/recovery procedure, not another blind reset or programming attempt.

### MaskROM ISP review — no further target operation

- Manufacturer documentation describes MaskROM ISP, but CONFIG3 enablement is unknown and invalid APROM is not established as automatic ISP entry. USB ISP is described as HS-USBD despite this board's Full-Speed USB; that discrepancy is unresolved.
- The parent checked both Nuvoton host repositories: NuISPTool-macOS requires LDROM ISP code (HID-only v1.0.1), and ISPTool_Cross_Platform also requires booting LDROM ISP code. Neither explicitly documents M3351 MaskROM compatibility. The Boot Loader ISP Tool manual specifies NuvoISP_BL.exe, without a verified macOS M3351 handshake implementation or packet-level no-write guarantee for Connect.
- Current serial enumeration returned no ports. No handshake, reset, configuration write or programming was attempted. The support request in docs/validation.md now asks about exact MaskROM entry, enabled interface/routing, compatible macOS tooling and a guaranteed non-writing connection sequence. This is a conditional vendor-guidance path, not a validated recovery method.

### Passive host/identity audit — 2026-10-28, 22:16–22:18 UTC

- Saved PDID 0x03302140 independently identifies M3351KJCAE in Nuvoton OpenOCD commit ad7b6fa42ea38f93246429c72ee46918acae789b (`numicro_dap.c:336`); KICAE is 0x03302141. This corroborates the user-confirmed chip without further target access.
- Only original binary backup found in results is 524288 bytes, SHA256 cdc14f595cf29c2877cc9b11bc564df62b66e3338a0a77ea35ba533aba0b93d3, covering 0x00000000–0x0007FFFF. Upper APROM 0x00080000–0x000FFFFF has no original backup.
- IORegistry now exposes /dev/cu.usbmodem1102 through Nu-Link2 CDC ACM interfaces 1/2, same probe 0416:2004 and serial. HID, WebUSB and MSC interfaces are also probe-owned, not target ROM interfaces. No target-native device enumerated. No device was opened and no control lines/reset changed. Evidence: results/host-interface-and-backup-audit.json and results/host-usb-passive-20261028T221626Z.json.
- Pinned vendor numicroM33.cfg examine-end reads vector at 0x4 and, when blank, invokes register-unlock/remap writes and reset halt (lines 46–73). It is not a passive fallback. No OpenOCD target session was opened.

### Boot Loader ISP V1.04 offline review

- The official V1.04 release-history supported-device table (p4) explicitly lists M3351KJCAE. This supersedes earlier uncertainty about product support; ROM-revision compatibility and entry from the current invalid-image state remain unverified.
- The archive ships a Windows GUI PE32/x86 executable, not native macOS: NuvoISP_BL_V1.04.exe SHA256 aed05e31a6a73c760076218dcfbd038e94e579b0287bb86bb2add7ba8daa35f0. Archive SHA256 4a7cfe5cd0207fa99f052ee1038b85c9110684cab9fb9fda2f594867c80ff5a7. Offline audit and PDFs are in results/boot-loader-v1.04; executable not run.
- Manual pp9-10 explicitly warns Nu-Link2-Me may automatically connect/reset at power-up, execute FMC commands and toggle ISPEN, interfering with Boot Loader ISP. This is a documented possible mechanism, not an observed cause of our failure. The manual's ICESW2-#4 example requires board-specific verification; no switch change or reset was performed.
- Manual p13 says the APROM option erases APROM then writes the file at its specified address. Exact erase extent is not defined; treat all 1 MiB as at risk. Erase All includes all APROM and LDROM. The lower-512-KiB backup does not protect the upper half. No safe programming manifest can yet be authorized.
- docs/validation.md contains the expanded unsent vendor request: exact ROM/tool/macOS compatibility; entry with unreadable CONFIG; effects of entry, complete Connect/read, failures/retries and disconnect; onboard probe interference; exact erase ranges and readback/preservation/interruption recovery.

### Final offline evidence handoff

- Added a reproducible provenance/error annex to `docs/validation.md`: pack and KI/KJ FLM hashes, image-local FLM symbols, complete saved second-attempt stderr, and current ELF load intervals. `task_mvspetpb_16c062.log` records the offline artifact recheck; the original backup hash still matches. No probe/serial connection or reset was made for this audit.
- The saved stderr transitions from Erasing to Programming, then reports `flash program page timed out`. Do not label this an erase timeout, treat later `FMC_ISPADDR=0xE000` as a proven failing page, or attribute PC `0xEFFFFFFE` to a specific FLM instruction. Captured LR `0xFFFFFFF9` is an exception-return value; no verified stacked fault PC or instruction trace is available.
- The installed package metadata is pyOCD 0.46.0/pip, not proof of a qualified Nuvoton fork. DFP disconnect writes core/debug-port state even when no reset is requested. Protocol version 2.1.0 and USB bcdDevice are not a confirmed probe firmware revision.
- The vendor-request draft is prepared, explicitly unsent, and separates confirmed V1.04 KJCAE support from unverified ROM entry/current-state recovery, macOS protocol support, full connection/disconnect effects and exact erase preservation. It now includes the full historical second command, pack/FLM hashes and limits of the post-fault PC/LR/FMC evidence. `build/validation.json` records the same audit in machine-readable form.
- Offline verification (`task_mvspgjkb_b22aa9.log`) passed: installed pyOCD version, pack and both FLM hashes, identical KI/KJ PrgCode/PrgData, original 524288-byte backup hash, CDC patch hash, JSON parsing and request consistency. No target connection, serial open, reset or programming was performed. The recovery/physical-test item remains blocked, not completed.

- Evidence-path disambiguation: the current 22-line `results/post-failed-flash.json` is the first-attempt unchanged-backup snapshot, not the second-attempt HardFault capture. The later halted PC/LR/xPSR are in `/Users/embedder/.embedder/hardware/f0d37af793f94e7b/script-call_9z2TSWBPtTpkGcA07qAXIoAW.log`. Current baseline ELF load ranges and hash are recorded in `docs/validation.md` and `build/validation.json`; there is no verified execution-time hash or historical sector/page manifest. These evidence limitations do not authorize another target operation.

## 2026-10-29 — authorized debug/reset and native UART follow-up

The user explicitly authorized opening interfaces, resetting and necessary diagnostic writes, while preservation of flash and security remains required. No mass erase, security/config write, LDROM write or flash algorithm was executed.

- At 21:40:48 UTC, MEM-AP-only status capture found CPUID `0x411fd210`, `DAUTHSTATUS=0xAF`, `DHCSR=0x03080000`, CFSR/HFSR/SFSR zero; APROM/SRAM/peripheral reads still faulted. The session initializes debug transport; it is not passive OS enumeration. Log: `script-call_b1OfG9MEZGLtih50kNu16dO6.log`.
- At 21:40:54 UTC, the documented debug-disable write followed by one hardware reset produced the same lockup/access failure. Log: `script-call_9W7Nz6ZviG3eSK4rqnOoVJMb.log`.
- Correct KJ pack, 100-kHz under-reset, all pack sequences disabled, auto-unlock off, explicit empty user script: discovery completed but core remained LOCKUP, `DAUTHSTATUS=0xAF`, `DHCSR=0x80000`. This eliminates the vendor DebugPortStart pulse as a sufficient explanation for the present failure. Log: `script-call_wZ8SZaWHydC5uJBrwe77DQCq.log`. `connect_check.py` now avoids implicit global config/user scripts and names the local pack explicitly.
- Implemented a bounded native UART adapter in `tools/bootloader_protocol.py` using the already-audited raw framing. Independent UART tests pass, including actual macOS pySerial through a host pseudo-terminal. This does not prove physical ROM compatibility.
- At 21:47:15 UTC, exact-identity Nu-Link VCOM `/dev/cu.usbmodem1202` opened at 115200 8-N-1, DTR on/RTS off. The 62-byte synchronization attempt timed out. At 21:47:21 UTC a second connect-before-reset attempt also timed out. No A0, D2 or flash/config command was sent because synchronization did not succeed. Results are timestamped `rom-uart-*.json`. The raw-host write returning is not proof bytes reached MCU pins.
- At 21:49:33 UTC, eliminated the diagnostic's post-reset wait as a sufficient explanation: `reset.post_delay=0`, and synchronization sent before probe disconnect. This third attempt also timed out before A0; see its timestamped `rom-uart-*.json`. No additional commands followed.
- No further reset/program retry is justified by these unchanged results alone. Need establish board UART switch routing/physical reset delivery and ROM-entry/enable conditions, or a vendor-reviewed access procedure. Configuration remains unreadable, so ROM enablement cannot be inferred from failed reads.

## 2026-10-29 23:30–00:03 UTC — root cause established, access recovered, programming verified

Root cause of the "lockup": the historical interrupted programming left APROM page 0 erased
(`0xFFFFFFFF` vectors). The Secure Bootloader (32 KiB mask ROM) then has no valid application to
start and halts with the ROM/VECMAP state the earlier diagnostics observed. With a debugger
connected during reset, the ROM additionally reports `DAUTHSTATUS=0xAF` (secure debug not
enabled) and every bus access faults, which is why every under-reset connect, halt and ROM-UART
attempt failed. `rom_window_timing.py` showed the difference: if the DP is powered down while
nRESET is pulsed and only powered up afterwards, the ROM finishes, `DAUTHSTATUS` becomes `0xFF`
and the core is accessible. No security, CONFIG or lock was ever active: every documented
CONFIG word reads `0xFFFFFFFF` except CONFIG11 SCRLOCK `0xFFFFFF5A` and CONFIG13 ARLOCK
`0xFFFFFF5A` (both unlocked); FNSADDR = `0x100000`; APWPROT/SCACT/XOM registers zero.

Sequence that recovered access (debug-register writes, FMC volatile command and pin resets only):

1. `rom_window_timing.py`: DP down during nRESET, DP up ~4–6 ms after release. Runs 1–2 reached
   `DAUTHSTATUS=0xFF`, no LOCKUP. Result `rom-window-timing-20261029T233029758867Z.json`.
2. `halted_sde_check.py`: reset-catch halt in ROM, `DHCSR=0x130003`, `S_SDE=1`, `DSCSR=0x30000`
   (Secure), PC in SRAM ROM-copy `0x20000d74`. `halted-sde-check-20261029T233134168582Z.json`.
3. `preflight_config.py`: FMC READ of all documented CONFIG words succeeded (values above);
   the only failing `tools/flash.py` guard was "Unexpected bank/vector mapping" because the ROM
   had left `VECMAP=0x3E000` (remap base `0x0F800000`). `preflight-config-20261029T233448218719Z.json`.
4. `vecmap_restore_backup.py`: volatile FMC `VECMAP` (0x2E) command to page 0 (no flash write;
   reverts on reset), all guards pass, fresh full 1 MiB APROM + LDROM + Data Flash + CONFIG
   backups taken (`.embedder/backups/m3351kjcae-*`). `vecmap-restore-backup-20261029T234007594165Z.json`.
   The historical erased interval is `0xE000–0x110F0` relative to the 2026-10-28 512 KiB backup.
5. Arbitrated `flash` tool, `tools/flash.py --program` (KJ pack, `M3351_AP_1M.FLM`, attach, no reset,
   all guards): sector erase/program `[0, 0x1E000)` of `build/server`, full APROM, CONFIG, LDROM and
   Data Flash verified. First successful programming of this board.
6. `boot_release.py` (clear DEMCR/DHCSR, DP down, one nRESET pulse): UART0 prints the Zephyr banner
   and `Modbus server ready: RTU id10, TCP id1 port502`; J3 enumerates as `0416:B002`
   "NK-M3351 Modbus RTU + TCP". `boot-release-20261029T234626730366Z.json`, boot_and_observe logs.

Repeatable entry for an already-valid APROM (`fpb_reset_halt.py`, now `tools/flash.py
--halt-at-reset-vector`): FPB comparator on the application `Reset_Handler`, `C_DEBUGEN`, DP
down during the nRESET pulse, DP up 50 ms later. The core halts at the first application
instruction (`pc=0x29e4`/`0x2b74`, Secure privileged Thread on MSP, `MSPLIM=0`, `VECMAP=0`),
which satisfies every `tools/flash.py` guard without any volatile FMC command.
`fpb-reset-halt-20261029T235332076922Z.json`, `...235654293523Z.json`. Ordinary `pyocd`
under-reset / reset-halt and the pack `DebugPortStart` sequence keep the DP powered across
reset and therefore always land in the inaccessible ROM state on this part; do not use them.

Verified with that entry: `build/server-usbdbg` (USB debug logging) and the upstream
`samples/subsys/usb/cdc_acm` reference (`2FE3:0001`) were each programmed, booted and
enumerated; then `build/server` was restored with the single integrated command
`tools/flash.py --build-dir build/server --program --probe <id> --halt-at-reset-vector --boot`
(backup `m3351kjcae-aprom-f93feec5…`, boot log 00:02:54 UTC: banner + `Modbus server ready`,
J3 `0416:B002`). Note macOS shows the J3 device `!registered, !matched` with no CDC interfaces
for both our image and the upstream reference sample; that is the pending USB acceptance item,
not a programming problem.

Limits: the Embedder serial provider does not enumerate the Nu-Link VCOM, so UART capture uses
`boot_and_observe.py` (pySerial). The ROM-halt route (steps 1–4) is only needed again if APROM
page 0 is ever left invalid; the historical 512 KiB backup is now superseded by the full 1 MiB
backups above.

## Next probe

Physical USB acceptance of the server image on J3 (why macOS does not create CDC ACM/ECM
interfaces for the enumerated composite device) per `docs/validation.md`. Programming access is
no longer blocked.

## Historical next-probe note (superseded 2026-10-29)

Blocked pending a new, testable physical-routing or reviewed M3351KJCAE recovery hypothesis for the current invalid-image lockup. The user confirms M3351KJCAE on NuMaker M3351KI V1.2 and has macOS only. Current configuration selects m3351kjcae / M3351_AP_1M.FLM and retains the upstream 1 MiB APROM map; the corrected-target connection-only check failed before programming. No cited reference establishes a non-erasing recovery-entry flow through Nu-Link2 CMSIS-DAP for this state. Do not repeat failed pyOCD/reset attempts blindly. Establish a supported connection, preserve/read all accessible 1 MiB APROM and configuration/status, then restore or program only an explicitly approved address interval with verified erase scope and readback. An APROM-only procedure is not sufficient if it can erase the unbacked upper half. The historical 512 KiB backup covers only the lower half; it cannot restore the upper half, configuration, LDROM, data flash, keys or OTP. No evidence makes mass erase/security changes necessary. If proposed, explain exact affected regions and obtain specific approval first. Physical USB acceptance remains pending.

## 2026-10-30: post-recovery J3 RTU observation (application, not flash access)

Flash access is resolved and re-verified: the server build programmed via the arbitrated
flash tool boots and answers raw binary Modbus RTU on the native J3 ACM port
(`/dev/cu.usbmodem1101`, unit 10). `tools/modbus_verify.py board-server --transport rtu`
passes 26 cases; the failures are one reproducible application defect:

- After a burst of ~10+ back-to-back FC6/FC16 transactions the device stops replying
  (no response to any later request). Pattern is content-independent and nondeterministic
  (`rtu_scenarios.py`: same 5-word sequence wedged on runs 1 and 3, passed on 2).
- Host OUT writes of 64 KiB are still accepted while wedged, so the OUT path is alive;
  no reply arrives, 3 s of silence does not recover it, and a DTR close/reopen does not
  recover it either (`rtu_wedge_direction.py`). Only a pin reset recovers.
- Suspect: `lib/modbus/Src/ModbusRtu.c` TX/CDC interaction (tx_pending/irq handshake with
  usbd_cdc_acm `cdc_acm_tx_fifo_space_get`/`tx_fifo.irq`). Not yet root-caused.

This is tracked as the next application item; it does not affect programming/readback.
