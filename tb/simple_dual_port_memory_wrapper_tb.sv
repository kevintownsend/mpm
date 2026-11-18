module simple_dual_port_memory_wrapper_tb;
  parameter WIDTH = 8;
  parameter DEPTH = 256;

  logic clk;
  logic [$clog2(DEPTH)-1:0]addr_d;
  logic [WIDTH-1:0]d;
  logic en;
  logic [$clog2(DEPTH)-1:0]addr_q;
  logic [WIDTH-1:0]q;

  simple_dual_port_memory_wrapper #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) sdp (
    .clk(clk),
    .addr_d(addr_d),
    .d(d),
    .en(en),
    .addr_q(addr_q),
    .q(q)
  );

  initial begin
    clk = 1;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    addr_d = 0;
    d = 0;
    en = 0;
    addr_q = 0;
    @(negedge clk);

    // Write 42 to address 3, then read it back.
    en = 1;
    addr_d = 3;
    d = 42;
    @(negedge clk);
    en = 0;
    addr_q = 3;
    @(negedge clk);
    if (q != 42) begin
      $fatal(1, "FAILED: expected 42, got %0d", q);
    end

    // Write-first forwarding when en == 1 and addr_d == addr_q.
    addr_q = 5;
    addr_d = 5;
    en = 1;
    d = 41;
    @(negedge clk);
    en = 0;
    if (q != 41) begin
      $fatal(1, "FAILED: expected write-forwarded 41, got %0d", q);
    end

    // Ensure forwarding does NOT happen when en == 0 and addr_d == addr_q.
    addr_q = 5;
    addr_d = 5;
    en = 0;
    d = 99;
    @(negedge clk);
    if (q != 41) begin
      $fatal(1, "FAILED: spurious forwarding with en=0, expected 41, got %0d", q);
    end

    // Back-to-back read switching back to address 3.
    addr_q = 3;
    addr_d = 3;
    d = 123;
    @(negedge clk);
    if (q != 42) begin
      $fatal(1, "FAILED: expected 42 at addr 3, got %0d", q);
    end

    $display("Passed");
    $finish();
  end

endmodule // simple_dual_port_memory_wrapper_tb
