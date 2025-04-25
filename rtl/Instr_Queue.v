//=====================================================================
//
// Designer: Yuyang Chen
// Student number: 3220101054
//
// Description: Instruction Fetch Unit
//
// ====================================================================
`include "../rtl/Parameters.v"
`include "../rtl/Std_sre_DFF.v"

module Instr_Queue (
    // Clock and Reset
    input  wire                   clk,                      // Clock signal, rising edge triggered
    input  wire                   rst,                      // Synchronous reset, active low (0: reset, 1: normal operation)

    // Inputs from IFU (Instruction Fetch Unit)
    input  wire  [`XLEN/2-1:0]     inst0_i,                  // First 32-bit instruction from IFU (part of a 64-bit instruction pair)
    input  wire  [`XLEN/2-1:0]     inst1_i,                  // Second 32-bit instruction from IFU (part of a 64-bit instruction pair)
    input  wire                   inst_valid_i,             // Indicates if the input instructions are valid (1: valid, 0: invalid)
    input  wire                   misaligned_exception_i,   // Indicates if the fetched instructions have a misaligned address exception (1: exception, 0: normal)
    input  wire  [`ADDR_WIDTH-1:0] misaligned_addr_i,        // Misaligned address from IFU, used for exception handling (64-bit address)
    input  wire                   ifu_flush_i,              // Flush signal from IFU or control unit, clears the queue (1: flush, 0: normal operation)

    // Input from Decode Stage
    input  wire                   decode_ready_i,           // Indicates if the Decode stage is ready to accept instructions (1: ready, 0: not ready)

    // Output to IFU
    output wire                   instr_queue_ready_o,        // Indicates if the queue is ready to accept new instructions from IFU (1: ready, 0: full)
                                                            // Used by IFU to determine whether to fetch and send new instructions

    // Outputs to Decode Stage
    output wire  [`XLEN/2-1:0]     inst0_o,                  // First 32-bit instruction output to Decode stage
    output wire  [`XLEN/2-1:0]     inst1_o,                  // Second 32-bit instruction output to Decode stage
    output wire                   inst_valid_o,             // Indicates if the output instructions are valid (1: valid, 0: invalid)
    output wire                   misaligned_exception_o,   // Misaligned exception indicator for the output instructions (1: exception, 0: normal)

    // Outputs for Exception Handling (Bypass Path)
    output wire                   misaligned_addr_valid_o,  // Indicates if the misaligned address output is valid (1: valid, 0: invalid)
    output wire  [`ADDR_WIDTH-1:0] misaligned_addr_bypass_o  // Misaligned address bypass output for exception handling (64-bit address)
);
localparam ENTRY_WIDTH = (`XLEN/2) + (`XLEN/2) + 1 + 1;

wire [ENTRY_WIDTH-1:0] queue_w [0:7];
wire [2:0] queue_write_ptr_w;
wire [2:0] queue_read_ptr_w;
wire queue_full_w;
wire queue_empty_w;
wire [2:0] next_queue_write_ptr_w;
wire [2:0] next_queue_read_ptr_w;
wire [ENTRY_WIDTH-1:0] queue_write_data_w;
wire [7:0] queue_write_en_w;
wire [`XLEN/2-1:0] next_inst0_o_w;
wire [`XLEN/2-1:0] next_inst1_o_w;
wire next_inst_valid_o_w;
wire next_misaligned_exception_o_w;
wire [`ADDR_WIDTH-1:0] misaligned_addr_reg_w;
wire misaligned_addr_reg_en_w;

    // Compute queue_full_w and queue_empty_w
assign queue_full_w = ((queue_write_ptr_w + 3'd1) == queue_read_ptr_w);
assign queue_empty_w = (queue_write_ptr_w == queue_read_ptr_w);
assign instr_queue_ready_o = ~queue_full_w;

    // Simplify queue_write_en_w generation
wire write_enable_condition;
assign write_enable_condition = inst_valid_i && ~queue_full_w;

assign queue_write_data_w = {inst0_i, inst1_i, inst_valid_i, misaligned_exception_i};

assign queue_write_en_w[0] = (write_enable_condition && (queue_write_ptr_w == 3'd0));
assign queue_write_en_w[1] = (write_enable_condition && (queue_write_ptr_w == 3'd1));
assign queue_write_en_w[2] = (write_enable_condition && (queue_write_ptr_w == 3'd2));
assign queue_write_en_w[3] = (write_enable_condition && (queue_write_ptr_w == 3'd3));
assign queue_write_en_w[4] = (write_enable_condition && (queue_write_ptr_w == 3'd4));
assign queue_write_en_w[5] = (write_enable_condition && (queue_write_ptr_w == 3'd5));
assign queue_write_en_w[6] = (write_enable_condition && (queue_write_ptr_w == 3'd6));
assign queue_write_en_w[7] = (write_enable_condition && (queue_write_ptr_w == 3'd7));

assign next_queue_write_ptr_w = ifu_flush_i ? queue_read_ptr_w :
                                   (write_enable_condition) ? (queue_write_ptr_w + 3'd1) : queue_write_ptr_w;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : queue_dff
            Std_sre_DFF #(
                .DATA_WIDTH(ENTRY_WIDTH),
                .RESET_MODE(1)
            ) u_Std_sre_DFF_queue_entry (
                .clk(clk),
                .rst(rst),
                .en(queue_write_en_w[i]),
                .d(queue_write_data_w),
                .q(queue_w[i])
            );
        end
    endgenerate

    Std_sre_DFF #(
        .DATA_WIDTH(3),
        .RESET_MODE(1)
    ) u_Std_sre_DFF_queue_write_ptr (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .d(next_queue_write_ptr_w),
        .q(queue_write_ptr_w)
    );

assign next_queue_read_ptr_w = ifu_flush_i ? queue_read_ptr_w :
                                  (~queue_empty_w && decode_ready_i) ? (queue_read_ptr_w + 3'd1) : queue_read_ptr_w;

wire [ENTRY_WIDTH-1:0] queue_read_data_w;
assign queue_read_data_w = (queue_read_ptr_w == 3'd0) ? queue_w[0] :
                               (queue_read_ptr_w == 3'd1) ? queue_w[1] :
                               (queue_read_ptr_w == 3'd2) ? queue_w[2] :
                               (queue_read_ptr_w == 3'd3) ? queue_w[3] :
                               (queue_read_ptr_w == 3'd4) ? queue_w[4] :
                               (queue_read_ptr_w == 3'd5) ? queue_w[5] :
                               (queue_read_ptr_w == 3'd6) ? queue_w[6] :
                               (queue_read_ptr_w == 3'd7) ? queue_w[7] : {ENTRY_WIDTH{1'b0}};

wire [`XLEN/2-1:0] queue_inst0_w = queue_read_data_w[ENTRY_WIDTH-1 -: `XLEN/2];
wire [`XLEN/2-1:0] queue_inst1_w = queue_read_data_w[ENTRY_WIDTH-`XLEN/2-1 -: `XLEN/2];
wire queue_inst_valid_w = queue_read_data_w[ENTRY_WIDTH-`XLEN-1];
wire queue_misaligned_exception_w = queue_read_data_w[ENTRY_WIDTH-`XLEN-2];

assign next_inst0_o_w = (~queue_empty_w && decode_ready_i) ? queue_inst0_w : {`XLEN/2{1'b0}};
assign next_inst1_o_w = (~queue_empty_w && decode_ready_i) ? queue_inst1_w : {`XLEN/2{1'b0}};
assign next_inst_valid_o_w = ifu_flush_i ? 1'b0 :
                                (~queue_empty_w && decode_ready_i) ? queue_inst_valid_w : 1'b0;
assign next_misaligned_exception_o_w = (~queue_empty_w && decode_ready_i) ? queue_misaligned_exception_w : 1'b0;

assign misaligned_addr_reg_en_w = inst_valid_i && misaligned_exception_i && ~queue_full_w;

    Std_sre_DFF #(
        .DATA_WIDTH(`ADDR_WIDTH)
    ) u_Std_sre_DFF_misaligned_addr_reg (
        .clk(clk),
        .rst(rst),
        .en(misaligned_addr_reg_en_w),
        .d(misaligned_addr_i),
        .q(misaligned_addr_reg_w)
    );

assign misaligned_addr_valid_o = misaligned_exception_o && inst_valid_o;
assign misaligned_addr_bypass_o = misaligned_addr_reg_w;

    Std_sre_DFF #(
        .DATA_WIDTH(3),
        .RESET_MODE(1)
    ) u_Std_sre_DFF_queue_read_ptr (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .d(next_queue_read_ptr_w),
        .q(queue_read_ptr_w)
    );

    Std_sre_DFF #(
        .DATA_WIDTH(`XLEN/2),
        .RESET_MODE(1)
    ) u_Std_sre_DFF_inst0_o (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .d(next_inst0_o_w),
        .q(inst0_o)
    );

    Std_sre_DFF #(
        .DATA_WIDTH(`XLEN/2),
        .RESET_MODE(1)
    ) u_Std_sre_DFF_inst1_o (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .d(next_inst1_o_w),
        .q(inst1_o)
    );

    Std_sre_DFF #(
        .DATA_WIDTH(1),
        .RESET_MODE(1)
    ) u_Std_sre_DFF_inst_valid_o (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .d(next_inst_valid_o_w),
        .q(inst_valid_o)
    );

    Std_sre_DFF #(
        .DATA_WIDTH(1),
        .RESET_MODE(1)
    ) u_Std_sre_DFF_misaligned_exception_o (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .d(next_misaligned_exception_o_w),
        .q(misaligned_exception_o)
    );
endmodule