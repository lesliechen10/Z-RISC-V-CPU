//=====================================================================
//
// Designer: Yuyang Chen
// Student number: 3220101054
//
// Description: Instruction Fetch Unit
//
// ====================================================================
`include "../rtl/Parameters.v"
`include "../rtl/PipelineControl.v"
`include "../rtl/Std_sre_DFF.v"
`include "../rtl/Instr_Align.v"
module IFU(
    //system signals
    input                         clk,
    input                         rst,

    // From Branch Prediction Unit
    input                         bpu_taken_i,
    input       [`ADDR_WIDTH-1:0] bpu_addr_i,

    // Branch Mis-prediction Feedback (from BRU)
    input                         bru_miss_i,                  //mispredict
    input       [`ADDR_WIDTH-1:0] bru_addr_i,                  //corret addr

    // I-Cache Interface
    output wire [`ADDR_WIDTH-1:0] icache_addr_o,               // Address to I-Cache (PC)
    input                         icache_hit_i,                // I-Cache hit signal
    input       [`XLEN-1:0]       icache_data_i,               // Two instructions (8 bytes) from I-Cache
    input                         icache_valid_i,              // I-Cache data valid
    input                         icache_ready_i,//handshake   // I-Cache ready to accept new request

    // Instruction Queue Interface
    output wire [`XLEN/2-1:0]     inst0_o,                     // First instruction (4 bytes)
    output wire [`XLEN/2-1:0]     inst1_o,                     // Second instruction (4 bytes)
    output wire                   inst_valid_o,                // Instructions valid
    input                         instr_queue_ready_i,//handshake   // Instruction Queue ready to accept instructions
    output wire                   misaligned_exception_o, // Exception signal for misaligned address
    output wire [`ADDR_WIDTH-1:0] misaligned_addr_o,       // Address causing the exception  
    
    //
    input                         exception_flush_i,   // flush caused by exceptions
    input                         interrupt_stall_i,   //stall caused by interruption

    // Pipeline Control
    output wire                   ifu_stall_o,                    // Stall signal to pipeline
    output wire                   ifu_flush_o                    // Flush signal to pipeline


);
//pc generation
wire [`XLEN-1:0] current_pc_w;
wire [`XLEN-1:0] next_pc_w;
assign next_pc_w = bru_miss_i ? bru_addr_i :
                    bpu_taken_i ? bpu_addr_i :
                    current_pc_w + 8;  // If miss, addr; not miss --> if taken, addr; not taken, pc+8
//instantiation for PipelineControl
wire stall_w, flush_w;
wire en;
PipelineControl u_PipelineControl(
    .icache_hit_i(icache_hit_i),
    .icache_ready_i(icache_ready_i),
    .instr_queue_ready_i(instr_queue_ready_i),
    .bru_miss_i(bru_miss_i),
    .exception_flush_i(exception_flush_i),
    .interrupt_stall_i(interrupt_stall_i),
    .stall_o(stall_w),
    .flush_o(flush_w)
);
assign ifu_stall_o = stall_w;
assign ifu_flush_o = flush_w || misaligned_exception_w; // Flush if misaligned exception
assign en = !ifu_stall_o;

assign icache_addr_o = current_pc_w;
// Instruction outputs (directly from I-Cache)
wire [`XLEN/2-1:0] inst0_w, inst1_w;
wire inst_valid_w;
assign inst0_w = icache_data_i[`XLEN/2-1:0];  // First 4-byte instruction
assign inst1_w = icache_data_i[`XLEN-1:`XLEN/2]; // Second 4-byte instruction
assign inst_valid_w = icache_valid_i && !ifu_flush_o; // Valid only if I-Cache data is valid and no flush

// Instantiation of Standardized DFF for current PC
Std_sre_DFF #(
    .DATA_WIDTH(`PC_WIDTH),
    .RESET_MODE(0) // Reset mode: 0 = PC_BOOT_ADDR, 1 = 0
) u_Std_sre_DFF_pc (
    .clk(clk),
    .rst(rst),
    .en(en),
    .d(next_pc_w),
    .q(current_pc_w)
);
// Instantiation of Standardized DFF for instruction output
Std_sre_DFF #(
    .DATA_WIDTH(`XLEN/2),
    .RESET_MODE(1)
) u_Std_sre_DFF_inst0 (
    .clk(clk),
    .rst(rst),
    .en(en),
    .d(inst0_w),
    .q(inst0_o)
);
Std_sre_DFF #(
    .DATA_WIDTH(`XLEN/2),
    .RESET_MODE(1)
) u_Std_sre_DFF_inst1 (
    .clk(clk),
    .rst(rst),
    .en(en),
    .d(inst1_w),
    .q(inst1_o)
);
// Instantiation of Standardized DFF for instruction valid output
Std_sre_DFF #(
    .DATA_WIDTH(1),
    .RESET_MODE(1)
) u_Std_sre_DFF_inst_valid (
    .clk(clk),
    .rst(rst),
    .en(en),
    .d(inst_valid_w),
    .q(inst_valid_o)
);

wire misaligned_exception_w;
wire [`ADDR_WIDTH-1:0] misaligned_addr_w;
//instruction alignment
Instr_Align u_Instr_Align(
    .pc_i(current_pc_w),
    .bpu_addr_i(bpu_addr_i),
    .bpu_taken_i(bpu_taken_i),
    .bru_addr_i(bru_addr_i),
    .bru_miss_i(bru_miss_i),
    .misaligned_exception(misaligned_exception_w),
    .misaligned_addr(misaligned_addr_w)
);

//Instantation of Standardized DFF for misaligned exception
Std_sre_DFF #(
    .DATA_WIDTH(1),
    .RESET_MODE(1)
) u_Std_sre_DFF_misaligned_exception (
    .clk(clk),
    .rst(rst),
    .en(en),
    .d(misaligned_exception_w),
    .q(misaligned_exception_o)
);
//Instantation of Standardized DFF for misaligned address
Std_sre_DFF #(
    .DATA_WIDTH(`ADDR_WIDTH),
    .RESET_MODE(1)
) u_Std_sre_DFF_misaligned_addr (
    .clk(clk),
    .rst(rst),
    .en(en),
    .d(misaligned_addr_w),
    .q(misaligned_addr_o)
);
endmodule