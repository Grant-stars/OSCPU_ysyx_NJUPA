module ysyx_26070215_adder(
	input [31:0] A1,
	input [31:0] B1,
	input Cin,
	output carry,
	output overflow,
	output [31:0] result
);
wire [31:0] B_in;

assign B_in = {32{Cin}}^B1;
assign {carry, result} = A1 + B_in + {31'b0, Cin};
assign overflow = (A1[31]==B_in[31]) && (result[31]!=A1[31]);
endmodule

