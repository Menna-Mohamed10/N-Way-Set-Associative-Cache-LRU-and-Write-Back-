module RAM (clk, rd_en, wr_en, addr, data_wr, data_rd);
    parameter ADDR_SIZE = 16;
    parameter DATA_WIDTH  = 32;
    localparam MEM_DEPTH = 1 << ADDR_SIZE;

    input clk,rd_en,wr_en;
    input  wire [ADDR_SIZE-1:0] addr;
    input  wire [DATA_WIDTH-1:0] data_wr;
    output reg  [DATA_WIDTH-1:0] data_rd;
    
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    always @(posedge clk) begin
        if (wr_en) mem[addr] <= data_wr;

        else if (rd_en)data_rd <= mem[addr];
    end

endmodule
