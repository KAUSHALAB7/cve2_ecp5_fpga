// Startup code for CVE2 RISC-V
// RV32E has only 16 registers (x0-x15)

.section .text.init
.global _start

_start:
    // Set stack pointer to top of 8KB SRAM
    li sp, 0x2000         // sp = 0x2000 (8KB)
    
    // Zero BSS section
    la a0, __bss_start
    la a1, __bss_end
clear_bss:
    bge a0, a1, clear_bss_done
    sw zero, 0(a0)
    addi a0, a0, 4
    j clear_bss
clear_bss_done:
    
    // Call main
    call main
    
    // Infinite loop if main returns
hang:
    j hang
