# Firmware Makefile for CVE2 RISC-V (RV32E)

# Toolchain - use riscv64 toolchain with 32-bit flags
PREFIX = riscv64-unknown-elf-
CC = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump
SIZE = $(PREFIX)size

# Flags for RV32E (16 registers, no multiply)
ARCH = rv32e
ABI = ilp32e
CFLAGS = -march=$(ARCH) -mabi=$(ABI) -O1 -Wall -Wextra \
         -ffreestanding -nostdlib -nostartfiles \
         -fno-builtin -ffunction-sections -fdata-sections

LDFLAGS = -T link.ld -Wl,-Map=firmware.map

# Source files
SRCS = start.S main.c delay.S
OBJS = $(SRCS:.c=.o)
OBJS := $(OBJS:.S=.o)

# Output files
ELF = firmware.elf
BIN = firmware.bin
HEX = firmware.hex
LST = firmware.lst
INIT_VH = firmware_init.vh

all: $(HEX) $(LST) $(INIT_VH)

$(ELF): $(OBJS) link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@
	$(SIZE) $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(HEX): $(ELF)
	$(OBJCOPY) -O verilog $< $@

$(LST): $(ELF)
	$(OBJDUMP) -d -S $< > $@

# Generate Verilog include file for memory initialization
# Convert hex format to memory[addr] = 32'hXXXXXXXX; statements
$(INIT_VH): $(HEX)
	@echo "// Auto-generated firmware initialization - DO NOT EDIT" > $@
	@echo "// Generated from firmware.hex on $$(date)" >> $@
	@awk 'BEGIN { addr = 0; } \
	      /^@/ { addr = strtonum("0x" substr($$0, 2)) / 4; next; } \
	      /^[0-9A-Fa-f]/ { \
	          gsub(/\r/, ""); \
	          split($$0, bytes, " "); \
	          for (i = 1; i + 3 <= NF; i += 4) { \
	              word = bytes[i+3] bytes[i+2] bytes[i+1] bytes[i]; \
	              printf("        memory[%d] = 32'\''h%s;\n", addr, word); \
	              addr++; \
	          } \
	      }' $< >> $@
	@echo "Firmware init file generated: $@"

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(ELF) $(BIN) $(HEX) $(LST) $(INIT_VH) *.map

.PHONY: all clean
