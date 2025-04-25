//=====================================================================
//
// Designer: Yuyang Chen
// Student number: 3220101054
//
// Description: IFU testbench
//
// ====================================================================

`timescale 1ns / 1ps
`include "../rtl/Instr_Queue.v"
`include "../rtl/Parameters.v"

module Instr_Queue_tb ();

// Declare integer variable
integer i;

// Parameters
localparam CLK_PERIOD = 10;  // Clock period in ns
localparam XLEN = 64;
localparam ADDR_WIDTH = 64;

// Inputs
reg                          clk;
reg                          rst;
reg       [XLEN/2-1:0]       inst0_i;
reg       [XLEN/2-1:0]       inst1_i;
reg                          inst_valid_i;
reg                          misaligned_exception_i;
reg       [ADDR_WIDTH-1:0]   misaligned_addr_i;
reg                          ifu_flush_i;
reg                          decode_ready_i;

// Outputs
wire                         instr_que_ready_o;
wire      [XLEN/2-1:0]       inst0_o;
wire      [XLEN/2-1:0]       inst1_o;
wire                         inst_valid_o;
wire                         misaligned_exception_o;
wire                         misaligned_addr_valid_o;
wire      [ADDR_WIDTH-1:0]   misaligned_addr_bypass_o;

// Instantiate the Unit Under Test (UUT)
Instr_Queue uut (
    .clk(clk),
    .rst(rst),
    .inst0_i(inst0_i),
    .inst1_i(inst1_i),
    .inst_valid_i(inst_valid_i),
    .misaligned_exception_i(misaligned_exception_i),
    .misaligned_addr_i(misaligned_addr_i),
    .ifu_flush_i(ifu_flush_i),
    .decode_ready_i(decode_ready_i),
    .instr_queue_ready_o(instr_que_ready_o),
    .inst0_o(inst0_o),
    .inst1_o(inst1_o),
    .inst_valid_o(inst_valid_o),
    .misaligned_exception_o(misaligned_exception_o),
    .misaligned_addr_valid_o(misaligned_addr_valid_o),
    .misaligned_addr_bypass_o(misaligned_addr_bypass_o)
);

// Clock generation
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Test procedure
initial begin
    $dumpfile("Instr_Queue_tb.vcd");
    $dumpvars(0, Instr_Queue_tb);
    // Initialize inputs
    rst = 0;
    inst0_i = 0;
    inst1_i = 0;
    inst_valid_i = 0;
    misaligned_exception_i = 0;
    misaligned_addr_i = 0;
    ifu_flush_i = 0;
    decode_ready_i = 0;

    // Reset the system (synchronous reset)
    @(posedge clk);  // Wait for first clock edge (5ns)
    rst = 0;         // Assert reset
    repeat(2) @(posedge clk);  // Hold reset for 2 cycles (15ns)
    rst = 1;         // Deassert reset
    @(posedge clk);  // 25ns

    // Test Case 1: Normal Write and Read
    @(negedge clk);  // 30ns, just before 35ns rising edge
    $display("Test Case 1: Normal Write and Read");
    // Write two instructions
    inst0_i = 32'hDEADBEEF;
    inst1_i = 32'hCAFEBABE;
    inst_valid_i = 1;
    @(posedge clk);  // 35ns, signals should be sampled here

    @(negedge clk);  // 40ns, just before 45ns rising edge
    inst0_i = 32'h12345678;
    inst1_i = 32'h87654321;
    @(posedge clk);  // 45ns

    @(negedge clk);  // 50ns
    inst_valid_i = 0;  // Stop writing
    @(posedge clk);  // 55ns

    // Read instructions
    @(negedge clk);  // 60ns
    decode_ready_i = 1;
    @(posedge clk);  // 65ns
    repeat(2) @(posedge clk);  // 75ns, 85ns

    // Test Case 2: Fill Queue to Full
    @(negedge clk);  // 90ns
    $display("Test Case 2: Fill Queue to Full");
    inst_valid_i = 1;
    @(posedge clk);  // 95ns
    for (i = 0; i < 8; i = i + 1) begin
        @(negedge clk);  // 100ns, 110ns, ...
        inst0_i = 32'h00000000 + i;
        inst1_i = 32'h11111111 + i;
        @(posedge clk);  // 105ns, 115ns, ...
    end

    @(negedge clk);  // 170ns
    inst_valid_i = 0;
    @(posedge clk);  // 175ns

    @(negedge clk);  // 180ns
    inst_valid_i = 0;
    @(posedge clk);  // 185ns

    // Test Case 3: Misaligned Exception
    @(negedge clk);  // 190ns
    $display("Test Case 3: Misaligned Exception");
    decode_ready_i = 1;  // Clear queue
    @(posedge clk);  // 195ns
    repeat(8) @(posedge clk);  // 205ns ~ 275ns
    @(negedge clk);  // 280ns
    decode_ready_i = 0;
    @(posedge clk);  // 285ns

    // Write with misaligned exception
    @(negedge clk);  // 290ns
    inst0_i = 32'h55555555;
    inst1_i = 32'hAAAAAAAA;
    inst_valid_i = 1;
    misaligned_exception_i = 1;
    misaligned_addr_i = 64'hFFFF_FFFF_FFFF_FFFC;
    @(posedge clk);  // 295ns

    @(negedge clk);  // 300ns
    inst_valid_i = 0;
    misaligned_exception_i = 0;
    @(posedge clk);  // 305ns

    // Read with misaligned exception
    @(negedge clk);  // 310ns
    decode_ready_i = 1;
    @(posedge clk);  // 315ns
    @(negedge clk);  // 320ns
    decode_ready_i = 0;
    @(posedge clk);  // 325ns

    // Test Case 4: Flush Queue
    @(negedge clk);  // 330ns
    $display("Test Case 4: Flush Queue");
    // Write some instructions
    inst0_i = 32'hBBBBBBBB;
    inst1_i = 32'hCCCCCCCC;
    inst_valid_i = 1;
    @(posedge clk);  // 335ns
    @(posedge clk);  // 345ns

    @(negedge clk);  // 350ns
    inst_valid_i = 0;
    @(posedge clk);  // 355ns

    // Flush the queue
    @(negedge clk);  // 360ns
    ifu_flush_i = 1;
    @(posedge clk);  // 365ns
    @(negedge clk);  // 370ns
    ifu_flush_i = 0;
    @(posedge clk);  // 375ns

    // Read after flush
    @(negedge clk);  // 380ns
    decode_ready_i = 1;
    @(posedge clk);  // 385ns
    @(negedge clk);  // 390ns
    decode_ready_i = 0;
    @(posedge clk);  // 395ns

    // End simulation
    @(negedge clk);  // 400ns
    $display("Simulation Finished");
    $finish;
end

// Monitor outputs
initial begin
    $monitor("Time=%0t rst=%b inst_valid_i=%b decode_ready_i=%b instr_que_ready_o=%b inst_valid_o=%b inst0_o=%h inst1_o=%h misaligned_exception_o=%b misaligned_addr_bypass_o=%h",
             $time, rst, inst_valid_i, decode_ready_i, instr_que_ready_o, inst_valid_o, inst0_o, inst1_o, misaligned_exception_o, misaligned_addr_bypass_o);
end

// Debug signal changes
initial begin
    $monitor("Time=%0t Inputs: inst0_i=%h, inst1_i=%h, inst_valid_i=%b, misaligned_exception_i=%b",
             $time, inst0_i, inst1_i, inst_valid_i, misaligned_exception_i);
end

endmodule