module execution(
    input [31:0] op1,
    input [31:0] op2,
    input [4:0] alu_op,
    output reg [31:0] out
);

//parameter definition
parameter [4:0] ALU_ADD = 1;

always @(*)begin
    out = op1+op2;
    case(alu_op)
        ALU_ADD:begin
            out = op1+op2;
        end

        default: begin
            out = 0;
        end
    endcase

end                                          
endmodule
