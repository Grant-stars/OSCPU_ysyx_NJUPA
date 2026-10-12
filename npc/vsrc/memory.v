module memory(
	input clk,
	input rst,
    input lsu_reqValid,
	output reg lsu_respValid,
    input lsu_wen,
    input [31:0] lsu_addr,
    output reg [31:0] lsu_rdata,
    input [31:0] lsu_wdata,
    input [7:0] lsu_wmask,

	input ifu_reqValid,
	output ifu_respValid,
    input [31:0] ifu_addr,
    output reg [31:0] ifu_rdata
);

	parameter [4:0] DELAY = 5;
    initial begin
		ifu_rdata = pmem_read(32'h80000000);
	end

	//delay:
	//reg [DELAY - 1 :0] ifu_delay, lsu_delay;
	reg [DELAY - 1 :0] ifu_delay;
	always @(posedge clk)begin
		if(rst) begin
			ifu_delay <= 0;
			//lsu_delay <= 0;
		end
		else begin
			ifu_delay <= { ifu_delay[DELAY-2:0], ifu_reqValid };
			//lsu_delay <= { lsu_delay[DELAY-2:0], lsu_reqValid };
		end
	end
	assign ifu_respValid = ifu_delay[DELAY-1];
	//assign lsu_respValid = lsu_delay[DELAY-1];

	//ram:
    always @(posedge clk)begin
		//lsu_rdata <= (lsu_reqValid && !lsu_wen) ? pmem_read(lsu_addr) : 32'b0;
		if(lsu_reqValid && !lsu_wen) begin
			lsu_rdata <= pmem_read(lsu_addr);

		end
		if(lsu_reqValid && lsu_wen)begin
            pmem_write(lsu_addr, lsu_wdata, lsu_wmask);
		end
		lsu_respValid <= lsu_reqValid;
	end

	//rom:
	always @(posedge clk)begin
		if(ifu_reqValid) begin
			ifu_rdata <= pmem_read(ifu_addr);
		end
	end
endmodule
