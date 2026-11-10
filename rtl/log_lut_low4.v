//NGUYEN VAN THUC - 24161421
/*
 * Module: log_lut_low4
 * Description: Optimized 8-entry low-fraction lookup table.
 * Values were generated independently using exhaustive signed INT8 MED.
 * They are NOT claimed to equal the LUT values from LUT-ALM 2026.
 */

module log_lut_low4 (
    input  wire [2:0] addr_i,
    output reg  [3:0] data_o
);

    always @(*) begin
        case (addr_i)
            3'd0: data_o = 4'd3;
            3'd1: data_o = 4'd5;
            3'd2: data_o = 4'd7;
            3'd3: data_o = 4'd9;
            3'd4: data_o = 4'd11;
            3'd5: data_o = 4'd13;
            3'd6: data_o = 4'd15;
            3'd7: data_o = 4'd15;
            default: data_o = 4'd0;
        endcase
    end

endmodule
