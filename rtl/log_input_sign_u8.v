//NGUYEN VAN THUC - 24161421
/*
 * Module: log_input_sign_u8
 * Description: Convert signed INT8 to its unsigned absolute magnitude.
 * The magnitude of -128 is 128 and fits into 8 unsigned bits.
 * This exact sign handler avoids approximate sign-handling error.
 */

module log_input_sign_u8 (
    input  wire signed [7:0] data_i,
    output wire [7:0]        mag_o,
    output wire              sign_o,
    output wire              zero_o
);

    assign sign_o = data_i[7];
    assign zero_o = (data_i == 8'sd0);
    assign mag_o  = sign_o ? (-data_i) : data_i;

endmodule
