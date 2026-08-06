module load_store(
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

    output reg valid,   //读写请求
    output reg wen          //写请求
);
    parameter [4:0] LS_LW = 3, LS_LBU = 4;;
    assign raddr_to_mem = raddr;
    assign waddr_to_mem = waddr;



    //其中读操作总是返回按4字节对齐读出的数据, 需要由RTL代码根据读地址选择出需要的部分
    //wmask`中每比特表示`wdata`中1个字节的掩码传递给pmem_write(),如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
    always @(*)begin                                        
        rdata_to_gpr = rdata_from_mem;
        wdata_to_mem = wdata_from_gpr;
        valid = 0;
        wen = 0;
        wmask = 0;

        case(ls_type)
            LS_LW:begin
                rdata_to_gpr = rdata_from_mem;
                valid = 1;
            end
            LS_LBU:begin
                rdata_to_gpr = {24'b0,rdata_from_mem[7:0]};
                valid = 1;
            end

            default:begin
                wmask = 0;
            end
        endcase

    end                                          

endmodule
