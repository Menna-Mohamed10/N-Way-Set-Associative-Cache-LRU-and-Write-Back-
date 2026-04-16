module CacheWrapper (clk, rst_n, rd_en, wr_en, addr, data_wr, data_rd, ready);
    parameter ADDR_SIZE = 16;
    parameter DATA_WIDTH = 32;
    parameter SETS_NUMBER = 64;
    parameter WAY_NUM   = 4;

    input clk,rst_n,rd_en,wr_en;
    input [ADDR_SIZE-1:0] addr;
    input [DATA_WIDTH-1:0] data_wr;
    output[DATA_WIDTH-1:0] data_rd;
    output ready;

    // cache_signals
    wire cache_rd,cache_wr,cache_dirty_in,cache_valid,cache_dirty;                        
    wire [$clog2(SETS_NUMBER)-1:0] cache_set;
    wire [$clog2(WAY_NUM)-1:0] cache_way;
    wire [ADDR_SIZE-$clog2(SETS_NUMBER)-1:0] cache_tag;
    wire [DATA_WIDTH-1:0] cache_wrdata;
    wire [ADDR_SIZE-$clog2(SETS_NUMBER)-1:0] cache_tag_out;
    wire [DATA_WIDTH-1:0]             cache_rdata;

    // RAM_signals
    wire ram_rd,ram_wr;
    wire [ADDR_SIZE-1:0]  ram_addr;
    wire [DATA_WIDTH-1:0] ram_wdata;
    wire [DATA_WIDTH-1:0] ram_rdata;

    CacheController controller_dut (clk, rst_n, rd_en, wr_en, addr, data_wr, data_rd, ready,cache_rd, cache_wr, cache_set, 
    cache_way, cache_tag, cache_wrdata, cache_dirty_in,cache_valid, cache_dirty, cache_tag_out, cache_rdata,
    ram_rd, ram_wr, ram_addr, ram_wdata, ram_rdata);

    cache cache_dut (clk, cache_rd, cache_wr, cache_set, cache_way, cache_tag, cache_wrdata, cache_dirty_in,
    cache_valid, cache_dirty, cache_tag_out, cache_rdata);

    RAM ram_dut (clk, ram_rd, ram_wr, ram_addr, ram_wdata, ram_rdata);

endmodule
