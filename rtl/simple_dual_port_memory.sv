module simple_dual_port_memory #(
  parameter WIDTH = 8,
  parameter DEPTH = 256
) (
  input  logic                     clk,
  input  logic [$clog2(DEPTH)-1:0] addr_d,
  input  logic [WIDTH-1:0]         d,
  input  logic                     en,
  input  logic [$clog2(DEPTH)-1:0] addr_q,
  output logic [WIDTH-1:0]         q
);

  logic [WIDTH-1:0] ram[DEPTH-1:0];

  initial begin
    for (int i = 0; i < DEPTH; i++) begin
      ram[i] = '0;
    end
  end

  always_ff @(posedge clk) begin
    if (en) begin
      ram[addr_d] <= d;
    end
  end

  always_ff @(posedge clk) begin
    q <= ram[addr_q];
  end

endmodule  // simple_dual_port_memory
