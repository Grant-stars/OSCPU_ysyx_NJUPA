module inst_fetch(
    input rst,
    input clk,
    input [31:0] target_address,
	input flag,
    input [1:0] jump,
    output reg [31:0] pc,
    output [31:0] inst,
	output valid,
	input idu_ready,

	output ifu_reqValid,
	input ifu_reqReady,
	input ifu_respValid,
	output reg ifu_respReady,
    output [31:0] ifu_addr,
    input [31:0] ifu_rdata
);
    parameter [1:0] JUMP_NOP = 0, JUMP_JALR = 1, JUMP_JAL =2, JUMP_CB = 3;
	parameter IDLE = 0, WAIT_READY = 1, WAIT_RESP = 2, WAIT_HANDLE = 3;
    initial begin
        pc = 32'h80000000;
		inst_reg = pmem_read(32'h80000000);
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

    assign ifu_addr = pc;
	reg [31:0] inst_reg;
	always@ (posedge clk)begin
		inst_reg <= inst;
	end

	assign inst = ((ifu_state==WAIT_RESP) && (ifu_respValid && ifu_respReady)) ? ifu_rdata : inst_reg;

    // fsm
	//IDLE -> WAIT_READY -> WAIT_RESP -> WAIT_HANDLE
    reg [1:0] ifu_state, ifu_next_state;
	wire inst_finish /*verilator public*/;
	assign inst_finish = ifu_next_state == IDLE;

	always @(*)begin
		case(ifu_state)
			IDLE: ifu_next_state = ifu_reqReady ? WAIT_RESP : WAIT_READY;
			WAIT_READY: ifu_next_state = ifu_reqReady ? WAIT_RESP : WAIT_READY;
			WAIT_RESP: ifu_next_state = (ifu_respValid && ifu_respReady) ? (idu_ready ? IDLE : WAIT_HANDLE) : WAIT_RESP;
			WAIT_HANDLE: ifu_next_state = idu_ready ? IDLE : WAIT_HANDLE;
		endcase
	end

    assign valid = ((ifu_state==WAIT_RESP) && ifu_respValid && ifu_respReady) || (ifu_state==WAIT_HANDLE);
	assign ifu_reqValid = (ifu_state==IDLE) || (ifu_state==WAIT_READY);
	reg ifu_respReady_reg;
	always @(posedge clk)begin
		if(rst)begin
			ifu_respReady <= 0;
			ifu_respReady_reg <= 0;
		end
		else begin
			if(ifu_state==WAIT_RESP && ifu_respValid && !ifu_respReady_reg && !ifu_respReady) ifu_respReady_reg <= 1;
			else ifu_respReady_reg <= 0;
			ifu_respReady <= ifu_respReady_reg;
		end

	end


    always@(posedge clk)begin
       if(rst) ifu_state <= 0;
       else ifu_state <= ifu_next_state;
    end
endmodule




