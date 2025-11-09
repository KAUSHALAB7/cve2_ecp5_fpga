# CVE2 RISC-V on ECP5 FPGA

A complete RISC-V SoC implementation on Lattice ECP5 FPGA (Versa 5G board) using the OpenHW Group CVE2 core.

## Features

- **CPU**: CVE2 RISC-V RV32E core @ 50 MHz
- **Memory**: 8KB on-chip SRAM (unified instruction/data)
- **Peripherals**: GPIO mapped at 0x80000000 (8 LEDs)
- **Firmware**: C programming with GCC RISC-V cross-compiler
- **Toolchain**: Fully open-source (Yosys, nextpnr, ecppack, OpenOCD)
- **Clock**: 100 MHz board clock, 50 MHz CPU (divide-by-2 for timing)

## Current Demo

**Prime Number Display**: LEDs show all prime numbers less than 256 in binary sequence with visible delays, then loop.

## Project Structure

```
cve2_fpga_project/
├── cve2_soc.v              # SoC wrapper (CPU + RAM + GPIO)
├── cve2_top.v              # Board-level top module
├── cve2_clock_gate_fpga.v  # Clock gating wrapper
├── versa.lpf               # Pin constraints for Versa 5G
├── firmware/               # C firmware
│   ├── main.c              # Application code (primes demo)
│   ├── start.S             # Startup assembly
│   ├── delay.S             # Delay routines
│   ├── link.ld             # Linker script (8KB memory map)
│   └── Makefile            # Firmware build
├── cve2/                   # CVE2 core (submodule)
├── build/                  # Generated files (gitignored)
├── update_firmware.py      # Auto-injects firmware into HDL
├── gen_sv2v.sh             # SystemVerilog → Verilog converter
├── Makefile                # Top-level build & program
├── paper_main.tex          # Research paper (LaTeX)
├── fpga_recipe_book.tex    # Practical guide (LaTeX)
└── README.md               # This file
```

## Prerequisites

### Software Tools
- **RISC-V Toolchain**: `riscv64-unknown-elf-gcc` (RV32E support)
- **FPGA Synthesis**: `yosys` (open synthesis)
- **Place & Route**: `nextpnr-ecp5` (for Lattice ECP5)
- **Bitstream Packing**: `ecppack` (part of Project Trellis)
- **Programming**: `openocd` (JTAG programming)
- **SV Converter**: `sv2v` (SystemVerilog to Verilog)
- **Python 3** (for build scripts)

### Hardware
- Lattice ECP5 Versa 5G development board (LFE5UM5G-45F)
- USB cable for JTAG programming

## Quick Start

### 1. Clone Repository
```bash
git clone --recursive https://github.com/YOUR_USERNAME/cve2-fpga.git
cd cve2-fpga
```

### 2. Build and Program FPGA
```bash
make all prog
```

This will:
1. Compile firmware (`firmware/main.c` → `firmware.hex`)
2. Inject firmware into SoC memory initialization
3. Convert SystemVerilog to Verilog
4. Synthesize with Yosys
5. Place & route with nextpnr
6. Pack bitstream with ecppack
7. Program FPGA via OpenOCD

### 3. Observe LEDs
LEDs will display primes in binary:
- `00000010` (2)
- `00000011` (3)
- `00000101` (5)
- `00000111` (7)
- ... up to `11111011` (251)

Then pause and restart.

## Modifying Firmware

### Edit Application Code
```bash
vim firmware/main.c
```

### Rebuild and Program
```bash
make all prog
```

The workflow automatically:
- Compiles C/assembly to ELF
- Converts to Verilog hex
- Updates `cve2_soc.v` memory initialization
- Rebuilds bitstream
- Programs FPGA

### Example: Blink Pattern
```c
#define GPIO_BASE 0x80000000
extern void delay_cycles(void);

int main(void) {
    volatile unsigned int *gpio = (volatile unsigned int *)GPIO_BASE;
    while (1) {
        *gpio = 0xAA;  // 10101010
        delay_cycles();
        *gpio = 0x55;  // 01010101
        delay_cycles();
    }
}
```

## Memory Map

| Address Range         | Size | Description              |
|-----------------------|------|--------------------------|
| `0x00000000-0x00001FFF` | 8KB  | Unified RAM (code+data)  |
| `0x80000000`            | 4B   | GPIO register (LEDs)     |

## Performance and Resources

### FPGA Utilization (LFE5UM5G-45F)
- **LUTs**: ~26,000 / 44,000 (59%)
- **Flip-Flops**: ~7,500 / 44,000 (17%)
- **Block RAM**: ~16 / 108 (15%)

### Timing
- **Board Clock**: 100 MHz
- **CPU Clock**: 50 MHz (divide-by-2)
- **Max Frequency**: 52.54 MHz (per nextpnr)
- **Timing Slack**: Positive at 50 MHz

### Firmware Size
- **Current Demo**: 196 bytes (text section)
- **Available**: 8KB total

## Documentation

### Research Paper
`paper_main.tex` → Compile with:
```bash
./compile_paper.sh
```

Comprehensive 60+ page research paper covering:
- CVE2 architecture
- SoC design
- FPGA flow
- Firmware development
- Performance evaluation

### Recipe Book
`fpga_recipe_book.tex` → Quick practical guide for:
- Tool installation
- Building from scratch
- Debugging techniques
- Adding peripherals

### Firmware Guide
See `FIRMWARE_README.md` for detailed firmware documentation.

## Build Targets

```bash
make firmware    # Build firmware only
make synth       # Synthesize (Yosys)
make pnr         # Place & route (nextpnr)
make bitstream   # Pack bitstream
make prog        # Program FPGA
make all         # Build everything
make clean       # Clean build artifacts
```

## Debugging

### Check Firmware Compilation
```bash
cd firmware
riscv64-unknown-elf-objdump -d firmware.elf | less
```

### View Memory Initialization
```bash
grep "memory\[" cve2_soc.v | head -20
```

### Check Synthesis Log
```bash
grep -i "error\|warning" build/*.log
```

### Verify Timing
```bash
grep "Max frequency" build/*.log
```

## Firmware Update Workflow

The project uses a Python script to embed firmware into HDL:

1. Compile firmware → `firmware.hex`
2. `update_firmware.py` reads hex and rewrites `cve2_soc.v`
3. Synthesis preserves initialization in FPGA configuration

**Why?** Generic `$readmemh` doesn't survive synthesis for inferred RAMs in this flow. Hardcoding ensures firmware is present at FPGA power-up.

## Extending the Project

### Add UART
1. Implement UART peripheral in `cve2_soc.v` at `0x80001000`
2. Add TX/RX pins to `versa.lpf`
3. Use UART in firmware for `printf` debugging

### Enable M Extension
1. Set `RV32M` parameter in CVE2 instantiation
2. Recompile firmware with `-march=rv32em`
3. Use multiplication/division in C code

### Measure Performance
Add cycle counter to firmware:
```c
static inline uint32_t rdcycle(void) {
    uint32_t c;
    asm volatile("csrr %0, cycle" : "=r"(c));
    return c;
}
```

## License

- **CVE2 Core**: Apache 2.0 (OpenHW Group)
- **SoC & Firmware**: MIT License (see LICENSE file)

## Acknowledgments

- [OpenHW Group](https://www.openhwgroup.org/) for CVE2 RISC-V core
- [YosysHQ](https://yosyshq.com/) for open FPGA tools (Yosys, nextpnr)
- [Project Trellis](https://prjtrellis.readthedocs.io/) for ECP5 support
- RISC-V Foundation for ISA specifications

## Contact

For questions or contributions, please open an issue or pull request.

---

Built using open-source FPGA tools
