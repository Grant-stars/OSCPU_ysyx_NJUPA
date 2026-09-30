/* verilator lint_off UNUSEDSIGNAL */
module inst_fetch(
    input rst,
    input clk,
    input [31:0] target_address,
	input flag,
    input [1:0] jump,
    output reg [31:0] pc,
    output reg [31:0] inst
);
    parameter [1:0] JUMP_NOP = 0, JUMP_JALR = 1, JUMP_JAL =2, JUMP_CB = 3;
    initial begin
        pc = 32'h80000000;
    end

    reg [31:0] dnpc;
    always@(*)begin
        case(jump)
            JUMP_NOP: dnpc = pc+4;
            JUMP_JALR: dnpc = {target_address[31:1], 1'b0};
            JUMP_JAL: dnpc = target_address;
			JUMP_CB: dnpc = flag?target_address:pc+4;
        default: dnpc = pc+4;
        endcase
    end

    always @(posedge clk)begin                                        
        if(rst) pc<=32'h80000000;
        else begin
            pc<=dnpc;
        end
    end

	/*
    always @(*) begin                                        
        inst = pmem_read(pc);
    end
	*/
reg [31:0] imem [0:255];
initial $readmemh("/home/grant/Projects/PA/ysyx-workbench/npc/bin/sum.hex", imem);
assign inst = imem[pc[9:2]];      // pc 起点 0x80000000 是 4KB 对齐，取低位即可
endmodule

/* verilator lint_on UNUSEDSIGNAL */



