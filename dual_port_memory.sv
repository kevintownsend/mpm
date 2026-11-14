module dual_port_memory #(
  parameter WIDTH = 8,
  parameter DEPTH = 256)(
  input clk,
  input [$clog2(DEPTH)-1:0]addr_a,
  input en_a,
  input [WIDTH-1:0]d_a,
  output logic [WIDTH-1:0]q_a,
  input [$clog2(DEPTH)-1:0]addr_b,
  input en_b,
  input [WIDTH-1:0]d_b,
  output logic [WIDTH-1:0]q_b
);

  reg [WIDTH-1:0]ram[DEPTH-1:0];

  initial begin
    for (int i = 0; i < DEPTH; i++) begin
      ram[i] = '0;
    end
  end

  always @(posedge clk) begin
    if(en_a) begin
      ram[addr_a] <= d_a;
    end
    q_a <= ram[addr_a];
  end
  always @(posedge clk) begin
    if(en_b) begin
      ram[addr_b] <= d_b;
    end
    q_b <= ram[addr_b];
  end

endmodule // dual_port_memory
