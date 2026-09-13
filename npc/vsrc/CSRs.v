module CSRs #(DATA_WIDTH = 32) (
	input clk,
	input rst,
	input [11:0] addr,
	input [DATA_WIDTH-1:0] wdata,
	input wen,
	input ren,
	output reg [DATA_WIDTH-1:0] rdata
);

reg [63:0] mcycle;
wire [63:0] n_mcycle;

assign n_mcycle = mcycle + 1;

always@(posedge clk)begin
	if(rst)begin
		mcycle <= 0;
	end
	else begin
		if(wen)begin
			case(addr)
				12'hB00: mcycle <= {n_mcycle[63:32], wdata};
				12'hB80: mcycle <= {wdata, n_mcycle[31:0]};
				
				default: begin
					mcycle <= n_mcycle;
				end
			endcase
		end
		else if(ren)begin
			case(addr)
				12'hB00: mcycle <= {mcycle[63:32],wdata}+1;
				12'hB80: mcycle <= {wdata,mcycle[31:0]}+1;

				default:begin
					mcycle <= n_mcycle;
				end
			endcase
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

		default: rdata = 0;

	endcase
end


endmodule
