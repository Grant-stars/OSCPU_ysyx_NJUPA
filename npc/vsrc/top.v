import "DPI-C" function void finish();
import "DPI-C" function void unimplement();
import "DPI-C" function void CSRexception();
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

  //MEM
  wire [31:0] lsu_addr, lsu_rdata, lsu_wdata;
  wire [7:0] lsu_wmask;
  wire lsu_wen, mem_to_lsu_valid;
  memory MEM(
	.clk(clk),
    .lsu_reqValid(lsu_to_mem_valid),
    .lsu_respValid(mem_to_lsu_valid),
    .lsu_wen(lsu_wen),
    .lsu_addr(lsu_addr),
    .lsu_rdata(lsu_rdata),
    .lsu_wdata(lsu_wdata),
    .lsu_wmask(lsu_wmask)
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
	.idu_ready(idu_ready)
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
  wire lsu_to_mem_valid;
  wire lsu_to_wbu_valid;
  wire lsu_ready;

  load_store LSU(
	.rst(rst),
	.clk(clk),
    .ls_type(ls_type),
    .addr(outdata),
    .addr_to_mem(lsu_addr),

    .rdata_from_mem(lsu_rdata),
    .rdata_to_wbu(lsu_to_wbu_data),

    .wdata_from_gpr(rdata2),
    .wdata_to_mem(lsu_wdata),

    .wmask(lsu_wmask),
    .wen(lsu_wen),
	
	.exu_valid(exu_valid),
	.lsu_to_wbu_valid(lsu_to_wbu_valid),
	.lsu_to_mem_valid(lsu_to_mem_valid),
	.mem_to_lsu_valid(mem_to_lsu_valid),

	.wbu_ready(wbu_ready),
	.lsu_ready(lsu_ready)
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
