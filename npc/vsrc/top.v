import "DPI-C" function void finish();
import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
    input int waddr, input int wdata, input byte wmask);
`define GPR_ADDR_WIDTH 5
module top(
  input clk,
  input rst,
  output [31:0] pc,
  output [31:0] inst,
  output [31:0] rf0,
  output [31:0] rf1,
  output [31:0] rf2,
  output [31:0] rf3,
  output [31:0] rf4,
  output [31:0] rf5,
  output [31:0] rf6,
  output [31:0] rf7,
  output [31:0] rf8,
  output [31:0] rf9,
  output [31:0] rf10,
  output [31:0] rf11,
  output [31:0] rf12,
  output [31:0] rf13,
  output [31:0] rf14,
  output [31:0] rf15
); 

  //ebreak
  wire ebreak;

  always @(*) begin                                        
    if(ebreak) begin
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
    .rf0(rf0),
    .rf1(rf1),
    .rf2(rf2),
    .rf3(rf3),
    .rf4(rf4),
    .rf5(rf5),
    .rf6(rf6),
    .rf7(rf7),
    .rf8(rf8),
    .rf9(rf9),
    .rf10(rf10),
    .rf11(rf11),
    .rf12(rf12),
    .rf13(rf13),
    .rf14(rf14),
    .rf15(rf15)

  );

  //MEM
  wire [31:0] laddr, saddr, ldata, sdata;
  wire [7:0] smask;
  wire valid, sen;
  memory MEM(
    .valid(valid),
    .wen(sen),
    .raddr(laddr),
    .rdata(ldata),
    .waddr(saddr),
    .wdata(sdata),
    .wmask(smask)
  );


  //IFU:
  wire [1:0] jump;

  inst_fetch IFU(
    .rst(rst),
    .clk(clk),
    .data(outdata),
    .jump(jump),
    .pc(pc),
    .inst(inst)
  );


  //IDU
  wire [4:0] rd;
  wire [31:0] op1, op2;
  wire [4:0] alu_op;
  wire [4:0] ls_type;
  wire w;
  wire [1:0] wb_sel;

  inst_decode IDU(
    .inst(inst),
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
    .wen(w)
    );

  //EXU
  execution EXU(
    .op1(op1),
    .op2(op2),
    .alu_op(alu_op),
    .out(outdata)
  );


  //LSU: 
  wire [31:0] ldata_to_gpr;
  load_store LSU(
    .ls_type(ls_type),

    .raddr(outdata),
    .raddr_to_mem(laddr),

    .waddr(outdata),
    .waddr_to_mem(saddr),

    .rdata_from_mem(ldata),
    .rdata_to_gpr(ldata_to_gpr),

    .wdata_from_gpr(rdata2),
    .wdata_to_mem(sdata),

    .wmask(smask),
    .valid(valid),
    .wen(sen)
  );


  //WBU
  writeback WBU(
    .w(w),
    .rd(rd),
    .data(outdata),
    .l_data(ldata_to_gpr),
    .PC(pc),
    .wb_sel(wb_sel),
    .w_en(w_en),
    .waddr(waddr),
    .wdata(wdata)
  );

endmodule
