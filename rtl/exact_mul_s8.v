//NGUYEN VAN THUC - 24161421
/*
 * Module: exact_mul_s8
 * Description: Exact signed INT8 reference multiplier for PPA and
 * numerical error comparisons. Both operands are explicitly signed.
 */

module exact_mul_s8 (
    input  signed [7:0] a_i,
    input  signed [7:0] b_i,
    output signed [15:0] p_o
);

    TheMultiplier baseline_mul_inst (
        .a(a_i),
        .b(b_i),
        .S(p_o)
    );

endmodule
 