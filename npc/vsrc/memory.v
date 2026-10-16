module memory(
	input clk,
	input rst,
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
	input ifu_bready,

	//lsu
	//AR
	input [31:0] lsu_araddr,
	input lsu_arvalid,
	output lsu_arready,

	//R
	output reg [31:0] lsu_rdata,
	output [1:0] lsu_rresp,
	output lsu_rvalid,
	input lsu_rready,

	//AW
	input [31:0] lsu_awaddr,
	input lsu_awvalid,
	output lsu_awready,

	//W
	input [31:0] lsu_wdata,
	input [3:0] lsu_wstrb,
	input lsu_wvalid,
	output lsu_wready,

	//B
	output [1:0] lsu_bresp,
	output lsu_bvalid,
	input lsu_bready
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
	

    //lsu_fsm
	//lsu_R
	//lsu_AR_IDLE -> lsu_R -> lsu_WAIT_RREADY
	parameter [1:0] lsu_AR_IDLE = 0, lsu_READ = 1, lsu_WAIT_RREADY = 2;
    reg [1:0] lsu_state, lsu_next_state;
	reg [31:0] lsu_araddr_reg;

	always @(*)begin
		case(lsu_state)
			lsu_AR_IDLE: lsu_next_state = lsu_arvalid ? lsu_READ : lsu_AR_IDLE;
			lsu_READ: lsu_next_state = lsu_WAIT_RREADY;
			lsu_WAIT_RREADY: lsu_next_state = lsu_rready ? lsu_AR_IDLE : lsu_WAIT_RREADY;
			default: lsu_next_state = lsu_AR_IDLE;
		endcase
	end

	assign lsu_arready = lsu_state==lsu_AR_IDLE;
	assign lsu_rresp = 0;
	assign lsu_rvalid = lsu_state==lsu_WAIT_RREADY;

    always@ (posedge clk)begin
       if(rst) lsu_state <= 0;
       else lsu_state <= lsu_next_state;
    end

	always@ (posedge clk)begin
		if(lsu_state==lsu_AR_IDLE && lsu_next_state==lsu_READ)begin
			lsu_araddr_reg <= lsu_araddr;
		end
	end

	always @(posedge clk)begin
		if(lsu_state==lsu_READ && lsu_next_state==lsu_WAIT_RREADY) begin
			lsu_rdata <= pmem_read(lsu_araddr_reg);
		end
	end

	//lsu_W
	//lsu_AW_IDLE -> lsu_WAIT_W -> lsu_W -> lsu_B
	parameter [1:0] lsu_AW_IDLE = 0, lsu_WAIT_W = 1, lsu_W = 2, lsu_B = 3;
	reg [1:0] lsu_w_state, lsu_w_next_state;
	reg [31:0] lsu_awaddr_reg, lsu_wdata_reg;
	reg [3:0] lsu_wstrb_reg;

	always @(*)begin
		case(lsu_w_state)
			lsu_AW_IDLE: lsu_w_next_state = lsu_awvalid ? lsu_WAIT_W : lsu_AW_IDLE;
			lsu_WAIT_W: lsu_w_next_state = lsu_wvalid ? lsu_W : lsu_WAIT_W;
			lsu_W: lsu_w_next_state = lsu_B;
			lsu_B: lsu_w_next_state = lsu_bready ? lsu_AW_IDLE : lsu_B;
		endcase
	end

	assign lsu_awready = lsu_w_state==lsu_AW_IDLE;
	assign lsu_wready = lsu_w_state==lsu_WAIT_W;
	assign lsu_bresp = 0;
	assign lsu_bvalid = lsu_w_state==lsu_B;
	
    always@ (posedge clk)begin
       if(rst) lsu_w_state <= 0;
       else lsu_w_state <= lsu_w_next_state;
    end

	always@ (posedge clk)begin
		if(lsu_w_state==lsu_AW_IDLE && lsu_w_next_state==lsu_WAIT_W)begin
			lsu_awaddr_reg <= lsu_awaddr;
		end
		if(lsu_w_state==lsu_WAIT_W && lsu_w_next_state==lsu_W)begin
			lsu_wdata_reg <= lsu_wdata;
			lsu_wstrb_reg <= lsu_wstrb;
		end
	end

	always@ (posedge clk)begin
		if(lsu_w_state==lsu_W && lsu_w_next_state==lsu_B)begin
            pmem_write(lsu_awaddr_reg, lsu_wdata_reg, {4'b0, lsu_wstrb_reg});
		end
	end

endmodule
