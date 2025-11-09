// Top-level module for CVE2 RISC-V on ECP5 Versa 5G
module top (
    input clk,
    output [7:0] led,
    output [13:0] disp
);

    // Power-on reset generation
    reg [7:0] reset_counter = 8'h0;
    reg rst_n = 1'b0;
    
    always @(posedge clk) begin
        if (reset_counter != 8'hFF) begin
            reset_counter <= reset_counter + 1'b1;
            rst_n <= 1'b0;
        end else begin
            rst_n <= 1'b1;
        end
    end

    // Instantiate the CVE2 SoC
    cve2_soc u_soc (
        .clk(clk),
        .rst_n(rst_n),
        .led(led),
        .disp(disp)
    );

endmodule
