module inst_fetch(
    input rst,
    input clk,
    input [31:0] target_address,
	input flag,
    input [1:0] jump,
    output reg [31:0] pc,
    output [31:0] inst,
	output valid,
	input idu_ready
);
    parameter [1:0] JUMP_NOP = 0, JUMP_JALR = 1, JUMP_JAL =2, JUMP_CB = 3;
	parameter IDLE = 0, WAIT = 1;
    initial begin
        pc = 32'h80000000;
		ifu_rdata = pmem_read(32'h80000000);
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
        else if(inst_finish) begin
            pc<=dnpc;
        end
    end

    reg [31:0] ifu_raddr, ifu_rdata;
    assign inst = ifu_rdata;
    assign ifu_raddr = pc;
    always @(posedge clk) begin
		if(if_state == IDLE) ifu_rdata <= pmem_read(ifu_raddr);
    end

    // fsm
    reg if_state;
    wire if_next_state;
	wire inst_finish /*verilator public*/;

	assign inst_finish = if_state & idu_ready;
    assign if_next_state = (if_state & idu_ready) ? IDLE : WAIT;
    assign valid = if_state;

    always@(posedge clk)begin
       if(rst) if_state <= 0;
       else if_state <= if_next_state;
    end
endmodule




