#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

GEN_DIR=build/generated
CVE2_RTL=cve2/rtl
PRIM_RTL=cve2/vendor/lowrisc_ip/ip/prim/rtl

mkdir -p "$GEN_DIR"

# Function to run sv2v for one source
sv_convert() {
  local src="$1" out="$2"
  ~/.local/bin/sv2v \
    --define=SYNTHESIS \
    $CVE2_RTL/*_pkg.sv \
    $PRIM_RTL/prim_ram_1p_pkg.sv \
    $PRIM_RTL/prim_secded_pkg.sv \
    -I$PRIM_RTL \
    -Icve2/vendor/lowrisc_ip/dv/sv/dv_utils \
    "$src" > "$out"
}

# Convert CVE2 core and top (skip packages)
for f in $CVE2_RTL/*.sv; do
  base=$(basename "$f")
  mod="${base%.sv}"
  if [[ "$mod" == *_pkg ]]; then continue; fi
  sv_convert "$f" "$GEN_DIR/${mod}.v"
done

# Remove not-needed variants
rm -f "$GEN_DIR/cve2_tracer.v" || true
rm -f "$GEN_DIR/cve2_top_tracing.v" || true
rm -f "$GEN_DIR/cve2_register_file_latch.v" || true
rm -f "$GEN_DIR/cve2_register_file_fpga.v" || true

# Convert our SoC and top as well (so we fully avoid SV in yosys)
sv_convert cve2_soc.v "$GEN_DIR/cve2_soc_gen.v"
sv_convert cve2_top.v "$GEN_DIR/cve2_top_gen.v"

echo "SV2V conversion done. Generated in $GEN_DIR"