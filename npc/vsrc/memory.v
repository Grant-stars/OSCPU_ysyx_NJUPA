module memory(
	input clk,
    input lsu_reqValid,
	output reg lsu_respValid,
    input lsu_wen,
    input [31:0] lsu_addr,
    output reg [31:0] lsu_rdata,
    input [31:0] lsu_wdata,
    input [7:0] lsu_wmask
);
    always @(posedge clk)begin
		lsu_rdata <= (lsu_reqValid && !lsu_wen) ? pmem_read(lsu_addr) : 32'b0;
		if(lsu_reqValid && lsu_wen)begin
            pmem_write(lsu_addr, lsu_wdata, lsu_wmask);
		end
		lsu_respValid <= lsu_reqValid;
	end
endmodule
