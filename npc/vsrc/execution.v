module execution(
    input [31:0] op1,
    input [31:0] op2,
    input [4:0] alu_op,
	input [31:0] offset,
	input [31:0] base,
    output reg [31:0] out,
	output [31:0] target_address
);

//parameter definition
parameter [4:0] ALU_ADD = 1, ALU_SUB = 2, ALU_SLL= 3, ALU_SRL = 4, 
	ALU_SRA = 5, ALU_SLT = 6, ALU_SLTU = 7, ALU_BEQ = 8, ALU_BNE = 9, ALU_AND = 10;

wire overflow, carry;
wire [31:0] add_out;
wire Cin;
	
assign Cin = (alu_op==ALU_SUB) | (alu_op==ALU_SLT) | (alu_op==ALU_BEQ) |
	(alu_op==ALU_BNE);
assign target_address = offset + base;

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
		ALU_BEQ: out = {31'b0, ~(|add_out)};
		ALU_BNE: out = {31'b0, (|add_out)};
		ALU_AND: out = op1 & op2;

        default: begin
            out = 0;
        end
    endcase

end
endmodule
