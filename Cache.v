module cache (clk, rd_en, wr_en, index, way, tag_in, data_in, dirty_in, valid_out, dirty_out, tag_out, data_out);
    parameter WAY_NUM = 4;
    parameter SETS_NUMBER = 64;
    parameter cache_memory_ADDR_SIZE = 16;
    parameter DATA_WIDTH = 32;

    localparam INDEX = $clog2(SETS_NUMBER);
    localparam TAG = cache_memory_ADDR_SIZE - INDEX ; 
    localparam LINE_WIDTH = 1 + 1 + TAG + DATA_WIDTH;

    input clk,rd_en,wr_en,dirty_in;
    input [$clog2(SETS_NUMBER)-1:0] index;
    input [$clog2(WAY_NUM)-1:0] way;
    input [TAG-1:0] tag_in;
    input [DATA_WIDTH-1:0] data_in;

    output reg valid_out,dirty_out;
    output reg [TAG-1:0] tag_out;
    output reg [DATA_WIDTH-1:0] data_out;

    reg [LINE_WIDTH-1:0] cache_memory [0:SETS_NUMBER*WAY_NUM-1];

    wire [$clog2(SETS_NUMBER*WAY_NUM)-1:0] addr = index + way * SETS_NUMBER;

    always @(posedge clk) begin
        if (wr_en) begin
            cache_memory[addr] <= {1'b1, dirty_in, tag_in, data_in};
        end
        else if (rd_en) begin
            {valid_out, dirty_out, tag_out, data_out} <= cache_memory[addr];
        end
    end
endmodule
