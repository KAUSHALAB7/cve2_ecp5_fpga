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

all: $(HEX) $(LST)

$(ELF): $(OBJS) link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@
	$(SIZE) $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(HEX): $(ELF)
	$(OBJCOPY) -O verilog $< $@

$(LST): $(ELF)
	$(OBJDUMP) -d -S $< > $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(ELF) $(BIN) $(HEX) $(LST) *.map

.PHONY: all clean
