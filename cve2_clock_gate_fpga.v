// FPGA-safe replacement for CVE2 clock gate: do not gate clocks on FPGA
module cve2_clock_gate(
    input  wire clk_i,
    input  wire en_i,
    input  wire scan_cg_en_i,
    output wire clk_o
);
    // For FPGA, use clock enables instead of gating. Pass-through clock.
    assign clk_o = clk_i;
endmodule
