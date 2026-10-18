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
  //AXI4-Lite

  //ifu
	//R
	wire [31:0] ifu_araddr;
	wire ifu_arvalid, ifu_arready;

	//AR
	wire [31:0] ifu_rdata;
	wire [1:0] ifu_rresp;
	wire ifu_rvalid, ifu_rready;

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

	//AR
	wire [31:0] lsu_rdata;
	wire [1:0] lsu_rresp;
	wire lsu_rvalid, lsu_rready;

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
	.rdata0(ifu_rdata),
	.rresp0(ifu_rresp),
	.rvalid0(ifu_rvalid),
	.rready0(ifu_rready),
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
	.rdata1(lsu_rdata),
	.rresp1(lsu_rresp),
	.rvalid1(lsu_rvalid),
	.rready1(lsu_rready),
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
	.rdata(Xbar_rdata),
	.rresp(Xbar_rresp),
	.rvalid(Xbar_rvalid),
	.rready(Xbar_rready),
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
  wire reg [31:0] Xbar_rdata;
  wire [1:0] Xbar_rresp;
  wire Xbar_rvalid;
  wire Xbar_rready;
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
	.rdata(Xbar_rdata),
	.rresp(Xbar_rresp),
	.rvalid(Xbar_rvalid),
	.rready(Xbar_rready),
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
	.rdata0(uart_rdata),
	.rresp0(uart_rresp),
	.rvalid0(uart_rvalid),
	.rready0(uart_rready),
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
	
	.araddr1(m_araddr),
	.arvalid1(m_arvalid),
	.arready1(m_arready),
	.rdata1(m_rdata),
	.rresp1(m_rresp),
	.rvalid1(m_rvalid),
	.rready1(m_rready),
	.awaddr1(m_awaddr),
	.awvalid1(m_awvalid),
	.awready1(m_awready),
	.wdata1(m_wdata),
	.wstrb1(m_wstrb),
	.wvalid1(m_wvalid),
	.wready1(m_wready),
	.bresp1(m_bresp),
	.bvalid1(m_bvalid),
	.bready1(m_bready)
  );


 //uart:
  wire [31:0] uart_araddr;
  wire uart_arvalid;
  wire uart_arready;
  wire reg [31:0] uart_rdata;
  wire [1:0] uart_rresp;
  wire uart_rvalid;
  wire uart_rready;
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
	 .rdata(uart_rdata),
	 .rresp(uart_rresp),
	 .rvalid(uart_rvalid),
	 .rready(uart_rready),
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


  //MEM
  wire [31:0] m_araddr;
  wire m_arvalid;
  wire m_arready;
  wire reg [31:0] m_rdata;
  wire [1:0] m_rresp;
  wire m_rvalid;
  wire m_rready;
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
	 .rdata(m_rdata),
	 .rresp(m_rresp),
	 .rvalid(m_rvalid),
	 .rready(m_rready),
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
