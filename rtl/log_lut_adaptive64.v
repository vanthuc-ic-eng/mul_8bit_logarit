//NGUYEN VAN THUC - 24161421
/*
 * Module: log_lut_adaptive64
 * Description: Directly mapped 64x3 ROM using LUT6 primitives.
 */
(* rom_style = "distributed" *)
module log_lut_adaptive64 (
    input  wire [5:0] addr_i,
    output wire [2:0] data_o
);

    reg [2:0] rom_data;
    always @(*) begin
        case (addr_i)
            6'd0:  rom_data = 3'd0;
            6'd1:  rom_data = 3'd0;
            6'd2:  rom_data = 3'd1;
            6'd3:  rom_data = 3'd3;
            6'd4:  rom_data = 3'd4;
            6'd5:  rom_data = 3'd5;
            6'd6:  rom_data = 3'd6;
            6'd7:  rom_data = 3'd7;
            6'd8:  rom_data = 3'd1;
            6'd9:  rom_data = 3'd2;
            6'd10: rom_data = 3'd4;
            6'd11: rom_data = 3'd5;
            6'd12: rom_data = 3'd6;
            6'd13: rom_data = 3'd7;
            6'd14: rom_data = 3'd7;
            6'd15: rom_data = 3'd7;
            6'd16: rom_data = 3'd3;
            6'd17: rom_data = 3'd4;
            6'd18: rom_data = 3'd5;
            6'd19: rom_data = 3'd6;
            6'd20: rom_data = 3'd7;
            6'd21: rom_data = 3'd7;
            6'd22: rom_data = 3'd7;
            6'd23: rom_data = 3'd7;
            6'd24: rom_data = 3'd3;
            6'd25: rom_data = 3'd5;
            6'd26: rom_data = 3'd6;
            6'd27: rom_data = 3'd7;
            6'd28: rom_data = 3'd7;
            6'd29: rom_data = 3'd7;
            6'd30: rom_data = 3'd7;
            6'd31: rom_data = 3'd7;
            6'd32: rom_data = 3'd3;
            6'd33: rom_data = 3'd4;
            6'd34: rom_data = 3'd5;
            6'd35: rom_data = 3'd6;
            6'd36: rom_data = 3'd7;
            6'd37: rom_data = 3'd7;
            6'd38: rom_data = 3'd7;
            6'd39: rom_data = 3'd7;
            6'd40: rom_data = 3'd3;
            6'd41: rom_data = 3'd3;
            6'd42: rom_data = 3'd4;
            6'd43: rom_data = 3'd5;
            6'd44: rom_data = 3'd6;
            6'd45: rom_data = 3'd7;
            6'd46: rom_data = 3'd7;
            6'd47: rom_data = 3'd7;
            6'd48: rom_data = 3'd1;
            6'd49: rom_data = 3'd2;
            6'd50: rom_data = 3'd3;
            6'd51: rom_data = 3'd4;
            6'd52: rom_data = 3'd5;
            6'd53: rom_data = 3'd6;
            6'd54: rom_data = 3'd6;
            6'd55: rom_data = 3'd7;
            6'd56: rom_data = 3'd0;
            6'd57: rom_data = 3'd1;
            6'd58: rom_data = 3'd2;
            6'd59: rom_data = 3'd3;
            6'd60: rom_data = 3'd3;
            6'd61: rom_data = 3'd4;
            6'd62: rom_data = 3'd5;
            6'd63: rom_data = 3'd6;
            default: rom_data = 3'd0;
        endcase
    end
    assign data_o = rom_data;
endmodule
