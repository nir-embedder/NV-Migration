# Exact M3351 DFP 1.0.6 FLM offline audit

## Scope and evidence boundary

No hardware/probe/serial operation, reset, vendor EXE execution, download, or security change was performed. Files were created only in this audit directory. Existing identity/backup conclusions were not re-audited. The full original `FlashPrg.c` is not supplied by this cached pack; analysis uses every executable byte, embedded DWARF source-line mappings, cached pack register headers, and the installed pyOCD 0.46.0 source. DWARF line references are not a claim that the original C text was recovered.

**New material finding:** `CFSR=0x00100001` is **STKOF + IACCVIOL**, not INVSTATE/INVPC. Inherited Cortex-M33 stack limits are a specifically supported failure mechanism missing from the current programming context guards. `PC=0xEFFFFFFE` is the Armv8-M architectural lockup PC, not an FLM instruction or evidence of a particular corrupt return address. This does not prove which event happened first.

## Exact artifacts and differences

Cached pack: `/Users/embedder/.embedder/downloads/799943d72f89b55f/Nuvoton.NuMicroM33_DFP.1.0.6.pack`.

| Artifact | SHA-256 |
|---|---|
| Pack | `0aae782356a261b976169fb677a5785c8647b5e0a0a93fa1632fb71a04b2dde2` |
| `Flash/M3351_AP_512.FLM` | `8729859484afaa838c46bc7094fdcd6f4f29f908cadac5b3d6d901cb6928d473` |
| `Flash/M3351_AP_1M.FLM` | `6ad56e7e085dae4ed3f61abd6bcc2edde2ffd53424ca28a6fedc6d743b369717` |
| Both `PrgCode`, 1544 bytes | `92fe8010b78cca2f21758e07a0bb184dfa12252f2a5b9493e60d6fabac06c14f` |
| Both `PrgData`, four zero bytes | `df3f619804a92fdb4057192dc43dd748ea778adc52bc498ce80524c014b81119` |
| Both pyOCD-loaded blobs, 1552 bytes including 4-byte breakpoint header | `b5dfba4c4dbd18cd1d385ec6736296a6aa6269c100558b0603b06a4d33315348` |

Every ELF section is byte-identical except `DevDscr` and `.comment`. `DevDscr` differs only at section offsets `0xE,0xF,0x10,0x11,0x12,0x8A`: device-name text and flash size. Names are `M3351 APROM 512kB` versus `M3351 APROM 1MB`; sizes are `0x80000` versus `0x100000`. Both start at zero, advertise page/sector size `0x2000`, erased value `0xFF`, programming timeout 1000 ms and erase timeout 3000 ms. `.comment` is non-executable build metadata. All DWARF sections and symbols are identical.

Therefore the wrong KI choice changes host geometry/coverage, not the executable routines, clock setup, CPU context handling, or page/stack placement. Correct KJ selection remains required, but switching to the 1M FLM alone cannot fix a CPU-context failure shared by the identical code. Neither code body contains a SKU-specific APROM upper-bound check; geometry enforcement belongs to the host's selected region.

## Execution layout and preparation

Recomputed using the installed `PackFlashAlgo.get_pyocd_flash_algo(0x2000, RamRegion(0x20000000,0x4000))`; matches saved log `/Users/embedder/.embedder/hardware/f0d37af793f94e7b/script-call_9z2TSWBPtTpkGcA07qAXIoAW.log:142-144`.

| Item | Address/range |
|---|---|
| pyOCD breakpoint/return header | `0x200039F0..0x200039F3` (`bkpt 0; b .-2`) |
| executable code | `0x200039F4..0x20003FFB` |
| static base / PrgData | `0x20003FFC..0x20003FFF` |
| page buffer, one buffer | `0x200019F0..0x200039EF` |
| stack allocation, downward | `0x20000000..0x200019EF`; initial SP `0x200019F0` |
| Init | image Thumb `0x1`; runtime Thumb `0x200039F5` |
| UnInit | image Thumb `0xCD`; runtime Thumb `0x20003AC1` |
| EraseSector | image Thumb `0x103`; runtime Thumb `0x20003AF7` |
| EraseSectorEx, not a standard pyOCD entry | image Thumb `0x1BD`; runtime Thumb `0x20003BB1` |
| ProgramPage | image Thumb `0x2B5`; runtime Thumb `0x20003CA9` |
| Verify, not exposed by this generated dictionary | image Thumb `0x4FD`; runtime Thumb `0x20003EF1` |

Installed pyOCD `flash/flash.py:223-240,309-315,548-583` halts (unless reset explicitly selected), invokes a default **no-op** `prepare_target`, loads the blob, and writes PC/arguments/LR. On Init it additionally sets R9, SP and xPSR Thumb state. It does not establish PRIMASK, BASEPRI, CONTROL.SPSEL, MPU, VTOR, NVIC/SysTick, MSPLIM or PSPLIM. LR is set to `0x200039F1`, not the later captured exception-return value. `flash_algo.py:168-258` establishes the layout above.

## What the FLM actually changes

Complete disassembly is in `M3351_AP_1M.asm` and `M3351_AP_512.asm`; all 1544 code bytes decode within the six function symbols, with no gaps. There is no `MSR`, `CPSID`, `CPSIE`, `BL` or `BLX`. Helper operations are inlined. No routine writes SCB/NVIC/SysTick/MPU/SAU or core stack-limit registers. Normal execution therefore inherits interrupt masks, stack selection/limits, vector table and memory permissions; it is not an execution-context reset.

- **Init** (`image 0x0000..0x00CB`, asm lines 6-90): writes `0x59,0x16,0x88` to SYS_REGLCTL `0x40000100`, checks unlocked state. Enables HIRC through CLK_PWRCTL `0x40000200` bit 2 if necessary; waits for CLK_STATUS `0x40000250` bit 4. Selects HCLK source 7 at `0x40000210`, clears CLKDIV0 `0x40000220`, enables ISP/DFMC clocks (`0x40000204 |= 0x4004`). Writes FMC_ISPCTL `0x4000C000=0xE9`; bit 6 clears fail status, APROM/LDROM/Data update enables are set, **CONFIG update bit 4 remains clear**, and ISP interrupt-enable bit 24 is cleared. Sets FMC_CYCCTL `0x4000C04C=2`.
- Init conditionally reads `0x4000FFFC` and accesses DFMC `0x4000F000`; sets control `0x49`, and, if DFMC_ISPSTS bit 11 is set, issues command `0x33` at address `0x0F21E000`. The cached DFMC header names this **EEPROM emulation initial read**, not erase/program. Then sets DFMC_CYCCTL `0x4000F04C=2`. Init's three API arguments are overwritten before use; `VERIFY` Init performs the same register setup.
- **UnInit** (`0xCC..0x101`, asm lines 92-113): waits for busy to clear and writes zero to FMC and conditional DFMC ISPCTL. It does **not** restore original clock/divider/cycle settings or relock SYS_REGLCTL. It does not repair CPU context.
- **EraseSector** (`0x102..0x1BB`, asm lines 115-187): normal APROM path writes `ISPCMD=0x22`, `ISPADDR=(adr & 0xEFFFE000)`, `ISPDAT=0`, triggers, polls busy, and tests/clears fail status. Alternate DFMC path aligns to 4 KiB. No pushes, no frame allocation, no interrupt/vector/MPU manipulation.
- **ProgramPage** (`0x2B4..0x4FB`, asm lines 287-508): **first instruction is `push {r4,r5,r6,r7,lr}`**, at actual instruction address `0x20003CA8`. That requires 20 bytes below initial SP, down to `0x200019DC`. The normal aligned APROM path reads two words from the page buffer and issues `ISPCMD=0x61` (64-bit program), polls busy, increments by eight. Alternate data-flash/EEPROM paths also exist. It does not erase. A fault before its first controller write can leave the last completed erase's `ISPCMD=0x22` and `ISPADDR` unchanged.
- `EraseSectorEx` and `Verify` also use stack frames, but standard generated pyOCD entries do not call `EraseSectorEx`, and the installed generated dictionary does not expose FLM `Verify` as a callable verification entry.

Register meanings are anchored to exact cached-pack member/line excerpts in `pack-source-excerpts.txt`, including FMC/DFMC headers and command definitions. Header interpretation is corroboration of the disassembly, not proof that these header copies built the FLM.

## Saved snapshots: do not conflate attempts

1. `/Users/embedder/Desktop/Nuvoton/.embedder/hardware/results/post-failed-flash.json:1-20` is the **first** attempt: running state, no readable core registers, CFSR/HFSR zero, unchanged APROM. Its 16 bytes at `0x20003C00` (`74fa3868c003fcd51d48f86038688003`) do not occur in either exact APROM FLM PrgCode. They do not prove the algorithm was executing there.
2. `/Users/embedder/Desktop/Nuvoton/.embedder/hardware/results/passive-snapshot-20261028T211754816957Z.json:24-57` is the **second** attempt: CFSR `0x00100001`, HFSR `0x40000000`, DAUTHSTATUS `0xFF`, first 16 APROM bytes erased, controller command `0x22`, address `0xE000`, trigger zero. Its SRAM sample `4ef20006cef6ff764cf200070025c4f2` matches FLM code offset `0x20C`, exactly relocated at `0x20003C00`. This verifies only that sample and relocation, not every loaded byte or which instruction executed.
3. Later core log `/Users/embedder/.embedder/hardware/f0d37af793f94e7b/script-call_9z2TSWBPtTpkGcA07qAXIoAW.log:58-70` records PC `0xEFFFFFFE`, LR `0xFFFFFFF9`, MSP `0x2001FC00`, PSP `0x20020000`, CONTROL=0, PRIMASK=BASEPRI=FAULTMASK=0, xPSR `0x41000003`. It explicitly failed to read names `msplim` and `psplim`. The supported installed pyOCD names are **`msplim_s`, `psplim_s`, `msplim_ns`, `psplim_ns`** (`cortex_m_core_registers.py:162-186`). No limit values were captured.

## Supported fault mechanisms and limits

**Architectural facts:** cached `/Users/embedder/.embedder/downloads/ca5a67950f84a6f4/DDI0553A_k_armv8m_arm.pdf` (Arm DDI0553A.k), B3.21 pp97-99, B3.31 pp118-119, and D1.2 UFSR p1193; relevant fine print was checked with PDF zoom. CMSIS `core_cm33.h:767-819` corroborates the masks.

- CFSR bit20 is UFSR.STKOF, bit0 is MMFSR.IACCVIOL. HFSR bit30 is FORCED. INVSTATE, INVPC, data bus-fault and valid fault-address bits are absent in this sample. Sticky fault bits do not record chronology.
- On stack-limit violations during exception entry the architecture sets SP to the limit and suppresses pushes below it. An instruction updating SP below its applicable limit generates STKOF. The initial algorithm SP is far below captured MSP `0x2001FC00`; an inherited high MSPLIM is a strong candidate, especially because Init/UnInit/EraseSector are stackless while ProgramPage first pushes. A hypothetical `MSPLIM_S=0x2001FC00` would explain why erase ran but the first programming call faulted and why exception entry left MSP at that high value. **The hypothetical limit was not measured.** This is a mechanism supported by the code and flags, not a proven root cause or proof of the first failing instruction.
- Cortex-M33 PC `0xEFFFFFFE` is the architecture-defined **lockup address**. Entering Debug state exits lockup and clears S_LOCKUP; therefore captured halted `DHCSR=0x00130003` without S_LOCKUP does not contradict prior lockup. Resuming unmodified from this PC itself guarantees IACCVIOL. PC alone cannot identify a bad FLM return, a particular vector value, or an MPU rule.
- Unmasked interrupts into erased/stale application vectors remain possible: PRIMASK was zero, no FLM IRQ/VTOR setup exists, and APROM's HardFault vector slot at `0xC` was erased in the saved sample. **Active VTOR and pre-fault NVIC/SysTick/SHCSR state were not captured**, so this chain is conditional. A resulting exception can itself hit inherited stack limits.
- An MPU execute-never rule for SRAM could produce IACCVIOL, but MPU state was not captured; successful stackless RAM erase execution would weigh against a fixed blanket SRAM-XN explanation. Lockup/address execution is an alternative explanation for IACCVIOL. Do not equate IACCVIOL with proof of an enabled MPU region.
- The saved `ISPCMD=0x22`, `ISPADDR=0xE000`, `ISPTRG=0` are consistent with the final completed erase and a ProgramPage prologue fault. They do not establish a program operation at `0xE000`, a hardware busy hang, or the page that timed out. The reported error remains a **programming-stage timeout**.
- DAUTHSTATUS `0xFF` at failure and SFSR zero do not support permanent debug-lock as the cause of this captured event. No revised security setting is justified.

## Focused follow-up: narrow fail-closed guard, not a recovery workaround

The completed comparison `/Users/embedder/Desktop/Nuvoton/.embedder/hardware/results/flm-comparison/findings.txt:14-32` is the reference for the shared FLM behavior and saved fault evidence. Its findings agree with this audit. No additional binary comparison is needed for the following recommendation.

### What the current host code does and does not handle

- Current `/Users/embedder/Desktop/Nuvoton/tools/flash.py:325-351` checks HALTED, IPSR==0 and CONTROL.nPRIV==0; then temporarily sets PRIMASK=1 and MPU_CTRL=0. It does **not** inspect MSPLIM/PSPLIM, CONTROL.SPSEL, or the CPU's current security domain. `ap.hnonsec_lock(0)` at line 361 selects memory transaction attributes, not the core's executing domain or active register bank.
- Installed `.venv/lib/python3.12/site-packages/pyocd/flash/flash.py:548-583` writes arguments/PC/LR; Init additionally writes R9, **the currently selected SP** and xPSR=`0x01000000`. This establishes intended Thumb status but does not write CONTROL or any stack limit. An xPSR write is not a comprehensive exception/stack-context reset and must not be used as a substitute for rejecting the captured HardFault state.
- Installed `pyocd/coresight/cortex_m.py:1424-1517` maps register names to DCRSR selectors and writes them. Writing a PRIMASK subregister preserves the other CFBP bytes, including CONTROL; it does not normalize SPSEL. No implicit stack-limit preparation is present in that path. `flash.py:309-315` provides an empty base `prepare_target()`.
- Installed `pyocd/coresight/cortex_m_core_registers.py:162-186` has `msplim_s`, `psplim_s`, `msplim_ns`, `psplim_ns`; it has no unsuffixed `msplim`/`psplim` aliases. Explicit names matter: the saved log's unsuffixed reads failed, so the historical limits remain unknown.
- The experimental emulated reset is not the missing fix: `pyocd/coresight/cortex_m.py:818-868` writes xPSR/CFBP, selected stack pointers and several SCS registers, but omits stack-limit registers and MPU. It was not successfully executed in this case.

### Recommended rejection-only preflight

Before the first Init, and preferably at the existing early context check **before scratch/FMC writes**, add a read-only guard. Recheck it immediately before entering `flash_execution_context` if any intervening setup could change context. Do not write a limit, change CONTROL, clear fault status, relocate vectors, reset, or retry on failure.

1. Retain HALTED and Thread-mode checks. Verify actual xPSR has IPSR==0 (`xpsr & 0x1FF == 0`) and Thumb state set (`xpsr & 0x01000000 != 0`). If a register read is unsupported, fails, or is inconsistent, refuse programming. Setting xPSR later must not be treated as repair permission.
2. Deliberately support only the known **Secure, privileged, MSP-based Thread** case for this guard. Read the current domain using the installed core `get_security_state()` (`cortex_m_v8m.py:239-248` reads DSCSR.CDS), and refuse Non-secure/unknown state. Require CONTROL.nPRIV=0 **and CONTROL.SPSEL=0** (`control & 3 == 0`), with matching explicit `control_s`. Conservatively require DSCSR.SBRSELEN=0 (`dscsr & 1 == 0`) so unbanked debug register accesses follow the confirmed current domain; reject an override rather than change DSCSR.SBRSELEN/SBRSEL. These bits are defined at `cortex_m_v8m.py:36-40`. No automatic switch from PSP or another domain.
3. Read **`msplim_s`**, not an unsuffixed alias. Read the chosen flash algorithm's `end_stack` and `begin_stack` metadata; reject missing/invalid metadata. Require `msplim_s <= end_stack < begin_stack` with both allocation boundaries in the approved algorithm RAM. For the audited layout this means **MSPLIM_S <= `0x20000000`**, with `begin_stack=0x200019F0`. This conservative condition accepts a compatible existing limit and rejects a high inherited limit without changing it. Merely checking `msplim_s < begin_stack` is insufficient to cover the entire stack allocation.
4. Refuse a pre-existing `CFSR & 0x00100000` (STKOF) rather than clear it and continue. Together with the retained IPSR check, this prevents interpreting the saved HardFault/stack-overflow state as a programming entry condition. A zero STKOF bit is necessary for this guard, not proof that context is otherwise safe.

PSPLIM_S and Non-secure limits do not govern the accepted Secure-MSP path and need not be altered or required to be zero. If PSP-based execution is ever supported, it requires a separately reviewed PSPLIM guard plus a valid MSP/limit for exception entry; do not expand this minimal guard by silently changing stack selection.

The stricter low-limit condition intentionally rejects otherwise potentially usable configurations instead of attempting recovery. It addresses the demonstrated preparation gap; it does **not** prove historical MSPLIM caused STKOF or authorize another connection/erase/program attempt. IRQ/MPU preparation still cannot prevent every fault/NMI path. The existing recovery stop, backup/preservation gates and HIL-qualification requirement remain in force. No tools/tests or existing evidence were edited.

## Reproduction/checks

From project root:

```sh
.venv/bin/python -B .embedder/hardware/results/boot-loader-v1.04/flm-audit/audit_flm.py
```

The run passed: both FLMs parsed; all 1544 executable bytes decoded into their function ranges; code/data equality and absence of MSR/CPSID/CPSIE/BL/BLX asserted; layouts and snapshot matches recomputed. `audit.json` records exact section differences, hashes, source-file hashes at audit time and parser versions. These are host-only static checks, not emulated execution or hardware tests.
