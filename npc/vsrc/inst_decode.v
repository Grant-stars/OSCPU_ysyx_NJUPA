`define GPR_ADDR_WIDTH 5
module inst_decode(
    input [31:0] inst,
	input [31:0] pc,
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
    output reg [2:0] wb_sel,
    output reg ebreak,
    output reg wen,
	output reg [31:0] offset,
	output reg [31:0] base,
	output reg [11:0] csr_addr,
	output reg [31:0] csr_wdata,
	output reg [31:0] csr_wdata_gpr,
	input  [31:0] csr_rdata,
	output reg csr_wen,
	output reg csr_ren,
	output reg trap,
	output reg [31:0] mepc,
	output reg [31:0] mcause,
	input [31:0] mtvec,
	input [31:0] mret_mepc,
	input ifu_valid,
	output valid,
	input exu_ready,
	output ready
);

//parameter definition
parameter [4:0] ALU_NOP = 0, ALU_ADD = 1, ALU_SUB = 2, ALU_SLL= 3, ALU_SRL = 4,
	ALU_SRA = 5, ALU_SLT = 6, ALU_SLTU = 7, ALU_BEQ = 8, ALU_BNE = 9,
	ALU_BLT = 10, ALU_BLTU = 11,  ALU_BGE = 12, ALU_BGEU = 13, ALU_AND = 14,
	ALU_OR = 15, ALU_XOR = 16;
parameter [4:0] LS_NOP = 0, LS_LB = 1, LS_LH = 2, LS_LW = 3, LS_LBU = 4, LS_LHU = 5, LS_SB = 6, LS_SH = 7, LS_SW = 8;
parameter [2:0] WB_ALU = 1, WB_MEM = 2, WB_PC = 3, WB_CSR = 4;
parameter [1:0] JUMP_NOP = 0, JUMP_JALR = 1, JUMP_JAL = 2, JUMP_CB = 3;

assign valid = ifu_valid;
assign ready = exu_ready;

//sign definition
wire [4:0] rs1 /*verilator public*/, rs2;
wire [31:0] src1, src2;
wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;
wire [31:0] immI;
wire [31:0] immS;
wire [31:0] immU;
wire [31:0] immJ;
wire [31:0] immB;
wire [31:0] shamt;

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
assign immJ = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};
assign immB = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

assign shamt = {27'b0, rs2};

assign csr_addr= inst[31:20];


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
	offset = 0;
	base = 0;
	csr_wdata = 0;
	csr_wdata_gpr = 0;
	csr_wen = 0;
	csr_ren = 0;
	trap = 0;
	mepc = 0;
	mcause = 0;

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


		//auipc
		7'b0010111:begin
			op1 = pc;
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

				//slti
				3'b010:begin
					op1 = src1;
					op2 = immI;
					alu_op = ALU_SLT;
					wen = 1;
					wb_sel = WB_ALU;
				end

				//sltiu
				3'b011:begin
					op1 = src1;
					op2 = immI;
					alu_op = ALU_SLTU;
					wen = 1;
					wb_sel = WB_ALU;
				end

				//xori
				3'b100:begin
					op1 = src1;
					op2 = immI;
					alu_op = ALU_XOR;
					wen = 1;
					wb_sel = WB_ALU;
				end

				//ori
				3'b110:begin
					op1 = src1;
					op2 = immI;
					alu_op = ALU_OR;
					wen = 1;
					wb_sel = WB_ALU;
				end

				//andi
				3'b111:begin
					op1 = src1;
					op2 = immI;
					alu_op = ALU_AND;
					wen = 1;
					wb_sel = WB_ALU;
				end

				//slli
				3'b001:begin
					case(funct7)
						7'b0000000:begin
							op1 = src1;
							op2 = shamt;
							alu_op = ALU_SLL;
							wen = 1;
							wb_sel = WB_ALU;
						end
						default: unimplement(); //The instruction is not implemented
					endcase
				end

				3'b101:begin
					case(funct7)
						//srli
						7'b0000000:begin
							op1 = src1;
							op2 = shamt;
							alu_op = ALU_SRL;
							wen = 1;
							wb_sel = WB_ALU;
						end

						//srai
						7'b0100000:begin
							op1 = src1;
							op2 = shamt;
							alu_op = ALU_SRA;
							wen = 1;
							wb_sel = WB_ALU;
						end
						
						default: unimplement(); //The instruction is not implemented
					endcase
				end
				
                default:begin
					unimplement(); //The instruction is not implemented
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
				//lb
				3'b000:begin
                    op1 = src1;
                    op2 = immI;
                    alu_op = ALU_ADD;
                    wen = 1;
                    wb_sel = WB_MEM;
                    ls_type = LS_LB;
				end

				//lh
				3'b001:begin
                    op1 = src1;
                    op2 = immI;
                    alu_op = ALU_ADD;
                    wen = 1;
                    wb_sel = WB_MEM;
                    ls_type = LS_LH;
				end

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

				//lhu
				3'b101:begin
                    op1 = src1;
                    op2 = immI;
                    alu_op = ALU_ADD;
                    wen = 1;
                    wb_sel = WB_MEM;
                    ls_type = LS_LHU;
				end

                default:begin
					unimplement(); //The instruction is not implemented
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

				//sh
				3'b001:begin
					op1 = src1;
					op2 = immS;
					alu_op = ALU_ADD;
					ls_type = LS_SH;
					
				end

                //sw
                3'b010:begin
                    op1 = src1;
                    op2 = immS;
                    alu_op = ALU_ADD;
                    ls_type = LS_SW;
                end

                default:begin
					op1 = 0;
					unimplement(); //The instruction is not implemented
				end
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
						
						//sub
						7'b0100000:begin
                            op1 = src1;
                            op2 = src2;
                            alu_op = ALU_SUB;
                            wen = 1;
                            wb_sel = WB_ALU;
						end

						default: begin
							op1 = 0;
							unimplement(); //The instruction is not implemented
						end
                    endcase
                end
               
				//sll
				3'b001:begin
					case(funct7)
						7'b0000000:begin
							op1 = src1;
                            op2 = {27'b0, src2[4:0]};
                            alu_op = ALU_SLL;
                            wen = 1;
                            wb_sel = WB_ALU;
						end
						default: unimplement(); //The instruction is not implemented
					endcase
				end

				//slt
				3'b010:begin
					case(funct7)
						7'b0000000:begin
							op1 = src1;
							op2 = src2;
							alu_op = ALU_SLT;
							wen = 1;
							wb_sel = WB_ALU;
						end
						default: unimplement(); //The instruction is not implemented
					endcase
				end

				//sltu
				3'b011:begin
					case(funct7)
						7'b0000000:begin
							op1 = src1;
							op2 = src2;
							alu_op = ALU_SLTU;
							wen = 1;
							wb_sel = WB_ALU;
						end
						default: unimplement(); //The instruction is not implemented
					endcase
				
				end

				//xor
				3'b100:begin
					op1 = src1;
					op2 = src2;
					alu_op = ALU_XOR;
					wen = 1;
					wb_sel = WB_ALU;
				end

				3'b101:begin
					case(funct7)
						//srl
						7'b0000000:begin
							op1 = src1;
                            op2 = {27'b0, src2[4:0]};
                            alu_op = ALU_SRL;
                            wen = 1;
                            wb_sel = WB_ALU;
						end

						//sra
						7'b0100000:begin
							op1 = src1;
                            op2 = {27'b0, src2[4:0]};
                            alu_op = ALU_SRA;
                            wen = 1;
                            wb_sel = WB_ALU;
						end
						default: unimplement(); //The instruction is not implemented
					endcase
				end

				//or
				3'b110:begin
					op1 = src1;
					op2 = src2;
					alu_op = ALU_OR;
					wen = 1;
					wb_sel = WB_ALU;
				end

				//and
				3'b111:begin
					op1 = src1;
					op2 = src2;
					alu_op = ALU_AND;
					wen = 1;
					wb_sel = WB_ALU;
				end

				default: begin
					op1 = 0;
					unimplement(); //The instruction is not implemented
				end
            endcase
        end

        //Control Transfer Instructions
		//jal
		7'b1101111:begin
			offset = immJ;
			base = pc;
			wen = 1;
			jump = JUMP_JAL;
			wb_sel = WB_PC;
		end


        7'b1100111:begin
            case(funct3)
                //jalr
                3'b000:begin
                    offset = immI;
					base = src1;
                    wen = 1;
                    jump = JUMP_JALR;
                    wb_sel = WB_PC;
                end

				default:begin
					op1 = 0;
					unimplement(); //The instruction is not implemented
				end
            endcase
        end

		//Conditional Branches
		7'b1100011:begin
			case(funct3)
				//beq
				3'b000:begin
					op1 = src1;
					op2 = src2;
					alu_op = ALU_BEQ;
					jump = JUMP_CB;
					offset = immB;
					base = pc;
				end

				//bne
				3'b001:begin
					op1 = src1;
					op2 = src2;
					alu_op = ALU_BNE;
					jump = JUMP_CB;
					offset = immB;
					base = pc;
				end

				//blt
				3'b100:begin
					op1 = src1;
					op2 = src2;
					alu_op = ALU_BLT;
					jump = JUMP_CB;
					offset = immB;
					base = pc;
				end

				//bltu
				3'b110:begin
					op1 = src1;
					op2 = src2;
					alu_op = ALU_BLTU;
					jump = JUMP_CB;
					offset = immB;
					base = pc;
				end

				//bge
				3'b101:begin
					op1 = src1;
					op2 = src2;
					alu_op = ALU_BGE;
					jump = JUMP_CB;
					offset = immB;
					base = pc;
				end

				//bgeu
				3'b111:begin
					op1 = src1;
					op2 = src2;
					alu_op = ALU_BGEU;
					jump = JUMP_CB;
					offset = immB;
					base = pc;
				end
				default: unimplement(); //The instruction is not implemented
			endcase

		end
		

        7'b1110011:begin
            case(inst[31:7])

				//ecall:
                25'b0000000000000000000000000:begin
					trap = 1;
					mepc = pc;
					mcause = 32'd11;
					//like JAL
					offset = 0;
					base = mtvec;
					jump = JUMP_JAL;

                end

				//ebreak:
                25'b0000000000010000000000000:begin
                    ebreak = 1;
                end

				//mret:
				25'b0011000000100000000000000:begin
					//like JAL
					offset = 0;
					base = mret_mepc;
					jump = JUMP_JAL;

				end

				default: begin
				//control state register
					case(funct3)
						//csrrw
						3'b001:begin
							csr_wdata = src1;
							csr_wen = 1;
							wb_sel = WB_CSR;
							csr_wdata_gpr = csr_rdata;
							wen = 1;
						end

						//csrrs:
						3'b010:begin
							wb_sel = WB_CSR;
							csr_wdata = src1 | csr_rdata;
							csr_wdata_gpr = csr_rdata;
							csr_ren = 1;
							wen = 1;
						end

						default: unimplement(); //The instruction is not implemented
					endcase
				end
            endcase
        end

        default:begin
			unimplement(); //The instruction is not implemented
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

