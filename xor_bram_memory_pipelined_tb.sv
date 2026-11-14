module xor_bram_memory_pipelined_tb;
  parameter WIDTH = 32;
  parameter DEPTH = 512;
  parameter PORTS = 4;

  logic clk;
  logic [$clog2(DEPTH)-1:0] addr[PORTS-1:0];
  logic [WIDTH-1:0] d[PORTS-1:0];
  logic en[PORTS-1:0];
  logic [WIDTH-1:0] q[PORTS-1:0];

  logic [WIDTH-1:0] golden[DEPTH-1:0];

  xor_bram_memory_pipelined #(WIDTH, DEPTH, PORTS) dut(clk, addr, d, en, q);

  initial begin
    clk = 1;
    forever #5 clk = ~clk;
  end

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

    // 1. Single-port write and cross-port read (2-cycle read latency, forwarded at write cycle).
    addr[0] = 9'd5; d[0] = 32'd42; en[0] = 1'b1; golden[5] = 32'd42;
    @(negedge clk);
    clear_inputs();
    addr[1] = 9'd5;
    @(negedge clk);
    clear_inputs();
    addr[0] = 9'd5; addr[2] = 9'd11; addr[3] = 9'd12;
    @(negedge clk);
    if (q[1] != 32'd42) $fatal(1, "FAILED: cross-port read expected 42, got %0d", q[1]);
    @(negedge clk);
    if (q[0] != 32'd42) $fatal(1, "FAILED: self-read expected 42, got %0d", q[0]);

    // 2. Concurrent multi-port writes to distinct addresses.
    clear_inputs();
    addr[0] = 9'd10; d[0] = 32'hDEAD_0001; en[0] = 1'b1; golden[10] = 32'hDEAD_0001;
    addr[1] = 9'd20; d[1] = 32'hDEAD_0002; en[1] = 1'b1; golden[20] = 32'hDEAD_0002;
    addr[2] = 9'd30; d[2] = 32'hDEAD_0003; en[2] = 1'b1; golden[30] = 32'hDEAD_0003;
    addr[3] = 9'd40; d[3] = 32'hDEAD_0004; en[3] = 1'b1; golden[40] = 32'hDEAD_0004;
    @(negedge clk);

    // 3. Overwrite by different ports on the next cycle.
    clear_inputs();
    addr[1] = 9'd10; d[1] = 32'hCAFE_0010; en[1] = 1'b1; golden[10] = 32'hCAFE_0010;
    addr[2] = 9'd20; d[2] = 32'hCAFE_0020; en[2] = 1'b1; golden[20] = 32'hCAFE_0020;
    addr[3] = 9'd30; d[3] = 32'hCAFE_0030; en[3] = 1'b1; golden[30] = 32'hCAFE_0030;
    addr[0] = 9'd40; d[0] = 32'hCAFE_0040; en[0] = 1'b1; golden[40] = 32'hCAFE_0040;
    @(negedge clk);

    // 4. Back-to-back pipelined reads (2-cycle read latency).
    clear_inputs();
    addr[0] = 9'd10; addr[1] = 9'd20; addr[2] = 9'd30; addr[3] = 9'd40;
    @(negedge clk);
    addr[0] = 9'd5; addr[1] = 9'd10; addr[2] = 9'd20; addr[3] = 9'd30;
    @(negedge clk);
    if (q[0] != golden[10] || q[1] != golden[20] || q[2] != golden[30] || q[3] != golden[40])
      $fatal(1, "FAILED: cycle 1 back-to-back read mismatch");

    addr[0] = 9'd40; addr[1] = 9'd5; addr[2] = 9'd10; addr[3] = 9'd20;
    @(negedge clk);
    if (q[0] != golden[5] || q[1] != golden[10] || q[2] != golden[20] || q[3] != golden[30])
      $fatal(1, "FAILED: cycle 2 back-to-back read mismatch");

    addr[0] = 9'd0; addr[1] = 9'd0; addr[2] = 9'd0; addr[3] = 9'd0;
    @(negedge clk);
    if (q[0] != golden[40] || q[1] != golden[5] || q[2] != golden[10] || q[3] != golden[20])
      $fatal(1, "FAILED: cycle 3 back-to-back read mismatch");

    $display("Passed");
    $finish();
  end

endmodule // xor_bram_memory_pipelined_tb
