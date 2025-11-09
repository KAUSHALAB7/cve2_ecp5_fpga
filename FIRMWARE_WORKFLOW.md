# CVE2 RISC-V FPGA Firmware Workflow

## Overview

This project runs C firmware on a CVE2 RISC-V CPU (RV32E) on an ECP5 FPGA at 50 MHz.

## Workflow: C Code → FPGA

The complete workflow is **automated** via the Makefile:

```bash
make all prog
```

### What happens behind the scenes:

1. **`make firmware`** (in firmware/ directory):
   - Compiles `main.c` with `riscv64-unknown-elf-gcc`
   - Links with `start.S` (startup code) and `delay.S` (assembly delay)
   - Generates `firmware.hex` (Verilog hex format)

2. **`update_firmware.py`** (automatic):
   - Parses `firmware/firmware.hex`
   - Updates `cve2_soc.v` with hardcoded memory initialization
   - **Why?** Yosys doesn't synthesize `$readmemh` into FPGA block RAM

3. **`gen_sv2v.sh`**:
   - Converts SystemVerilog CVE2 core to Verilog
   - Generates files in `build/generated/`

4. **Synthesis & P&R**:
   - Yosys: RTL → JSON netlist
   - nextpnr-ecp5: Place & route
   - ecppack: Generate bitstream

5. **Programming**:
   - OpenOCD: Upload bitstream via JTAG

## Editing Firmware

Just edit the C code and run `make all prog`:

```bash
# Edit your firmware
vim firmware/main.c

# Build and program FPGA
make all prog
```

The script automatically updates the HDL with your new firmware!

## Current Firmware

**Knight Rider pattern** - single LED sweeping back and forth across 8 LEDs.

## Memory Map

- `0x00000000 - 0x00001FFF`: 8KB SRAM (code + data)
- `0x80000000`: GPIO register (bits [7:0] = LEDs)

## Technical Details

- **CPU**: CVE2 RV32E (16 registers, no multiply)
- **Clock**: 50 MHz (100 MHz input ÷ 2)
- **Max frequency**: 52 MHz (per STA)
- **Compiler**: `riscv64-unknown-elf-gcc -march=rv32e -mabi=ilp32e -O1`
- **LEDs**: Active-LOW (HDL inverts: `led = ~gpio_out`)

## Files

- `firmware/main.c` - Your application code
- `firmware/start.S` - Startup code (sets stack, clears BSS)
- `firmware/delay.S` - Assembly delay (prevents compiler optimization)
- `firmware/link.ld` - Linker script
- `update_firmware.py` - Auto-updates HDL with firmware
- `cve2_soc.v` - SoC wrapper (memory, GPIO, CPU)
