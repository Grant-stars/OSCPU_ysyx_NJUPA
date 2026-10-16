module memory(
	input clk,
	input rst,
    input lsu_reqValid,
	output reg lsu_reqReady,
	output lsu_respValid,
	input lsu_respReady,
	output lsu_error,
    input lsu_wen,
    input [31:0] lsu_addr,
    output reg [31:0] lsu_rdata,
    input [31:0] lsu_wdata,
    input [7:0] lsu_wmask,

	//AXI4-Lite
	
	//ifu
	//AR
	input [31:0] ifu_araddr,
	input ifu_arvalid,
	output ifu_arready,

	//R
	output reg [31:0] ifu_rdata,
	output [1:0] ifu_rresp,
	output ifu_rvalid,
	input ifu_rready,

	//AW
	input [31:0] ifu_awaddr,
	input ifu_awvalid,
	output ifu_awready,

	//W
	input [31:0] ifu_wdata,
	input [3:0] ifu_wstrb,
	input ifu_wvalid,
	output ifu_wready,

	//B
	output [1:0] ifu_bresp,
	output ifu_bvalid,
	input ifu_bready
	);

    initial begin
		ifu_rdata = pmem_read(32'h80000000);
	end


	//ifu_fsm
	//IFU_R
	//IFU_AR_IDLE -> IFU_R -> IFU_WAIT_RREADY
	parameter [1:0] IFU_AR_IDLE = 0, IFU_READ = 1, IFU_WAIT_RREADY = 2;
    reg [1:0] ifu_state, ifu_next_state;
	reg [31:0] ifu_araddr_reg;

	always @(*)begin
		case(ifu_state)
			IFU_AR_IDLE: ifu_next_state = ifu_arvalid ? IFU_READ : IFU_AR_IDLE;
			IFU_READ: ifu_next_state = IFU_WAIT_RREADY;
			IFU_WAIT_RREADY: ifu_next_state = ifu_rready ? IFU_AR_IDLE : IFU_WAIT_RREADY;
			default: ifu_next_state = IFU_AR_IDLE;
		endcase
	end

	assign ifu_arready = ifu_state==IFU_AR_IDLE;
	assign ifu_rresp = 0;
	assign ifu_rvalid = ifu_state==IFU_WAIT_RREADY;

    always@ (posedge clk)begin
       if(rst) ifu_state <= 0;
       else ifu_state <= ifu_next_state;
    end

	always@ (posedge clk)begin
		if(ifu_state==IFU_AR_IDLE && ifu_next_state==IFU_READ)begin
			ifu_araddr_reg <= ifu_araddr;
		end
	end

	//rom:
	always @(posedge clk)begin
		if(ifu_state==IFU_READ && ifu_next_state==IFU_WAIT_RREADY) begin
			ifu_rdata <= pmem_read(ifu_araddr_reg);
		end
	end

	//IFU_W
	//IFU_AW_IDLE -> IFU_WAIT_W -> IFU_W -> IFU_B
	parameter [1:0] IFU_AW_IDLE = 0, IFU_WAIT_W = 1, IFU_W = 2, IFU_B = 3;
	reg [1:0] ifu_w_state, ifu_w_next_state;
	reg [31:0] ifu_awaddr_reg, ifu_wdata_reg;
	reg [3:0] ifu_wstrb_reg;

	always @(*)begin
		case(ifu_w_state)
			IFU_AW_IDLE: ifu_w_next_state = ifu_awvalid ? IFU_WAIT_W : IFU_AW_IDLE;
			IFU_WAIT_W: ifu_w_next_state = ifu_wvalid ? IFU_W : IFU_WAIT_W;
			IFU_W: ifu_w_next_state = IFU_B;
			IFU_B: ifu_w_next_state = ifu_bready ? IFU_AW_IDLE : IFU_B;
		endcase
	end

	assign ifu_awready = ifu_w_state==IFU_AW_IDLE;
	assign ifu_wready = ifu_w_state==IFU_WAIT_W;
	assign ifu_bresp = 0;
	assign ifu_bvalid = ifu_w_state==IFU_B;
	
    always@ (posedge clk)begin
       if(rst) ifu_w_state <= 0;
       else ifu_w_state <= ifu_w_next_state;
    end

	always@ (posedge clk)begin
		if(ifu_w_state==IFU_AW_IDLE && ifu_w_next_state==IFU_WAIT_W)begin
			ifu_awaddr_reg <= ifu_awaddr;
		end
		if(ifu_w_state==IFU_WAIT_W && ifu_w_next_state==IFU_W)begin
			ifu_wdata_reg <= ifu_wdata;
			ifu_wstrb_reg <= ifu_wstrb;
		end
	end

	always@ (posedge clk)begin
		if(ifu_w_state==IFU_W && ifu_w_next_state==IFU_B)begin
            pmem_write(ifu_awaddr_reg, ifu_wdata_reg, {4'b0, ifu_wstrb_reg});
		end
	end
	

	//delay:
	reg [3:0] lfsr;
	wire [3:0] delay;
	always @(posedge clk)begin
		if(rst)begin
			lfsr <= 4'b1;
		end
		else begin
			if(lsu_reqValid && lsu_reqReady)begin
				lfsr <= {lfsr[3]^lfsr[0],lfsr[3:1]};
			end
		end
	end
	assign delay = lfsr > 1 ? lfsr : 2;
	
	reg [3:0] lsu_delay_counter;
	always @(posedge clk)begin
		if(rst)begin
			lsu_delay_counter <= 0;
		end
		else begin
			//lsu
			if (lsu_delay_counter==0)begin
				if (lsu_reqValid && lsu_reqReady)begin
					lsu_delay_counter <= lsu_delay_counter + 1;
				end
			end
			else begin
				if(lsu_delay_counter==delay)begin
					if(lsu_respReady) lsu_delay_counter <= 0;
				end
				else begin
					lsu_delay_counter <= lsu_delay_counter + 1;
				end
			end
		end
	end

	reg lsu_reqReady_reg;
	always @(posedge clk)begin
		if(rst)begin
			lsu_reqReady <= 0;
			lsu_reqReady_reg <= 0;
		end
		else begin
			if(lsu_delay_counter==0 && lsu_reqValid && !lsu_reqReady_reg && !lsu_reqReady) lsu_reqReady_reg <= 1;
			else lsu_reqReady_reg <= 0;
			lsu_reqReady <= lsu_reqReady_reg;
		end
	end


	assign lsu_respValid = lsu_delay_counter==delay;
	assign lsu_error = 0;

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

endmodule
