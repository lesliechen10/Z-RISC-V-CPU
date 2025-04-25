//=====================================================================
//
// Designer: Yuyang Chen
// Student number: 3220101054
//
// Description: Control flush and stall for pipeline
//
// ====================================================================
`include "../rtl/Parameters.v"
module PipelineControl (
    input        icache_hit_i,
    input        icache_ready_i,
    input        instr_queue_ready_i,
    input        bru_miss_i,
    input        exception_flush_i,
    input        interrupt_stall_i,
    output wire  stall_o,
    output wire  flush_o
);
assign stall_o = !icache_hit_i || !icache_ready_i || !instr_queue_ready_i || interrupt_stall_i;
assign flush_o = bru_miss_i || exception_flush_i;

endmodule