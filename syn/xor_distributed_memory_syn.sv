module xor_distributed_memory_syn #(
  parameter WIDTH = 32,
  parameter DEPTH = 1024,
  parameter PORTS = 2
) (
  input  logic clk,
  input  logic d,
  input  logic push,
  output logic q
);

  logic [$clog2(DEPTH)-1:0] addr[PORTS-1:0];
  logic                     en[PORTS-1:0];
  logic [WIDTH-1:0]         xor_d[PORTS-1:0];
  logic [WIDTH-1:0]         xor_q[PORTS-1:0];

  logic [PORTS*$clog2(DEPTH)-1:0] addr_unrolled;
  logic [PORTS*WIDTH-1:0]         xor_d_unrolled;
  logic [PORTS*WIDTH-1:0]         xor_q_unrolled;

  always_ff @(posedge clk) begin
    addr_unrolled[0] <= d;
    addr_unrolled[PORTS*$clog2(DEPTH)-1:1] <= addr_unrolled[PORTS*$clog2(DEPTH)-2:0];
    xor_d_unrolled[0] <= addr_unrolled[PORTS*$clog2(DEPTH)-1];
    xor_d_unrolled[PORTS*WIDTH-1:1] <= xor_d_unrolled[PORTS*WIDTH-2:0];
    en[0] <= xor_d_unrolled[PORTS*WIDTH-1];
    en[PORTS-1:1] <= en[PORTS-2:0];

    if (push) begin
      for (int i = 0; i < PORTS; i++) begin
        xor_q_unrolled[(i+1)*WIDTH-1 -:WIDTH] <= xor_q[i];
      end
    end else begin
      xor_q_unrolled[PORTS*WIDTH-1:1] <= xor_q_unrolled[PORTS*WIDTH-2:0];
    end
    q <= xor_q_unrolled[PORTS*WIDTH-1];
  end

  always_comb begin
    for (int j = 0; j < PORTS; j++) begin
      addr[j] = addr_unrolled[(j+1)*$clog2(DEPTH)-1 -:$clog2(DEPTH)];
      xor_d[j] = xor_d_unrolled[(j+1)*WIDTH-1 -:WIDTH];
    end
  end

  // Instantiate xor_distributed_memory
  xor_distributed_memory #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH),
    .PORTS(PORTS)
  ) dut (
    .clk(clk),
    .addr(addr),
    .d(xor_d),
    .en(en),
    .q(xor_q)
  );

endmodule // xor_distributed_memory_syn
