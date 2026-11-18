module xor_distributed_memory_tb;
  parameter WIDTH = 8;
  parameter DEPTH = 256;
  parameter PORTS = 4;

  logic clk;
  logic [$clog2(DEPTH)-1:0] addr[PORTS-1:0];
  logic [WIDTH-1:0] d[PORTS-1:0];
  logic en[PORTS-1:0];
  logic [WIDTH-1:0] q[PORTS-1:0];

  logic [WIDTH-1:0] golden[DEPTH-1:0];

  xor_distributed_memory #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH),
    .PORTS(PORTS)
  ) dut (
    .clk(clk),
    .addr(addr),
    .d(d),
    .en(en),
    .q(q)
  );

  initial begin
    clk = 1;
    forever #5 clk = ~clk;
  end

`ifdef TRACE
  initial begin
    $dumpfile("build/xor_distributed_memory_tb.fst");
    $dumpvars(0, xor_distributed_memory_tb);
  end
`endif

  task automatic clear_inputs();
    for (int i = 0; i < PORTS; i++) begin
      addr[i] = '0;
      d[i] = '0;
      en[i] = 1'b0;
    end
  endtask

  initial begin
    for (int a = 0; a < DEPTH; a++) begin
      golden[a] = '0;
    end
    clear_inputs();
    @(negedge clk);

    // 1. Single-port write and cross-port combinational read.
    addr[0] = 8'd5; d[0] = 8'd42; en[0] = 1'b1; golden[5] = 8'd42;
    @(negedge clk);
    clear_inputs();
    addr[1] = 8'd5;
    #1;
    if (q[1] != 8'd42) $fatal(1, "FAILED: cross-port read expected 42, got %0d", q[1]);

    // 2. Self-read by port 0 while other ports read different addresses.
    addr[0] = 8'd5; addr[1] = 8'd10; addr[2] = 8'd11; addr[3] = 8'd12;
    #1;
    if (q[0] != 8'd42) $fatal(1, "FAILED: self-read expected 42, got %0d", q[0]);

    // 3. Concurrent multi-port writes to distinct addresses.
    clear_inputs();
    addr[0] = 8'd10; d[0] = 8'hA1; en[0] = 1'b1; golden[10] = 8'hA1;
    addr[1] = 8'd20; d[1] = 8'hB2; en[1] = 1'b1; golden[20] = 8'hB2;
    addr[2] = 8'd30; d[2] = 8'hC3; en[2] = 1'b1; golden[30] = 8'hC3;
    addr[3] = 8'd40; d[3] = 8'hD4; en[3] = 1'b1; golden[40] = 8'hD4;
    @(negedge clk);

    // 4. Overwrite by different ports.
    clear_inputs();
    addr[1] = 8'd10; d[1] = 8'h1A; en[1] = 1'b1; golden[10] = 8'h1A;
    addr[2] = 8'd20; d[2] = 8'h2B; en[2] = 1'b1; golden[20] = 8'h2B;
    addr[3] = 8'd30; d[3] = 8'h3C; en[3] = 1'b1; golden[30] = 8'h3C;
    addr[0] = 8'd40; d[0] = 8'h4D; en[0] = 1'b1; golden[40] = 8'h4D;
    @(negedge clk);

    // 5. Back-to-back reads changing addresses every cycle.
    clear_inputs();
    addr[0] = 8'd10; addr[1] = 8'd20; addr[2] = 8'd30; addr[3] = 8'd40;
    #1;
    if (q[0] != golden[10] || q[1] != golden[20] || q[2] != golden[30] || q[3] != golden[40])
      $fatal(1, "FAILED: cycle 1 read mismatch");
    @(negedge clk);

    addr[0] = 8'd5; addr[1] = 8'd10; addr[2] = 8'd20; addr[3] = 8'd30;
    #1;
    if (q[0] != golden[5] || q[1] != golden[10] || q[2] != golden[20] || q[3] != golden[30])
      $fatal(1, "FAILED: cycle 2 back-to-back read mismatch");
    @(negedge clk);

    addr[0] = 8'd40; addr[1] = 8'd5; addr[2] = 8'd10; addr[3] = 8'd20;
    #1;
    if (q[0] != golden[40] || q[1] != golden[5] || q[2] != golden[10] || q[3] != golden[20])
      $fatal(1, "FAILED: cycle 3 back-to-back read mismatch");

    $display("Passed");
    $finish();
  end

endmodule // xor_distributed_memory_tb
