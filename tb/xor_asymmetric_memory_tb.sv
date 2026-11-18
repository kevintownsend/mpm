module xor_asymmetric_memory_tb;
  parameter WIDTH = 8;
  parameter DEPTH = 256;
  parameter FULL_PORTS = 2;
  parameter WRITE_PORTS = 2;
  parameter READ_PORTS = 2;

  logic clk;
  logic [$clog2(DEPTH)-1:0] full_addr[FULL_PORTS-1:0];
  logic [WIDTH-1:0]         full_d[FULL_PORTS-1:0];
  logic                     full_en[FULL_PORTS-1:0];
  logic [WIDTH-1:0]         full_q[FULL_PORTS-1:0];
  logic [$clog2(DEPTH)-1:0] write_addr[WRITE_PORTS-1:0];
  logic [WIDTH-1:0]         write_d[WRITE_PORTS-1:0];
  logic                     write_en[WRITE_PORTS-1:0];
  logic [$clog2(DEPTH)-1:0] read_addr[READ_PORTS-1:0];
  logic [WIDTH-1:0]         read_q[READ_PORTS-1:0];

  logic [WIDTH-1:0] golden[DEPTH-1:0];

  xor_asymmetric_memory #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH),
    .FULL_PORTS(FULL_PORTS),
    .WRITE_PORTS(WRITE_PORTS),
    .READ_PORTS(READ_PORTS)
  ) dut (
    .clk(clk),
    .full_addr(full_addr),
    .full_d(full_d),
    .full_en(full_en),
    .full_q(full_q),
    .write_addr(write_addr),
    .write_d(write_d),
    .write_en(write_en),
    .read_addr(read_addr),
    .read_q(read_q)
  );

  initial begin
    clk = 1;
    forever #5 clk = ~clk;
  end

`ifdef TRACE
  initial begin
    $dumpfile("build/xor_asymmetric_memory_tb.fst");
    $dumpvars(0, xor_asymmetric_memory_tb);
  end
`endif

  task automatic clear_inputs();
    for (int f = 0; f < FULL_PORTS; f++) begin
      full_addr[f] = '0;
      full_d[f]    = '0;
      full_en[f]   = 1'b0;
    end
    for (int w = 0; w < WRITE_PORTS; w++) begin
      write_addr[w] = '0;
      write_d[w]    = '0;
      write_en[w]   = 1'b0;
    end
    for (int r = 0; r < READ_PORTS; r++) begin
      read_addr[r] = '0;
    end
  endtask

  initial begin
    for (int a = 0; a < DEPTH; a++) begin
      golden[a] = '0;
    end
    clear_inputs();
    @(negedge clk);

    // 1. Single write via full port 0, read back via read-only port 0 and full port 1.
    full_addr[0] = 8'd5; full_d[0] = 8'd42; full_en[0] = 1'b1; golden[5] = 8'd42;
    @(negedge clk);
    clear_inputs();
    read_addr[0] = 8'd5;
    full_addr[1] = 8'd5;
    @(negedge clk);
    if (read_q[0] != 8'd42) $fatal(1, "FAILED: read_q[0] expected 42, got %0d", read_q[0]);
    if (full_q[1] != 8'd42) $fatal(1, "FAILED: full_q[1] expected 42, got %0d", full_q[1]);

    // 2. Single write via write-only port 0, self-read on full_q[0] and read_q[1].
    clear_inputs();
    write_addr[0] = 8'd6; write_d[0] = 8'd99; write_en[0] = 1'b1; golden[6] = 8'd99;
    @(negedge clk);
    clear_inputs();
    full_addr[0] = 8'd5;
    read_addr[1] = 8'd6;
    @(negedge clk);
    if (full_q[0] != 8'd42) $fatal(1, "FAILED: full_q[0] expected 42, got %0d", full_q[0]);
    if (read_q[1] != 8'd99) $fatal(1, "FAILED: read_q[1] expected 99, got %0d", read_q[1]);

    // 3. Concurrent writes across all 4 write-capable ports (2 full + 2 write-only).
    clear_inputs();
    full_addr[0]  = 8'd10; full_d[0]  = 8'hA1; full_en[0]  = 1'b1; golden[10] = 8'hA1;
    full_addr[1]  = 8'd20; full_d[1]  = 8'hB2; full_en[1]  = 1'b1; golden[20] = 8'hB2;
    write_addr[0] = 8'd30; write_d[0] = 8'hC3; write_en[0] = 1'b1; golden[30] = 8'hC3;
    write_addr[1] = 8'd40; write_d[1] = 8'hD4; write_en[1] = 1'b1; golden[40] = 8'hD4;
    @(negedge clk);

    // 4. Adjacent-cycle overwrites swapping writers between full and write-only ports.
    clear_inputs();
    write_addr[0] = 8'd10; write_d[0] = 8'h1A; write_en[0] = 1'b1; golden[10] = 8'h1A;
    write_addr[1] = 8'd20; write_d[1] = 8'h2B; write_en[1] = 1'b1; golden[20] = 8'h2B;
    full_addr[0]  = 8'd30; full_d[0]  = 8'h3C; full_en[0]  = 1'b1; golden[30] = 8'h3C;
    full_addr[1]  = 8'd40; full_d[1]  = 8'h4D; full_en[1]  = 1'b1; golden[40] = 8'h4D;
    @(negedge clk);

    // 5. Back-to-back pipelined reads across all 4 read-capable ports.
    clear_inputs();
    full_addr[0] = 8'd10; full_addr[1] = 8'd20;
    read_addr[0] = 8'd30; read_addr[1] = 8'd40;
    @(negedge clk);
    if (full_q[0] != golden[10] || full_q[1] != golden[20] ||
        read_q[0] != golden[30] || read_q[1] != golden[40])
      $fatal(1, "FAILED: cycle 1 read mismatch");

    full_addr[0] = 8'd40; full_addr[1] = 8'd30;
    read_addr[0] = 8'd20; read_addr[1] = 8'd10;
    @(negedge clk);
    if (full_q[0] != golden[40] || full_q[1] != golden[30] ||
        read_q[0] != golden[20] || read_q[1] != golden[10])
      $fatal(1, "FAILED: cycle 2 back-to-back read mismatch");

    full_addr[0] = 8'd5; full_addr[1] = 8'd6;
    read_addr[0] = 8'd5; read_addr[1] = 8'd6;
    @(negedge clk);
    if (full_q[0] != golden[5] || full_q[1] != golden[6] ||
        read_q[0] != golden[5] || read_q[1] != golden[6])
      $fatal(1, "FAILED: cycle 3 shared-address read mismatch");

    $display("Passed");
    $finish();
  end

endmodule // xor_asymmetric_memory_tb
