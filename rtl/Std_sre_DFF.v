//=====================================================================
//
// Designer: Yuyang Chen
// Student number: 3220101054
//
// Description: Standardized DFF with synchronous reset and enable
//
// ====================================================================
`include "../rtl/Parameters.v"
module Std_sre_DFF#(
    parameter DATA_WIDTH = 64,
    parameter RESET_MODE = 1
)(
    input clk,
    input rst,
    input en,

    input [DATA_WIDTH-1:0] d,
    output reg [DATA_WIDTH-1:0] q
);
wire [DATA_WIDTH-1:0] reset_value_w; 
assign reset_value_w = RESET_MODE ? 0 : `PC_BOOT_ADDR;
always @(posedge clk)
begin
    if(!rst)
      q<= reset_value_w;
    else if(en)
      q<=d;
end
endmodule