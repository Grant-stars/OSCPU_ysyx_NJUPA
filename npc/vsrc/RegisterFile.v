module RegisterFile #(ADDR_WIDTH = 4, DATA_WIDTH = 32) (
  input clk,
  input rst,
  output [DATA_WIDTH-1:0] rdata1,
  input [ADDR_WIDTH-1:0] raddr1,
  output [DATA_WIDTH-1:0] rdata2,
  input [ADDR_WIDTH-1:0] raddr2,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input w_en,
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

  wire wen;
  assign wen = w_en & (|waddr);
  reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
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


  assign rf0 = rf[0];
  assign rf1 = rf[1];
  assign rf2 = rf[2];
  assign rf3 = rf[3];
  assign rf4 = rf[4];
  assign rf5 = rf[5];
  assign rf6 = rf[6];
  assign rf7 = rf[7];
  assign rf8 = rf[8];
  assign rf9 = rf[9];
  assign rf10 = rf[10];
  assign rf11 = rf[11];
  assign rf12 = rf[12];
  assign rf13 = rf[13];
  assign rf14 = rf[14];
  assign rf15 = rf[15];



endmodule







