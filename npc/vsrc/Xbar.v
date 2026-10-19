module Xbar(
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
	input [31:0] wdata,
	input [3:0] wstrb,
	input wvalid,
	output wready,
	output [1:0] bresp,
	output bvalid,
	input bready,

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
	input reg [3:0] rid0,
	output [31:0] awaddr0,
	output awvalid0,
	input awready0,
	output [31:0] wdata0,
	output [3:0] wstrb0,
	output wvalid0,
	input wready0,
	input [1:0] bresp0,
	input bvalid0,
	output bready0,

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
	input reg [3:0] rid1,
	output [31:0] awaddr1,
	output awvalid1,
	input awready1,
	output [31:0] wdata1,
	output [3:0] wstrb1,
	output wvalid1,
	input wready1,
	input [1:0] bresp1,
	input bvalid1,
	output bready1,
	
	output [31:0] araddr2,
	output arvalid2,
	input arready2,
	output [3:0] arid2,
	output [7:0] arlen2,
	output [2:0] arsize2,
	output [1:0] arburst2,
	input [31:0] rdata2,
	input [1:0] rresp2,
	input rvalid2,
	output rready2,
	input rlast2,
	input reg [3:0] rid2,
	output [31:0] awaddr2,
	output awvalid2,
	input awready2,
	output [31:0] wdata2,
	output [3:0] wstrb2,
	output wvalid2,
	input wready2,
	input [1:0] bresp2,
	input bvalid2,
	output bready2
);

	parameter [1:0] ERROR = 0, UART = 1, CLINT = 2, SRAM = 3;
	parameter [1:0] DECERR = 2'b11;

	reg [1:0] r_slave_sel, r_slave_sel_reg;
	reg [1:0] w_slave_sel, w_slave_sel_reg;

	always @(*)begin
		//R
		if(araddr>=32'h10000000 && araddr<32'h10000fff)	r_slave_sel = UART;
		else if (araddr>=32'h80000000 && araddr<32'h8fffffff)	r_slave_sel = SRAM;
		else if (araddr>=32'h02000000 && araddr<32'h0200ffff)	r_slave_sel = CLINT;
		else r_slave_sel = ERROR;

		//W
		if(awaddr>=32'h10000000 && awaddr<32'h10000fff)	w_slave_sel = UART;
		else if (awaddr>=32'h80000000 && awaddr<32'h8fffffff)	w_slave_sel = SRAM;
		else if (awaddr>=32'h02000000 && awaddr<32'h0200ffff)	w_slave_sel = CLINT;
		else w_slave_sel = ERROR;
	end

	reg [3:0] rid_reg;

	always @(posedge clk)begin
		if(rst)begin
			r_slave_sel_reg <= 0;
			w_slave_sel_reg <= 0;
		end
		else begin
			if(access)begin
				rid_reg <= arid;
				r_slave_sel_reg <= r_slave_sel;
				w_slave_sel_reg <= w_slave_sel;

			end
		end
	end

	//R
	assign {araddr0, araddr1, araddr2} =
		(r_slave_sel_reg==UART) ? {araddr, 64'b0} :
		(r_slave_sel_reg==CLINT) ? {32'b0, araddr, 32'b0} :
		(r_slave_sel_reg==SRAM) ? {64'b0, araddr} : {96'b0};

	assign {arvalid0, arvalid1, arvalid2} =
		(r_slave_sel_reg==UART) ? {arvalid, 2'b0} :
		(r_slave_sel_reg==CLINT) ? {1'b0, arvalid, 1'b0} :
		(r_slave_sel_reg==SRAM) ? {2'b0, arvalid} : {3'b0};
	
	assign {arid0, arid1, arid2} =
		(r_slave_sel_reg==UART) ? {arid, 8'b0} :
		(r_slave_sel_reg==CLINT) ? {4'b0, arid, 4'b0} :
		(r_slave_sel_reg==SRAM) ? {8'b0, arid} : {12'b0};

	assign {arlen0, arlen1, arlen2} =
		(r_slave_sel_reg==UART) ? {arlen, 16'b0} :
		(r_slave_sel_reg==CLINT) ? {8'b0, arlen, 8'b0} :
		(r_slave_sel_reg==SRAM) ? {16'b0, arlen} : {24'b0};

	assign {arsize0, arsize1, arsize2} =
		(r_slave_sel_reg==UART) ? {arsize, 6'b0} :
		(r_slave_sel_reg==CLINT) ? {3'b0, arsize, 3'b0} :
		(r_slave_sel_reg==SRAM) ? {6'b0, arsize} : {9'b0};

	assign {arburst0, arburst1, arburst2} =
		(r_slave_sel_reg==UART) ? {arburst, 4'b0} :
		(r_slave_sel_reg==CLINT) ? {2'b0, arburst, 2'b0} :
		(r_slave_sel_reg==SRAM) ? {4'b0, arburst} : {6'b0};

	assign {rready0, rready1, rready2} =
		(r_slave_sel_reg==UART) ? {rready, 2'b0} :
		(r_slave_sel_reg==CLINT) ? {1'b0, rready, 1'b0} :
		(r_slave_sel_reg==SRAM) ? {2'b0, rready} : {3'b0};


	assign arready = (r_slave_sel_reg==UART) ? arready0 :
		(r_slave_sel_reg==CLINT) ? arready1 :
		(r_slave_sel_reg==SRAM) ? arready2 : 1;

	assign rdata = (r_slave_sel_reg==UART) ? rdata0 :
		(r_slave_sel_reg==CLINT) ? rdata1 :
		(r_slave_sel_reg==SRAM) ? rdata2 : 32'b0;

	assign rresp = (r_slave_sel_reg==UART) ? rresp0 :
		(r_slave_sel_reg==CLINT) ? rresp1 :
		(r_slave_sel_reg==SRAM) ? rresp2 : DECERR;

	assign rvalid = (r_slave_sel_reg==UART) ? rvalid0 :
		(r_slave_sel_reg==CLINT) ? rvalid1 :
		(r_slave_sel_reg==SRAM) ? rvalid2 : 1;

	assign rlast = (r_slave_sel_reg==UART) ? rlast0 :
		(r_slave_sel_reg==CLINT) ? rlast1 :
		(r_slave_sel_reg==SRAM) ? rlast2 : 1;

	assign rid = (r_slave_sel_reg==UART) ? rid0 :
		(r_slave_sel_reg==CLINT) ? rid1 :
		(r_slave_sel_reg==SRAM) ? rid2 : rid_reg;



	//W

	assign {awaddr0, awaddr1, awaddr2} =
		(w_slave_sel_reg==UART) ? {awaddr, 64'b0} :
		(w_slave_sel_reg==CLINT) ? {32'b0, awaddr, 32'b0} :
		(w_slave_sel_reg==SRAM) ? {64'b0, awaddr} : {96'b0};

	assign {awvalid0, awvalid1, awvalid2} =
		(w_slave_sel_reg==UART) ? {awvalid, 2'b0} :
		(w_slave_sel_reg==CLINT) ? {1'b0, awvalid, 1'b0} :
		(w_slave_sel_reg==SRAM) ? {2'b0, awvalid} : {3'b0};

	assign {wdata0, wdata1, wdata2} =
		(w_slave_sel_reg==UART) ? {wdata, 64'b0} :
		(w_slave_sel_reg==CLINT) ? {32'b0, wdata, 32'b0} :
		(w_slave_sel_reg==SRAM) ? {64'b0, wdata} : {96'b0};

	assign {wstrb0, wstrb1, wstrb2} =
		(w_slave_sel_reg==UART) ? {wstrb, 8'b0} :
		(w_slave_sel_reg==CLINT) ? {4'b0, wstrb, 4'b0} :
		(w_slave_sel_reg==SRAM) ? {8'b0, wstrb} : {12'b0};

	assign {wvalid0, wvalid1, wvalid2} =
		(w_slave_sel_reg==UART) ? {wvalid, 2'b0} :
		(w_slave_sel_reg==CLINT) ? {1'b0, wvalid, 1'b0} :
		(w_slave_sel_reg==SRAM) ? {2'b0, wvalid} : {3'b0};

	assign {bready0, bready1, bready2} =
		(w_slave_sel_reg==UART) ? {bready, 2'b0} :
		(w_slave_sel_reg==CLINT) ? {1'b0, bready, 1'b0} :
		(w_slave_sel_reg==SRAM) ? {2'b0, bready} : {3'b0};


	assign awready = (w_slave_sel_reg==UART) ? awready0 :
		(w_slave_sel_reg==CLINT) ? awready1 :
		(w_slave_sel_reg==SRAM) ? awready2 : 1;

	assign wready = (w_slave_sel_reg==UART) ? wready0 :
		(w_slave_sel_reg==CLINT) ? wready1 :
		(w_slave_sel_reg==SRAM) ? wready2 : 1;

	assign bresp = (w_slave_sel_reg==UART) ? bresp0 :
		(w_slave_sel_reg==CLINT) ? bresp1 :
		(w_slave_sel_reg==SRAM) ? bresp2 : DECERR;

	assign bvalid = (w_slave_sel_reg==UART) ? bvalid0 :
		(w_slave_sel_reg==CLINT) ? bvalid1 :
		(w_slave_sel_reg==SRAM) ? bvalid2 : 1;


endmodule
