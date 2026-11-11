// ============================================================================
// V10: Signed INT8 Logarithmic / Mitchell-style Approximate Multiplier
// Target: Xilinx 7-Series (xc7z010clg400-1), Vivado 2024.2
// Team: Conquerors (NGUYEN VAN THUC - 24161421)
//
// Operational Modes:
//   MODE 0: 1-bit fraction Mitchell approximation + 2-entry antilog LUT (MRED ~ 30.8%)
//   MODE 1: 2-bit fraction Mitchell approximation + 4-entry antilog LUT (MRED ~ 19.0%)
//   MODE 2: 2-bit fraction + Mantissa cross-term compensation table (MRED ~ 13.3%)
// ============================================================================

`timescale 1ns / 1ps

module lutalm_mul_s8 #(
    parameter integer MODE              = 2, // 0, 1, or 2 (Default: 2)
    parameter integer OPERAND_ISOLATION = 1,
    parameter integer ROUND_OUTPUT      = 1, // round right shift by 4, else truncate
    // Legacy compatibility parameters for registered wrapper and EDA testbenches
    parameter integer LOW_W             = 2,
    parameter integer TRUNC_BITS        = 4,
    parameter integer ZERO_ADDER        = 1,
    parameter integer ADAPTIVE_LUT      = 0,
    parameter integer QUAD_CURV         = 0,
    parameter integer USE_CARRY         = 0
)(
    input  wire signed [7:0]  a_i,
    input  wire signed [7:0]  b_i,
    output wire signed [15:0] p_o
);

    wire sign_p = a_i[7] ^ b_i[7];
    wire zero_p = (a_i == 8'sd0) || (b_i == 8'sd0);

    // Two's-complement absolute value in 8 bits. This correctly represents
    // abs(-128) as 8'h80 (128), unlike a 7-bit magnitude implementation.
    wire [7:0] abs_a_raw = a_i[7] ? (~a_i + 8'd1) : a_i[7:0];
    wire [7:0] abs_b_raw = b_i[7] ? (~b_i + 8'd1) : b_i[7:0];

    wire [7:0] abs_a = (OPERAND_ISOLATION && zero_p) ? 8'd0 : abs_a_raw;
    wire [7:0] abs_b = (OPERAND_ISOLATION && zero_p) ? 8'd0 : abs_b_raw;

    // Encode positive magnitude as k.f1f0, where
    // magnitude ~= 2^k * (1 + f1/2 + f0/4).
    // The leading one is implicit. k ranges from 0 to 7.
    function [4:0] log_encode_2f;
        input [7:0] x;
        begin
            if      (x[7]) log_encode_2f = {3'd7, 2'b00};
            else if (x[6]) log_encode_2f = {3'd6, x[5:4]};
            else if (x[5]) log_encode_2f = {3'd5, x[4:3]};
            else if (x[4]) log_encode_2f = {3'd4, x[3:2]};
            else if (x[3]) log_encode_2f = {3'd3, x[2:1]};
            else if (x[2]) log_encode_2f = {3'd2, x[1:0]};
            else if (x[1]) log_encode_2f = {3'd1, x[0], 1'b0};
            else           log_encode_2f = {3'd0, 2'b00};
        end
    endfunction

    wire [4:0] enc_a = log_encode_2f(abs_a);
    wire [4:0] enc_b = log_encode_2f(abs_b);
    wire [2:0] ka = enc_a[4:2];
    wire [2:0] kb = enc_b[4:2];
    wire [1:0] fa = enc_a[1:0];
    wire [1:0] fb = enc_b[1:0];

    // MODE 0: Mitchell with one fraction bit. The code is k.f1.
    wire [3:0] log_a_1f = {ka, fa[1]};
    wire [3:0] log_b_1f = {kb, fb[1]};
    wire [4:0] log_sum_1f = {1'b0, log_a_1f} + {1'b0, log_b_1f};
    wire [3:0] exp_1f = log_sum_1f[4:1];
    wire       frac_1f = log_sum_1f[0];
    // Q4 approximation of 2^(fraction): 16*2^0=16, 16*2^0.5 ~= 23.
    wire [5:0] mant_1f = frac_1f ? 6'd23 : 6'd16;
    wire [19:0] shifted_1f = ({14'd0, mant_1f} << exp_1f);

    // MODE 1: Two fraction bits in the log-domain representation.
    wire [5:0] log_a_2f = {ka, fa};
    wire [5:0] log_b_2f = {kb, fb};
    wire [6:0] log_sum_2f = {1'b0, log_a_2f} + {1'b0, log_b_2f};
    wire [3:0] exp_2f = log_sum_2f[6:2];
    wire [1:0] frac_2f = log_sum_2f[1:0];

    reg [5:0] mant_2f;
    always @* begin
        case (frac_2f)
            2'd0: mant_2f = 6'd16; // 16 * 2^0
            2'd1: mant_2f = 6'd19; // 16 * 2^0.25 ~= 19
            2'd2: mant_2f = 6'd23; // 16 * 2^0.50 ~= 23
            default: mant_2f = 6'd27; // 16 * 2^0.75 ~= 27
        endcase
    end
    wire [19:0] shifted_2f = ({14'd0, mant_2f} << exp_2f);

    // MODE 2: Lightweight mantissa cross-term compensation.
    // Instead of approximating 2^(fa+fb), approximate
    // (1+fa)(1+fb) = 1+fa+fb+fa*fb using a 4x4 constant table.
    // fa/fb are the two-bit normalized mantissa fractions (0, .25, .5, .75).
    // Values are rounded Q4: round(16*(1+fa)*(1+fb)).
    reg [5:0] mant_comp_q4;
    always @* begin
        case ({fa, fb})
            4'b0000: mant_comp_q4 = 6'd16;
            4'b0001: mant_comp_q4 = 6'd20;
            4'b0010: mant_comp_q4 = 6'd24;
            4'b0011: mant_comp_q4 = 6'd28;

            4'b0100: mant_comp_q4 = 6'd20;
            4'b0101: mant_comp_q4 = 6'd25;
            4'b0110: mant_comp_q4 = 6'd30;
            4'b0111: mant_comp_q4 = 6'd35;

            4'b1000: mant_comp_q4 = 6'd24;
            4'b1001: mant_comp_q4 = 6'd30;
            4'b1010: mant_comp_q4 = 6'd36;
            4'b1011: mant_comp_q4 = 6'd42;

            4'b1100: mant_comp_q4 = 6'd28;
            4'b1101: mant_comp_q4 = 6'd35;
            4'b1110: mant_comp_q4 = 6'd42;
            default: mant_comp_q4 = 6'd49;
        endcase
    end
    wire [3:0] exp_comp = {1'b0, ka} + {1'b0, kb};
    wire [19:0] shifted_comp = ({14'd0, mant_comp_q4} << exp_comp);

    // Select unrounded Q4 magnitude, then convert Q4 to integer product.
    reg [19:0] selected_q4;
    always @* begin
        case (MODE)
            0: selected_q4 = shifted_1f;
            1: selected_q4 = shifted_2f;
            default: selected_q4 = shifted_comp;
        endcase
    end

    wire [19:0] rounded_q4 = ROUND_OUTPUT ? (selected_q4 + 20'd8) : selected_q4;
    wire [15:0] magnitude_product = zero_p ? 16'd0 : rounded_q4[19:4];

    // Correct two's-complement sign restoration, including -16384.
    wire signed [16:0] magnitude_ext = {1'b0, magnitude_product};
    wire signed [16:0] signed_product = sign_p ? -magnitude_ext : magnitude_ext;
    assign p_o = zero_p ? 16'sd0 : signed_product[15:0];

endmodule
