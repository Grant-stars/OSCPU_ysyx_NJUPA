module load_store(
	input rst,
	input clk,
    input [4:0] ls_type,

    input [31:0] raddr,
    output [31:0] raddr_to_mem,

    input [31:0] waddr,
    output [31:0] waddr_to_mem,

    input [31:0] rdata_from_mem,
    output reg [31:0] rdata_to_gpr,

    input [31:0] wdata_from_gpr,
    output reg [31:0] wdata_to_mem,
    output reg [7:0] wmask,

    output reg wen,     //写请求
	input exu_valid,
	output lsu_to_mem_valid,
	input mem_to_lsu_valid,
	output lsu_to_wbu_valid,

	input wbu_ready,
	output lsu_ready
);
    parameter [4:0] LS_LB = 1, LS_LH = 2 ,LS_LW = 3, LS_LBU = 4, LS_LHU = 5, LS_SB = 6, LS_SH = 7, LS_SW=8;
	parameter IDLE = 0, WAIT = 1;
    assign raddr_to_mem = raddr;
    assign waddr_to_mem = waddr;

	reg valid;
	assign lsu_to_mem_valid = exu_valid & valid;

	//Module bus
	wire lsu_busy;
	assign lsu_to_wbu_valid = exu_valid && ((lsu_state && mem_to_lsu_valid) || (!lsu_state && !valid));
	assign lsu_ready =(!lsu_busy) && wbu_ready;
	
	assign lsu_busy = (!lsu_state && lsu_to_mem_valid) || (lsu_state && !wbu_ready);

	//SimpleBus fsm
	reg lsu_state, lsu_next_state;

	always @(*)begin
		case(lsu_state)
			IDLE: lsu_next_state = lsu_to_mem_valid ? WAIT : IDLE;
			WAIT: lsu_next_state = (mem_to_lsu_valid && wbu_ready) ? IDLE : WAIT;
		endcase
	end
	
	always@(posedge clk)begin
		if(rst) lsu_state <= 0;
		else lsu_state <= lsu_next_state;
	end

	

    //其中读操作总是返回按4字节对齐读出的数据, 需要由RTL代码根据读地址选择出需要的部分
    //wmask`中每比特表示`wdata`中1个字节的掩码传递给pmem_write(),如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
    always @(*)begin                                        
        rdata_to_gpr = rdata_from_mem;
        wdata_to_mem = wdata_from_gpr;
        valid = 0;
        wen = 0;
        wmask = 0;

        case(ls_type)
			LS_LB:begin
                case(raddr[1:0])
                    2'b00: rdata_to_gpr = {{24{rdata_from_mem[7]}},rdata_from_mem[7:0]};
                    2'b01: rdata_to_gpr = {{24{rdata_from_mem[15]}},rdata_from_mem[15:8]};
                    2'b10: rdata_to_gpr = {{24{rdata_from_mem[23]}},rdata_from_mem[23:16]};
                    2'b11: rdata_to_gpr = {{24{rdata_from_mem[31]}},rdata_from_mem[31:24]};
                endcase
                valid = 1;
			end

			LS_LH:begin
				case(raddr[1:0])
					2'b00: rdata_to_gpr = {{16{rdata_from_mem[15]}},rdata_from_mem[15:0]};
					2'b10: rdata_to_gpr = {{16{rdata_from_mem[31]}},rdata_from_mem[31:16]};
					default:rdata_to_gpr = 0;
				endcase
				valid = 1;
			end

            LS_LW:begin
                rdata_to_gpr = rdata_from_mem;
                valid = 1;
            end

            LS_LBU:begin
                case(raddr[1:0])
                    2'b00: rdata_to_gpr = {24'b0,rdata_from_mem[7:0]};
                    2'b01: rdata_to_gpr = {24'b0,rdata_from_mem[15:8]};
                    2'b10: rdata_to_gpr = {24'b0,rdata_from_mem[23:16]};
                    2'b11: rdata_to_gpr = {24'b0,rdata_from_mem[31:24]};
                endcase
                valid = 1;
            end

			LS_LHU:begin
				case(raddr[1:0])
					2'b00: rdata_to_gpr = {16'b0,rdata_from_mem[15:0]};
					2'b10: rdata_to_gpr = {16'b0,rdata_from_mem[31:16]};
					default:rdata_to_gpr = 0;
				endcase
				valid = 1;

			end

            //pmem_write()总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
            //故此处data需根据指令类型以及地址低两位做搬移

            LS_SB:begin
                valid = 1;
                wen = 1;
                wdata_to_mem = {4{wdata_from_gpr[7:0]}};
                case(waddr_to_mem[1:0])
                    2'b00: wmask = 8'b00000001;
                    2'b01: wmask = 8'b00000010;
                    2'b10: wmask = 8'b00000100;
                    2'b11: wmask = 8'b00001000;
                endcase
            end
			
			LS_SH:begin
				valid = 1;
                wen = 1;
                wdata_to_mem = {2{wdata_from_gpr[15:0]}};
                case(waddr_to_mem[1:0])
                    2'b00: wmask = 8'b00000011;
                    2'b10: wmask = 8'b00001100;
					default: wmask = 0; 
                endcase

			end

            LS_SW:begin
                valid = 1;
                wen = 1;
                wmask = 8'b00001111;
            end

            default:begin
                wmask = 0;
            end
        endcase

    end                                          

endmodule
