`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2025 09:48:15 PM
// Design Name: 
// Module Name: FullAdder1bit
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


module FullAdder1bit(
	input A,B,Cin,
	output S,Cout
    );
	 
assign S=(A^B)^Cin;
assign Cout=(A&B)|((A^B)&Cin);

endmodule
