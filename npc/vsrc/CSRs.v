module CSRs #(DATA_WIDTH = 32) (
	input clk,
	input rst,
	input [11:0] addr,
	input [DATA_WIDTH-1:0] wdata,
	input wen,
	input ren,
	output reg [DATA_WIDTH-1:0] rdata,
	input trap,
	input [31:0] mepc_data,
	input [31:0] mcause_data,
	output [31:0] mtvec_data
);

reg [63:0] mcycle; //0xB80, 0xB00
wire [63:0] n_mcycle;

reg [31:0] mvendorid; //0xF11
reg [31:0] marchid; //0xF12


// mstatus: 0x300; mtvec: 0x305; mepc: 0x341; mcause: 0x342
reg [31:0] mstatus; //0x300
reg [31:0] mtvec; //0x305
reg [31:0] mepc; //0x341
reg [31:0] mcause; //0x342

assign mtvec_data = mtvec;

assign n_mcycle = mcycle + 1;

always@(posedge clk)begin
	if(rst)begin
		mcycle <= 0;
		mvendorid <= 32'h79737978;
		marchid <= 32'h18DCCC7;
		mstatus <= 32'h1800;
		mtvec <= 0;
		mepc <= 0;
		mcause <= 0;
	end
	else begin
		if(wen)begin
			case(addr)
				12'hB00: mcycle <= {n_mcycle[63:32], wdata};
				12'hB80: mcycle <= {wdata, n_mcycle[31:0]};
			    12'hF11: mcycle <= n_mcycle;
				12'hF12: mcycle <= n_mcycle;
				12'h300: begin
					mstatus <= wdata;
					mcycle <= n_mcycle;
				end
				12'h305: begin
					mtvec <= wdata;
					mcycle <= n_mcycle;
				end
				12'h341: begin
					mepc <= wdata;
					mcycle <= n_mcycle;
				end
				12'h342: begin
					mcause <= wdata;
					mcycle <= n_mcycle;
				end

				default: begin
					mcycle <= n_mcycle;
				end
			endcase
		end
		else if(ren)begin
			case(addr)
				12'hB00: mcycle <= {mcycle[63:32],wdata}+1;
				12'hB80: mcycle <= {wdata,mcycle[31:0]}+1;
			    12'hF11: mcycle <= n_mcycle;
				12'hF12: mcycle <= n_mcycle;
				12'h300: begin
					mstatus <= wdata;
					mcycle <= n_mcycle;
				end
				12'h305: begin
					mtvec <= wdata;
					mcycle <= n_mcycle;
				end
				12'h341: begin
					mepc <= wdata;
					mcycle <= n_mcycle;
				end
				12'h342: begin
					mcause <= wdata;
					mcycle <= n_mcycle;
				end

				default:begin
					mcycle <= n_mcycle;
				end
			endcase
		end
		else if(trap)begin
			mepc <= mepc_data;
			mcause <= mcause_data;
			mcycle <= n_mcycle;
		end
		else begin
			mcycle <= n_mcycle;
		end
	end
end

always@(*)begin
	case(addr)
		12'hB00: rdata = mcycle[31:0];
		12'hB80: rdata = mcycle[63:32];
		12'hF11: rdata = mvendorid;
		12'hF12: rdata = marchid;
		12'h300: rdata = mstatus;
		12'h305: rdata = mtvec;
		12'h341: rdata = mepc;
		12'h342: rdata = mcause;
		default: rdata = 0;

	endcase
end


endmodule
