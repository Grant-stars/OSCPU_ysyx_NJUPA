module memory_access(
	input clk,
	input rst,
    //AXI4-Lite
	
	//ifu
	//AR
	input [31:0] ifu_araddr,
	input ifu_arvalid,
	output ifu_arready,

	//R
	output reg [31:0] ifu_rdata,
	output [1:0] ifu_rresp,
	output ifu_rvalid,
	input ifu_rready,

	//AW
	input [31:0] ifu_awaddr,
	input ifu_awvalid,
	output ifu_awready,

	//W
	input [31:0] ifu_wdata,
	input [3:0] ifu_wstrb,
	input ifu_wvalid,
	output ifu_wready,

	//B
	output [1:0] ifu_bresp,
	output ifu_bvalid,
	input ifu_bready,

	//lsu
	//AR
	input [31:0] lsu_araddr,
	input lsu_arvalid,
	output lsu_arready,

	//R
	output reg [31:0] lsu_rdata,
	output [1:0] lsu_rresp,
	output lsu_rvalid,
	input lsu_rready,

	//AW
	input [31:0] lsu_awaddr,
	input lsu_awvalid,
	output lsu_awready,

	//W
	input [31:0] lsu_wdata,
	input [3:0] lsu_wstrb,
	input lsu_wvalid,
	output lsu_wready,

	//B
	output [1:0] lsu_bresp,
	output lsu_bvalid,
	input lsu_bready
	);

	memory ifu_memory(
	  .clk(clk),
	  .rst(rst),
	  .araddr(ifu_araddr),
	  .arvalid(ifu_arvalid),
	  .arready(ifu_arready),
	  .rdata(ifu_rdata),
	  .rresp(ifu_rresp),
	  .rvalid(ifu_rvalid),
	  .rready(ifu_rready),
	  .awaddr(ifu_awaddr),
	  .awvalid(ifu_awvalid),
	  .awready(ifu_awready),
	  .wdata(ifu_wdata),
	  .wstrb(ifu_wstrb),
	  .wvalid(ifu_wvalid),
	  .wready(ifu_wready),
	  .bresp(ifu_bresp),
	  .bvalid(ifu_bvalid),
	  .bready(ifu_bready)
	);

    memory lsu_memory(
	  .clk(clk),
	  .rst(rst),
	  .araddr(lsu_araddr),
	  .arvalid(lsu_arvalid),
	  .arready(lsu_arready),
	  .rdata(lsu_rdata),
	  .rresp(lsu_rresp),
	  .rvalid(lsu_rvalid),
	  .rready(lsu_rready),
	  .awaddr(lsu_awaddr),
	  .awvalid(lsu_awvalid),
	  .awready(lsu_awready),
	  .wdata(lsu_wdata),
	  .wstrb(lsu_wstrb),
	  .wvalid(lsu_wvalid),
	  .wready(lsu_wready),
	  .bresp(lsu_bresp),
	  .bvalid(lsu_bvalid),
	  .bready(lsu_bready)
	);

endmodule


