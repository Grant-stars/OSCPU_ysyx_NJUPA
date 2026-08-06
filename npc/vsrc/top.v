import "DPI-C" function void finish();
`define GPR_ADDR_WIDTH 5
module top(
  input clk,
  input rst,

  //to C++ mem
  input [31:0] inst,
  output reg [31:0] pc,
  output [31:0] addr,
  output s_en,
  output l_en,
  output [31:0] s_data,
  input [31:0] l_data,
  output [2:0] len
); 


  wire [31:0] rdata1, rdata2, wdata, outdata;
  wire [`GPR_ADDR_WIDTH-1:0] raddr1, raddr2, waddr;
  wire w_en, ebreak;

  //ebreak
  always @(*) begin                                        
    if(ebreak) begin
      $display("FINISH");
      finish();
    end
  end                                          

  //PC:
  parameter [1:0] JUMP_NOP = 0, JUMP_JALR = 1;
  wire [1:0] jump;
  reg [31:0] dnpc;

  always@(*)begin
    case(jump)
      JUMP_NOP: dnpc = pc+4;
      JUMP_JALR: dnpc = {outdata[31:1], 1'b0};
      default: dnpc = pc+4;
    endcase
  end
  always @(posedge clk)begin                                        
    if(rst) pc<=32'b0;
    else begin
      pc<=dnpc;
    end
  end                                          

  //GPR：
  RegisterFile #(`GPR_ADDR_WIDTH, 32) GPR (
    .clk(clk),
    .rst(rst),
    .rdata1(rdata1),
    .raddr1(raddr1),
    .rdata2(rdata2),
    .raddr2(raddr2), 
    .wdata(wdata),
    .waddr(waddr),
    .w_en(w_en)
  );


  //IFU: implemented by C++

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
  wire [31:0] l_data_to_gpr;
  load_store LSU(
    .ls_type(ls_type),
    .addr(outdata),
    .addr_to_mem(addr),
    .l_data_from_mem(l_data),
    .l_data_to_gpr(l_data_to_gpr),
    .s_data_from_gpr(rdata2),
    .s_data_to_mem(s_data),
    .l_en(l_en),
    .s_en(s_en),
    .len(len)
  );

  //WBU
  writeback WBU(
    .w(w),
    .rd(rd),
    .data(outdata),
    .l_data(l_data_to_gpr),
    .PC(pc),
    .wb_sel(wb_sel),
    .w_en(w_en),
    .waddr(waddr),
    .wdata(wdata)
  );

endmodule
