`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2025 09:39:24 PM
// Design Name: 
// Module Name: LAST_ROW
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2025 09:49:04 PM
// Design Name: 
// Module Name: ADD_ROW
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


module LAST_ROW(
    input [7:0] S, PP,
    output [8:0] Sout
);


wire c1, c2, c3, c4, c5, c6, c7, c8;

FullAdder1bit FA0(.A(S[0]), .B(PP[0]), .Cin(1'b0), .S(Sout[0]), .Cout(c1));
FullAdder1bit FA1(.A(S[1]), .B(PP[1]), .Cin(c1), .S(Sout[1]), .Cout(c2));
FullAdder1bit FA2(.A(S[2]), .B(PP[2]), .Cin(c2), .S(Sout[2]), .Cout(c3));
FullAdder1bit FA3(.A(S[3]), .B(PP[3]), .Cin(c3), .S(Sout[3]), .Cout(c4));
FullAdder1bit FA4(.A(S[4]), .B(PP[4]), .Cin(c4), .S(Sout[4]), .Cout(c5));
FullAdder1bit FA5(.A(S[5]), .B(PP[5]), .Cin(c5), .S(Sout[5]), .Cout(c6));
FullAdder1bit FA6(.A(S[6]), .B(PP[6]), .Cin(c6), .S(Sout[6]), .Cout(c7));
FullAdder1bit FA7(.A(S[7]), .B(PP[7]), .Cin(c7), .S(Sout[7]), .Cout(c8));
HalfAdder1bit HA8(.A(1'b1), .B(c8), .S(Sout[8]), .C());
endmodule

