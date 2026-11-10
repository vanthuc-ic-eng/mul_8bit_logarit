`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2025 11:05:08 PM
// Design Name: 
// Module Name: HalfAdder1bit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module HalfAdder1bit(
	input A, B,
	output S, C
    );

assign S=A^B;
assign C=A&B;

endmodule

