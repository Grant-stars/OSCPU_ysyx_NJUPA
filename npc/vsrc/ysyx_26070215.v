import "DPI-C" function void finish();
import "DPI-C" function void unimplement(input int pc, input int inst);
import "DPI-C" function void CSRexception();
import "DPI-C" function void sig_assert(input bit condition, input string s);
import "DPI-C" function void uart_put(input int waddr, input int wdata, input byte wmask);
import "DPI-C" function void difftest_skip();
import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
    input int waddr, input int wdata, input byte wmask);
`define GPR_ADDR_WIDTH 5
module ysyx_26070215(
  input clock,
  input reset,
  input io_interrupt,

  output [31:0] io_master_araddr,
  output io_master_arvalid,
  input io_master_arready,
  output [3:0] io_master_arid,
  output [7:0] io_master_arlen,
  output [2:0] io_master_arsize,
  output [1:0] io_master_arburst,
  input [31:0] io_master_rdata,
  input [1:0] io_master_rresp,
  input io_master_rvalid,
  output io_master_rready,
  input io_master_rlast,
  input [3:0] io_master_rid,
  output [31:0] io_master_awaddr,
  output io_master_awvalid,
  input io_master_awready,
  output [3:0] io_master_awid,
  output [7:0] io_master_awlen,
  output [2:0] io_master_awsize,
  output [1:0] io_master_awburst,
  output [31:0] io_master_wdata,
  output [3:0] io_master_wstrb,
  output io_master_wvalid,
  input io_master_wready,
  output io_master_wlast,
  input [1:0] io_master_bresp,
  input io_master_bvalid,
  output io_master_bready,
  input [3:0] io_master_bid,
  
  input [31:0] io_slave_araddr,
  input io_slave_arvalid,
  output io_slave_arready,
  input [3:0] io_slave_arid,
  input [7:0] io_slave_arlen,
  input [2:0] io_slave_arsize,
  input [1:0] io_slave_arburst,
  output [31:0] io_slave_rdata,
  output [1:0] io_slave_rresp,
  output io_slave_rvalid,
  input io_slave_rready,
  output io_slave_rlast,
  output [3:0] io_slave_rid,
  input [31:0] io_slave_awaddr,
  input io_slave_awvalid,
  output io_slave_awready,
  input [3:0] io_slave_awid,
  input [7:0] io_slave_awlen,
  input [2:0] io_slave_awsize,
  input [1:0] io_slave_awburst,
  input [31:0] io_slave_wdata,
  input [3:0] io_slave_wstrb,
  input io_slave_wvalid,
  output io_slave_wready,
  input io_slave_wlast,
  output [1:0] io_slave_bresp,
  output io_slave_bvalid,
  input io_slave_bready,
  output [3:0] io_slave_bid
  );

  assign io_slave_arready = 1'b0;
  assign io_slave_rdata   = 32'b0;
  assign io_slave_rresp   = 2'b0;
  assign io_slave_rvalid  = 1'b0;
  assign io_slave_rlast   = 1'b0;
  assign io_slave_rid     = 4'b0;
  assign io_slave_awready = 1'b0;
  assign io_slave_wready  = 1'b0;
  assign io_slave_bresp   = 2'b0;
  assign io_slave_bvalid  = 1'b0;
  assign io_slave_bid     = 4'b0;

  wire _unused = &{1'b0,
    io_interrupt,

    io_slave_araddr, io_slave_arvalid, io_slave_arid, io_slave_arlen,
    io_slave_arsize, io_slave_arburst, io_slave_arready,

    io_slave_rdata, io_slave_rresp, io_slave_rvalid, io_slave_rready,
    io_slave_rlast, io_slave_rid,

    io_slave_awaddr, io_slave_awvalid, io_slave_awid, io_slave_awlen,
    io_slave_awsize, io_slave_awburst, io_slave_awready,

    io_slave_wdata, io_slave_wstrb, io_slave_wvalid, io_slave_wready,
    io_slave_wlast,

    io_slave_bresp, io_slave_bvalid, io_slave_bready, io_slave_bid};

  //ebreak
  wire ebreak;

  always @(*) begin
    if(ebreak & idu_valid) begin
      $display("FINISH");
      finish();
    end
  end

  //GPR：
  wire [31:0] rdata1, rdata2, wdata, outdata;
  wire [`GPR_ADDR_WIDTH-1:0] raddr1, raddr2, waddr;
  wire w_en;

 ysyx_26070215_RegisterFile #(`GPR_ADDR_WIDTH, 32) ysyx_26070215_GPR (
    .clk(clock),
    .rst(reset),
    .rdata1(rdata1),
    .raddr1(raddr1),
    .rdata2(rdata2),
    .raddr2(raddr2),
    .wdata(wdata),
    .waddr(waddr),
    .w_en(w_en),
	.wbu_valid(wbu_valid)
     );

  //CSRs:
  wire [11:0] csr_addr;
  wire [31:0] csr_wdata, csr_rdata, csr_wdata_gpr;
  wire csr_wen, csr_ren;
  wire [31:0] mepc, mcause, mtvec, mret_mepc;
  wire trap;

  ysyx_26070215_CSRs #(32) ysyx_26070215_CSR (
	.clk(clock),
	.rst(reset),
	.addr(csr_addr),
	.wdata(csr_wdata),
	.wen(csr_wen),
	.ren(csr_ren),
	.rdata(csr_rdata),
	.trap(trap),
	.mepc_data(mepc),
	.mcause_data(mcause),
	.mtvec_data(mtvec),
	.mret_mepc(mret_mepc),
	.wbu_valid(wbu_valid)
  );

  //ARBITER
  //AXI4

  //ifu
	//R
	wire [31:0] ifu_araddr;
	wire ifu_arvalid, ifu_arready;
	wire [3:0] ifu_arid;
	wire [7:0] ifu_arlen;
	wire [2:0] ifu_arsize;
	wire [1:0] ifu_arburst;
 
	//AR
	wire [31:0] ifu_rdata;
	wire [1:0] ifu_rresp;
	wire ifu_rvalid, ifu_rready, ifu_rlast;
	wire [3:0] ifu_rid;

	//AW
	wire [31:0] ifu_awaddr;
	wire ifu_awvalid, ifu_awready;
	wire [3:0] ifu_awid;
	wire [7:0] ifu_awlen;
	wire [2:0] ifu_awsize;
	wire [1:0] ifu_awburst;

	//W
	wire [31:0] ifu_wdata;
	wire [3:0] ifu_wstrb;
	wire ifu_wvalid, ifu_wready;
	wire ifu_wlast;

	//B
	wire [1:0] ifu_bresp;
	wire ifu_bvalid, ifu_bready;
	wire [3:0] ifu_bid;

  //lsu
	//R
	wire [31:0] lsu_araddr;
	wire lsu_arvalid, lsu_arready;
	wire [3:0] lsu_arid;
	wire [7:0] lsu_arlen;
	wire [2:0] lsu_arsize;
	wire [1:0] lsu_arburst;

	//AR
	wire [31:0] lsu_rdata;
	wire [1:0] lsu_rresp;
	wire lsu_rvalid, lsu_rready, lsu_rlast;
	wire [3:0] lsu_rid;

	//AW
	wire [31:0] lsu_awaddr;
	wire lsu_awvalid, lsu_awready;
	wire [3:0] lsu_awid;
	wire [7:0] lsu_awlen;
	wire [2:0] lsu_awsize;
	wire [1:0] lsu_awburst;

	//W
	wire [31:0] lsu_wdata;
	wire [3:0] lsu_wstrb;
	wire lsu_wvalid, lsu_wready;
	wire lsu_wlast;

	//B
	wire [1:0] lsu_bresp;
	wire lsu_bvalid, lsu_bready;
	wire [3:0] lsu_bid;


	wire Bus_access;
  ysyx_26070215_arbiter ysyx_26070215_arbiter(
	.clk(clock),
	.rst(reset),

	.araddr0(ifu_araddr),
	.arvalid0(ifu_arvalid),
	.arready0(ifu_arready),
	.arid0(ifu_arid),
	.arlen0(ifu_arlen),
	.arsize0(ifu_arsize),
	.arburst0(ifu_arburst),
	.rdata0(ifu_rdata),
	.rresp0(ifu_rresp),
	.rvalid0(ifu_rvalid),
	.rready0(ifu_rready),
	.rlast0(ifu_rlast),
	.rid0(ifu_rid),
	.awaddr0(ifu_awaddr),
	.awvalid0(ifu_awvalid),
	.awready0(ifu_awready),
	.awid0(ifu_awid),
	.awlen0(ifu_awlen),
	.awsize0(ifu_awsize),
	.awburst0(ifu_awburst),
	.wdata0(ifu_wdata),
	.wstrb0(ifu_wstrb),
	.wvalid0(ifu_wvalid),
	.wready0(ifu_wready),
	.wlast0(ifu_wlast),
	.bresp0(ifu_bresp),
	.bvalid0(ifu_bvalid),
	.bready0(ifu_bready),
	.bid0(ifu_bid),
	
	.araddr1(lsu_araddr),
	.arvalid1(lsu_arvalid),
	.arready1(lsu_arready),
	.arid1(lsu_arid),
	.arlen1(lsu_arlen),
	.arsize1(lsu_arsize),
	.arburst1(lsu_arburst),
	.rdata1(lsu_rdata),
	.rresp1(lsu_rresp),
	.rvalid1(lsu_rvalid),
	.rready1(lsu_rready),
	.rlast1(lsu_rlast),
	.rid1(lsu_rid),
	.awaddr1(lsu_awaddr),
	.awvalid1(lsu_awvalid),
	.awready1(lsu_awready),
	.awid1(lsu_awid),
	.awlen1(lsu_awlen),
	.awsize1(lsu_awsize),
	.awburst1(lsu_awburst),
	.wdata1(lsu_wdata),
	.wstrb1(lsu_wstrb),
	.wvalid1(lsu_wvalid),
	.wready1(lsu_wready),
	.wlast1(lsu_wlast),
	.bresp1(lsu_bresp),
	.bvalid1(lsu_bvalid),
	.bready1(lsu_bready),
	.bid1(lsu_bid),

	.araddr(Xbar_araddr),
	.arvalid(Xbar_arvalid),
	.arready(Xbar_arready),
	.arid(Xbar_arid),
	.arlen(Xbar_arlen),
	.arsize(Xbar_arsize),
	.arburst(Xbar_arburst),
	.rdata(Xbar_rdata),
	.rresp(Xbar_rresp),
	.rvalid(Xbar_rvalid),
	.rready(Xbar_rready),
	.rlast(Xbar_rlast),
	.rid(Xbar_rid),
	.awaddr(Xbar_awaddr),
	.awvalid(Xbar_awvalid),
	.awready(Xbar_awready),
	.awid(Xbar_awid),
	.awlen(Xbar_awlen),
	.awsize(Xbar_awsize),
	.awburst(Xbar_awburst),
	.wdata(Xbar_wdata),
	.wstrb(Xbar_wstrb),
	.wvalid(Xbar_wvalid),
	.wready(Xbar_wready),
	.wlast(Xbar_wlast),
	.bresp(Xbar_bresp),
	.bvalid(Xbar_bvalid),
	.bready(Xbar_bready),
	.bid(Xbar_bid),

	.access(Bus_access)

  );

	
  //Xbar
  wire [31:0] Xbar_araddr;
  wire Xbar_arvalid;
  wire Xbar_arready;
  wire [3:0] Xbar_arid;
  wire [7:0] Xbar_arlen;
  wire [2:0] Xbar_arsize;
  wire [1:0] Xbar_arburst;
  wire [31:0] Xbar_rdata;
  wire [1:0] Xbar_rresp;
  wire Xbar_rvalid;
  wire Xbar_rready;
  wire Xbar_rlast;
  wire [3:0] Xbar_rid;
  wire [31:0] Xbar_awaddr;
  wire Xbar_awvalid;
  wire Xbar_awready;
  wire [3:0] Xbar_awid;
  wire [7:0] Xbar_awlen;
  wire [2:0] Xbar_awsize;
  wire [1:0] Xbar_awburst;
  wire [31:0] Xbar_wdata;
  wire [3:0] Xbar_wstrb;
  wire Xbar_wvalid;
  wire Xbar_wready;
  wire Xbar_wlast;
  wire [1:0] Xbar_bresp;
  wire Xbar_bvalid;
  wire Xbar_bready;
  wire [3:0] Xbar_bid;
	
  ysyx_26070215_Xbar ysyx_26070215_Xbar(
	.clk(clock),
	.rst(reset),
	.access(Bus_access),

	.araddr(Xbar_araddr),
	.arvalid(Xbar_arvalid),
	.arready(Xbar_arready),
	.arid(Xbar_arid),
	.arlen(Xbar_arlen),
	.arsize(Xbar_arsize),
	.arburst(Xbar_arburst),
	.rdata(Xbar_rdata),
	.rresp(Xbar_rresp),
	.rvalid(Xbar_rvalid),
	.rready(Xbar_rready),
	.rlast(Xbar_rlast),
	.rid(Xbar_rid),
	.awaddr(Xbar_awaddr),
	.awvalid(Xbar_awvalid),
	.awready(Xbar_awready),
	.awid(Xbar_awid),
	.awlen(Xbar_awlen),
	.awsize(Xbar_awsize),
	.awburst(Xbar_awburst),
	.wdata(Xbar_wdata),
	.wstrb(Xbar_wstrb),
	.wvalid(Xbar_wvalid),
	.wready(Xbar_wready),
	.wlast(Xbar_wlast),
	.bresp(Xbar_bresp),
	.bvalid(Xbar_bvalid),
	.bready(Xbar_bready),
	.bid(Xbar_bid),

	.araddr0(clint_araddr),
	.arvalid0(clint_arvalid),
	.arready0(clint_arready),
	.arid0(clint_arid),
	.arlen0(clint_arlen),
	.arsize0(clint_arsize),
	.arburst0(clint_arburst),
	.rdata0(clint_rdata),
	.rresp0(clint_rresp),
	.rvalid0(clint_rvalid),
	.rready0(clint_rready),
	.rlast0(clint_rlast),
	.rid0(clint_rid),
	.awaddr0(clint_awaddr),
	.awvalid0(clint_awvalid),
	.awready0(clint_awready),
	.awid0(clint_awid),
	.awlen0(clint_awlen),
	.awsize0(clint_awsize),
	.awburst0(clint_awburst),
	.wdata0(clint_wdata),
	.wstrb0(clint_wstrb),
	.wvalid0(clint_wvalid),
	.wready0(clint_wready),
	.wlast0(clint_wlast),
	.bresp0(clint_bresp),
	.bvalid0(clint_bvalid),
	.bready0(clint_bready),
	.bid0(clint_bid),
	
	.araddr1(io_master_araddr),
	.arvalid1(io_master_arvalid),
	.arready1(io_master_arready),
	.arid1(io_master_arid),
	.arlen1(io_master_arlen),
	.arsize1(io_master_arsize),
	.arburst1(io_master_arburst),
	.rdata1(io_master_rdata),
	.rresp1(io_master_rresp),
	.rvalid1(io_master_rvalid),
	.rready1(io_master_rready),
	.rlast1(io_master_rlast),
	.rid1(io_master_rid),
	.awaddr1(io_master_awaddr),
	.awvalid1(io_master_awvalid),
	.awready1(io_master_awready),
	.awid1(io_master_awid),
	.awlen1(io_master_awlen),
	.awsize1(io_master_awsize),
	.awburst1(io_master_awburst),
	.wdata1(io_master_wdata),
	.wstrb1(io_master_wstrb),
	.wvalid1(io_master_wvalid),
	.wready1(io_master_wready),
	.wlast1(io_master_wlast),
	.bresp1(io_master_bresp),
	.bvalid1(io_master_bvalid),
	.bready1(io_master_bready),
	.bid1(io_master_bid)
  );


 //CLINT:
  wire [31:0] clint_araddr;
  wire clint_arvalid;
  wire clint_arready;
  wire [3:0] clint_arid;
  wire [7:0] clint_arlen;
  wire [2:0] clint_arsize;
  wire [1:0] clint_arburst;
  wire [31:0] clint_rdata;
  wire [1:0] clint_rresp;
  wire clint_rvalid;
  wire clint_rready;
  wire clint_rlast;
  wire [3:0] clint_rid;
  wire [31:0] clint_awaddr;
  wire clint_awvalid;
  wire clint_awready;
  wire [3:0] clint_awid;
  wire [7:0] clint_awlen;
  wire [2:0] clint_awsize;
  wire [1:0] clint_awburst;
  wire [31:0] clint_wdata;
  wire [3:0] clint_wstrb;
  wire clint_wvalid;
  wire clint_wready;
  wire clint_wlast;
  wire [1:0] clint_bresp;
  wire clint_bvalid;
  wire clint_bready;
  wire [3:0] clint_bid;
	
  ysyx_26070215_CLINT ysyx_26070215_CLINT(
	 .clk(clock),
	 .rst(reset),
	 .araddr(clint_araddr),
	 .arvalid(clint_arvalid),
	 .arready(clint_arready),
	 .arid(clint_arid),
	 .arlen(clint_arlen),
	 .arsize(clint_arsize),
     .arburst(clint_arburst),
	 .rdata(clint_rdata),
	 .rresp(clint_rresp),
	 .rvalid(clint_rvalid),
	 .rready(clint_rready),
	 .rlast(clint_rlast),
	 .rid(clint_rid),
	 .awaddr(clint_awaddr),
	 .awvalid(clint_awvalid),
	 .awready(clint_awready),
	 .awid(clint_awid),
	 .awlen(clint_awlen),
	 .awsize(clint_awsize),
	 .awburst(clint_awburst),
	 .wdata(clint_wdata),
	 .wstrb(clint_wstrb),
	 .wvalid(clint_wvalid),
	 .wready(clint_wready),
	 .wlast(clint_wlast),
	 .bresp(clint_bresp),
	 .bvalid(clint_bvalid),
	 .bready(clint_bready),
	 .bid(clint_bid)
  );



  //IFU:
  wire [1:0] jump;
  wire [31:0] target_address;
  wire ifu_valid;
  wire [31:0] pc /*verilator public*/;
  wire [31:0] inst /*verilator public*/;

  ysyx_26070215_inst_fetch ysyx_26070215_IFU(
    .rst(reset),
    .clk(clock),
	.target_address(target_address),
	.flag(outdata[0]),
    .jump(jump),
    .pc(pc),
    .inst(inst),
	.valid(ifu_valid),
	.idu_ready(idu_ready),

	.araddr(ifu_araddr),
	.arvalid(ifu_arvalid),
	.arready(ifu_arready),
	.arid(ifu_arid),
	.arlen(ifu_arlen),
	.arsize(ifu_arsize),
    .arburst(ifu_arburst),
	.rdata(ifu_rdata),
	.rresp(ifu_rresp),
	.rvalid(ifu_rvalid),
	.rready(ifu_rready),
	.rlast(ifu_rlast),
	.rid(ifu_rid),
	.awaddr(ifu_awaddr),
	.awvalid(ifu_awvalid),
	.awready(ifu_awready),
	.awid(ifu_awid),
	.awlen(ifu_awlen),
	.awsize(ifu_awsize),
	.awburst(ifu_awburst),
	.wdata(ifu_wdata),
	.wstrb(ifu_wstrb),
	.wvalid(ifu_wvalid),
	.wready(ifu_wready),
	.wlast(ifu_wlast),
	.bresp(ifu_bresp),
	.bvalid(ifu_bvalid),
	.bready(ifu_bready),
	.bid(ifu_bid)
  );


  //IDU
  wire [4:0] rd;
  wire [31:0] op1, op2;
  wire [4:0] alu_op;
  wire [4:0] ls_type;
  wire w;
  wire [2:0] wb_sel;
  wire [31:0] offset;
  wire [31:0] base;
  wire idu_valid;
  wire idu_ready;

  ysyx_26070215_inst_decode ysyx_26070215_IDU(
    .inst(inst),
	.pc(pc),
    .rdata1(rdata1),
    .rdata2(rdata2),
    .rd(rd),
    .op1(op1),
    .op2(op2),
    .raddr1(raddr1),
    .raddr2(raddr2),
    .alu_op(alu_op),
    .ls_type(ls_type),
    .jump(jump),
    .wb_sel(wb_sel),
    .ebreak(ebreak),
    .wen(w),
	.offset(offset),
	.base(base),
	.csr_addr(csr_addr),
	.csr_wdata(csr_wdata),
	.csr_wdata_gpr(csr_wdata_gpr),
	.csr_rdata(csr_rdata),
	.csr_wen(csr_wen),
	.csr_ren(csr_ren),
	.trap(trap),
	.mepc(mepc),
	.mcause(mcause),
	.mtvec(mtvec),
	.mret_mepc(mret_mepc),
	.ifu_valid(ifu_valid),
	.valid(idu_valid),
	.exu_ready(exu_ready),
	.ready(idu_ready)
  );

  //EXU
  wire exu_valid;
  wire exu_ready;
  
  ysyx_26070215_execution ysyx_26070215_EXU(
    .op1(op1),
    .op2(op2),
    .alu_op(alu_op),
	.offset(offset),
	.base(base),
    .out(outdata),
	.target_address(target_address),
	.idu_valid(idu_valid),
	.valid(exu_valid),
	.lsu_ready(lsu_ready),
	.ready(exu_ready)
  );


  //LSU:
  wire [31:0] lsu_to_wbu_data;
  wire lsu_ready, lsu_to_wbu_valid;

  ysyx_26070215_load_store ysyx_26070215_LSU(
	.rst(reset),
	.clk(clock),
    .ls_type(ls_type),
    .addr(outdata),
    .rdata_to_wbu(lsu_to_wbu_data),
    .wdata_from_gpr(rdata2),
	.exu_valid(exu_valid),
	.lsu_to_wbu_valid(lsu_to_wbu_valid),
	.wbu_ready(wbu_ready),
	.lsu_ready(lsu_ready),

	.araddr(lsu_araddr),
	.arvalid(lsu_arvalid),
	.arready(lsu_arready),
	.arid(lsu_arid),
	.arlen(lsu_arlen),
	.arsize(lsu_arsize),
    .arburst(lsu_arburst),
	.rdata(lsu_rdata),
	.rresp(lsu_rresp),
	.rvalid(lsu_rvalid),
	.rready(lsu_rready),
	.rlast(lsu_rlast),
	.rid(lsu_rid),
	.awaddr(lsu_awaddr),
	.awvalid(lsu_awvalid),
	.awready(lsu_awready),
	.awid(lsu_awid),
	.awlen(lsu_awlen),
	.awsize(lsu_awsize),
	.awburst(lsu_awburst),
	.wdata(lsu_wdata),
	.wstrb(lsu_wstrb),
	.wvalid(lsu_wvalid),
	.wready(lsu_wready),
	.wlast(lsu_wlast),
	.bresp(lsu_bresp),
	.bvalid(lsu_bvalid),
	.bready(lsu_bready),
	.bid(lsu_bid)
  );


  //WBU
  wire wbu_valid;
  wire wbu_ready;

  ysyx_26070215_writeback ysyx_26070215_WBU(
    .w(w),
    .rd(rd),
    .data(outdata),
    .lsu_data(lsu_to_wbu_data),
    .PC(pc),
    .wb_sel(wb_sel),
	.csr_data(csr_wdata_gpr),
    .w_en(w_en),
    .waddr(waddr),
    .wdata(wdata),
	.lsu_valid(lsu_to_wbu_valid),
	.wbu_valid(wbu_valid),
	.wbu_ready(wbu_ready)
  );

endmodule
