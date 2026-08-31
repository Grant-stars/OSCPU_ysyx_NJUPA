module execution(
    input [31:0] op1,
    input [31:0] op2,
    input [4:0] alu_op,
    output reg [31:0] out
);

//parameter definition
parameter [4:0] ALU_ADD = 1, ALU_SUB = 2, ALU_SLL= 3, ALU_SRL = 4, ALU_SRA = 5, ALU_SLT = 6, ALU_SLTU = 7;

wire overflow, carry;
wire [31:0] add_out;
wire Cin;
	
assign Cin = (alu_op==ALU_SUB) | (alu_op==ALU_SLT);

adder ADDER(
	.A1(op1),
	.B1(op2),
	.Cin(Cin),
	.carry(carry),
	.overflow(overflow),
	.result(add_out)
);

always @(*)begin
    out = add_out;
    case(alu_op)
        ALU_ADD: out = add_out;
		ALU_SUB: out = add_out;
		ALU_SLL: out = op1 << op2;
		ALU_SRL: out = op1 >> op2;
		ALU_SRA: out = op1 >>> op2;
		ALU_SLT: out = {31'b0, overflow ^ add_out[31]};
		ALU_SLTU:out = {31'b0, ~carry};
        default: begin
            out = 0;
        end
    endcase

end
endmodule
