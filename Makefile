PROJ=cve2_top
CONSTR=versa.lpf
TRELLIS?=/usr/share/trellis

# Speed knobs for nextpnr (multi-thread + relaxed effort). Adjust THREADS if needed.
THREADS?=$(shell nproc 2>/dev/null || echo 4)
NEXTPNR_FLAGS?=--um5g-45k --package CABGA381 --lpf ${CONSTR} \
			   --timing-allow-fail --threads $(THREADS) --seed 1

# Try to locate an OpenOCD cfg either from system-wide Trellis
# or from the local prjtrellis checkout in this workspace
PRJTRELLIS_LOCAL?=../ecp5-toolchain/prjtrellis
OPENOCD_CFG:=$(firstword \
	$(wildcard $(TRELLIS)/misc/openocd/ecp5-versa5g.cfg) \
	$(wildcard $(PRJTRELLIS_LOCAL)/misc/openocd/ecp5-versa5g.cfg))

### OpenHW CVE2 sources ###
CVE2_DIR=cve2
CVE2_RTL=$(CVE2_DIR)/rtl
PRIM_RTL=$(CVE2_DIR)/vendor/lowrisc_ip/ip/prim/rtl

# Primitive files needed by cve2_top
PRIM_SOURCES = \
	$(PRIM_RTL)/prim_assert.sv \
	$(PRIM_RTL)/prim_ram_1p_pkg.sv

# Generated Verilog output directory
GEN_DIR=build/generated

# Generated sources (SV->V)
CVE2_GEN_ALL = $(wildcard $(GEN_DIR)/cve2_*.v)
# Exclude SoC/top wrappers and the original simulation-only clock gate
CVE2_GEN = $(filter-out $(GEN_DIR)/cve2_soc_gen.v $(GEN_DIR)/cve2_top_gen.v $(GEN_DIR)/cve2_clock_gate.v,$(CVE2_GEN_ALL))
SOURCES_GEN = $(GEN_DIR)/cve2_soc_gen.v $(GEN_DIR)/cve2_top_gen.v

# FPGA-safe stub to replace simulation-only clock gating
CLOCK_GATE_STUB = cve2_clock_gate_fpga.v

all: ${PROJ}.bit

firmware:
	$(MAKE) -C firmware
	@echo "Updating cve2_soc.v with firmware..."
	./update_firmware.py

gen_sv: firmware
	./gen_sv2v.sh

${PROJ}.json: gen_sv $(CLOCK_GATE_STUB) $(CVE2_GEN) $(SOURCES_GEN)
	yosys -p "read_verilog $(CLOCK_GATE_STUB) $(CVE2_GEN) $(SOURCES_GEN); \
          synth_ecp5 -top top -json $@" 2>&1 | tee synth.log

${PROJ}_out.config: ${PROJ}.json
	nextpnr-ecp5 --json $< --textcfg $@ ${NEXTPNR_FLAGS} 2>&1 | tee pnr.log

${PROJ}.bit: ${PROJ}_out.config
	ecppack --svf-rowsize 100000 --svf ${PROJ}.svf $< $@

${PROJ}.svf: ${PROJ}.bit

prog: ${PROJ}.svf
ifeq ($(strip $(OPENOCD_CFG)),)
	@echo "ERROR: Could not find ecp5-versa5g.cfg. Set TRELLIS=/path/to/trellis or ensure $(PRJTRELLIS_LOCAL) exists."
	@false
else
	openocd -f $(OPENOCD_CFG) -c "transport select jtag; init; svf $<; exit"
endif

clean:
	rm -f *.bit *.svf *_out.config *.json *.log
	$(MAKE) -C firmware clean

.PHONY: all prog clean firmware gen_sv
.PRECIOUS: ${PROJ}.json ${PROJ}_out.config

# Fast path: reprogram only if you didn't change HDL/netlist
prog-only:
ifeq ($(strip $(OPENOCD_CFG)),)
	@echo "ERROR: Could not find ecp5-versa5g.cfg. Set TRELLIS=/path/to/trellis or ensure $(PRJTRELLIS_LOCAL) exists."
	@false
else
	@test -f ${PROJ}.svf || (echo "Missing ${PROJ}.svf; run 'make all' once first." && false)
	openocd -f $(OPENOCD_CFG) -c "transport select jtag; init; svf ${PROJ}.svf; exit"
endif

.PHONY: prog-only
