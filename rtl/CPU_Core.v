//=====================================================================
//
// Designer: Yuyang Chen
// Student number: 3220101054
//
// Description: CPU top
//
// ====================================================================
`include "Parameters.v"
module CPU_Core(
    //system signals
    input clk,
    input rst,

    //AXI Bus interface
    
    //
    input irq_i,
    input debug_halt_i
);
wire inst_valid_w;
wire [`XLEN/2-1:0]     inst0_w;
wire [`XLEN/2-1:0]     inst1_w;
wire instr_queue_ready_w;
wire misaligned_exception_w;
wire [`ADDR_WIDTH-1:0] misaligned_addr_w;
wire ifu_flush_w;
wire ifu_stall_w;
IFU u_IFU(
    //system signals
    .clk(clk),
    .rst(rst),

    // From Branch Prediction Unit
    .bpu_taken_i(),
    input       [`ADDR_WIDTH-1:0] bpu_addr_i,

    // Branch Mis-prediction Feedback (from BRU)
    .bru_miss_i(),                  //mispredict
    input       [`ADDR_WIDTH-1:0] bru_addr_i,                  //corret addr

    // I-Cache Interface
    output wire [`ADDR_WIDTH-1:0] icache_addr_o,               // Address to I-Cache (PC)
    input                         icache_hit_i,                // I-Cache hit signal
    input       [`XLEN-1:0]       icache_data_i,               // Two instructions (8 bytes) from I-Cache
    input                         icache_valid_i,              // I-Cache data valid
    input                         icache_ready_i,//handshake   // I-Cache ready to accept new request

    // Instruction Queue Interface
    .inst0_o(inst0_w),                     // First instruction (4 bytes)
    .inst1_o(inst1_w),                     // Second instruction (4 bytes)
    .inst_valid_o(inst_valid_w),                // Instructions valid
    .instr_queue_ready_i(instr_queue_ready_w),//handshake   // Instruction Queue ready to accept instructions
    .misaligned_exception_o(misaligned_exception_w), // Exception signal for misaligned address
    .misaligned_addr_o(misaligned_addr_w),       // Address causing the exception  
    
    //
    input                         exception_flush_i,   // flush caused by exceptions
    input                         interrupt_stall_i,   //stall caused by interruption

    // Pipeline Control
    .ifu_stall_o(ifu_stall_w),                    // Stall signal to pipeline
    .ifu_flush_o(ifu_flush_w)                    // Flush signal to pipeline
);
Instr_Queue u_Instr_Queue(
    //system signals
    .clk(clk),
    .rst(rst),
    // IFU Interface
    .inst0_i(inst0_w),
    .inst1_i(inst1_w),
    .inst_valid_i(inst_valid_w),
    .instr_queue_ready_o(instr_queue_ready_w),
    .misaligned_exception_i(misaligned_exception_w),
    .misaligned_addr_i(misaligned_addr_w),
    .ifu_flush_i(ifu_flush_w),
    
    // Decode Stage Interface
    input  wire                    decode_ready_i,
    output wire [`XLEN/2-1:0]      inst0_o,
    output wire [`XLEN/2-1:0]      inst1_o,
    output wire                    inst_valid_o,
    output wire                    misaligned_exception_o,
    output wire                    misaligned_addr_valid_o,
    output wire [`ADDR_WIDTH-1:0]  misaligned_addr_bypass_o
);
endmodule