`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: TRAN DINH VAN (HCMUTE)
// 
// Create Date:    13:30:45 03/04/2025 
// Design Name: 
// Module Name:    TheMultiplier 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module TheMultiplier( //Bo nh�n 8 bit nhung thuc chat bit MSB se duoc su dung l�m bit dau', ta chi c�n 7 bit l�m do lon.
	input signed [7:0]a,b,
	output signed [15:0] S
    );

wire [7:0] PP_Row0, PP_Row1, PP_Row2, PP_Row3, PP_Row4, PP_Row5, PP_Row6, PP_Row7;
wire [8:0] S_Row_1, S_Row_2, S_Row_3, S_Row_4,S_Row_5, S_Row_6;

PARTIAL_PRODUCT_ROW Row_0(.A(a), .B(b[0]), .Y(PP_Row0));//
PARTIAL_PRODUCT_ROW Row_1(.A(a), .B(b[1]), .Y(PP_Row1));
PARTIAL_PRODUCT_ROW Row_2(.A(a), .B(b[2]), .Y(PP_Row2));
PARTIAL_PRODUCT_ROW Row_3(.A(a), .B(b[3]), .Y(PP_Row3));
PARTIAL_PRODUCT_ROW Row_4(.A(a), .B(b[4]), .Y(PP_Row4));
PARTIAL_PRODUCT_ROW Row_5(.A(a), .B(b[5]), .Y(PP_Row5));
PARTIAL_PRODUCT_ROW Row_6(.A(a), .B(b[6]), .Y(PP_Row6));
PP_NROW Row_7 (.A(a), .B(b[7]), .Y(PP_Row7));

ADD_ROW Add_Row_1(
    .S({1'b1,PP_Row0[7:1]}), 
    .PP(PP_Row1), 
    .Cout(S_Row_1[8]), 
    .Sout(S_Row_1[7:0])
);

ADD_ROW Add_Row_2(
    .S(S_Row_1[8:1]), 
    .PP(PP_Row2), 
    .Cout(S_Row_2[8]), 
    .Sout(S_Row_2[7:0])
);

ADD_ROW Add_Row_3(
    .S(S_Row_2[8:1]), 
    .PP(PP_Row3), 
    .Cout(S_Row_3[8]), 
    .Sout(S_Row_3[7:0])
);

ADD_ROW Add_Row_4(
    .S(S_Row_3[8:1]), 
    .PP(PP_Row4), 
    .Cout(S_Row_4[8]), 
    .Sout(S_Row_4[7:0])
);

ADD_ROW Add_Row_5(
    .S(S_Row_4[8:1]), 
    .PP(PP_Row5), 
    .Cout(S_Row_5[8]), 
    .Sout(S_Row_5[7:0])
);

ADD_ROW Add_Row_6(
    .S(S_Row_5[8:1]), 
    .PP(PP_Row6), 
    .Cout(S_Row_6[8]), 
    .Sout(S_Row_6[7:0])
);

LAST_ROW Add_Row_7(.S(S_Row_6[8:1]), .PP(PP_Row7), .Sout(S[15:7]));

assign S[0] = PP_Row0[0];
assign S[1] = S_Row_1[0];
assign S[2] = S_Row_2[0];
assign S[3] = S_Row_3[0];
assign S[4] = S_Row_4[0];
assign S[5] = S_Row_5[0];
assign S[6] = S_Row_6[0];


endmodule
