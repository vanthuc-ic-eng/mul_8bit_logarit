`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2025 09:39:06 PM
// Design Name: 
// Module Name: PARTIAL_PRODUCT_ROW
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


module PARTIAL_PRODUCT_ROW(
    input [7:0] A,
    input B, 
    output [7:0] Y
    );

assign Y[0] = A[0] & B;
assign Y[1] = A[1] & B;
assign Y[2] = A[2] & B;
assign Y[3] = A[3] & B;
assign Y[4] = A[4] & B;
assign Y[5] = A[5] & B;
assign Y[6] = A[6] & B;
assign Y[7] = ~(A[7] & B);

endmodule
