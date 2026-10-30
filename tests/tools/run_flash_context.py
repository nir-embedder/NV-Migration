#!/usr/bin/env python3
"""Host-only Cortex-M33 experiment. Never opens a physical target or USB device.

Executes the exact vendor ProgramPage push, not the peripheral-programming body.
QEMU's AN505 SRAM is 32 KiB, so the synthetic high limit is 0x20007c00,
not the historical (unmeasured) M3351 limit. No M3351 peripheral is emulated.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import subprocess
import zipfile

from elftools.elf.elffile import ELFFile

PACK_HASH = "0aae782356a261b976169fb677a5785c8647b5e0a0a93fa1632fb71a04b2dde2"
ASM = r'''
.syntax unified
.cpu cortex-m33
.thumb
.section .vectors,"a",%progbits
.word 0x20007ff0
.word reset_handler
.word fault_handler
.word fault_handler
.word fault_handler
.word fault_handler
.word fault_handler
.rept 9
.word fault_handler
.endr
.section .text,"ax",%progbits
.global reset_handler
.thumb_func
reset_handler:
    ldr r0, =0x10000000
    ldr r1, =0xe000ed08
    str r0, [r1]
    ldr r0, =LIMIT
    msr msplim, r0
    /* Equivalent to pyOCD setting the algorithm SP without changing MSPLIM. */
    ldr r0, =0x200019f0
    msr msp, r0
    /* Stackless control: no peripheral emulation or flash erase occurs. */
    bl stackless_control
#if GUARDED
    mrs r0, msplim
    ldr r1, =0x20000000
    cmp r0, r1
    bhi guard_rejected
#endif
    ldr r3, =program_prologue
    blx r3
    ldr r0, =0x20007ff0
    msr msp, r0
    b success_report
.thumb_func
stackless_control:
    movs r0, #0
    bx lr
.thumb_func
guard_rejected:
    movs r0, #0
    msr msplim, r0
    ldr r0, =0x20007ff0
    msr msp, r0
    b guard_report
.thumb_func
fault_handler:
    mrs r0, msp
    mrs r1, msplim
    ldr r2, =0xe000ed28
    ldr r2, [r2]
    ldr r3, =0xe000ed2c
    ldr r3, [r3]
    /* Only the synthetic VM recovers to print; production never does this. */
    movs r4, #0
    msr msplim, r4
    ldr r4, =0x20007ff0
    msr msp, r4
    b fault_report
.section .vendor_push,"ax",%progbits
.thumb_func
program_prologue:
    .incbin "vendor-push.bin"
    /* Stop after the prologue: deliberately do not execute vendor MMIO. */
    pop {r4,r5,r6,r7,pc}
'''
C = r'''
#include <stdint.h>
static void out(const char *text) {
    register uint32_t r0 __asm__("r0") = 4;
    register const char *r1 __asm__("r1") = text;
    __asm__ volatile("bkpt 0xab" : "+r"(r0) : "r"(r1) : "memory");
}
__attribute__((noreturn)) static void done(uint32_t status) {
    uint32_t args[2] = {0x20026, status};
    register uint32_t r0 __asm__("r0") = 0x20;
    register uint32_t *r1 __asm__("r1") = args;
    __asm__ volatile("bkpt 0xab" : "+r"(r0) : "r"(r1) : "memory");
    for (;;) {}
}
static void hex(const char *name, uint32_t value) {
    char buf[11] = "00000000\n";
    static const char digits[] = "0123456789abcdef";
    for (unsigned i = 0; i < 8; ++i) buf[i] = digits[(value >> (28 - 4 * i)) & 15];
    out(name); out(buf);
}
__attribute__((noreturn)) void success_report(void) {
    out("PROLOGUE_RETURNED\n"); done(LIMIT == 0 ? 0 : 1);
}
__attribute__((noreturn)) void guard_report(void) {
    out("GUARD_REFUSED_BEFORE_VENDOR_PUSH\n"); done(GUARDED && LIMIT != 0 ? 0 : 1);
}
__attribute__((noreturn)) void fault_report(uint32_t sp, uint32_t limit,
                                           uint32_t cfsr, uint32_t hfsr) {
    out("FAULT_AFTER_VENDOR_PUSH\n"); hex("MSP=", sp); hex("MSPLIM=", limit);
    hex("CFSR=", cfsr); hex("HFSR=", hfsr);
    done(!GUARDED && LIMIT != 0 && sp == LIMIT && limit == LIMIT &&
         cfsr == 0x00100000 && hfsr == 0x40000000 ? 0 : 1);
}
'''
LINKER = '''ENTRY(reset_handler)
SECTIONS {
 .vectors 0x10000000 : { KEEP(*(.vectors)) }
 .text 0x10000040 : { *(.text*) *(.rodata*) }
 .vendor_push 0x20003ca8 : { KEEP(*(.vendor_push)) }
 /DISCARD/ : { *(.comment) *(.ARM.attributes) *(.ARM.exidx*) }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pack", type=Path, required=True)
    parser.add_argument("--compiler", type=Path, required=True)
    parser.add_argument("--qemu", type=Path, required=True)
    parser.add_argument("--build-dir", type=Path, required=True,
                        help="output directory for generated simulation sources and evidence")
    args = parser.parse_args()
    pack = args.pack.read_bytes()
    if hashlib.sha256(pack).hexdigest() != PACK_HASH:
        raise ValueError("Unexpected pack hash")
    with zipfile.ZipFile(io.BytesIO(pack)) as archive:
        code = ELFFile(io.BytesIO(archive.read("Flash/M3351_AP_1M.FLM"))).get_section_by_name("PrgCode").data()
    push = code[0x2b4:0x2b6]
    if push != bytes.fromhex("f0b5"):
        raise ValueError("Vendor ProgramPage prologue changed")
    directory = args.build_dir.expanduser().resolve()
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "probe.S").write_text(ASM)
    (directory / "report.c").write_text(C)
    (directory / "layout.ld").write_text(LINKER)
    (directory / "vendor-push.bin").write_bytes(push)
    results = {"scope": "Host-only QEMU Cortex-M33; synthetic limits; exact vendor push only; no M3351 MMIO or physical hardware", "vendor_push_hex": push.hex(), "cases": {}}
    for name, limit, guard in (("compatible", 0, 0), ("inherited_high", 0x20007c00, 0), ("guarded_high", 0x20007c00, 1)):
        elf = directory / (name + ".elf")
        # The Zephyr SDK driver injects picolibc.ld even with -nostdlib.
        # Compile separately and invoke the matching linker with only our script.
        for source in ("probe.S", "report.c"):
            subprocess.run([str(args.compiler.resolve()), "-mcpu=cortex-m33", "-mthumb", "-mfloat-abi=soft", "-Os", "-ffreestanding", "-fno-builtin", f"-DLIMIT={limit}", f"-DGUARDED={guard}", "-c", source, "-o", source + ".o"], cwd=directory, check=True, timeout=30)
        linker = args.compiler.resolve().with_name("arm-zephyr-eabi-ld")
        subprocess.run([str(linker), "-T", "layout.ld", "probe.S.o", "report.c.o", "-o", str(elf)], cwd=directory, check=True, timeout=30)
        run = subprocess.run([str(args.qemu.resolve()), "-M", "mps2-an505", "-nographic", "-monitor", "none", "-serial", "none", "-semihosting-config", "enable=on,target=native", "-kernel", str(elf)], capture_output=True, text=True, timeout=10)
        results["cases"][name] = {"limit": hex(limit), "guard": bool(guard), "elf_sha256": hashlib.sha256(elf.read_bytes()).hexdigest(), "exit_code": run.returncode, "output": run.stdout + run.stderr}
        print(name, run.returncode, run.stdout + run.stderr, flush=True)
        if run.returncode:
            (directory / "results.json").write_text(json.dumps(results, indent=2) + "\n")
            raise RuntimeError(f"Unexpected result for {name}")
    results["compiler"] = subprocess.check_output([str(args.compiler.resolve()), "--version"], text=True).splitlines()[0]
    results["qemu"] = subprocess.check_output([str(args.qemu.resolve()), "--version"], text=True).splitlines()[0]
    (directory / "results.json").write_text(json.dumps(results, indent=2) + "\n")


if __name__ == "__main__":
    main()
