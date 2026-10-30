
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
