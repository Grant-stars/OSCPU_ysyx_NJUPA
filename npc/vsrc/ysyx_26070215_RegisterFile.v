module ysyx_26070215_RegisterFile #(ADDR_WIDTH = 4, DATA_WIDTH = 32) (
  input clk,
  input rst,
  output [DATA_WIDTH-1:0] rdata1,
  input [ADDR_WIDTH-1:0] raddr1,
  output [DATA_WIDTH-1:0] rdata2,
  input [ADDR_WIDTH-1:0] raddr2,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input w_en,
  input wbu_valid
);

  wire wen;
  assign wen = w_en & (|waddr) & wbu_valid;
  reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0] /*verilator public*/;
  integer i;
  always @(posedge clk) begin
    if(rst)begin
      for(i=0; i<=2**ADDR_WIDTH-1;i++)begin
        rf[i]<=0;
      end
    end
    else begin
      if(wen) rf[waddr] <= wdata;
      //$display(rf[10]);
    end
  end
  assign rdata1 = rf[raddr1];
  assign rdata2 = rf[raddr2];

endmodule







