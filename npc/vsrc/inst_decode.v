`define GPR_ADDR_WIDTH 5
module inst_decode(
    input [31:0] inst,
    input [31:0] rdata1,
    input [31:0] rdata2,
    output [4:0] rd /*verilator public*/,
    output reg [31:0] op1,
    output reg [31:0] op2,
    output [`GPR_ADDR_WIDTH-1:0] raddr1,
    output [`GPR_ADDR_WIDTH-1:0] raddr2,
    output reg [4:0] alu_op,
    output reg [4:0] ls_type,
    output reg [1:0] jump /*verilator public*/,
    output reg [1:0] wb_sel,
    output reg ebreak,
    output reg wen
);

//parameter definition
parameter [4:0] ALU_NOP = 0, ALU_ADD = 1;
parameter [4:0] LS_NOP = 0, LS_LW = 3, LS_LBU = 4, LS_SB = 6, LS_SW = 8;
parameter [1:0] WB_ALU = 1, WB_MEM = 2, WB_PC = 3;
parameter [1:0] JUMP_NOP = 0, JUMP_JALR = 1;  //注：添加JUMP_JAL时mian.cpp里ftrace也需要同步修改

//sign definition
wire [4:0] rs1 /*verilator public*/, rs2;
wire [31:0] src1, src2;
wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;
wire [31:0] immI;
wire [31:0] immS;
wire [31:0] immU;

//data decode
assign rs1 = inst[19:15] ;
assign rs2 = inst[24:20];
assign rd = inst[11:7];
assign opcode = inst[6:0];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];

assign raddr1 =rs1[`GPR_ADDR_WIDTH-1:0];
assign raddr2 =rs2[`GPR_ADDR_WIDTH-1:0];
assign src1 = rdata1;
assign src2 = rdata2;
assign immI = {{20{inst[31]}}, inst[31:20]};
assign immS = {{20{inst[31]}}, inst[31:25], inst[11:7]};
assign immU = {inst[31:12], 12'b0};


//opcode decode
always@(*) begin

    //default
    op1 = 0;
    op2 = 0;
    alu_op = ALU_NOP;
    wen = 0;
    jump = JUMP_NOP;
    wb_sel = 0;
    ebreak = 0;
    ls_type = LS_NOP;

    case(opcode)
        //lui
        //此处实现为immU+0
        7'b0110111:begin
            op1 = 0;
            op2 = immU;
            alu_op = ALU_ADD;
            wen = 1;
            wb_sel = WB_ALU;
        end


        //Integer Register-Immediate Instructions
        7'b0010011:begin
            case(funct3)
                //addi
                3'b000:begin
                    op1 = src1;
                    op2 = immI;
                    alu_op = ALU_ADD;
                    wen = 1;
                    jump = 0;
                    wb_sel = WB_ALU;
                    ls_type = LS_NOP;
                end

                default:begin
                    op1 = 0;
                    op2 = 0;
                    alu_op = ALU_NOP;
                    wen = 0;
                    jump = 0;
                    ls_type = LS_NOP;
                end
            endcase
        end

        //Load and Store Instructions
        7'b0000011:begin
            case(funct3)
                //lw
                3'b010:begin
                    op1 = src1;
                    op2 = immI;
                    alu_op = ALU_ADD;
                    wen = 1;
                    wb_sel = WB_MEM;
                    ls_type = LS_LW;
                end

                //lbu
                3'b100:begin
                    op1 = src1;
                    op2 = immI;
                    alu_op = ALU_ADD;
                    wen = 1;
                    wb_sel = WB_MEM;
                    ls_type = LS_LBU;
                end

                default:begin
                    op1 = 0;
                    op2 = 0;
                    alu_op = ALU_NOP;
                    wen = 0;
                    jump = 0;
                    ls_type = LS_NOP;
                end
            endcase
        end

        7'b0100011:begin
            case(funct3)
                //sb
                3'b000:begin
                    op1 = src1;
                    op2 = immS;
                    alu_op = ALU_ADD;
                    ls_type = LS_SB;
                end

                //sw
                3'b010:begin
                    op1 = src1;
                    op2 = immS;
                    alu_op = ALU_ADD;
                    ls_type = LS_SW;
                end

                default: op1 = 0;
            endcase
        end

        //Integer Register-Register Operations
        7'b0110011:begin
            case(funct3)
                3'b000:begin
                    case(funct7)
                        //add
                        7'b0000000:begin
                            op1 = src1;
                            op2 = src2;
                            alu_op = ALU_ADD;
                            wen = 1;
                            wb_sel = WB_ALU;
                        end

                        default: op1 = 0;
                    endcase
                end
                
                default: op1 = 0;
            endcase
        end

        //Control Transfer Instructions
        7'b1100111:begin
            case(funct3)
                //jalr
                3'b000:begin
                    op1 = src1;
                    op2 = immI;
                    alu_op = ALU_ADD;
                    wen = 1;
                    jump = JUMP_JALR;
                    wb_sel = WB_PC;
                end

                default:op1 = 0;
            endcase
        end

        //ebreak:
        7'b1110011:begin
            case(inst[31:7])
                25'b0000000000010000000000000:begin
                    ebreak = 1;
                end
            endcase
        end

        default:begin
            op1 = 0;
            op2 = 0;
            alu_op = ALU_NOP;
            wen = 0;
            jump = 0;
            ls_type = LS_NOP;
        end
    endcase

end

endmodule

