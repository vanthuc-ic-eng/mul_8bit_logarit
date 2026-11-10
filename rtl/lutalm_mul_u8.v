//NGUYEN VAN THUC - 24161421
/*
 * Module: lutalm_mul_u8
 * Description: Unsigned 8x8 approximate logarithmic multiplier using
 * the same lower LUT values calibrated for signed INT8 magnitudes.
 */

module lutalm_mul_u8 #(
    parameter integer LOW_W = 3
)(
    input  wire [7:0]  a_i,
    input  wire [7:0]  b_i,
    output wire [15:0] p_o
);

    wire [LOW_W+5:0] log_a_w, log_b_w;
    wire [LOW_W+6:0] log_sum_w;
    wire [15:0] approx_mag_w;

    log_encoder_u8 #(
        .LOW_W             ( LOW_W                  )
    ) u_log_a (
        .mag_i             ( a_i                    ),
        .log_o             ( log_a_w                )
    );

    log_encoder_u8 #(
        .LOW_W             ( LOW_W                  )
    ) u_log_b (
        .mag_i             ( b_i                    ),
        .log_o             ( log_b_w                )
    );

    log_adder_u8 #(
        .LOW_W             ( LOW_W                  )
    ) u_log_add (
        .log_a_i           ( log_a_w                ),
        .log_b_i           ( log_b_w                ),
        .log_sum_o         ( log_sum_w              )
    );

    log_antilog_u16 #(
        .LOW_W             ( LOW_W                  )
    ) u_antilog (
        .log_sum_i         ( log_sum_w              ),
        .product_o         ( approx_mag_w           )
    );

    assign p_o = ((a_i == 8'd0) || (b_i == 8'd0)) ? 16'd0 : approx_mag_w;

endmodule
