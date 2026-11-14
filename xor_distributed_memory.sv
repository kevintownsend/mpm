module xor_distributed_memory #(
  parameter WIDTH = 32,
  parameter DEPTH = 1024,
  parameter PORTS = 8
) (
  input  logic                     clk,
  input  logic [$clog2(DEPTH)-1:0] addr[PORTS-1:0],
  input  logic [WIDTH-1:0]         d[PORTS-1:0],
  input  logic                     en[PORTS-1:0],
  output logic [WIDTH-1:0]         q[PORTS-1:0]
);

  initial begin
    if (PORTS < 2) begin
      $fatal(1, "PORTS (%0d) must be at least 2", PORTS);
    end
  end

  logic [WIDTH-1:0] ram_output[PORTS-1:0][PORTS-1:0];
  logic [WIDTH-1:0] partial_xor_input[PORTS-1:0];

  always_comb begin
    for (int i = 0; i < PORTS; i = i + 1) begin
      partial_xor_input[i] = '0;
      for (int j = 0; j < PORTS; j = j + 1) begin
        if (i != j) begin
          partial_xor_input[i] = partial_xor_input[i] ^ ram_output[j][i];
        end
      end
      q[i] = partial_xor_input[i] ^ ram_output[i][i];
    end
  end

  genvar gi, gj;
  generate
    for (gi = 0; gi < PORTS; gi = gi + 1) begin : y_genblock
      for (gj = 0; gj < PORTS; gj = gj + 1) begin : x_genblock
        simple_distributed_ram #(
          .WIDTH(WIDTH),
          .DEPTH(DEPTH)
        ) gen_ram (
          .clk(clk),
          .addr_d(addr[gi]),
          .d(d[gi] ^ partial_xor_input[gi]),
          .en(en[gi]),
          .addr_q(addr[gj]),
          .q(ram_output[gi][gj])
        );
      end
    end
  endgenerate

endmodule // xor_distributed_memory
