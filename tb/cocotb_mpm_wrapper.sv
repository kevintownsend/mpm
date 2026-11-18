module cocotb_mpm_wrapper #(
  parameter int MODULE_ID = 0,
  parameter int WIDTH     = 8,
  parameter int DEPTH     = 64,
  parameter int PORTS     = 4
) (
  input  logic                            clk,
  input  logic [PORTS*$clog2(DEPTH)-1:0]  addr_flat,
  input  logic [PORTS*WIDTH-1:0]          d_flat,
  input  logic [PORTS-1:0]                en_flat,
  output logic [PORTS*WIDTH-1:0]          q_flat
);

  localparam int ADDR_W = $clog2(DEPTH);

  logic [ADDR_W-1:0] addr[PORTS-1:0];
  logic [WIDTH-1:0]  d[PORTS-1:0];
  logic              en[PORTS-1:0];
  logic [WIDTH-1:0]  q[PORTS-1:0];

  genvar p;
  generate
    for (p = 0; p < PORTS; p++) begin : gen_pack
      assign addr[p] = addr_flat[(p + 1) * ADDR_W - 1 -: ADDR_W];
      assign d[p]    = d_flat[(p + 1) * WIDTH - 1 -: WIDTH];
      assign en[p]   = en_flat[p];
      assign q_flat[(p + 1) * WIDTH - 1 -: WIDTH] = q[p];
    end
  endgenerate

  generate
    case (MODULE_ID)
      0: begin : gen_dut
        xor_memory #(
          .WIDTH(WIDTH),
          .DEPTH(DEPTH),
          .PORTS(PORTS)
        ) dut (
          .clk(clk),
          .addr(addr),
          .d(d),
          .en(en),
          .q(q)
        );
      end
      1: begin : gen_dut
        xor_bram_memory_pipelined #(
          .WIDTH(WIDTH),
          .DEPTH(DEPTH),
          .PORTS(PORTS)
        ) dut (
          .clk(clk),
          .addr(addr),
          .d(d),
          .en(en),
          .q(q)
        );
      end
      2: begin : gen_dut
        xor_distributed_memory #(
          .WIDTH(WIDTH),
          .DEPTH(DEPTH),
          .PORTS(PORTS)
        ) dut (
          .clk(clk),
          .addr(addr),
          .d(d),
          .en(en),
          .q(q)
        );
      end
      3: begin : gen_dut
        xor_distributed_memory_pipelined #(
          .WIDTH(WIDTH),
          .DEPTH(DEPTH),
          .PORTS(PORTS)
        ) dut (
          .clk(clk),
          .addr(addr),
          .d(d),
          .en(en),
          .q(q)
        );
      end
      4: begin : gen_dut
        lvt_memory #(
          .WIDTH(WIDTH),
          .DEPTH(DEPTH),
          .PORTS(PORTS)
        ) dut (
          .clk(clk),
          .addr(addr),
          .d(d),
          .en(en),
          .q(q)
        );
      end
      5: begin : gen_dut
        lvt_memory_pipelined #(
          .WIDTH(WIDTH),
          .DEPTH(DEPTH),
          .PORTS(PORTS)
        ) dut (
          .clk(clk),
          .addr(addr),
          .d(d),
          .en(en),
          .q(q)
        );
      end
      default: begin : gen_err
        $error("Unsupported MODULE_ID (%0d)", MODULE_ID);
      end
    endcase
  endgenerate

endmodule // cocotb_mpm_wrapper
