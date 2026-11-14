# bidirectional-xor-memory

Multi-port memory architectures in SystemVerilog using bidirectional XOR banks and Live Value Tables (LVT), targeting FPGA block RAM (BRAM) and distributed LUT RAM primitives.

## Modules

All multi-port top-level modules share the uniform port interface:

- `clk`: Clock input
- `addr[PORTS-1:0]`: Per-port read/write address (`$clog2(DEPTH)` bits)
- `d[PORTS-1:0]`: Per-port write data (`WIDTH` bits)
- `en[PORTS-1:0]`: Per-port write enable
- `q[PORTS-1:0]`: Per-port read data (`WIDTH` bits)

All top-level modules are parameterized by `WIDTH`, `DEPTH`, and `PORTS` (`PORTS >= 2`).

| Module | Backing Storage | Read Latency | Notes |
| --- | --- | --- | --- |
| [`xor_memory`](xor_memory.sv) | `simple_dual_port_memory_wrapper` | 1 cycle | Buffered write with same-cycle write forwarding |
| [`xor_bram_memory_pipelined`](xor_bram_memory_pipelined.sv) | `simple_dual_port_memory_wrapper` | 2 cycles | Registered output stage for BRAM timing closure |
| [`xor_distributed_memory`](xor_distributed_memory.sv) | `simple_distributed_ram` | 0 cycles (comb.) | Synchronous write, combinational read |
| [`xor_distributed_memory_pipelined`](xor_distributed_memory_pipelined.sv) | `simple_distributed_ram` | 2 cycles | Pipelined read/write path; avoid adjacent-cycle writes |
| [`lvt_memory`](lvt_memory.sv) | `dual_port_memory` + `xor_distributed_memory` | 1 cycle | XOR-based LVT index with BRAM bank storage |
| [`lvt_memory_pipelined`](lvt_memory_pipelined.sv) | `dual_port_memory` + `xor_distributed_memory_pipelined` | 2 cycles | Pipelined LVT + registered bank outputs; avoid adjacent-cycle writes |

### Supporting Primitives & Synthesis Wrappers

- [`simple_dual_port_memory.sv`](simple_dual_port_memory.sv): Generic synchronous simple dual-port RAM.
- [`simple_dual_port_memory_wrapper.sv`](simple_dual_port_memory_wrapper.sv): Adds read-during-write bypass forwarding around `simple_dual_port_memory`.
- [`simple_dual_port_memory_xilinx.sv`](simple_dual_port_memory_xilinx.sv): Xilinx `xpm_memory_sdpram` wrapper for Vivado flows.
- [`simple_distributed_ram.sv`](simple_distributed_ram.sv): Synchronous write / combinational read distributed RAM primitive.
- [`dual_port_memory.sv`](dual_port_memory.sv): True dual-port RAM primitive for LVT data banks.
- [`syn/`](syn/): Serialized shift-register I/O wrappers and Vivado project files (`syn/syn.xpr`) for out-of-context synthesis benchmarking.

## Simulation

Install Verilator:

```sh
sudo apt install verilator
```

Run all testbenches (compiled with `verilator -Wall --binary`):

```sh
make sim
```

Individual targets are also available (`make lvt_sim`, `make lvt_pipelined_sim`, `make simple_dual_port_memory_wrapper_sim`), and build artifacts can be removed with:

```sh
make clean
```

## Contributing

To contribute, please file an issue or open a pull request on GitHub:

```sh
git clone https://github.com/kevintownsend/bidirectional-xor-memory.git
```
