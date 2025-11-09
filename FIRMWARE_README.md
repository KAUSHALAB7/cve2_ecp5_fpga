# CVE2 RISC-V Firmware Workflow

## Overview

This project now uses **C firmware compiled with GCC** instead of hardcoded assembly in the Verilog. The Knight Rider LED pattern sweeps a single LED back and forth.

## What Changed

### 1. **Firmware Directory** (`firmware/`)

```
firmware/
├── main.c        # Knight Rider LED pattern in C
├── start.S       # RISC-V startup code (sets stack, clears BSS, calls main)
├── link.ld       # Linker script for 8KB SRAM at 0x00000000
├── Makefile      # Compiles C to firmware.hex
└── firmware.hex  # Generated hex file (loaded into FPGA memory)
```

### 2. **C Code** (`firmware/main.c`)

- **GPIO base address**: `0x80000000`
- **Pattern**: Single LED sweeping left-right (bouncing at edges)
- **Delay**: Software delay loop for visible movement
- **Active-LOW**: LEDs invert in hardware (Versa 5G board)

### 3. **Memory Loading** (`cve2_soc.v`)

**OLD (hardcoded):**
```verilog
initial begin
    memory[0] = 32'h80000537;  // Assembly instructions
    memory[1] = 32'h00000593;
    ...
end
```

**NEW (loaded from hex):**
```verilog
initial begin
    $readmemh("firmware/firmware.hex", memory);
end
```

### 4. **Clock Frequency**

**OLD**: Divide by 2^21 → ~47.7 Hz CPU clock (for visible counter)

**NEW**: Divide by 4 → ~25 MHz CPU clock (proper frequency for firmware)

```verilog
reg [1:0] clk_div;
assign clk_cpu = clk_div[1];  // 100 MHz / 4 = 25 MHz
```

## Build Flow

```bash
make all      # Builds firmware, synthesizes, P&R, generates bitstream
make prog     # Programs FPGA via JTAG
```

**Detailed steps:**
1. `make firmware` → Compiles C code to `firmware/firmware.hex`
2. `make gen_sv` → Converts SystemVerilog to Verilog (sv2v)
3. Yosys reads `firmware.hex` during synthesis (`$readmemh`)
4. nextpnr places and routes
5. ecppack generates bitstream
6. OpenOCD programs FPGA

## Firmware Development

### Modify the C Code

Edit `firmware/main.c`:

```c
#define GPIO_BASE 0x80000000
#define GPIO_REG (*(volatile unsigned int *)GPIO_BASE)

void delay(unsigned int count) {
    for (volatile unsigned int i = 0; i < count; i++) {
        asm volatile ("nop");
    }
}

int main(void) {
    // Your code here
    while (1) {
        GPIO_REG = 0x01;  // LED pattern
        delay(50000);
    }
    return 0;
}
```

### Rebuild and Reprogram

```bash
cd firmware
make              # Rebuild firmware only
cd ..
make all prog     # Full rebuild and program
```

## Quick Reprogram (Firmware Only)

If you **only change firmware** (no RTL changes):

```bash
cd firmware && make && cd ..
make synth        # Fast: skips sv2v
make pnr bit prog # Place-route-program
```

## Memory Map

| Address Range       | Purpose       | Notes                        |
|---------------------|---------------|------------------------------|
| `0x00000000-0x1FFF` | 8KB SRAM      | Code + data                  |
| `0x80000000`        | GPIO register | Bits [7:0] = LEDs (active-LOW) |
| `0x80000000`        | GPIO register | Bits [21:8] = 14-seg display |

## Toolchain Requirements

- **RISC-V GCC**: `riscv64-unknown-elf-gcc` (installed on your system)
- **Architecture**: RV32E (16 registers)
- **ABI**: `ilp32e`
- **No multiply**: M extension disabled to save area

## Expected Behavior

After programming:
1. Single LED starts at position 0 (right-most)
2. Sweeps left (LED 0→1→2→3→4→5→6→7)
3. Bounces back (7→6→5→4→3→2→1→0)
4. Repeats forever

**Timing**: ~0.1 second per position (depends on delay value)

## Troubleshooting

### Firmware doesn't compile

```bash
# Check toolchain
riscv64-unknown-elf-gcc --version

# Should see: gcc version ... for riscv64-unknown-elf
```

### LEDs don't move

1. Check hex file exists: `ls -lh firmware/firmware.hex`
2. Verify synthesis log shows memory initialization:
   ```bash
   grep readmemh *.log
   ```

### Wrong LED pattern

- Adjust `delay()` count in `main.c`
- Change Knight Rider logic (direction, speed)
- Rebuild firmware and reprogram

### Build fails after firmware change

```bash
# Clean and rebuild
make clean
make all prog
```

## Advanced: Custom Firmware

### Add UART Output

1. Implement UART peripheral in `cve2_soc.v` at address `0x80001000`
2. Update `main.c` to write characters to UART register
3. Rebuild

### Use Multiply Instructions

1. Change CVE2 parameter in `cve2_soc.v`:
   ```verilog
   .RV32M(cve2_pkg::RV32MSlow),  // Enable multiply
   ```
2. Use `*` operator in C code
3. Area increases by ~30%

### Boot from SPI Flash

1. Use `ecppack --bootaddr` and `--spimode` flags
2. Load firmware to SPI flash instead of internal memory
3. Beyond scope (requires bootloader)

## Files Modified

- **NEW**: `firmware/` directory (all files)
- **MODIFIED**: `cve2_soc.v` (clock divider, memory loading)
- **MODIFIED**: `Makefile` (firmware dependency)

## Performance

- **CPU frequency**: 25 MHz (STA reports 53.58 MHz max)
- **Instruction throughput**: ~20-25 MIPS (depends on code)
- **LED update rate**: ~10 Hz (software delay-limited)

## Next Steps

1. Add more peripherals (UART, SPI, timer)
2. Implement interrupt handling
3. Port FreeRTOS or bare-metal scheduler
4. Add external DRAM interface
5. Run RISC-V compliance tests

---

**Generated**: November 5, 2025  
**Status**: ✅ Working with Knight Rider pattern at 25 MHz
