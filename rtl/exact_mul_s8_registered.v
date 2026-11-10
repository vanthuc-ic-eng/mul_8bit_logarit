//NGUYEN VAN THUC - 24161421
/*
 * Module: exact_mul_s8_registered
 * Description: Industrial benchmark registered wrapper for exact_mul_s8 (TheMultiplier).
 * Provides identical synchronous input and output registers for a fair 1-to-1
 * Reg2Reg timing and dynamic power comparison against lutalm_mul_s8_registered.
 */

`timescale 1ns / 1ps

module exact_mul_s8_registered (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [7:0]  a_i,
    input  wire signed [7:0]  b_i,
    output reg  signed [15:0] p_o
);

    reg signed [7:0] a_reg;
    reg signed [7:0] b_reg;
    wire signed [15:0] core_p_w;

    exact_mul_s8 u_core (
        .a_i               ( a_reg                  ),
        .b_i               ( b_reg                  ),
        .p_o               ( core_p_w               )
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'sd0;
            b_reg <= 8'sd0;
            p_o   <= 16'sd0;
        end else begin
            a_reg <= a_i;
            b_reg <= b_i;
            p_o   <= core_p_w;
        end
    end

endmodule
