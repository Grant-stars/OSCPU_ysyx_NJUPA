module memory(
	input clk,
	input rst,
	//AR
	input [31:0] araddr,
	input arvalid,
	output arready,
	input [3:0] arid,
	input [7:0] arlen,
	input [2:0] arsize,
	input [1:0] arburst,

	//R
	output reg [31:0] rdata,
	output [1:0] rresp,
	output rvalid,
	input rready,
	output rlast,
	output reg [3:0] rid,

	//AW
	input [31:0] awaddr,
	input awvalid,
	output awready,
	input [3:0] awid,
	input [7:0] awlen,
	input [2:0] awsize,
	input [1:0] awburst,

	//W
	input [31:0] wdata,
	input [3:0] wstrb,
	input wvalid,
	output wready,
	input wlast,

	//B
	output [1:0] bresp,
	output bvalid,
	input bready,
	output reg [3:0] bid
);

    initial begin
		rdata = pmem_read(32'h80000000);
	end


	//fsm
	//R
	//AR_IDLE -> R -> WAIT_RREADY
	parameter [1:0] AR_IDLE = 0, READ = 1, WAIT_RREADY = 2;
    reg [1:0] state, next_state;
	reg [31:0] araddr_reg;

	always @(*)begin
		case(state)
			AR_IDLE: next_state = arvalid ? READ : AR_IDLE;
			READ: next_state = WAIT_RREADY;
			WAIT_RREADY: next_state = rready ? AR_IDLE : WAIT_RREADY;
			default: next_state = AR_IDLE;
		endcase
	end

	assign arready = state==AR_IDLE;
	assign rresp = 0;
	assign rvalid = state==WAIT_RREADY;
	assign rlast = state==WAIT_RREADY;

    always@ (posedge clk)begin
       if(rst) state <= 0;
       else state <= next_state;
    end

	always@ (posedge clk)begin
		if(state==AR_IDLE && next_state==READ)begin
			araddr_reg <= araddr;
			rid <= arid;
		end
	end

	//rom:
	always @(posedge clk)begin
		if(state==READ && next_state==WAIT_RREADY) begin
			rdata <= pmem_read(araddr_reg);
		end
	end

	wire _unused = &{arlen, arsize, arburst, awlen, awsize, awburst};

	//W
	//AW_IDLE -> WAIT_W -> W -> B
	parameter [1:0] AW_IDLE = 0, WAIT_W = 1, W = 2, B = 3;
	reg [1:0] w_state, w_next_state;
	reg [31:0] awaddr_reg, wdata_reg;
	reg [3:0] wstrb_reg;

	always @(*)begin
		case(w_state)
			AW_IDLE: w_next_state = awvalid ? WAIT_W : AW_IDLE;
			WAIT_W: w_next_state = (wvalid && wlast) ? W : WAIT_W;
			W: w_next_state = B;
			B: w_next_state = bready ? AW_IDLE : B;
		endcase
	end

	assign awready = w_state==AW_IDLE;
	assign wready = w_state==WAIT_W;
	assign bresp = 0;
	assign bvalid = w_state==B;
	
    always@ (posedge clk)begin
       if(rst) w_state <= 0;
       else w_state <= w_next_state;
    end

	always@ (posedge clk)begin
		if(w_state==AW_IDLE && w_next_state==WAIT_W)begin
			awaddr_reg <= awaddr;
			bid <= awid;
		end
		if(w_state==WAIT_W && w_next_state==W)begin
			wdata_reg <= wdata;
			wstrb_reg <= wstrb;
		end
	end

	always@ (posedge clk)begin
		if(w_state==W && w_next_state==B)begin
            pmem_write(awaddr_reg, wdata_reg, {4'b0, wstrb_reg});
		end
	end
	

endmodule

