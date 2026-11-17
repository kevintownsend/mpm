# mpm

[![CI](https://github.com/kevintownsend/mpm/actions/workflows/ci.yml/badge.svg)](https://github.com/kevintownsend/mpm/actions/workflows/ci.yml)

Parameterized multi-port memory architectures in SystemVerilog using bidirectional XOR banks and Live Value Tables (LVT), targeting FPGA block RAM (BRAM) and distributed LUT RAM primitives.

## FPGA '26 Publication & Synthesis Highlights

This repository accompanies the ACM/SIGDA FPGA '26 paper:

> **Multi-Port Memory with Bidirectional Ports for FPGAs Using XOR and LVT Methods**  
> Kevin Townsend — *Proceedings of the 2026 ACM/SIGDA International Symposium on Field Programmable Gate Arrays (FPGA '26)*  
> DOI: [10.1145/3748173.3779548](https://doi.org/10.1145/3748173.3779548) · [Short Paper (PDF)](doc/fpga26/paper.pdf) · [Poster (PDF)](doc/fpga26/poster/poster.pdf) · [Full Manuscript (PDF)](doc/paper.pdf)

- **Key Idea**: Generalizes XOR multi-port memory ($a \oplus b \oplus b = a$) to support bidirectional (read/write) ports using $F^2$ simple dual-port RAMs, and uses bidirectional XOR memory as the Live Value Table (LVT) index to scale wide multi-port memories with $F(F - 1)/2$ data BRAMs.
- **Vivado Synthesis Summary** (`WIDTH = 32`, `DEPTH = 1024`, targeting an AMD Virtex UltraScale+ HBM VU47P-3; 16- and 32-port designs wrapped with serialized I/O in [`syn/`](syn/)):

| Ports | XOR BRAM (`Fmax` / BRAMs / LUTs) | LVT (`Fmax` / BRAMs / LUTs) | LVT Pipelined (`Fmax` / BRAMs / LUTs) |
| --- | --- | --- | --- |
| 2 | 625 MHz / 4 / 144 | 588 MHz / 1 / 191 | 714 MHz / 1 / 119 |
| 4 | 476 MHz / 16 / 512 | 556 MHz / 6 / 1,144 | 667 MHz / 6 / 1,268 |
| 8 | 370 MHz / 64 / 1,920 | 455 MHz / 28 / 5,428 | 625 MHz / 28 / 5,588 |
| 16 | 263 MHz / 256 / 6,656 | 250 MHz / 120 / 31,075 | 417 MHz / 120 / 31,328 |
| 32 | 123 MHz / 1,024 / 10,240 | 127 MHz / 496 / 161,216 | 247 MHz / 496 / 162,960 |

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

## Simulation & Linting

Install Verilator:

```sh
sudo apt install verilator
```

Run all testbenches (compiled with `verilator -Wall --binary`):

```sh
make sim
```

Lint all synthesis wrappers in `syn/`:

```sh
make lint_syn
```

Individual targets are also available (`make lvt_sim`, `make lvt_pipelined_sim`, `make simple_dual_port_memory_wrapper_sim`), and build artifacts can be removed with:

```sh
make clean
```

## Contributing

To contribute, please file an issue or open a pull request on GitHub:

```sh
git clone https://github.com/kevintownsend/mpm.git
```
