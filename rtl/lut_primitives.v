//NGUYEN VAN THUC - 24161421
/*
 * Module: lut_primitives
 * Description: Pure logic gate primitives for carry-chain free (CARRY4 = 0)
 * arithmetic implementations on FPGA and standard cell ASIC synthesis.
 * Provides explicit carry-propagation equations that map 100% to Slice LUTs
 * without triggering dedicated FPGA carry primitives (CARRY4).
 */

`timescale 1ns / 1ps

module lut_adder_n #(
    parameter integer WIDTH = 9
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH:0]   sum
);
    wire [WIDTH:0] c;
    assign c[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_fa
            assign sum[i] = a[i] ^ b[i] ^ c[i];
            assign c[i+1] = (a[i] & b[i]) | (a[i] & c[i]) | (b[i] & c[i]);
        end
    endgenerate

    assign sum[WIDTH] = c[WIDTH];
endmodule

module lut_inc_n #(
    parameter integer WIDTH = 11
)(
    input  wire [WIDTH-1:0] a,
    input  wire             cin,
    output wire [WIDTH-1:0] sum
);
    wire [WIDTH:0] c;
    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_ha
            assign sum[i] = a[i] ^ c[i];
            assign c[i+1] = a[i] & c[i];
        end
    endgenerate
endmodule
