module simple_dual_port_memory #(
  parameter WIDTH = 8,
  parameter DEPTH = 256)(
  input clk,
  input [$clog2(DEPTH)-1:0]addr_d,
  input [WIDTH-1:0]d,
  input en,
  input [$clog2(DEPTH)-1:0]addr_q,
  output logic [WIDTH-1:0]q);

  reg [WIDTH-1:0]ram[DEPTH-1:0];

  initial begin
    for (int i = 0; i < DEPTH; i++) begin
      ram[i] = '0;
    end
  end

  always @(posedge clk) begin
    if(en) begin
      ram[addr_d] <= d;
    end
  end
  always @(posedge clk) begin
    q <= ram[addr_q];
  end

endmodule // simple_dual_port_memory
