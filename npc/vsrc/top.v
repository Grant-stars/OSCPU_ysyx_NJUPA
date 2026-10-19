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
module top(
  input clk,
  input rst,
  output [31:0] pc,
  output [31:0] inst
  );

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

  RegisterFile #(`GPR_ADDR_WIDTH, 32) GPR (
    .clk(clk),
    .rst(rst),
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

  CSRs #(32) CSR (
	.clk(clk),
	.rst(rst),
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

	//W
	wire [31:0] ifu_wdata;
	wire [3:0] ifu_wstrb;
	wire ifu_wvalid, ifu_wready;

	//B
	wire [1:0] ifu_bresp;
	wire ifu_bvalid, ifu_bready;

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

	//W
	wire [31:0] lsu_wdata;
	wire [3:0] lsu_wstrb;
	wire lsu_wvalid, lsu_wready;

	//B
	wire [1:0] lsu_bresp;
	wire lsu_bvalid, lsu_bready;


	wire Bus_access;
  memory_access arbiter(
	.clk(clk),
	.rst(rst),

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
	.wdata0(ifu_wdata),
	.wstrb0(ifu_wstrb),
	.wvalid0(ifu_wvalid),
	.wready0(ifu_wready),
	.bresp0(ifu_bresp),
	.bvalid0(ifu_bvalid),
	.bready0(ifu_bready),
	
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
	.wdata1(lsu_wdata),
	.wstrb1(lsu_wstrb),
	.wvalid1(lsu_wvalid),
	.wready1(lsu_wready),
	.bresp1(lsu_bresp),
	.bvalid1(lsu_bvalid),
	.bready1(lsu_bready),

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
	.wdata(Xbar_wdata),
	.wstrb(Xbar_wstrb),
	.wvalid(Xbar_wvalid),
	.wready(Xbar_wready),
	.bresp(Xbar_bresp),
	.bvalid(Xbar_bvalid),
	.bready(Xbar_bready),

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
  wire [31:0] Xbar_wdata;
  wire [3:0] Xbar_wstrb;
  wire Xbar_wvalid;
  wire Xbar_wready;
  wire [1:0] Xbar_bresp;
  wire Xbar_bvalid;
  wire Xbar_bready;
	
  Xbar Xbar(
	.clk(clk),
	.rst(rst),
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
	.wdata(Xbar_wdata),
	.wstrb(Xbar_wstrb),
	.wvalid(Xbar_wvalid),
	.wready(Xbar_wready),
	.bresp(Xbar_bresp),
	.bvalid(Xbar_bvalid),
	.bready(Xbar_bready),

	.araddr0(uart_araddr),
	.arvalid0(uart_arvalid),
	.arready0(uart_arready),
	.arid0(uart_arid),
	.arlen0(uart_arlen),
	.arsize0(uart_arsize),
	.arburst0(uart_arburst),
	.rdata0(uart_rdata),
	.rresp0(uart_rresp),
	.rvalid0(uart_rvalid),
	.rready0(uart_rready),
	.rlast0(uart_rlast),
	.rid0(uart_rid),
	.awaddr0(uart_awaddr),
	.awvalid0(uart_awvalid),
	.awready0(uart_awready),
	.wdata0(uart_wdata),
	.wstrb0(uart_wstrb),
	.wvalid0(uart_wvalid),
	.wready0(uart_wready),
	.bresp0(uart_bresp),
	.bvalid0(uart_bvalid),
	.bready0(uart_bready),
	
	.araddr1(clint_araddr),
	.arvalid1(clint_arvalid),
	.arready1(clint_arready),
	.arid1(clint_arid),
	.arlen1(clint_arlen),
	.arsize1(clint_arsize),
	.arburst1(clint_arburst),
	.rdata1(clint_rdata),
	.rresp1(clint_rresp),
	.rvalid1(clint_rvalid),
	.rready1(clint_rready),
	.rlast1(clint_rlast),
	.rid1(clint_rid),
	.awaddr1(clint_awaddr),
	.awvalid1(clint_awvalid),
	.awready1(clint_awready),
	.wdata1(clint_wdata),
	.wstrb1(clint_wstrb),
	.wvalid1(clint_wvalid),
	.wready1(clint_wready),
	.bresp1(clint_bresp),
	.bvalid1(clint_bvalid),
	.bready1(clint_bready),

	.araddr2(m_araddr),
	.arvalid2(m_arvalid),
	.arready2(m_arready),
	.arid2(m_arid),
	.arlen2(m_arlen),
	.arsize2(m_arsize),
	.arburst2(m_arburst),
	.rdata2(m_rdata),
	.rresp2(m_rresp),
	.rvalid2(m_rvalid),
	.rready2(m_rready),
	.rlast2(m_rlast),
	.rid2(m_rid),
	.awaddr2(m_awaddr),
	.awvalid2(m_awvalid),
	.awready2(m_awready),
	.wdata2(m_wdata),
	.wstrb2(m_wstrb),
	.wvalid2(m_wvalid),
	.wready2(m_wready),
	.bresp2(m_bresp),
	.bvalid2(m_bvalid),
	.bready2(m_bready)
  );


 //uart:
  wire [31:0] uart_araddr;
  wire uart_arvalid;
  wire uart_arready;
  wire [3:0] uart_arid;
  wire [7:0] uart_arlen;
  wire [2:0] uart_arsize;
  wire [1:0] uart_arburst;
  wire [31:0] uart_rdata;
  wire [1:0] uart_rresp;
  wire uart_rvalid;
  wire uart_rready;
  wire uart_rlast;
  wire [3:0] uart_rid;
  wire [31:0] uart_awaddr;
  wire uart_awvalid;
  wire uart_awready;
  wire [31:0] uart_wdata;
  wire [3:0] uart_wstrb;
  wire uart_wvalid;
  wire uart_wready;
  wire [1:0] uart_bresp;
  wire uart_bvalid;
  wire uart_bready;
	
  uart UART(
	 .clk(clk),
	 .rst(rst),
	 .araddr(uart_araddr),
	 .arvalid(uart_arvalid),
	 .arready(uart_arready),
	 .arid(uart_arid),
	 .arlen(uart_arlen),
	 .arsize(uart_arsize),
     .arburst(uart_arburst),
	 .rdata(uart_rdata),
	 .rresp(uart_rresp),
	 .rvalid(uart_rvalid),
	 .rready(uart_rready),
	 .rlast(uart_rlast),
	 .rid(uart_rid),
	 .awaddr(uart_awaddr),
	 .awvalid(uart_awvalid),
	 .awready(uart_awready),
	 .wdata(uart_wdata),
	 .wstrb(uart_wstrb),
	 .wvalid(uart_wvalid),
	 .wready(uart_wready),
	 .bresp(uart_bresp),
	 .bvalid(uart_bvalid),
	 .bready(uart_bready)
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
  wire [31:0] clint_wdata;
  wire [3:0] clint_wstrb;
  wire clint_wvalid;
  wire clint_wready;
  wire [1:0] clint_bresp;
  wire clint_bvalid;
  wire clint_bready;
	
  CLINT CLINT(
	 .clk(clk),
	 .rst(rst),
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
	 .wdata(clint_wdata),
	 .wstrb(clint_wstrb),
	 .wvalid(clint_wvalid),
	 .wready(clint_wready),
	 .bresp(clint_bresp),
	 .bvalid(clint_bvalid),
	 .bready(clint_bready)
  );


  //MEM
  wire [31:0] m_araddr;
  wire m_arvalid;
  wire m_arready;
  wire [3:0] m_arid;
  wire [7:0] m_arlen;
  wire [2:0] m_arsize;
  wire [1:0] m_arburst;
  wire [31:0] m_rdata;
  wire [1:0] m_rresp;
  wire m_rvalid;
  wire m_rready;
  wire m_rlast;
  wire [3:0] m_rid;
  wire [31:0] m_awaddr;
  wire m_awvalid;
  wire m_awready;
  wire [31:0] m_wdata;
  wire [3:0] m_wstrb;
  wire m_wvalid;
  wire m_wready;
  wire [1:0] m_bresp;
  wire m_bvalid;
  wire m_bready;
	
  memory MEM(
	 .clk(clk),
	 .rst(rst),
	 .araddr(m_araddr),
	 .arvalid(m_arvalid),
	 .arready(m_arready),
	 .arid(m_arid),
	 .arlen(m_arlen),
	 .arsize(m_arsize),
     .arburst(m_arburst),
	 .rdata(m_rdata),
	 .rresp(m_rresp),
	 .rvalid(m_rvalid),
	 .rready(m_rready),
	 .rlast(m_rlast),
	 .rid(m_rid),
	 .awaddr(m_awaddr),
	 .awvalid(m_awvalid),
	 .awready(m_awready),
	 .wdata(m_wdata),
	 .wstrb(m_wstrb),
	 .wvalid(m_wvalid),
	 .wready(m_wready),
	 .bresp(m_bresp),
	 .bvalid(m_bvalid),
	 .bready(m_bready)
  );




  //IFU:
  wire [1:0] jump;
  wire [31:0] target_address;
  wire ifu_valid;

  inst_fetch IFU(
    .rst(rst),
    .clk(clk),
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
	.wdata(ifu_wdata),
	.wstrb(ifu_wstrb),
	.wvalid(ifu_wvalid),
	.wready(ifu_wready),
	.bresp(ifu_bresp),
	.bvalid(ifu_bvalid),
	.bready(ifu_bready)
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

  inst_decode IDU(
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
  
  execution EXU(
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

  load_store LSU(
	.rst(rst),
	.clk(clk),
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
	.wdata(lsu_wdata),
	.wstrb(lsu_wstrb),
	.wvalid(lsu_wvalid),
	.wready(lsu_wready),
	.bresp(lsu_bresp),
	.bvalid(lsu_bvalid),
	.bready(lsu_bready)
  );


  //WBU
  wire wbu_valid;
  wire wbu_ready;

  writeback WBU(
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
