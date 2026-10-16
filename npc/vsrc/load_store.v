module load_store(
	input rst,
	input clk,
    input [4:0] ls_type,
    input [31:0] addr,
    output reg [31:0] rdata_to_wbu,
    input [31:0] wdata_from_gpr,
	input exu_valid,
	output lsu_to_wbu_valid,
	input wbu_ready,
	output lsu_ready,

	//AXI4-Lite
	//AR
	output [31:0] araddr,
	output arvalid,
	input arready,

	//R
	input [31:0] rdata,
	input [1:0] rresp,
	input rvalid,
	output reg rready,

	//AW
	output [31:0] awaddr,
	output awvalid,
	input awready,

	//W
	output reg [31:0] wdata,
	output [3:0] wstrb,
	output wvalid,
	input wready,

	//B
	input [1:0] bresp,
	input bvalid,
	output bready
);
    parameter [4:0] LS_LB = 1, LS_LH = 2 ,LS_LW = 3, LS_LBU = 4, LS_LHU = 5, LS_SB = 6, LS_SH = 7, LS_SW=8;
	parameter [2:0] IDLE = 0, WAIT_AR_READY = 1, WAIT_R = 2, WAIT_AW_READY = 3, WAIT_W = 4, WAIT_B = 5, WAIT_HANDLE = 6;

	reg valid, wen;

	//fsm
	
	//IDLE -> WAIT_AR_READY -> WAIT_R ->        ->  WAIT_HANDLE
	//	   -> WAIT_AW_READY -> WAIT_W -> WAIT_B
	reg [2:0] lsu_state, lsu_next_state;
	wire mem_data_ready;

	always @(*)begin
		case(lsu_state)
			IDLE: begin
				if(exu_valid && valid)begin
					if(wen) lsu_next_state = awready ? WAIT_W : WAIT_AW_READY;
					else lsu_next_state = arready ? WAIT_R : WAIT_AR_READY;
				end
				else lsu_next_state = IDLE;
			end

			WAIT_AR_READY: lsu_next_state = arready ? WAIT_R : WAIT_AR_READY;
			WAIT_R: lsu_next_state = (rvalid && rready && !(|rresp)) ? (wbu_ready ? IDLE : WAIT_HANDLE) : WAIT_R;

			WAIT_AW_READY: lsu_next_state = awready ? WAIT_W : WAIT_AW_READY;
			WAIT_W: lsu_next_state = (wvalid && wready) ? WAIT_B : WAIT_W;
			WAIT_B: lsu_next_state = (bvalid && bready) ? (wbu_ready ? IDLE : WAIT_HANDLE) : WAIT_B;

			WAIT_HANDLE: lsu_next_state = wbu_ready ? IDLE : WAIT_HANDLE;
			default: lsu_next_state = IDLE;
		endcase
	end

    assign araddr = addr;
	assign awaddr = addr;
	
	assign arvalid = ((lsu_state==IDLE || lsu_state==WAIT_AR_READY) && exu_valid && valid && !wen);
	assign awvalid = ((lsu_state==IDLE || lsu_state==WAIT_AW_READY) && exu_valid && valid && wen);

	assign wvalid = lsu_state==WAIT_W;

	assign bready = lsu_state==WAIT_B;

	always @(*)begin
		sig_assert(~(|bresp));
		sig_assert(~(|rresp));
	end

	assign lsu_ready = lsu_next_state == IDLE;
	assign mem_data_ready = ((lsu_state==WAIT_R) && rvalid && rready && !(|rresp)) ||
		((lsu_state==WAIT_B) && bvalid && bready) || (lsu_state==WAIT_HANDLE);
	assign lsu_to_wbu_valid = exu_valid && ((lsu_state==IDLE && !valid) || mem_data_ready);

	reg rready_reg;
	always @(posedge clk)begin
		if(rst)begin
			rready <= 0;
			rready_reg <= 0;
		end
		else begin
			if(lsu_state==WAIT_R && rvalid && !rready_reg && !rready) rready_reg <= 1;
			else rready_reg <= 0;
			rready <= rready_reg;
		end
	end

	reg [31:0] rdata_from_mem, rdata_from_mem_reg;
	always @(posedge clk)begin
		rdata_from_mem_reg <= rdata_from_mem;
	end

	assign rdata_from_mem= (lsu_state==WAIT_R && rvalid && rready && !(|rresp)) ? rdata : rdata_from_mem_reg;

	always@(posedge clk)begin
		if(rst) lsu_state <= 0;
		else lsu_state <= lsu_next_state;
	end


    //其中读操作总是返回按4字节对齐读出的数据, 需要由RTL代码根据读地址选择出需要的部分
    //wstrb`中每比特表示`wdata`中1个字节的掩码传递给pmem_write(),如`wstrb = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
    always @(*)begin
        wdata = wdata_from_gpr;
        valid = 0;
        wen = 0;
        wstrb = 0;

        case(ls_type)
			LS_LB:begin
                case(addr[1:0])
                    2'b00: rdata_to_wbu = {{24{rdata_from_mem[7]}},rdata_from_mem[7:0]};
                    2'b01: rdata_to_wbu = {{24{rdata_from_mem[15]}},rdata_from_mem[15:8]};
                    2'b10: rdata_to_wbu = {{24{rdata_from_mem[23]}},rdata_from_mem[23:16]};
                    2'b11: rdata_to_wbu = {{24{rdata_from_mem[31]}},rdata_from_mem[31:24]};
                endcase
                valid = 1;
			end

			LS_LH:begin
				case(addr[1:0])
					2'b00: rdata_to_wbu = {{16{rdata_from_mem[15]}},rdata_from_mem[15:0]};
					2'b10: rdata_to_wbu = {{16{rdata_from_mem[31]}},rdata_from_mem[31:16]};
					default:rdata_to_wbu = 0;
				endcase
				valid = 1;
			end

            LS_LW:begin
                rdata_to_wbu= rdata_from_mem;
                valid = 1;
            end

            LS_LBU:begin
                case(addr[1:0])
                    2'b00: rdata_to_wbu = {24'b0,rdata_from_mem[7:0]};
                    2'b01: rdata_to_wbu = {24'b0,rdata_from_mem[15:8]};
                    2'b10: rdata_to_wbu = {24'b0,rdata_from_mem[23:16]};
                    2'b11: rdata_to_wbu = {24'b0,rdata_from_mem[31:24]};
                endcase
                valid = 1;
            end

			LS_LHU:begin
				case(addr[1:0])
					2'b00: rdata_to_wbu = {16'b0,rdata_from_mem[15:0]};
					2'b10: rdata_to_wbu = {16'b0,rdata_from_mem[31:16]};
					default:rdata_to_wbu = 0;
				endcase
				valid = 1;

			end

            //pmem_write()总是往地址为`waddr & ~0x3u`的4字节按写掩码`wstrb`写入`wdata`
            //故此处data需根据指令类型以及地址低两位做搬移

            LS_SB:begin
                valid = 1;
                wen = 1;
                wdata = {4{wdata_from_gpr[7:0]}};
                case(addr[1:0])
                    2'b00: wstrb = 4'b0001;
                    2'b01: wstrb = 4'b0010;
                    2'b10: wstrb = 4'b0100;
                    2'b11: wstrb = 4'b1000;
                endcase
            end
			
			LS_SH:begin
				valid = 1;
                wen = 1;
                wdata = {2{wdata_from_gpr[15:0]}};
                case(addr[1:0])
                    2'b00: wstrb = 4'b0011;
                    2'b10: wstrb = 4'b1100;
					default: wstrb = 0;
                endcase

			end

            LS_SW:begin
                valid = 1;
                wen = 1;
                wstrb = 4'b1111;
            end

            default:begin
                wstrb = 0;
            end
        endcase

    end

endmodule
