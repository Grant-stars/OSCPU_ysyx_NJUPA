module memory_access(
	input clk,
	input rst,

   	input [31:0] araddr0,
	input arvalid0,
	output arready0,
	output [31:0] rdata0,
	output [1:0] rresp0,
	output rvalid0,
	input rready0,
	input [31:0] awaddr0,
	input awvalid0,
	output awready0,
	input [31:0] wdata0,
	input [3:0] wstrb0,
	input wvalid0,
	output wready0,
	output [1:0] bresp0,
	output bvalid0,
	input bready0,
	
	input [31:0] araddr1,
	input arvalid1,
	output arready1,
	output [31:0] rdata1,
	output [1:0] rresp1,
	output rvalid1,
	input rready1,
	input [31:0] awaddr1,
	input awvalid1,
	output awready1,
	input [31:0] wdata1,
	input [3:0] wstrb1,
	input wvalid1,
	output wready1,
	output [1:0] bresp1,
	output bvalid1,
	input bready1,

	output [31:0] araddr,
	output arvalid,
	input arready,
	input [31:0] rdata,
	input [1:0] rresp,
	input rvalid,
	output rready,
	output [31:0] awaddr,
	output awvalid,
	input awready,
	output [31:0] wdata,
	output [3:0] wstrb,
	output wvalid,
	input wready,
	input [1:0] bresp,
	input bvalid,
	output bready,

	output access
	);

	wire access0, access1;
	assign access0 = arvalid0 || awvalid0;
	assign access1 = arvalid1 || awvalid1;

	wire fire, idle;
	assign fire = (rvalid && rready) || (bvalid && bready);
	assign idle = arbiter_state==IDLE;
	reg grant;

	//arbiter fsm
	//IDLE -> BUSY
	parameter IDLE = 0, BUSY = 1;
	reg arbiter_state, arbiter_next_state;
	always @(*)begin
		case(arbiter_state)
			IDLE: arbiter_next_state = (access0 || access1) ? BUSY : IDLE;
			BUSY: arbiter_next_state = fire ? IDLE : BUSY;
		endcase
	end

	assign access = arbiter_state==IDLE && arbiter_next_state==BUSY;

	always @(posedge clk)begin
		if(rst) grant <= 0;
		else if(access)begin
			grant <= access1 && !access0;
		end
	end


	always@(posedge clk)begin
		if(rst) arbiter_state <= 0;
		else arbiter_state <= arbiter_next_state;
	end

	assign araddr = idle ? ((access1 && !access0) ? araddr1 : araddr0) : (grant ? araddr1 : araddr0);
	assign arvalid = idle ? 0 : (grant ? arvalid1: arvalid0);
	assign rready = idle ? 0 : (grant ? rready1: rready0);
	assign awaddr = idle ? ((access1 && !access0) ? awaddr1 : awaddr0) : (grant ? awaddr1: awaddr0);
	assign awvalid = idle ? 0 : (grant ? awvalid1: awvalid0);
	assign wdata = idle ? 0 : (grant ? wdata1: wdata0);
	assign wstrb = idle ? 0 : (grant ? wstrb1: wstrb0);
	assign wvalid = idle ? 0 : (grant ? wvalid1: wvalid0);
	assign bready = idle ? 0 : (grant ? bready1: bready0);

	assign {arready0, arready1} = idle ? 0 : (grant ? {1'b0, arready} : {arready, 1'b0});
	assign {rdata0, rdata1} = idle ? 0 : (grant ? {32'b0 , rdata} : {rdata, 32'b0});
	assign {rresp0, rresp1} = idle ? 0 : (grant ? {2'b0 , rresp} : {rresp, 2'b0});
	assign {rvalid0, rvalid1} = idle ? 0 : (grant ? {1'b0 , rvalid} : {rvalid, 1'b0});
	assign {awready0, awready1} = idle ? 0 : (grant ? {1'b0 , awready} : {awready, 1'b0});
	assign {wready0, wready1} = idle ? 0 : (grant ? {1'b0 , wready} : {wready, 1'b0});
	assign {bresp0, bresp1} = idle ? 0 : (grant ? {2'b0 , bresp} : {bresp, 2'b0});
	assign {bvalid0, bvalid1} = idle ? 0 : (grant ? {1'b0 , bvalid} : {bvalid, 1'b0});

endmodule


