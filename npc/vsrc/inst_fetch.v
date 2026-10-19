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

	//AXI4
	//AR
	output [31:0] araddr,
	output arvalid,
	input arready,
	output [3:0] arid,
	output [7:0] arlen,
	output [2:0] arsize,
	output [1:0] arburst,

	//R
	input [31:0] rdata,
	input [1:0] rresp,
	input rvalid,
	output reg rready,
	input rlast,
	input [3:0] rid,

	//AW
	output [31:0] awaddr,
	output awvalid,
	input awready,

	//W
	output [31:0] wdata,
	output [3:0] wstrb,
	output wvalid,
	input wready,

	//B
	input [1:0] bresp,
	input bvalid,
	output bready
);
    parameter [1:0] JUMP_NOP = 0, JUMP_JALR = 1, JUMP_JAL =2, JUMP_CB = 3;
	parameter IDLE = 0, WAIT_AR_READY = 1, WAIT_R = 2, WAIT_HANDLE = 3;
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

    assign araddr = pc;
	reg [31:0] inst_reg;
	always@ (posedge clk)begin
		inst_reg <= inst;
	end

	assign inst = ((ifu_state==WAIT_R) && (rvalid && rready && rlast && !(|rresp))) ? rdata : inst_reg;

    // fsm
	//IDLE -> WAIT_AR_READY -> WAIT_R -> WAIT_HANDLE
    reg [1:0] ifu_state, ifu_next_state;
	wire inst_finish /*verilator public*/;
	assign inst_finish = ifu_next_state == IDLE;

	always @(*)begin
		case(ifu_state)
			IDLE: ifu_next_state = arready ? WAIT_R : WAIT_AR_READY;
			WAIT_AR_READY: ifu_next_state = arready ? WAIT_R : WAIT_AR_READY;
			WAIT_R: ifu_next_state = (rvalid && rready && !(|rresp) && rlast) ? (idu_ready ? IDLE : WAIT_HANDLE) : WAIT_R;
			WAIT_HANDLE: ifu_next_state = idu_ready ? IDLE : WAIT_HANDLE;
		endcase
	end

    assign valid = ((ifu_state==WAIT_R) && rvalid && rlast && rready && !(|rresp)) || (ifu_state==WAIT_HANDLE);
	assign arvalid = (ifu_state==IDLE) || (ifu_state==WAIT_AR_READY);
	reg rready_reg;
	always @(posedge clk)begin
		if(rst)begin
			rready <= 0;
			rready_reg <= 0;
		end
		else begin
			if(ifu_state==WAIT_R && rvalid && !rready_reg && !rready) rready_reg <= 1;
			else rready_reg <= 0;
			rready <= rready_reg;
		end
	end

	assign arid = 0;
	assign arlen = 0;
	assign arsize = 3'b10;
	assign arburst = 2'b01;

	assign awaddr = 0;
	assign awvalid = 0;
	assign wdata = 0;
	assign wstrb = 0;
	assign wvalid = 0;
	assign bready = 0;

	wire _unused = &{awready, wready, bresp, bvalid, rid}; //consume unused signal

    always@(posedge clk)begin
       if(rst) ifu_state <= 0;
       else ifu_state <= ifu_next_state;
    end
endmodule




