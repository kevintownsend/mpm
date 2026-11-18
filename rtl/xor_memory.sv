module xor_memory #(
  parameter WIDTH = 8,
  parameter DEPTH = 256,
  parameter PORTS = 2,
  parameter bit USE_XPM = 0
) (
  input  logic                     clk,
  input  logic [$clog2(DEPTH)-1:0] addr[PORTS-1:0],
  input  logic [WIDTH-1:0]         d[PORTS-1:0],
  input  logic                     en[PORTS-1:0],
  output logic [WIDTH-1:0]         q[PORTS-1:0]
);

  if (PORTS < 2) begin : gen_check_ports
    $error("PORTS (%0d) must be at least 2", PORTS);
  end
  if (DEPTH < 2) begin : gen_check_depth
    $error("DEPTH (%0d) must be at least 2", DEPTH);
  end
  if (WIDTH < 1) begin : gen_check_width
    $error("WIDTH (%0d) must be at least 1", WIDTH);
  end

  logic [WIDTH-1:0] ram_output[PORTS-1:0][PORTS-1:0];
  logic [WIDTH-1:0] partial_xor_input[PORTS-1:0];

  logic [$clog2(DEPTH)-1:0] addr_buffered[PORTS-1:0];
  logic [WIDTH-1:0]         d_buffered[PORTS-1:0];
  logic                     en_buffered[PORTS-1:0];

  always_ff @(posedge clk) begin
    addr_buffered <= addr;
    d_buffered <= d;
    en_buffered <= en;
  end

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
        if (USE_XPM) begin : gen_xpm_ram
          simple_dual_port_memory_xilinx #(
            .WIDTH(WIDTH),
            .DEPTH(DEPTH),
            .WRITE_FIRST(1)
          ) gen_ram (
            .clk(clk),
            .addr_d(addr_buffered[gi]),
            .d(d_buffered[gi] ^ partial_xor_input[gi]),
            .en(en_buffered[gi]),
            .addr_q(addr[gj]),
            .q(ram_output[gi][gj])
          );
        end else begin : gen_generic_ram
          simple_dual_port_memory_wrapper #(
            .WIDTH(WIDTH),
            .DEPTH(DEPTH)
          ) gen_ram (
            .clk(clk),
            .addr_d(addr_buffered[gi]),
            .d(d_buffered[gi] ^ partial_xor_input[gi]),
            .en(en_buffered[gi]),
            .addr_q(addr[gj]),
            .q(ram_output[gi][gj])
          );
        end
      end
    end
  endgenerate

endmodule // xor_memory
