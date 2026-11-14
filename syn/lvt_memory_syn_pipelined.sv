module lvt_memory_syn_pipelined(
  input clk,
  input d,
  input push,
  output logic q
);
parameter WIDTH=32;
parameter DEPTH=512;
parameter PORTS=2;

logic [$clog2(DEPTH)-1:0]addr[PORTS-1:0];
logic [$clog2(DEPTH)-1:0]addr_buffered[1:0][PORTS-1:0];
logic en[PORTS-1:0];
logic en_buffered[PORTS-1:0];
logic [WIDTH-1:0]lvt_d[PORTS-1:0];
logic [WIDTH-1:0]lvt_q[PORTS-1:0];
logic push_buffered;
logic d_buffered;

logic [PORTS*$clog2(DEPTH)-1:0]addr_unrolled;
//logic [PORTS*$clog2(DEPTH)-1:0]addr_unrolled_buffered;
logic [PORTS*WIDTH-1:0]lvt_d_unrolled;
//logic [PORTS*WIDTH-1:0]lvt_d_unrolled_buffered;
logic [PORTS*WIDTH-1:0]lvt_q_unrolled;

always @(posedge clk) begin
  en_buffered <= en;
  push_buffered <= push;
  d_buffered <= d;
end

always @(posedge clk) begin
  addr_unrolled[0] <= d_buffered;
  addr_unrolled[PORTS*$clog2(DEPTH)-1:1] <= addr_unrolled[PORTS*$clog2(DEPTH)-2:0];
  lvt_d_unrolled[0] <= addr_unrolled[PORTS*$clog2(DEPTH)-1];
  lvt_d_unrolled[PORTS*WIDTH-1:1] <= lvt_d_unrolled[PORTS*WIDTH-2:0];
  en[0] <= lvt_d_unrolled[PORTS*WIDTH-1];
  en[PORTS-1:1] <= en[PORTS-2:0];

  if (push_buffered) begin
    for (int i = 0; i < PORTS; i++) begin
      lvt_q_unrolled[(i+1)*WIDTH-1 -:WIDTH] <= lvt_q[i];
    end
  end else begin
    lvt_q_unrolled[PORTS*WIDTH-1:1] <= lvt_q_unrolled[PORTS*WIDTH-2:0];
  end
  q <= lvt_q_unrolled[PORTS*WIDTH-1];
end

always @(posedge clk) begin
  for (int j = 0; j < PORTS; j++) begin
    addr[j] <= addr_unrolled[(j+1)*$clog2(DEPTH)-1 -:$clog2(DEPTH)];
    lvt_d[j] <= lvt_d_unrolled[(j+1)*WIDTH-1 -:WIDTH];
  end
end

always @(posedge clk) begin
  addr_buffered[0] <= addr;
  addr_buffered[1] <= addr_buffered[0];
end


//instanciate lvt
lvt_memory_pipelined #(
  WIDTH,
  DEPTH,
  PORTS
  ) dut (
  clk,
  addr_buffered[1],
  en_buffered,
  lvt_d,
  lvt_q
);

endmodule // lvt_memory_syn_pipelined
