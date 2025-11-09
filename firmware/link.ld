/* Linker script for CVE2 RISC-V on ECP5 with 8KB SRAM */

ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 8K
}

SECTIONS
{
    .text : ALIGN(4) {
        KEEP(*(.text.init))
        *(.text*)
        . = ALIGN(4);
    } > RAM

    .rodata : ALIGN(4) {
        *(.rodata*)
        . = ALIGN(4);
    } > RAM

    .data : ALIGN(4) {
        __data_start = .;
        *(.data*)
        . = ALIGN(4);
        __data_end = .;
    } > RAM

    .bss : ALIGN(4) {
        __bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM

    . = ALIGN(4);
    _end = .;
    
    /* Stack starts at end of used RAM, grows down */
    PROVIDE(__stack_top = 0x2000);  /* Top of 8KB */
}
