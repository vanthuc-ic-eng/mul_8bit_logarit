//NGUYEN VAN THUC - 24161421
/*
 * Module: log_normalizer_u8
 * Description: Detect the leading one, left-normalize an 8-bit unsigned
 * magnitude, and extract the seven normalized fractional bits.
 * Optimized for FPGA/ASIC synthesis by avoiding subtractors and barrel shifters.
 * The zero input produces k=0, fraction=0; zero bypass is handled externally.
 */

module log_normalizer_u8 (
    input  wire [7:0] mag_i,
    output reg  [2:0] k_o,
    output reg  [6:0] frac_o
);

    always @(*) begin
        if (mag_i[7]) begin
            k_o    = 3'd7;
            frac_o = mag_i[6:0];
        end else if (mag_i[6]) begin
            k_o    = 3'd6;
            frac_o = {mag_i[5:0], 1'b0};
        end else if (mag_i[5]) begin
            k_o    = 3'd5;
            frac_o = {mag_i[4:0], 2'b00};
        end else if (mag_i[4]) begin
            k_o    = 3'd4;
            frac_o = {mag_i[3:0], 3'b000};
        end else if (mag_i[3]) begin
            k_o    = 3'd3;
            frac_o = {mag_i[2:0], 4'b0000};
        end else if (mag_i[2]) begin
            k_o    = 3'd2;
            frac_o = {mag_i[1:0], 5'b00000};
        end else if (mag_i[1]) begin
            k_o    = 3'd1;
            frac_o = {mag_i[0], 6'b000000};
        end else begin
            k_o    = 3'd0;
            frac_o = 7'b0000000;
        end
    end

endmodule
