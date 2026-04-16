module CacheController_Testbench;

  localparam WAY_NUM   = 4;
  localparam ADDR_WIDTH = 16;
  localparam DATA_WIDTH = 32;
  localparam SETS_NUMBER = 64;
  localparam INDEX  = $clog2(SETS_NUMBER);
  localparam TAG  = ADDR_WIDTH - INDEX;
  localparam LINE_WIDTH = 2 + TAG + DATA_WIDTH; 

  reg clk, rst_n, rd_en, wr_en;
  reg  [ADDR_WIDTH-1:0] addr;
  reg  [DATA_WIDTH-1:0] data_wr;
  wire [DATA_WIDTH-1:0] data_rd;
  wire ready;

  CacheSystemWrapper dut (clk, rst_n, rd_en, wr_en, addr, data_wr, data_rd, ready);

  initial begin
    clk = 0;
    forever #1 clk = ~clk; 
  end
  
  integer i;
  initial begin
      for (i = 0; i < 65536; i = i + 1)
          dut.ram_dut.mem[i] = i; 
  end

  integer correct_count, error_count;
  reg [DATA_WIDTH-1:0] out;
  integer timeout;

  task OP_SETUP;
    input op_type;  // 0: READ, 1: WRITE
    input [ADDR_WIDTH-1:0] address;
    input [DATA_WIDTH-1:0] write_data;
    output [DATA_WIDTH-1:0] read_data;
    begin
      timeout = 0;
      while (!ready && timeout < 2000) begin @(posedge clk); timeout = timeout + 1; end // wait for cachecontroller ready 
      @(posedge clk);
      if (op_type) begin
        wr_en <= 1; rd_en <= 0; addr <= address; data_wr <= write_data;
      end else begin
        rd_en <= 1; wr_en <= 0; addr <= address; data_wr <= 'x;
      end
      @(posedge clk);
      rd_en <= 0; wr_en <= 0;
      timeout = 0;
      while (ready && timeout < 500) begin @(posedge clk); timeout = timeout + 1; end
      timeout = 0;
      while (!ready && timeout < 2000) begin @(posedge clk); timeout = timeout + 1; end
      repeat(2) @(posedge clk);
      read_data = data_rd;
    end
  endtask

  task compare;
    input [DATA_WIDTH-1:0] actual;
    input [DATA_WIDTH-1:0] expected;
    begin
      if (actual === expected) begin
        correct_count = correct_count + 1;
        $display("PASSED");
        $display("Expected: 0x%08h | Got: 0x%08h", expected, actual);
      end else begin
        error_count = error_count + 1;
        $display("FAILED");
        $display("Expected: 0x%08h | Got: 0x%08h", expected, actual);
      end
      $display("---------------------------------------------------");
    end
  endtask

  initial begin
    correct_count = 0; error_count = 0;
    rd_en = 0; wr_en = 0; addr = 0; data_wr = 0; rst_n = 0;
    repeat(3) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);
    // Test 1: MISS READ
    OP_SETUP(0, 16'h0002, 32'h0, out);
    compare(out, 32'h00000002);

    // Test 2: Cache HIT READ
    OP_SETUP(0, 16'h0002, 32'h0, out);
    compare(out, 32'h00000002);

    // Test 3: FILL LINE IN ALL WAYS
    OP_SETUP(1, 16'h0028, 32'hAAAA1234, out);
    OP_SETUP(1, 16'h0068, 32'hBBBB1234, out);
    OP_SETUP(1, 16'h00A8, 32'hCCCC1234, out);
    OP_SETUP(1, 16'h00E8, 32'hDDDD1234, out);

    // Test 4: READ ALL OF THEM
    OP_SETUP(0, 16'h0028, 32'h0, out);
    compare(out, 32'hAAAA1234);

    OP_SETUP(0, 16'h0068, 32'h0, out);
    compare(out, 32'hBBBB1234);
    
    OP_SETUP(0, 16'h00A8, 32'h0, out);
    compare(out, 32'hCCCC1234);
    
    OP_SETUP(0, 16'h00E8, 32'h0, out);
    compare(out, 32'hDDDD1234);

    // Test 5: Force eviction
    OP_SETUP(0, 16'h0128, 32'h0, out);
    compare(out, 32'h00000128);

    // Test 6: Modify and verify dirty line
    OP_SETUP(1, 16'h0068, 32'hAAAA9999, out);
    OP_SETUP(0, 16'h0068, 32'h0, out);
    compare(out, 32'hAAAA9999);

    // Test 7: UPDATE LRU 
    OP_SETUP(0, 16'h0028, 32'h0, out);
    OP_SETUP(0, 16'h00A8, 32'h0, out);
    OP_SETUP(0, 16'h00E8, 32'h0, out);

    // Test 8: WRITEBACK TRIGGER
    OP_SETUP(1, 16'h0168, 32'hC0FFEE77, out);

    // Test 9: VERIFY WRITEBACK IN RAM
    repeat(8) @(posedge clk);
    out = dut.ram_dut.mem[16'h0068];
    compare(out, 32'hAAAA9999);

    // Test 10: VERIFY UPDATED DATA
    OP_SETUP(0, 16'h0168, 32'h0, out);
    compare(out, 32'hC0FFEE77);

    $display("Tests Passed: %0d", correct_count);
    $display("Tests Failed: %0d", error_count);
    $finish;
  end
endmodule