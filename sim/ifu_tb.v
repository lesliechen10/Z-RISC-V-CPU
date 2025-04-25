//=====================================================================
//
// Designer: Yuyang Chen
// Student number: 3220101054
//
// Description: IFU testbench
//
// ====================================================================
/*
`include "Std_sre_DFF.v"
`include "PipelineControl.v"
`include "Instru_Align.v"
`include "IFU.v"
*/
`timescale 1ns / 1ps
`include "../rtl/IFU.v"
`include "../rtl/Parameters.v"

module ifu_tb;

    // Testbench signals
    reg clk;
    reg rst;
    reg bpu_taken_i;
    reg [`ADDR_WIDTH-1:0] bpu_addr_i;
    reg bru_miss_i;
    reg [`ADDR_WIDTH-1:0] bru_addr_i;
    reg icache_hit_i;
    reg [`XLEN-1:0] icache_data_i;
    reg icache_valid_i;
    reg icache_ready_i;
    reg iqueue_ready_i;
    reg exception_flush_i;
    reg interrupt_stall_i;

    wire [`ADDR_WIDTH-1:0] icache_addr_o;
    wire [`XLEN/2-1:0] inst0_o;
    wire [`XLEN/2-1:0] inst1_o;
    wire inst_valid_o;
    wire ifu_stall_o;
    wire ifu_flush_o;
    wire misaligned_exception_o;
    wire [`ADDR_WIDTH-1:0] misaligned_addr_o;

    // Instantiate IFU
    IFU u_IFU (
        .clk(clk),
        .rst(rst),
        .bpu_taken_i(bpu_taken_i),
        .bpu_addr_i(bpu_addr_i),
        .bru_miss_i(bru_miss_i),
        .bru_addr_i(bru_addr_i),
        .icache_addr_o(icache_addr_o),
        .icache_hit_i(icache_hit_i),
        .icache_data_i(icache_data_i),
        .icache_valid_i(icache_valid_i),
        .icache_ready_i(icache_ready_i),
        .inst0_o(inst0_o),
        .inst1_o(inst1_o),
        .inst_valid_o(inst_valid_o),
        .instr_queue_ready_i(iqueue_ready_i),
        .exception_flush_i(exception_flush_i),
        .interrupt_stall_i(interrupt_stall_i),
        .ifu_stall_o(ifu_stall_o),
        .ifu_flush_o(ifu_flush_o),
        .misaligned_exception_o(misaligned_exception_o),
        .misaligned_addr_o(misaligned_addr_o)
    );

    // I-Cache simulation
    reg [63:0] icache_mem [0:1023];  // Simulate 4KB I-Cache (1024 entries of 64-bit data)
    wire [9:0] icache_index;  // Index into icache_mem (10 bits for 1024 entries)
    assign icache_index = icache_addr_o[12:3];  // Map address to index (8-byte aligned)

    // Simulate I-Cache behavior
    always @(*) begin
        if (icache_hit_i && icache_ready_i && icache_valid_i) begin
            icache_data_i = icache_mem[icache_index];
        end else begin
            icache_data_i = 64'h0;
        end
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period
    end
integer i;
    // Initialize I-Cache with predefined instructions
    initial begin
        // Preload I-Cache with some RISC-V instructions
        // Address 0x0: addi x1, x0, 5 (0x00500093) | addi x2, x0, 10 (0x00A00113)
        icache_mem[0] = {32'h00A00113, 32'h00500093};
        // Address 0x8: beq x1, x2, 8 (0x00208463) | nop (0x00000013)
        icache_mem[1] = {32'h00000013, 32'h00208463};
        // Address 0x10: add x3, x1, x2 (0x002081B3) | sub x4, x1, x2 (0x40208233)
        icache_mem[2] = {32'h40208233, 32'h002081B3};
        // Address 0x1000: jal x1, 4 (0x004000EF) | nop (0x00000013)
        icache_mem[64'h200] = {32'h00000013, 32'h004000EF};
        // Address 0x2000: addi x5, x0, 15 (0x00F00293) | nop (0x00000013)
        icache_mem[1023] = {32'h00000013, 32'h00F00293};  // Use the last valid index
        // Fill remaining entries with nop
        for ( i = 3; i < 1023; i++) begin
            if (i != 'h200 && i != 'h400) begin
                icache_mem[i] = {32'h00000013, 32'h00000013};  // nop | nop
            end
        end
    end

    // Test stimulus
    initial begin
        // Initialize signals
        rst = 0;
        bpu_taken_i = 0;
        bpu_addr_i = 64'h0;
        bru_miss_i = 0;
        bru_addr_i = 64'h0;
        icache_hit_i = 0;
        icache_data_i = 64'h0;
        icache_valid_i = 0;
        icache_ready_i = 0;
        iqueue_ready_i = 0;
        exception_flush_i = 0;
        interrupt_stall_i = 0;

        // Dump signals to VCD file for GTKWave
        $dumpfile("ifu_tb.vcd");
        $dumpvars(0, ifu_tb);

        // Reset
        #10;
        rst = 1;
        $display("Test 1: Normal fetch with I-Cache hit");
        icache_hit_i = 1;
        icache_valid_i = 1;
        icache_ready_i = 1;
        iqueue_ready_i = 1;
        #10;
        if (icache_addr_o != 64'h8 || inst0_o != 32'h00500093 || inst1_o != 32'h00A00113 || inst_valid_o != 1) begin
            $display("Test 1 Failed: Normal fetch incorrect");
        end else begin
            $display("Test 1 Passed");
        end

        #10;  // PC increments to 0x10
        if (icache_addr_o != 64'h10 || inst0_o != 32'h00208463 || inst1_o != 32'h00000013 || inst_valid_o != 1) begin
            $display("Test 2 Failed: Normal fetch at 0x8 incorrect");
        end else begin
            $display("Test 2 Passed");
        end

        $display("Test 3: Branch prediction taken");
        bpu_taken_i = 1;
        bpu_addr_i = 64'h1000;
        #10;
        bpu_taken_i = 0;
        #10;
        if (icache_addr_o != 64'h1000 || inst0_o != 32'h004000EF || inst1_o != 32'h00000013) begin
            $display("Test 3 Failed: Branch prediction incorrect");
        end else begin
            $display("Test 3 Passed");
        end

        $display("Test 4: Branch misprediction");
        bru_miss_i = 1;
        bru_addr_i = 64'h2000;
        #10;
        bru_miss_i = 0;
        #10;
        if (icache_addr_o != 64'h2000 || inst0_o != 32'h00F00293 || inst1_o != 32'h00000013 || inst_valid_o != 0) begin
            $display("Test 4 Failed: Branch misprediction incorrect");
        end else begin
            $display("Test 4 Passed");
        end

        $display("Test 5: Misaligned PC");
        bpu_taken_i = 1;
        bpu_addr_i = 64'h1003;  // Not 4-byte aligned
        #10;
        bpu_taken_i = 0;
        #10;
        if (!misaligned_exception_o || misaligned_addr_o != 64'h1003 || !ifu_flush_o) begin
            $display("Test 5 Failed: Misaligned PC not detected");
        end else begin
            $display("Test 5 Passed");
        end

        $display("Test 6: I-Cache miss (stall)");
        icache_hit_i = 0;
        #10;
        if (!ifu_stall_o) begin
            $display("Test 6 Failed: I-Cache miss should stall");
        end else begin
            $display("Test 6 Passed");
        end
        icache_hit_i = 1;
        #10;

        $display("Test 7: Exception flush");
        exception_flush_i = 1;
        #10;
        exception_flush_i = 0;
        #10;
        if (inst_valid_o != 0 || !ifu_flush_o) begin
            $display("Test 7 Failed: Exception flush incorrect");
        end else begin
            $display("Test 7 Passed");
        end

        $display("Test 8: Interrupt stall");
        interrupt_stall_i = 1;
        #10;
        if (!ifu_stall_o) begin
            $display("Test 8 Failed: Interrupt stall incorrect");
        end else begin
            $display("Test 8 Passed");
        end
        interrupt_stall_i = 0;
        #10;

        // Finish simulation
        #100;
        $finish;
    end

endmodule