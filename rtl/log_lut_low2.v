//NGUYEN VAN THUC - 24161421
/*
 * Module: log_lut_low2
 * Description: Optimized 8-entry 2-bit low-fraction lookup table for ultra-compact
 * hardware footprint while maintaining MRED < 3.0% (MRED = 2.86%).
 */

module log_lut_low2 (
    input  wire [2:0] addr_i,
    output reg  [1:0] data_o
);

    always @(*) begin
        case (addr_i)
            3'd0: data_o = 2'd1;
            3'd1: data_o = 2'd1;
            3'd2: data_o = 2'd2;
            3'd3: data_o = 2'd2;
            3'd4: data_o = 2'd3;
            3'd5: data_o = 2'd3;
            3'd6: data_o = 2'd3;
            3'd7: data_o = 2'd3;
            default: data_o = 2'd0;
        endcase
    end

endmodule
