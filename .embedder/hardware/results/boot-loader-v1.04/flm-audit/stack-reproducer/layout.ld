ENTRY(reset_handler)
SECTIONS {
 .vectors 0x10000000 : { KEEP(*(.vectors)) }
 .text 0x10000040 : { *(.text*) *(.rodata*) }
 .vendor_push 0x20003ca8 : { KEEP(*(.vendor_push)) }
 /DISCARD/ : { *(.comment) *(.ARM.attributes) *(.ARM.exidx*) }
}
