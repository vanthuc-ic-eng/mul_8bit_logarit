//NGUYEN VAN THUC - 24161421
/*
 * Module: log_antilog_u16
 * Description: Approximate the inverse logarithm with fixed-point
 * mantissa expansion and direct exponent-controlled mapping.
 * Avoids wide 24-bit dynamic barrel shifting by using bounded case selection
 * directly synthesizable to FPGA LUT6/MUXF7 structures.
 * Formula: product = ((2^F + fraction) << exponent) >> F.
 */

module log_antilog_u16 #(
    parameter integer LOW_W     = 3,
    parameter integer QUAD_CURV = 1
)(
    input  wire [LOW_W+6:0] log_sum_i,
    output reg  [15:0]      product_o
);

    localparam integer F = 3 + LOW_W;

    wire [3:0] exponent_w = log_sum_i[F+3:F];
    wire [F-1:0] frac_s   = log_sum_i[F-1:0];

    // Direction 2: Piecewise Quadratic Curvature Correction (FQCL)
    // Symmetrical folded logic: q_fold = yh[1:0] ^ {2{yh[2]}}
    // Corrects for 2^x antilog curvature without any DSP or multiplier.
    wire [1:0] q_corr_w;
    generate
        if (QUAD_CURV && LOW_W == 3) begin : gen_quad_curv
            wire [2:0] yh = frac_s[5:3];
            wire [1:0] q_fold = yh[1:0] ^ {2{yh[2]}};
            assign q_corr_w = q_fold >> 1; // 1-bit parabolic correction [0, 0, 1, 1, 1, 1, 0, 0]
        end else begin : gen_linear
            assign q_corr_w = 2'b00;
        end
    endgenerate

    wire [F:0] mantissa_w = {1'b1, frac_s} - {{(F-1){1'b0}}, q_corr_w};

    generate
        if (LOW_W == 2) begin : gen_antilog_low2
            // F = 5, mantissa_w is 6 bits: [5:0]
            always @(*) begin
                case (exponent_w)
                    4'd0:  product_o = {15'd0, mantissa_w[5]};
                    4'd1:  product_o = {14'd0, mantissa_w[5:1]};
                    4'd2:  product_o = {13'd0, mantissa_w[5:2]};
                    4'd3:  product_o = {12'd0, mantissa_w[5:3]};
                    4'd4:  product_o = {11'd0, mantissa_w[5:4]};
                    4'd5:  product_o = {10'd0, mantissa_w};
                    4'd6:  product_o = {9'd0,  mantissa_w, 1'b0};
                    4'd7:  product_o = {8'd0,  mantissa_w, 2'b00};
                    4'd8:  product_o = {7'd0,  mantissa_w, 3'b000};
                    4'd9:  product_o = {6'd0,  mantissa_w, 4'b0000};
                    4'd10: product_o = {5'd0,  mantissa_w, 5'b00000};
                    4'd11: product_o = {4'd0,  mantissa_w, 6'b000000};
                    4'd12: product_o = {3'd0,  mantissa_w, 7'b0000000};
                    4'd13: product_o = {2'd0,  mantissa_w, 8'b00000000};
                    4'd14: product_o = {1'd0,  mantissa_w, 9'b000000000};
                    default: product_o = {mantissa_w, 10'b0000000000};
                endcase
            end
        end else if (LOW_W == 3) begin : gen_antilog_low3
            // F = 6, mantissa_w is 7 bits: [6:0]
            always @(*) begin
                case (exponent_w)
                    4'd0:  product_o = {15'd0, mantissa_w[6]};
                    4'd1:  product_o = {14'd0, mantissa_w[6:5]};
                    4'd2:  product_o = {13'd0, mantissa_w[6:4]};
                    4'd3:  product_o = {12'd0, mantissa_w[6:3]};
                    4'd4:  product_o = {11'd0, mantissa_w[6:2]};
                    4'd5:  product_o = {10'd0, mantissa_w[6:1]};
                    4'd6:  product_o = {9'd0,  mantissa_w};
                    4'd7:  product_o = {8'd0,  mantissa_w, 1'b0};
                    4'd8:  product_o = {7'd0,  mantissa_w, 2'b00};
                    4'd9:  product_o = {6'd0,  mantissa_w, 3'b000};
                    4'd10: product_o = {5'd0,  mantissa_w, 4'b0000};
                    4'd11: product_o = {4'd0,  mantissa_w, 5'b00000};
                    4'd12: product_o = {3'd0,  mantissa_w, 6'b000000};
                    4'd13: product_o = {2'd0,  mantissa_w, 7'b0000000};
                    4'd14: product_o = {1'd0,  mantissa_w, 8'b00000000};
                    default: product_o = {mantissa_w, 9'b000000000};
                endcase
            end
        end else if (LOW_W == 4) begin : gen_antilog_low4
            // F = 7, mantissa_w is 8 bits: [7:0]
            always @(*) begin
                case (exponent_w)
                    4'd0:  product_o = {15'd0, mantissa_w[7]};
                    4'd1:  product_o = {14'd0, mantissa_w[7:6]};
                    4'd2:  product_o = {13'd0, mantissa_w[7:5]};
                    4'd3:  product_o = {12'd0, mantissa_w[7:4]};
                    4'd4:  product_o = {11'd0, mantissa_w[7:3]};
                    4'd5:  product_o = {10'd0, mantissa_w[7:2]};
                    4'd6:  product_o = {9'd0,  mantissa_w[7:1]};
                    4'd7:  product_o = {8'd0,  mantissa_w};
                    4'd8:  product_o = {7'd0,  mantissa_w, 1'b0};
                    4'd9:  product_o = {6'd0,  mantissa_w, 2'b00};
                    4'd10: product_o = {5'd0,  mantissa_w, 3'b000};
                    4'd11: product_o = {4'd0,  mantissa_w, 4'b0000};
                    4'd12: product_o = {3'd0,  mantissa_w, 5'b00000};
                    4'd13: product_o = {2'd0,  mantissa_w, 6'b000000};
                    4'd14: product_o = {1'd0,  mantissa_w, 7'b0000000};
                    default: product_o = {mantissa_w, 8'b00000000};
                endcase
            end
        end else begin : gen_fallback
            wire [23:0] mantissa_ext_w = {{(23-F){1'b0}}, mantissa_w};
            wire [23:0] shifted_w      = mantissa_ext_w << exponent_w;
            wire [23:0] value_w        = shifted_w >> F;
            always @(*) product_o = value_w[15:0];
        end
    endgenerate

endmodule
