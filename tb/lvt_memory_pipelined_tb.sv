module lvt_memory_pipelined_tb;
  parameter WIDTH = 32;
  parameter DEPTH = 512;
  parameter PORTS = 4;

  logic clk;
  logic [$clog2(DEPTH)-1:0] addr[PORTS-1:0];
  logic en[PORTS-1:0];
  logic [WIDTH-1:0] d[PORTS-1:0];
  logic [WIDTH-1:0] q[PORTS-1:0];

  logic [WIDTH-1:0] golden[DEPTH-1:0];

  lvt_memory_pipelined #(
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
    $dumpfile("build/lvt_memory_pipelined_tb.fst");
    $dumpvars(0, lvt_memory_pipelined_tb);
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

    // 1. Single-port write (1-cycle LVT write delay) and cross-port read (2-cycle read latency).
    addr[0] = 9'd5; d[0] = 32'd42; en[0] = 1'b1; golden[5] = 32'd42;
    @(negedge clk);
    clear_inputs();
    @(negedge clk); // Wait 1 cycle for LVT write to commit.
    addr[1] = 9'd5;
    @(negedge clk);
    @(negedge clk);
    if (q[1] != 32'd42) $fatal(1, "FAILED: cross-port read expected 42, got %0d", q[1]);

    // 2. Concurrent multi-port writes to distinct addresses.
    clear_inputs();
    addr[0] = 9'd10; d[0] = 32'hDEAD_0001; en[0] = 1'b1; golden[10] = 32'hDEAD_0001;
    addr[1] = 9'd20; d[1] = 32'hDEAD_0002; en[1] = 1'b1; golden[20] = 32'hDEAD_0002;
    addr[2] = 9'd30; d[2] = 32'hDEAD_0003; en[2] = 1'b1; golden[30] = 32'hDEAD_0003;
    addr[3] = 9'd40; d[3] = 32'hDEAD_0004; en[3] = 1'b1; golden[40] = 32'hDEAD_0004;
    @(negedge clk);
    clear_inputs();
    @(negedge clk); // LVT write commits on this posedge.

    // 3. Self-read test across every port individually while other ports read distinct addresses.
    addr[0] = 9'd10; addr[1] = 9'd50; addr[2] = 9'd51; addr[3] = 9'd52;
    @(negedge clk);
    addr[0] = 9'd50; addr[1] = 9'd20; addr[2] = 9'd51; addr[3] = 9'd52;
    @(negedge clk);
    if (q[0] != golden[10]) $fatal(1, "FAILED: port 0 self-read expected %h, got %h", golden[10], q[0]);

    addr[0] = 9'd50; addr[1] = 9'd51; addr[2] = 9'd30; addr[3] = 9'd52;
    @(negedge clk);
    if (q[1] != golden[20]) $fatal(1, "FAILED: port 1 self-read expected %h, got %h", golden[20], q[1]);

    addr[0] = 9'd50; addr[1] = 9'd51; addr[2] = 9'd52; addr[3] = 9'd40;
    @(negedge clk);
    if (q[2] != golden[30]) $fatal(1, "FAILED: port 2 self-read expected %h, got %h", golden[30], q[2]);

    clear_inputs();
    @(negedge clk);
    if (q[3] != golden[40]) $fatal(1, "FAILED: port 3 self-read expected %h, got %h", golden[40], q[3]);

    // 4. Overwrite by different ports.
    addr[1] = 9'd10; d[1] = 32'hCAFE_0010; en[1] = 1'b1; golden[10] = 32'hCAFE_0010;
    addr[2] = 9'd20; d[2] = 32'hCAFE_0020; en[2] = 1'b1; golden[20] = 32'hCAFE_0020;
    addr[3] = 9'd30; d[3] = 32'hCAFE_0030; en[3] = 1'b1; golden[30] = 32'hCAFE_0030;
    addr[0] = 9'd40; d[0] = 32'hCAFE_0040; en[0] = 1'b1; golden[40] = 32'hCAFE_0040;
    @(negedge clk);
    clear_inputs();
    @(negedge clk); // LVT write commits on this posedge.

    // 5. Back-to-back pipelined reads changing addresses every cycle (2-cycle read latency).
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

endmodule // lvt_memory_pipelined_tb
