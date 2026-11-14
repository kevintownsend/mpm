module simple_dual_port_memory_wrapper #(
  parameter WIDTH = 8,
  parameter DEPTH = 256)(
  input clk,
  input [$clog2(DEPTH)-1:0]addr_d,
  input [WIDTH-1:0]d,
  input en,
  input [$clog2(DEPTH)-1:0]addr_q,
  output logic [WIDTH-1:0]q);

  logic [WIDTH-1:0] sdp_q;
  simple_dual_port_memory #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  )sdp(
    clk,
    addr_d,
    d,
    en,
    addr_q,
    sdp_q
  );

  logic addr_eq;
  logic [WIDTH-1:0]d_buffered;
  always @(posedge clk) begin
    addr_eq <= en && (addr_d == addr_q);
    d_buffered <= d;
  end

  always_comb begin
    if(addr_eq) begin
      q = d_buffered;
    end else begin
      q = sdp_q;
    end
  end

endmodule // simple_dual_port_memory_wrapper
