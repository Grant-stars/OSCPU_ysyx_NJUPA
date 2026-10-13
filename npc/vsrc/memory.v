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
	output ifu_reqReady,
	output ifu_respValid,
	input ifu_respReady,
    input [31:0] ifu_addr,
    output reg [31:0] ifu_rdata
);

    initial begin
		ifu_rdata = pmem_read(32'h80000000);
	end

	//delay:
	reg [3:0] lfsr;
	wire [3:0] delay;
	always @(posedge clk)begin
		if(rst)begin
			lfsr <= 4'b1;
		end
		else begin
			if((ifu_reqValid && ifu_reqReady)|| lsu_reqValid)begin
				lfsr <= {lfsr[3]^lfsr[0],lfsr[3:1]};
			end
		end
	end
	assign delay = lfsr > 1 ? lfsr : 2;
	
	reg [3:0] lsu_delay_counter, ifu_delay_counter;
	always @(posedge clk)begin
		if(rst)begin
			lsu_delay_counter <= 0;
			ifu_delay_counter <= 0;
		end
		else begin
			//ifu
			if (ifu_delay_counter==0)begin
				if (ifu_reqValid && ifu_reqReady)begin
					ifu_delay_counter <= ifu_delay_counter + 1;
				end
			end
			else begin
				if(ifu_delay_counter==delay)begin
					if(ifu_respReady) ifu_delay_counter <= 0;
				end
				else begin
					ifu_delay_counter <= ifu_delay_counter + 1;
				end
			end

			//lsu
			if (lsu_delay_counter==0)begin
				if (lsu_reqValid)begin
					lsu_delay_counter <= lsu_delay_counter + 1;
				end
			end
			else begin
				if(lsu_delay_counter==delay)begin
					lsu_delay_counter <= 0;
				end
				else begin
					lsu_delay_counter <= lsu_delay_counter + 1;
				end
			end
		end
	end

	assign ifu_reqReady = ifu_delay_counter==0;

	assign ifu_respValid = ifu_delay_counter==delay;
	assign lsu_respValid = lsu_delay_counter==delay;

	//ram:
    always @(posedge clk)begin
		//lsu_rdata <= (lsu_reqValid && !lsu_wen) ? pmem_read(lsu_addr) : 32'b0;
		if((lsu_delay_counter==delay-1) && !lsu_wen) begin
			lsu_rdata <= pmem_read(lsu_addr);

		end
		if((lsu_delay_counter==delay-1) && lsu_wen)begin
            pmem_write(lsu_addr, lsu_wdata, lsu_wmask);
		end
	end

	//rom:
	always @(posedge clk)begin
		if((ifu_delay_counter==delay-1)) begin
			ifu_rdata <= pmem_read(ifu_addr);
		end
	end
endmodule
