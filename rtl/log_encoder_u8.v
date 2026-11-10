//NGUYEN VAN THUC - 24161421
/*
 * Module: log_encoder_u8
 * Description: Compose leading-one normalization and logarithmic LUT
 * conversion. Output is unsigned fixed point with three exponent bits
 * and 3+LOW_W fractional bits.
 */

module log_encoder_u8 #(
    parameter integer LOW_W        = 3,
    parameter integer ADAPTIVE_LUT = 1
)(
    input  wire [7:0]           mag_i,
    output wire [LOW_W+5:0]     log_o
);

    wire [2:0] k_w;
    wire [6:0] frac_w;
    wire [LOW_W+2:0] log_frac_w;

    log_normalizer_u8 u_normalizer (
        .mag_i             ( mag_i                  ),
        .k_o               ( k_w                    ),
        .frac_o            ( frac_w                 )
    );

    log_lut_converter_u8 #(
        .LOW_W             ( LOW_W                  ),
        .ADAPTIVE_LUT      ( ADAPTIVE_LUT           )
    ) u_converter (
        .frac_i            ( frac_w                 ),
        .log_frac_o        ( log_frac_w             )
    );

    assign log_o = {k_w, log_frac_w};

endmodule
