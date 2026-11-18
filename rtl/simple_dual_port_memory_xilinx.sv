module simple_dual_port_memory_xilinx #(
  parameter WIDTH = 8,
  parameter DEPTH = 256,
  parameter WRITE_FIRST = 0
) (
  input  logic                     clk,
  input  logic [$clog2(DEPTH)-1:0] addr_d,
  input  logic [WIDTH-1:0]         d,
  input  logic                     en,
  input  logic [$clog2(DEPTH)-1:0] addr_q,
  output logic [WIDTH-1:0]         q
);

  /* verilator lint_off PINCONNECTEMPTY */
  xpm_memory_sdpram #(
    .ADDR_WIDTH_A($clog2(DEPTH)),   // DECIMAL
    .ADDR_WIDTH_B($clog2(DEPTH)),   // DECIMAL
    .AUTO_SLEEP_TIME(0),            // DECIMAL
    .BYTE_WRITE_WIDTH_A(WIDTH),     // DECIMAL
    .CASCADE_HEIGHT(0),             // DECIMAL
    .CLOCKING_MODE("common_clock"), // String
    .ECC_BIT_RANGE("7:0"),          // String
    .ECC_MODE("no_ecc"),            // String
    .ECC_TYPE("none"),              // String
    .IGNORE_INIT_SYNTH(0),          // DECIMAL
    .MEMORY_INIT_FILE("none"),      // String
    .MEMORY_INIT_PARAM("0"),        // String
    .MEMORY_OPTIMIZATION("true"),   // String
    .MEMORY_PRIMITIVE("auto"),      // String
    .MEMORY_SIZE(WIDTH * DEPTH),    // DECIMAL
    .MESSAGE_CONTROL(0),            // DECIMAL
    .RAM_DECOMP("auto"),            // String
    .READ_DATA_WIDTH_B(WIDTH),      // DECIMAL
    .READ_LATENCY_B(1),             // DECIMAL
    .READ_RESET_VALUE_B("0"),       // String
    .RST_MODE_A("SYNC"),            // String
    .RST_MODE_B("SYNC"),            // String
    .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
    .USE_MEM_INIT(1),               // DECIMAL
    .USE_MEM_INIT_MMI(0),           // DECIMAL
    .WAKEUP_TIME("disable_sleep"),  // String
    .WRITE_DATA_WIDTH_A(WIDTH),     // DECIMAL
    .WRITE_MODE_B(WRITE_FIRST ? "write_first" : "read_first"), // String
    .WRITE_PROTECT(1)               // DECIMAL
  ) xpm_memory_sdpram_inst (
    .dbiterrb(),                     // 1-bit output: Status signal to indicate double bit error occurrence on the data output of port B.
    .doutb(q),  // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
    .sbiterrb(),                     // 1-bit output: Status signal to indicate single bit error occurrence on the data output of port B.
    .addra(addr_d),  // ADDR_WIDTH_A-bit input: Address for port A write operations.
    .addrb(addr_q),  // ADDR_WIDTH_B-bit input: Address for port B read operations.
    .clka(clk),                      // 1-bit input: Clock signal for port A. Also clocks port B when parameter CLOCKING_MODE is "common_clock".
    .clkb(clk),                      // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is "independent_clock". Unused when
                                     // parameter CLOCKING_MODE is "common_clock".

    .dina(d),  // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
    .ena(en),                        // 1-bit input: Memory enable signal for port A. Must be high on clock cycles when write operations are
                                     // initiated. Pipelined internally.

    .enb(1'b1),                      // 1-bit input: Memory enable signal for port B. Must be high on clock cycles when read operations are
                                     // initiated. Pipelined internally.

    .injectdbiterra(1'b0),           // 1-bit input: Controls double bit error injection on input data when ECC enabled (Error injection capability
                                     // is not available in "decode_only" mode).

    .injectsbiterra(1'b0),           // 1-bit input: Controls single bit error injection on input data when ECC enabled (Error injection capability
                                     // is not available in "decode_only" mode).

    .regceb(1'b1),                   // 1-bit input: Clock Enable for the last register stage on the output data path.
    .rstb(1'b0),                     // 1-bit input: Reset signal for the final port B output register stage. Synchronously resets output port
                                     // doutb to the value specified by parameter READ_RESET_VALUE_B.

    .sleep(1'b0),  // 1-bit input: sleep signal to enable the dynamic power saving feature.
    .wea(en)                         // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector for port A input data port dina. 1 bit
                                     // wide when word-wide writes are used. In byte-wide write configurations, each bit controls the writing one
                                     // byte of dina to address addra. For example, to synchronously write only bits [15-8] of dina when
                                     // WRITE_DATA_WIDTH_A is 32, wea would be 4'b0010.

  );
  /* verilator lint_on PINCONNECTEMPTY */

endmodule
