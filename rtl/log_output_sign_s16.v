//NGUYEN VAN THUC - 24161421
/*
 * Module: log_output_sign_s16
 * Description: Restore the signed 16-bit multiplication result using
 * exact two's-complement sign handling and force products with zero to 0.
 * Synthesized with fused zero masking and sign inversion to minimize logic levels.
 */

module log_output_sign_s16 (
    input  wire [15:0] mag_i,
    input  wire        sign_i,
    input  wire        zero_i,
    output wire [15:0] product_o
);

    wire [15:0] effective_mag_w;

    // Mask with zero prior to two's-complement negation to share carry logic
    assign effective_mag_w = zero_i ? 16'd0 : mag_i;
    assign product_o       = sign_i ? (~effective_mag_w + 16'd1) : effective_mag_w;

endmodule
