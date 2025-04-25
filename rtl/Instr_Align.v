//=====================================================================
//
// Designer: Yuyang Chen
// Student number: 3220101054
//
// Description: Instruction Alignment module
//
// ====================================================================
`include "../rtl/Parameters.v"
module Instr_Align(
    // Inputs
    input [`PC_WIDTH-1:0]   pc_i,         // Program Counter from IFU
    input [`ADDR_WIDTH-1:0] bpu_addr_i,   // Branch predicted target address
    input                   bpu_taken_i,  // Branch prediction taken signal
    input [`ADDR_WIDTH-1:0] bru_addr_i,   // Corrected branch address (mispredict)
    input                   bru_miss_i,   // Branch misprediction signal

    // Outputs
    output wire                   misaligned_exception, // Exception signal for misaligned address
    output wire [`ADDR_WIDTH-1:0] misaligned_addr       // Address causing the exception
);

    // Check alignment (RV64G: instructions must be 4-byte aligned)
    wire pc_misaligned_w = (pc_i[1:0] != 2'b00) ? 1'b1 : 1'b0;
    wire bpu_misaligned_w = (bpu_addr_i[1:0] != 2'b00);
    wire bru_misaligned_w = (bru_addr_i[1:0] != 2'b00);

    // Generate exception if any address is misaligned
    // Priority: bru_mispredict > bp_predict_taken > pc
    assign misaligned_exception = bru_miss_i ? bru_misaligned_w :
                                  bpu_taken_i ? bpu_misaligned_w :
                                  pc_misaligned_w;

    // Output the address causing the exception
    assign misaligned_addr = bru_miss_i ? bru_addr_i :
                             bpu_taken_i ? bpu_addr_i :
                             pc_i;

endmodule