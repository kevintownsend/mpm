module xor_asymmetric_memory #(
  parameter WIDTH = 8,
  parameter DEPTH = 256,
  parameter FULL_PORTS = 2,
  parameter WRITE_PORTS = 2,
  parameter READ_PORTS = 2,
  parameter bit USE_XPM = 0
) (
  input  logic                     clk,
  input  logic [$clog2(DEPTH)-1:0] full_addr[FULL_PORTS-1:0],
  input  logic [WIDTH-1:0]         full_d[FULL_PORTS-1:0],
  input  logic                     full_en[FULL_PORTS-1:0],
  output logic [WIDTH-1:0]         full_q[FULL_PORTS-1:0],
  input  logic [$clog2(DEPTH)-1:0] write_addr[WRITE_PORTS-1:0],
  input  logic [WIDTH-1:0]         write_d[WRITE_PORTS-1:0],
  input  logic                     write_en[WRITE_PORTS-1:0],
  input  logic [$clog2(DEPTH)-1:0] read_addr[READ_PORTS-1:0],
  output logic [WIDTH-1:0]         read_q[READ_PORTS-1:0]
);

  if (FULL_PORTS < 1) begin : gen_check_full_ports
    $error("FULL_PORTS (%0d) must be at least 1", FULL_PORTS);
  end
  if (WRITE_PORTS < 1) begin : gen_check_write_ports
    $error("WRITE_PORTS (%0d) must be at least 1", WRITE_PORTS);
  end
  if (READ_PORTS < 1) begin : gen_check_read_ports
    $error("READ_PORTS (%0d) must be at least 1", READ_PORTS);
  end
  if (DEPTH < 2) begin : gen_check_depth
    $error("DEPTH (%0d) must be at least 2", DEPTH);
  end
  if (WIDTH < 1) begin : gen_check_width
    $error("WIDTH (%0d) must be at least 1", WIDTH);
  end

  localparam int NUM_ROWS = FULL_PORTS + WRITE_PORTS;
  localparam int NUM_COLS = FULL_PORTS + WRITE_PORTS + READ_PORTS;

  logic [$clog2(DEPTH)-1:0] row_addr[NUM_ROWS-1:0];
  logic [WIDTH-1:0]         row_d[NUM_ROWS-1:0];
  logic                     row_en[NUM_ROWS-1:0];

  logic [$clog2(DEPTH)-1:0] row_addr_buffered[NUM_ROWS-1:0];
  logic [WIDTH-1:0]         row_d_buffered[NUM_ROWS-1:0];
  logic                     row_en_buffered[NUM_ROWS-1:0];

  logic [$clog2(DEPTH)-1:0] col_addr[NUM_COLS-1:0];

  logic [WIDTH-1:0] ram_output[NUM_ROWS-1:0][NUM_COLS-1:0];
  logic [WIDTH-1:0] partial_xor_input[NUM_ROWS-1:0];

  always_comb begin
    for (int f = 0; f < FULL_PORTS; f++) begin
      row_addr[f] = full_addr[f];
      row_d[f]    = full_d[f];
      row_en[f]   = full_en[f];
      col_addr[f] = full_addr[f];
    end
    for (int w = 0; w < WRITE_PORTS; w++) begin
      row_addr[FULL_PORTS + w] = write_addr[w];
      row_d[FULL_PORTS + w]    = write_d[w];
      row_en[FULL_PORTS + w]   = write_en[w];
      col_addr[FULL_PORTS + w] = write_addr[w];
    end
    for (int r = 0; r < READ_PORTS; r++) begin
      col_addr[NUM_ROWS + r] = read_addr[r];
    end
  end

  always_ff @(posedge clk) begin
    row_addr_buffered <= row_addr;
    row_d_buffered    <= row_d;
    row_en_buffered   <= row_en;
  end

  always_comb begin
    for (int i = 0; i < NUM_ROWS; i++) begin
      partial_xor_input[i] = '0;
      for (int j = 0; j < NUM_ROWS; j++) begin
        if (i != j) begin
          partial_xor_input[i] = partial_xor_input[i] ^ ram_output[j][i];
        end
      end
    end
    for (int f = 0; f < FULL_PORTS; f++) begin
      full_q[f] = partial_xor_input[f] ^ ram_output[f][f];
    end
    for (int r = 0; r < READ_PORTS; r++) begin
      read_q[r] = '0;
      for (int j = 0; j < NUM_ROWS; j++) begin
        read_q[r] = read_q[r] ^ ram_output[j][NUM_ROWS + r];
      end
    end
  end

  // Instantiate (W + F)(W + F + R) - W banks: write-only rows (gi >= FULL_PORTS)
  // omit the diagonal RAM (gi == gj) since write-only ports have no read output.
  genvar gi, gj;
  generate
    for (gi = 0; gi < NUM_ROWS; gi++) begin : y_genblock
      for (gj = 0; gj < NUM_COLS; gj++) begin : x_genblock
        if (gi == gj && gi >= FULL_PORTS) begin : gen_unused_diag
          assign ram_output[gi][gj] = '0;
        end else if (USE_XPM) begin : gen_xpm_ram
          simple_dual_port_memory_xilinx #(
            .WIDTH(WIDTH),
            .DEPTH(DEPTH),
            .WRITE_FIRST(1)
          ) gen_ram (
            .clk(clk),
            .addr_d(row_addr_buffered[gi]),
            .d(row_d_buffered[gi] ^ partial_xor_input[gi]),
            .en(row_en_buffered[gi]),
            .addr_q(col_addr[gj]),
            .q(ram_output[gi][gj])
          );
        end else begin : gen_generic_ram
          simple_dual_port_memory_wrapper #(
            .WIDTH(WIDTH),
            .DEPTH(DEPTH)
          ) gen_ram (
            .clk(clk),
            .addr_d(row_addr_buffered[gi]),
            .d(row_d_buffered[gi] ^ partial_xor_input[gi]),
            .en(row_en_buffered[gi]),
            .addr_q(col_addr[gj]),
            .q(ram_output[gi][gj])
          );
        end
      end
    end
  endgenerate

endmodule // xor_asymmetric_memory
