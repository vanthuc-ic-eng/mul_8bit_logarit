//NGUYEN VAN THUC - 24161421
/*
 * Module: log_adder_u8
 * Description: Add two logarithmic fixed-point operands exactly.
 * This is the LUT-ALM 0-style baseline, not an approximate LOA.
 */

module log_adder_u8 #(
    parameter integer LOW_W = 3
)(
    input  wire [LOW_W+5:0] log_a_i,
    input  wire [LOW_W+5:0] log_b_i,
    output wire [LOW_W+6:0] log_sum_o
);

    assign log_sum_o = {1'b0, log_a_i} + {1'b0, log_b_i};
 
endmodule
