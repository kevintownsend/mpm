module xor_memory #(
  parameter WIDTH = 8,
  parameter DEPTH = 256,
  parameter PORTS = 2)(

  input clk,
  input [$clog2(DEPTH)-1:0]addr[PORTS-1:0],
  input [WIDTH-1:0]d[PORTS-1:0],
  input en[PORTS-1:0],
  output logic [WIDTH-1:0]q[PORTS-1:0]);

  logic [WIDTH-1:0]ram_output[PORTS-1:0][PORTS-1:0];

  logic [WIDTH-1:0]partial_xor_input[PORTS-1:0];

  logic [$clog2(DEPTH)-1:0]addr_buffered[PORTS-1:0];
  logic [WIDTH-1:0]d_buffered[PORTS-1:0];
  logic en_buffered[PORTS-1:0];

  always @(posedge clk) begin
    addr_buffered <= addr;
    d_buffered <= d;
    en_buffered <= en;
  end

  always_comb begin
    for (int i = 0; i < PORTS; i = i + 1) begin
      partial_xor_input[i] = 0;
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
    for(gi = 0; gi < PORTS; gi = gi + 1) begin : y_genblock
      for(gj = 0; gj < PORTS; gj = gj + 1) begin : x_genblock
        simple_ram #(WIDTH, DEPTH) gen_ram(clk, addr_buffered[gi], d_buffered[gi] ^ partial_xor_input[gi], en_buffered[gi], addr[gj], ram_output[gi][gj]);
      end
    end
  endgenerate

endmodule // xor_memory

/* verilator lint_off DECLFILENAME */
module simple_ram #(
  parameter WIDTH = 8,
  parameter DEPTH = 256)(
  input clk,
  input [$clog2(DEPTH)-1:0]addr_d,
  input [WIDTH-1:0]d,
  input en,
  input [$clog2(DEPTH)-1:0]addr_q,
  output reg [WIDTH-1:0]q);

  reg [WIDTH-1:0]ram[DEPTH-1:0];

  initial begin
    for (int i = 0; i < DEPTH; i = i + 1) begin
      ram[i] = '0;
    end
  end

  always @(posedge clk) begin
    if (en) begin
      ram[addr_d] <= d;
    end
    if (en && (addr_d == addr_q)) begin
      q <= d;
    end else begin
      q <= ram[addr_q];
    end
  end

endmodule // simple_ram
/* verilator lint_on DECLFILENAME */
