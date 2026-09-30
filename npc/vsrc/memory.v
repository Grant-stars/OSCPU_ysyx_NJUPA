/* verilator lint_off UNUSEDSIGNAL */
module memory(
	input clk,
	input rst,
    input valid,
    input wen,
    input [31:0] raddr ,
    output reg [31:0] rdata,
    input [31:0] waddr ,
    input [31:0] wdata,
    input [7:0] wmask
);
/*
    always @(*)begin
        if(valid && (~wen))begin
            rdata = pmem_read(raddr);
        end
        else begin
            rdata = 0;
        end
    end

	always @(posedge clk)begin
		if(valid && wen)begin
            pmem_write(waddr, wdata, wmask);
		end
	end
*/

wire [31:0] rdata2;

  RegisterFile #(8, 32) MEM1(
    .clk(clk),
    .rst(rst),
    .rdata1(rdata),
    .raddr1(raddr[7:0]),
    .rdata2(rdata2),
    .raddr2(0), 
    .wdata(wdata),
    .waddr(waddr[7:0]),
    .w_en(wen && valid)
     );


endmodule
/* verilator lint_on UNUSEDSIGNAL */
