module inst_fetch(
    input rst,
    input clk,
    input [31:0] data,
    input [1:0] jump,
    output reg [31:0] pc,
    output reg [31:0] inst
);
    parameter [1:0] JUMP_NOP = 0, JUMP_JALR = 1, JUMP_JAL =2;
    initial begin
        pc = 32'h80000000;
    end

    reg [31:0] dnpc;
    always@(*)begin
        case(jump)
            JUMP_NOP: dnpc = pc+4;
            JUMP_JALR: dnpc = {data[31:1], 1'b0};
            JUMP_JAL: dnpc = data;
        default: dnpc = pc+4;
        endcase
    end

    always @(posedge clk)begin                                        
        if(rst) pc<=32'h80000000;
        else begin
            pc<=dnpc;
        end
    end
    always @(*) begin                                        
        inst = pmem_read(pc);
    end                                          
endmodule




