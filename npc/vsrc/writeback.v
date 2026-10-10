`define GPR_ADDR_WIDTH 5
module writeback(
    input w,
    input [4:0] rd,
    input [31:0] data,
    input [31:0] lsu_data,
    input [31:0] PC,
    input [2:0] wb_sel,
	input [31:0] csr_data,
    output w_en,
    output [`GPR_ADDR_WIDTH-1:0] waddr,
    output reg [31:0] wdata,
	input lsu_valid,
	output wbu_valid,
	output wbu_ready
);
	assign wbu_ready = 1;

    parameter [2:0] WB_ALU = 1, WB_MEM = 2, WB_PC = 3, WB_CSR = 4;

	assign wbu_valid = lsu_valid;
    assign w_en = w;
    assign waddr = rd[`GPR_ADDR_WIDTH-1:0];
    always @(*)begin
        case(wb_sel)
            WB_ALU: wdata = data;
            WB_MEM: wdata = lsu_data;
            WB_PC: wdata = PC+4;
			WB_CSR: wdata = csr_data;
            default: wdata = 0;
        endcase
    end

endmodule
