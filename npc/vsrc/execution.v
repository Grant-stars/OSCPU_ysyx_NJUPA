module execution(
    input [31:0] op1,
    input [31:0] op2,
    input [4:0] alu_op,
	input [31:0] offset,
	input [31:0] base,
    output reg [31:0] out,
	output [31:0] target_address,
	input idu_valid,
	output valid,
	input lsu_ready,
	output ready
);

//parameter definition
parameter [4:0] ALU_ADD = 1, ALU_SUB = 2, ALU_SLL= 3, ALU_SRL = 4,
	ALU_SRA = 5, ALU_SLT = 6, ALU_SLTU = 7, ALU_BEQ = 8, ALU_BNE = 9,
	ALU_BLT = 10, ALU_BLTU = 11,  ALU_BGE = 12, ALU_BGEU = 13, ALU_AND = 14,
	ALU_OR = 15, ALU_XOR = 16;

assign valid = idu_valid;
assign ready = lsu_ready;

wire overflow, carry;
wire [31:0] add_out;
wire Cin;
wire alu_cmp;

assign alu_cmp = (alu_op==ALU_SLT) | (alu_op==ALU_SLTU) | (alu_op==ALU_BEQ) |
	(alu_op==ALU_BNE) | (alu_op==ALU_BLT) | (alu_op==ALU_BLTU) | (alu_op==ALU_BGE) |
	(alu_op==ALU_BGEU);

assign Cin = (alu_op==ALU_SUB) | alu_cmp;
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
		ALU_SRA: out = $signed(op1) >>> op2;
		ALU_SLT: out = {31'b0, overflow ^ add_out[31]};
		ALU_SLTU:out = {31'b0, ~carry};
		ALU_BEQ: out = {31'b0, ~(|add_out)};
		ALU_BNE: out = {31'b0, (|add_out)};
		ALU_BLT: out = {31'b0, overflow ^ add_out[31]};
		ALU_BLTU:out = {31'b0, ~carry};
		ALU_BGE: out = {31'b0, ~(overflow ^ add_out[31])};
		ALU_BGEU:out = {31'b0, carry};

		ALU_AND: out = op1 & op2;
		ALU_OR:  out = op1 | op2;
		ALU_XOR: out = op1 ^ op2;

        default: begin
            out = 0;
        end
    endcase

end
endmodule
