module ysyx_26070215_Xbar(
	input clk,
	input rst,
	input access,

	input [31:0] araddr,
	input arvalid,
	output arready,
	input [3:0] arid,
	input [7:0] arlen,
	input [2:0] arsize,
	input [1:0] arburst,
	output [31:0] rdata,
	output [1:0] rresp,
	output rvalid,
	input rready,
	output rlast,
	output reg [3:0] rid,
	input [31:0] awaddr,
	input awvalid,
	output awready,
	input [3:0] awid,
	input [7:0] awlen,
	input [2:0] awsize,
	input [1:0] awburst,
	input [31:0] wdata,
	input [3:0] wstrb,
	input wvalid,
	output wready,
	input wlast,
	output [1:0] bresp,
	output bvalid,
	input bready,
	output reg [3:0] bid,

   	output [31:0] araddr0,
	output arvalid0,
	input arready0,
	output [3:0] arid0,
	output [7:0] arlen0,
	output [2:0] arsize0,
	output [1:0] arburst0,
	input [31:0] rdata0,
	input [1:0] rresp0,
	input rvalid0,
	output rready0,
	input rlast0,
	input [3:0] rid0,
	output [31:0] awaddr0,
	output awvalid0,
	input awready0,
	output [3:0] awid0,
	output [7:0] awlen0,
	output [2:0] awsize0,
	output [1:0] awburst0,
	output [31:0] wdata0,
	output [3:0] wstrb0,
	output wvalid0,
	input wready0,
	output wlast0,
	input [1:0] bresp0,
	input bvalid0,
	output bready0,
	input [3:0] bid0,

	output [31:0] araddr1,
	output arvalid1,
	input arready1,
	output [3:0] arid1,
	output [7:0] arlen1,
	output [2:0] arsize1,
	output [1:0] arburst1,
	input [31:0] rdata1,
	input [1:0] rresp1,
	input rvalid1,
	output rready1,
	input rlast1,
	input [3:0] rid1,
	output [31:0] awaddr1,
	output awvalid1,
	input awready1,
	output [3:0] awid1,
	output [7:0] awlen1,
	output [2:0] awsize1,
	output [1:0] awburst1,
	output [31:0] wdata1,
	output [3:0] wstrb1,
	output wvalid1,
	input wready1,
	output wlast1,
	input [1:0] bresp1,
	input bvalid1,
	output bready1,
	input [3:0] bid1
);

	parameter CLINT = 0, DOWNSTREAM = 1;

	reg r_slave_sel, r_slave_sel_reg;
	reg w_slave_sel, w_slave_sel_reg;

	always @(*)begin
		//R
		if (araddr>=32'h02000000 && araddr<32'h0200ffff)	r_slave_sel = CLINT;
		else r_slave_sel = DOWNSTREAM;

		//W
		if (awaddr>=32'h02000000 && awaddr<32'h0200ffff)	w_slave_sel = CLINT;
		else w_slave_sel = DOWNSTREAM;
	end

	always @(posedge clk)begin
		if(rst)begin
			r_slave_sel_reg <= 0;
			w_slave_sel_reg <= 0;
		end
		else begin
			if(access)begin
				r_slave_sel_reg <= r_slave_sel;
				w_slave_sel_reg <= w_slave_sel;
			end
		end
	end


	//R
	assign {araddr0, araddr1} = (r_slave_sel_reg==CLINT) ? {araddr, 32'b0} : {32'b0, araddr};
	assign {arvalid0, arvalid1} = (r_slave_sel_reg==CLINT) ? {arvalid, 1'b0} : {1'b0, arvalid};
	assign {arid0, arid1} = (r_slave_sel_reg==CLINT) ? {arid, 4'b0} : {4'b0, arid};
	assign {arlen0, arlen1} = (r_slave_sel_reg==CLINT) ? {arlen, 8'b0} : {8'b0, arlen};
	assign {arsize0, arsize1} = (r_slave_sel_reg==CLINT) ? {arsize, 3'b0} : {3'b0, arsize};
	assign {arburst0, arburst1} = (r_slave_sel_reg==CLINT) ? {arburst, 2'b0} : {2'b0, arburst};
	assign {rready0, rready1} = (r_slave_sel_reg==CLINT) ? {rready, 1'b0} : {1'b0, rready};

	assign arready = (r_slave_sel_reg==CLINT) ? arready0 : arready1;
	assign rdata = (r_slave_sel_reg==CLINT) ? rdata0 : rdata1;
	assign rresp = (r_slave_sel_reg==CLINT) ? rresp0 : rresp1;
	assign rvalid = (r_slave_sel_reg==CLINT) ? rvalid0 : rvalid1;
	assign rlast = (r_slave_sel_reg==CLINT) ? rlast0 : rlast1;
	assign rid = (r_slave_sel_reg==CLINT) ? rid0 : rid1;

	
	//W

	assign {awaddr0, awaddr1} = (w_slave_sel_reg==CLINT) ? {awaddr, 32'b0} : {32'b0, awaddr};
	assign {awvalid0, awvalid1} = (w_slave_sel_reg==CLINT) ? {awvalid, 1'b0} : {1'b0, awvalid};
	assign {awid0, awid1} = (w_slave_sel_reg==CLINT) ? {awid, 4'b0} : {4'b0, awid};
	assign {awlen0, awlen1} = (w_slave_sel_reg==CLINT) ? {awlen, 8'b0} : {8'b0, awlen};
	assign {awsize0, awsize1} = (w_slave_sel_reg==CLINT) ? {awsize, 3'b0} : {3'b0, awsize};
	assign {awburst0, awburst1} = (w_slave_sel_reg==CLINT) ? {awburst, 2'b0} : {2'b0, awburst};

	assign {wdata0, wdata1} = (w_slave_sel_reg==CLINT) ? {wdata, 32'b0} : {32'b0, wdata};
	assign {wstrb0, wstrb1} = (w_slave_sel_reg==CLINT) ? {wstrb, 4'b0} : {4'b0, wstrb};
	assign {wvalid0, wvalid1} = (w_slave_sel_reg==CLINT) ? {wvalid, 1'b0} : {1'b0, wvalid};
	assign {wlast0, wlast1} = (w_slave_sel_reg==CLINT) ? {wlast, 1'b0} : {1'b0, wlast};
	assign {bready0, bready1} = (w_slave_sel_reg==CLINT) ? {bready, 1'b0} : {1'b0, bready};

	assign awready = (w_slave_sel_reg==CLINT) ? awready0 : awready1;
	assign wready = (w_slave_sel_reg==CLINT) ? wready0 : wready1;
	assign bresp = (w_slave_sel_reg==CLINT) ? bresp0 : bresp1;
	assign bvalid = (w_slave_sel_reg==CLINT) ? bvalid0 : bvalid1;
	assign bid = (w_slave_sel_reg==CLINT) ? bid0 : bid1;

endmodule
