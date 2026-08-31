module execution(
    input [31:0] op1,
    input [31:0] op2,
    input [4:0] alu_op,
    output reg [31:0] out
);

//parameter definition
parameter [4:0] ALU_NOP = 0, ALU_ADD = 1, ALU_SUB = 2, ALU_SLL= 3, ALU_SRL = 4, ALU_SRA = 5;

always @(*)begin
    out = op1+op2;
    case(alu_op)
        ALU_ADD: out = op1 + op2;
		ALU_SUB: out = op1 - op2;
		ALU_SLL: out = op1 << op2;
		ALU_SRL: out = op1 >> op2;
		ALU_SRA: out = op1 >>> op2;
        default: begin
            out = 0;
        end
    endcase

end
endmodule
