module load_store(
    input [4:0] ls_type,

    input [31:0] addr,
    output [31:0] addr_to_mem,

    input [31:0] l_data_from_mem,
    output reg [31:0] l_data_to_gpr,

    input [31:0] s_data_from_gpr,
    output reg [31:0] s_data_to_mem,


    output reg l_en,
    output reg s_en,

    output reg [2:0] len
);
    parameter [4:0] LS_LW = 3;
    assign addr_to_mem = addr;

    always @(*)begin                                        
        l_en = 0;
        s_en = 0;
        len = 0;
        l_data_to_gpr = l_data_from_mem;
        s_data_to_mem = s_data_from_gpr;

        case(ls_type)
            LS_LW:begin
                l_en = 1;
                s_en = 0;
                len = 3'd4;
                l_data_to_gpr = l_data_from_mem;
                s_data_to_mem = s_data_from_gpr;
            end

            default:begin
                l_en = 0;
                s_en = 0;
                l_data_to_gpr = l_data_from_mem;
                s_data_to_mem = s_data_from_gpr;
            end
        endcase

    end                                          

endmodule
