module lvt_memory_pipelined #(
  parameter WIDTH = 32,
  parameter DEPTH = 1024,
  parameter PORTS = 32
) (
  input  logic                     clk,
  input  logic [$clog2(DEPTH)-1:0] addr[PORTS-1:0],
  input  logic [WIDTH-1:0]         d[PORTS-1:0],
  input  logic                     en[PORTS-1:0],
  output logic [WIDTH-1:0]         q[PORTS-1:0]
);

  logic [WIDTH-1:0] intermediate_output[PORTS-1:0][PORTS-1:0];
  logic [WIDTH-1:0] intermediate_output_buffered[PORTS-1:0][PORTS-1:0];

  genvar gi, gj;
  generate
    for (gi = 0; gi < PORTS; gi++) begin : y_genblock
      for (gj = 0; gj < PORTS; gj++) begin : x_genblock
        if (gj < gi) begin : gen_ram
          dual_port_memory #(
            .WIDTH(WIDTH),
            .DEPTH(DEPTH)
          ) dp_ram (
            .clk(clk),
            .addr_a(addr[gi]),
            .en_a(en[gi]),
            .d_a(d[gi]),
            .q_a(intermediate_output[gi][gj]),
            .addr_b(addr[gj]),
            .en_b(en[gj]),
            .d_b(d[gj]),
            .q_b(intermediate_output[gj][gi])
          );
        end else if (gj == gi) begin : gen_diag
          assign intermediate_output[gi][gi] = '0;
        end
      end
    end
  endgenerate

  logic [$clog2(PORTS)-1:0] port_numbers[PORTS-1:0];
  initial begin
    if (PORTS < 2) begin
      $fatal(1, "PORTS (%0d) must be at least 2", PORTS);
    end
    for (int j = 0; j < PORTS; j++) begin
      port_numbers[j] = j[$clog2(PORTS)-1:0];
    end
  end

  logic [$clog2(PORTS)-1:0] lvt_output[PORTS-1:0];

  xor_distributed_memory_pipelined #(
    .WIDTH($clog2(PORTS)),
    .DEPTH(DEPTH),
    .PORTS(PORTS)
  ) lvt (
    .clk(clk),
    .addr(addr),
    .d(port_numbers),
    .en(en),
    .q(lvt_output)
  );

  always_ff @(posedge clk) begin
    intermediate_output_buffered <= intermediate_output;
    intermediate_output_buffered[0][0] <= intermediate_output[0][1];
    for (int i = 1; i < PORTS; i++) begin
      intermediate_output_buffered[i][i] <= intermediate_output[i][i-1];
    end
  end

  always_comb begin
    for (int k = 0; k < PORTS; k++) begin
      q[k] = intermediate_output_buffered[k][lvt_output[k]];
    end
  end

endmodule // lvt_memory_pipelined
