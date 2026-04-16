module CacheController (clk, rst_n, rd_en, wr_en, addr, data_wr, data_rd, ready,cache_rd, cache_wr, cache_set, cache_way, cache_tag, cache_wdata, cache_dirty_in,
    cache_valid, cache_dirty, cache_tag_out, cache_rdata,ram_rd, ram_wr, ram_addr, ram_wdata, ram_rdata);
    parameter WAY_NUM    = 4;
    parameter ADDR_SIZE  = 16;
    parameter DATA_WIDTH = 32;
    parameter SETS_NUMBER = 64;

    input clk,rst_n,rd_en,wr_en;

    input [ADDR_SIZE-1:0] addr;
    input [DATA_WIDTH-1:0] data_wr;
    output reg [DATA_WIDTH-1:0] data_rd;
    output reg ready;

    output reg cache_rd,cache_wr;
    output reg [$clog2(SETS_NUMBER)-1:0] cache_set;
    output reg [$clog2(WAY_NUM)-1:0] cache_way;
    output reg [ADDR_SIZE-$clog2(SETS_NUMBER)-1:0] cache_tag;
    output reg [DATA_WIDTH-1:0] cache_wdata;
    output reg cache_dirty_in;
    input cache_valid,cache_dirty;
    input [ADDR_SIZE-$clog2(SETS_NUMBER)-1:0] cache_tag_out;
    input [DATA_WIDTH-1:0] cache_rdata;

    output reg ram_rd,ram_wr;
    output reg [ADDR_SIZE-1:0] ram_addr;
    output reg [DATA_WIDTH-1:0] ram_wdata;
    input [DATA_WIDTH-1:0] ram_rdata;
  

    // DECODE ADDRESS
    localparam INDEX = $clog2(SETS_NUMBER);
    localparam TAG = ADDR_SIZE - INDEX;
    wire [INDEX-1:0] index = addr[INDEX-1:0];
    wire [TAG-1:0] tag   = addr[ADDR_SIZE-1:INDEX];

    //STATES
    localparam IDLE           = 4'b0000;
    localparam CACHE_CHK_RD   = 4'b0001;  
    localparam CACHE_CHK      = 4'b0010;  
    localparam HIT_READ       = 4'b0011;  
    localparam HIT_WRITE      = 4'b0100;  
    localparam CHOSEN_RD      = 4'b0101;  
    localparam CHOSEN_READY   = 4'b0110;  
    localparam WRITE_BACK     = 4'b0111;  
    localparam RAM_READ       = 4'b1000;  
    localparam RAM_READY      = 4'b1001;  
    localparam UPDATE_CACHE   = 4'b1010; 
    reg [3:0] cs, ns;

    reg [INDEX-1:0]  req_index;
    reg [TAG-1:0]    req_tag;
    reg req_rd, req_wr;
    reg [DATA_WIDTH-1:0] req_wdata;
    reg [$clog2(WAY_NUM)-1:0] way_counter;
    reg [$clog2(WAY_NUM)-1:0] rd_way;
    reg [$clog2(WAY_NUM)-1:0] hit_way;
    reg [DATA_WIDTH-1:0] hit_data;
    wire hit_now = (cache_valid === 1'b1) && (cache_tag_out == req_tag);
    reg [$clog2(WAY_NUM)-1:0] lru [0:SETS_NUMBER-1][0:WAY_NUM-1];
    reg [$clog2(WAY_NUM)-1:0] chosen;

    always @(posedge clk) begin
        if (!rst_n) cs <= IDLE;
        else cs <= ns;
    end

    always @(posedge clk) begin
    if (!rst_n) begin
        req_index <= 0; req_tag <= 0; req_rd <= 0; req_wr <= 0; req_wdata <= 0;
    end else if (cs == IDLE && (rd_en || wr_en)) begin
        req_index <= index; req_tag <= tag; req_rd <= rd_en; req_wr <= wr_en; req_wdata <= data_wr;
        end
    end

    reg chosen_valid_r;
    reg chosen_dirty_r;
    reg [TAG-1:0]  chosen_tag_r;
    reg [DATA_WIDTH-1:0] chosen_data_r;

    reg [DATA_WIDTH-1:0] BUFFER; // for write back

    integer i, j;
    always @(posedge clk) begin // LRU Update
        if (!rst_n) begin
            for (i = 0; i < SETS_NUMBER; i = i + 1)
                for (j = 0; j < WAY_NUM; j = j + 1)
                    lru[i][j] <= j;
        end else begin
            if (cs == HIT_READ || cs == HIT_WRITE) begin
                for (j = 0; j < WAY_NUM; j = j + 1) begin
                    if (j == hit_way) lru[req_index][j] <= WAY_NUM-1;
                    else if (lru[req_index][j] > lru[req_index][hit_way]) lru[req_index][j] <= lru[req_index][j] - 1;
                end
            end else if (cs == UPDATE_CACHE) begin
                for (j = 0; j < WAY_NUM; j = j + 1) begin
                    if (j == chosen) lru[req_index][j] <= WAY_NUM-1;
                    else if (lru[req_index][j] > lru[req_index][chosen]) lru[req_index][j] <= lru[req_index][j] - 1;
                end
            end
        end
    end

    always @(*) begin // Find chosen Way using LRU
        chosen = 0;
        for (i = 1; i < WAY_NUM; i = i + 1)
            if (lru[req_index][i] < lru[req_index][chosen])
                chosen = i;
    end

    always @(posedge clk) begin // Way counter
        if (!rst_n) begin
            way_counter <= 0;
            rd_way  <= 0;
        end else begin
            if (cs == IDLE) begin
                way_counter <= 0;
                rd_way  <= 0;
            end else if (cs == CACHE_CHK_RD) begin
                rd_way <= way_counter;
            end else if (cs == CACHE_CHK) begin
                if (!hit_now && way_counter != WAY_NUM-1)
                    way_counter <= way_counter + 1;
            end
        end
    end

    always @(posedge clk ) begin // Hit Check
        if (!rst_n) begin
            hit_way  <= 0;
            hit_data <= 0;
        end else if (cs == CACHE_CHK && hit_now) begin
            hit_way  <= rd_way;
            hit_data <= cache_rdata;
        end
    end

    always @(posedge clk) begin // Get Choosen Data We Want To Replace
        if (!rst_n) begin
            chosen_valid_r <= 0; chosen_dirty_r <= 0; chosen_tag_r <= 0; chosen_data_r <= 0;
        end else if (cs == CHOSEN_READY) begin
            chosen_valid_r <= cache_valid; chosen_dirty_r <= cache_dirty; chosen_tag_r <= cache_tag_out; chosen_data_r <= cache_rdata;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) BUFFER <= 0;
        else if (cs == RAM_READY) BUFFER <= ram_rdata;
    end
    // Next State
    always @(*) begin
        ns = cs;
        case (cs)
            IDLE:
                if (rd_en || wr_en) ns = CACHE_CHK_RD;
            CACHE_CHK_RD:
                ns = CACHE_CHK;
            CACHE_CHK: begin
                if (hit_now) begin
                    if (req_wr) ns = HIT_WRITE;
                    else  ns = HIT_READ;
                end else begin
                    if (way_counter == WAY_NUM-1) ns = CHOSEN_RD;
                    else  ns = CACHE_CHK_RD;
                end
            end

            HIT_READ:  ns = IDLE;
            HIT_WRITE: ns = IDLE;
            CHOSEN_RD:  ns = CHOSEN_READY;
            CHOSEN_READY: begin
                if ((cache_valid === 1'b1) && (cache_dirty === 1'b1))
                    ns = WRITE_BACK;
                else begin
                    if (req_rd) ns = RAM_READ;
                    else        ns = UPDATE_CACHE;
                end
            end
            WRITE_BACK: begin
                if (req_rd) ns = RAM_READ;
                else        ns = UPDATE_CACHE;
            end
            RAM_READ:  ns = RAM_READY;
            RAM_READY: ns = UPDATE_CACHE;
            UPDATE_CACHE: ns = IDLE;
            default: ns = IDLE;
        endcase
    end

    always @(*) begin
        // defaults
        cache_rd       = 0;
        cache_wr       = 0;
        cache_set      = req_index;
        cache_way      = way_counter;
        cache_tag      = req_tag;
        cache_wdata    = req_wdata;
        cache_dirty_in = 0;
        ram_rd    = 0;
        ram_wr    = 0;
        ram_addr  = addr; 
        ram_wdata = 0;
        ready = 0;

        case (cs)
            IDLE: ready = 1;
            CACHE_CHK_RD: begin
                cache_rd  = 1;
                cache_way = way_counter;
            end
            HIT_READ: ready = 1;
            HIT_WRITE: begin
                cache_wr       = 1;
                cache_way      = hit_way;
                cache_tag      = req_tag;
                cache_wdata    = req_wdata;
                cache_dirty_in = 1'b1;
                ready      = 1;
            end
            CHOSEN_RD: begin
                cache_rd  = 1;
                cache_way = chosen;
            end
            WRITE_BACK: begin
                ram_wr    = 1;
                ram_addr  = {chosen_tag_r, req_index};
                ram_wdata = chosen_data_r;
            end
            RAM_READ: begin
                ram_rd   = 1;
                ram_addr = {req_tag, req_index};
            end
            UPDATE_CACHE: begin
                cache_wr  = 1;
                cache_way = chosen;
                cache_tag = req_tag;
                if (req_wr) begin
                    cache_wdata    = req_wdata;
                    cache_dirty_in = 1'b1;
                end else begin
                    cache_wdata    = BUFFER;
                    cache_dirty_in = 1'b0;
                end
            end
        endcase
    end

    always @(posedge clk) begin // Output Data Logic
        if (!rst_n) data_rd <= 0;
        else begin
            if (cs == HIT_READ) data_rd <= hit_data;
            else if (cs == UPDATE_CACHE && req_rd) data_rd <= BUFFER;
            else if (cs == UPDATE_CACHE && req_wr) data_rd <= req_wdata;
        end
    end
endmodule
