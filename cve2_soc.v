// CVE2 RISC-V SoC for ECP5 Versa 5G board
// CVE2 is from OpenHW Group: https://github.com/openhwgroup/cve2
// Simplified design with internal memory and GPIO

module cve2_soc (
    input wire clk,
    input wire rst_n,
    output wire [7:0] led,
    output wire [13:0] disp
);

    // Clock and reset
    wire clk_cpu;
    wire rst_cpu_n;
    
    // Divide 100 MHz by 2 to get 50 MHz (within timing: max 51 MHz)
    reg clk_div;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div <= 1'b0;
        else
            clk_div <= ~clk_div;
    end
    assign clk_cpu = clk_div;
    
    // Reset synchronizer
    reg [3:0] rst_sync;
    always @(posedge clk_cpu or negedge rst_n) begin
        if (!rst_n)
            rst_sync <= 4'b0;
        else
            rst_sync <= {rst_sync[2:0], 1'b1};
    end
    assign rst_cpu_n = rst_sync[3];

    // CVE2 CPU signals
    wire        instr_req;
    wire        instr_gnt;
    wire        instr_rvalid;
    wire [31:0] instr_addr;
    wire [31:0] instr_rdata;
    wire        instr_err;
    
    wire        data_req;
    wire        data_gnt;
    wire        data_rvalid;
    wire        data_we;
    wire [3:0]  data_be;
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [31:0] data_rdata;
    wire        data_err;

    // Memory and peripherals
    reg [31:0] memory [0:2047];  // 8KB RAM
    reg [31:0] gpio_out;
    
    // Memory read data
    reg [31:0] mem_rdata;
    reg        mem_rvalid;
    reg        mem_rvalid_instr;
    
    // Address decoding
    wire mem_sel = (data_addr[31:16] == 16'h0000);  // 0x00000000 - 0x0000FFFF
    wire gpio_sel = (data_addr[31:16] == 16'h8000); // 0x80000000 - GPIO
    
    wire mem_sel_instr = (instr_addr[31:16] == 16'h0000);
    
    // Instruction memory interface with registered read
    reg [31:0] instr_rdata_reg;
    
    assign instr_gnt = instr_req;
    assign instr_rvalid = mem_rvalid_instr;
    assign instr_err = 1'b0;
    assign instr_rdata = instr_rdata_reg;
    
    always @(posedge clk_cpu or negedge rst_cpu_n) begin
        if (!rst_cpu_n) begin
            mem_rvalid_instr <= 1'b0;
            instr_rdata_reg <= 32'h0;
        end else begin
            mem_rvalid_instr <= instr_req & mem_sel_instr;
            if (instr_req && mem_sel_instr) begin
                instr_rdata_reg <= memory[instr_addr[12:2]];
            end
        end
    end
    
    // Data memory interface
    assign data_gnt = data_req;
    assign data_rvalid = mem_rvalid;
    assign data_err = 1'b0;
    assign data_rdata = mem_rdata;
    
    always @(posedge clk_cpu or negedge rst_cpu_n) begin
        if (!rst_cpu_n) begin
            mem_rvalid <= 1'b0;
            mem_rdata <= 32'h0;
        end else begin
            mem_rvalid <= data_req;
            
            if (data_req) begin
                if (mem_sel) begin
                    mem_rdata <= memory[data_addr[12:2]];
                end else if (gpio_sel) begin
                    mem_rdata <= gpio_out;
                end else begin
                    mem_rdata <= 32'h0;
                end
            end
        end
    end
    
    // Memory writes
    always @(posedge clk_cpu) begin
        if (data_req && data_we && mem_sel) begin
            if (data_be[0]) memory[data_addr[12:2]][7:0]   <= data_wdata[7:0];
            if (data_be[1]) memory[data_addr[12:2]][15:8]  <= data_wdata[15:8];
            if (data_be[2]) memory[data_addr[12:2]][23:16] <= data_wdata[23:16];
            if (data_be[3]) memory[data_addr[12:2]][31:24] <= data_wdata[31:24];
        end
    end
    
    // GPIO writes
    always @(posedge clk_cpu or negedge rst_cpu_n) begin
        if (!rst_cpu_n) begin
            gpio_out <= 32'h00;  // LEDs off on reset, CPU will control them
        end else if (data_req && data_we && gpio_sel) begin
            if (data_be[0]) gpio_out[7:0]   <= data_wdata[7:0];
            if (data_be[1]) gpio_out[15:8]  <= data_wdata[15:8];
            if (data_be[2]) gpio_out[23:16] <= data_wdata[23:16];
            if (data_be[3]) gpio_out[31:24] <= data_wdata[31:24];
        end
    end
    
    // Assign outputs (LEDs and display are active-LOW on Versa board)
    assign led = ~gpio_out[7:0];
    assign disp = ~gpio_out[21:8];
    
    // Load firmware - hardcoded initialization for FPGA synthesis
    // (Yosys doesn't support $readmemh for block RAM initialization)
    initial begin
        memory[0] = 32'h00002137;
        memory[1] = 32'h0C400513;
        memory[2] = 32'h0C400593;
        memory[3] = 32'h00B55863;
        memory[4] = 32'h00052023;
        memory[5] = 32'h00450513;
        memory[6] = 32'hFF5FF06F;
        memory[7] = 32'h008000EF;
        memory[8] = 32'h0000006F;
        memory[9] = 32'hFF410113;
        memory[10] = 32'h00112423;
        memory[11] = 32'h00812223;
        memory[12] = 32'h00912023;
        memory[13] = 32'h00100493;
        memory[14] = 32'h05C0006F;
        memory[15] = 32'h00170713;
        memory[16] = 32'h02870A63;
        memory[17] = 32'h00040793;
        memory[18] = 32'hFEE46AE3;
        memory[19] = 32'h40E787B3;
        memory[20] = 32'hFEE7FEE3;
        memory[21] = 32'hFE0794E3;
        memory[22] = 32'h00140413;
        memory[23] = 32'h10000793;
        memory[24] = 32'h02F40263;
        memory[25] = 32'h0284FC63;
        memory[26] = 32'h00200793;
        memory[27] = 32'h00200713;
        memory[28] = 32'hFC87EAE3;
        memory[29] = 32'h800007B7;
        memory[30] = 32'h0087A023;
        memory[31] = 32'h028000EF;
        memory[32] = 32'hFD9FF06F;
        memory[33] = 32'h800007B7;
        memory[34] = 32'h0007A023;
        memory[35] = 32'h018000EF;
        memory[36] = 32'h014000EF;
        memory[37] = 32'h00200413;
        memory[38] = 32'hFCDFF06F;
        memory[39] = 32'h00140413;
        memory[40] = 32'hFC5FF06F;
        memory[41] = 32'h03200293;
        memory[42] = 32'h00018337;
        memory[43] = 32'h6A030313;
        memory[44] = 32'hFFF30313;
        memory[45] = 32'hFE031EE3;
        memory[46] = 32'hFFF28293;
        memory[47] = 32'hFE0296E3;
        memory[48] = 32'h00008067;
    end

    // CVE2 CPU instantiation
    // Tie off Core-V X-Interface since we don't use it in this simple SoC
    logic x_issue_ready_i; assign x_issue_ready_i = 1'b1;
    cve2_pkg::x_issue_resp_t x_issue_resp_i; assign x_issue_resp_i = '0;
    logic x_result_valid_i; assign x_result_valid_i = 1'b0;
    cve2_pkg::x_result_t x_result_i; assign x_result_i = '0;

    cve2_top #(
        .MHPMCounterNum(0),
        .MHPMCounterWidth(40),
        // Use RV32E and remove M extension to shrink area and speed up P&R
        .RV32E(1'b1),
        .RV32M(cve2_pkg::RV32MNone),
        .XInterface(1'b0)
    ) u_cve2_core (
        .clk_i(clk_cpu),
        .rst_ni(rst_cpu_n),

        .test_en_i(1'b0),
        .ram_cfg_i('0),

        .hart_id_i(32'h0),
        .boot_addr_i(32'h00000000),

        // Instruction memory interface
        .instr_req_o(instr_req),
        .instr_gnt_i(instr_gnt),
        .instr_rvalid_i(instr_rvalid),
        .instr_addr_o(instr_addr),
        .instr_rdata_i(instr_rdata),
        .instr_err_i(instr_err),

        // Data memory interface
        .data_req_o(data_req),
        .data_gnt_i(data_gnt),
        .data_rvalid_i(data_rvalid),
        .data_we_o(data_we),
        .data_be_o(data_be),
        .data_addr_o(data_addr),
        .data_wdata_o(data_wdata),
        .data_rdata_i(data_rdata),
        .data_err_i(data_err),

        // Core-V X-Interface (unused)
        .x_issue_valid_o(),
        .x_issue_ready_i(x_issue_ready_i),
        .x_issue_req_o(),
        .x_issue_resp_i(x_issue_resp_i),
        .x_register_o(),
        .x_commit_valid_o(),
        .x_commit_o(),
        .x_result_valid_i(x_result_valid_i),
        .x_result_ready_o(),
        .x_result_i(x_result_i),

        // Interrupt inputs
        .irq_software_i(1'b0),
        .irq_timer_i(1'b0),
        .irq_external_i(1'b0),
        .irq_fast_i(16'b0),
        .irq_nm_i(1'b0),

        // Debug Interface
        .debug_req_i(1'b0),
        .debug_halted_o(),
        .dm_halt_addr_i(32'h0),
        .dm_exception_addr_i(32'h0),
        .crash_dump_o(),

        // CPU control
        .fetch_enable_i(1'b1),
        .core_sleep_o()
    );

endmodule
