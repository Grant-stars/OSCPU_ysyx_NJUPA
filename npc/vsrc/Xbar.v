module Xbar(
	input clk,
	input rst,
	input access,

	input [31:0] araddr,
	input arvalid,
	output arready,
	output [31:0] rdata,
	output [1:0] rresp,
	output rvalid,
	input rready,
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
	input [31:0] rdata0,
	input [1:0] rresp0,
	input rvalid0,
	output rready0,
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
	input [31:0] rdata1,
	input [1:0] rresp1,
	input rvalid1,
	output rready1,
	output [31:0] awaddr1,
	output awvalid1,
	input awready1,
	output [31:0] wdata1,
	output [3:0] wstrb1,
	output wvalid1,
	input wready1,
	input [1:0] bresp1,
	input bvalid1,
	output bready1
);

	parameter [1:0] ERROR = 0, UART = 1, SRAM = 2;
	parameter [1:0] DECERR = 2'b11;

	reg [1:0] r_slave_sel, r_slave_sel_reg;
	reg [1:0] w_slave_sel, w_slave_sel_reg;

	always @(*)begin
		//R
		if(araddr>=32'h10000000 && araddr<32'h10000fff)	r_slave_sel = UART;
		else if (araddr>=32'h80000000 && araddr<32'h800fffff)	r_slave_sel = SRAM;
		else r_slave_sel = ERROR;

		//W
		if(awaddr>=32'h10000000 && awaddr<32'h10000fff)	w_slave_sel = UART;
		else if (awaddr>=32'h80000000 && awaddr<32'h800fffff)	w_slave_sel = SRAM;
		else w_slave_sel = ERROR;
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
	assign {araddr0, araddr1} = (r_slave_sel_reg==UART) ? {araddr, 32'b0} :
		(r_slave_sel_reg==SRAM) ? {32'b0, araddr} : {64'b0};

	assign {arvalid0, arvalid1} = (r_slave_sel_reg==UART) ? {arvalid, 1'b0} :
		(r_slave_sel_reg==SRAM) ? {1'b0, arvalid} : {2'b0};

	assign {rready0, rready1} = (r_slave_sel_reg==UART) ? {rready, 1'b0} :
		(r_slave_sel_reg==SRAM) ? {1'b0, rready} : {2'b0};


	assign arready = (r_slave_sel_reg==UART) ? arready0 :
		(r_slave_sel_reg==SRAM) ? arready1 : 1;

	assign rdata = (r_slave_sel_reg==UART) ? rdata0 :
		(r_slave_sel_reg==SRAM) ? rdata1 : 32'b0;

	assign rresp = (r_slave_sel_reg==UART) ? rresp0 :
		(r_slave_sel_reg==SRAM) ? rresp1 : DECERR;

	assign rvalid = (r_slave_sel_reg==UART) ? rvalid0 :
		(r_slave_sel_reg==SRAM) ? rvalid1 : 1;


	//W

	assign {awaddr0, awaddr1} = (w_slave_sel_reg==UART) ? {awaddr, 32'b0} :
		(w_slave_sel_reg==SRAM) ? {32'b0, awaddr} : {64'b0};

	assign {awvalid0, awvalid1} = (w_slave_sel_reg==UART) ? {awvalid, 1'b0} :
		(w_slave_sel_reg==SRAM) ? {1'b0, awvalid} : {2'b0};

	assign {wdata0, wdata1} = (w_slave_sel_reg==UART) ? {wdata, 32'b0} :
		(w_slave_sel_reg==SRAM) ? {32'b0, wdata} : {64'b0};

	assign {wstrb0, wstrb1} = (w_slave_sel_reg==UART) ? {wstrb, 4'b0} :
		(w_slave_sel_reg==SRAM) ? {4'b0, wstrb} : {8'b0};

	assign {wvalid0, wvalid1} = (w_slave_sel_reg==UART) ? {wvalid, 1'b0} :
		(w_slave_sel_reg==SRAM) ? {1'b0, wvalid} : {2'b0};

	assign {bready0, bready1} = (w_slave_sel_reg==UART) ? {bready, 1'b0} :
		(w_slave_sel_reg==SRAM) ? {1'b0, bready} : {2'b0};


	assign awready = (w_slave_sel_reg==UART) ? awready0 :
		(w_slave_sel_reg==SRAM) ? awready1 : 1;

	assign wready = (w_slave_sel_reg==UART) ? wready0 :
		(w_slave_sel_reg==SRAM) ? wready1 : 1;

	assign bresp = (w_slave_sel_reg==UART) ? bresp0 :
		(w_slave_sel_reg==SRAM) ? bresp1 : DECERR;

	assign bvalid = (w_slave_sel_reg==UART) ? bvalid0 :
		(w_slave_sel_reg==SRAM) ? bvalid1 : 1;


endmodule
