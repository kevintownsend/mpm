# Synthesis Workflows (`syn/`)

This directory provides reproducible out-of-context (OOC) Vivado synthesis via a scripted non-project Tcl flow, serialized I/O wrappers for high-port-count designs, and the original Vivado GUI project.

## Non-Project Vivado OOC Flow (`synth.tcl`)

[`synth.tcl`](synth.tcl) elaborates and synthesizes any RTL module or synthesis wrapper from [`../rtl/mpm.f`](../rtl/mpm.f) in memory, applies an OOC clock constraint on `clk`, and emits utilization and timing reports without touching [`syn.xpr`](syn.xpr).

### Direct Vivado Batch Usage

```sh
vivado -mode batch -nojournal -nolog -source syn/synth.tcl \
  -tclargs <top> <part> <width> <depth> <ports> <clk_ns> <out_dir> [use_xpm] [run_impl]
```

Default `-tclargs` values:

| Arg | Name | Default | Notes |
| --- | --- | --- | --- |
| `0` | `top` | `xor_bram_memory_pipelined` | Any module in `rtl/` or wrapper in `syn/<top>.sv` |
| `1` | `part` | `xcvu47p-fsvh2892-3-e` | Paper's VU47P-3 target; falls back to `xc7a200tiffg1156-1L` if unavailable locally |
| `2` | `width` | `32` | Word width (`WIDTH`) |
| `3` | `depth` | `1024` | Word depth (`DEPTH`) |
| `4` | `ports` | `4` | Port count (`PORTS`) |
| `5` | `clk_ns` | `2.5` | Target clock period in ns for `create_clock` |
| `6` | `out_dir` | `syn/out/${top}_${ports}p` | Output report directory |
| `7` | `use_xpm` | `0` (or `$MPM_USE_XPM`) | Passed as `-generic USE_XPM=...` on XPM-enabled XOR modules |
| `8` | `run_impl` | `0` (or `$MPM_RUN_IMPL`) | Set to `1` to also run `opt_design`, `place_design`, and `route_design` |

### `make synth` Wrapper

The root [`makefile`](../makefile) exposes the same parameters as overridable Make variables:

```sh
# Portable BRAM inference (USE_XPM=0)
make synth SYNTH_TOP=xor_bram_memory_pipelined SYNTH_PORTS=8 SYNTH_WIDTH=32 SYNTH_DEPTH=1024 USE_XPM=0

# Native Xilinx xpm_memory_sdpram BRAM primitive (USE_XPM=1)
make synth SYNTH_TOP=xor_bram_memory_pipelined SYNTH_PORTS=8 SYNTH_WIDTH=32 SYNTH_DEPTH=1024 USE_XPM=1

# High-port serialized wrapper example
make synth SYNTH_TOP=xor_bram_memory_pipelined_syn SYNTH_PORTS=16 SYNTH_WIDTH=32 SYNTH_DEPTH=1024
```

Variables supported by `make synth`: `SYNTH_TOP`, `SYNTH_PART`, `SYNTH_WIDTH`, `SYNTH_DEPTH`, `SYNTH_PORTS`, `SYNTH_CLK_NS`, `USE_XPM`, and `SYNTH_OUT_DIR`.

### Output Reports

Each run creates three files under `SYNTH_OUT_DIR`:

- `utilization.rpt`: Full hierarchical and primitive resource report (`report_utilization`).
- `timing_summary.rpt`: Setup/hold timing summary (`report_timing_summary -delay_type max -max_paths 5`).
- `summary.txt`: Compact key-value summary of `top`, `part`, `width`, `depth`, `ports`, `use_xpm`, `clk_ns`, `wns_ns`, and computed `fmax_mhz`.

## Serialized I/O Wrappers (`*_syn.sv`)

Multi-port designs with `PORTS >= 16` exceed physical FPGA I/O pin counts if synthesized with raw parallel ports. The wrappers below pack inputs and outputs into narrow shift-register chains (`d`, `push`, `q`) so OOC synthesis preserves internal memory structure without I/O bottlenecks:

- [`lvt_memory_syn.sv`](lvt_memory_syn.sv): Wraps `lvt_memory`
- [`lvt_memory_syn_pipelined.sv`](lvt_memory_syn_pipelined.sv): Wraps `lvt_memory_pipelined`
- [`xor_bram_memory_pipelined_syn.sv`](xor_bram_memory_pipelined_syn.sv): Wraps `xor_bram_memory_pipelined` (exposes `USE_XPM`)
- [`xor_distributed_memory_syn.sv`](xor_distributed_memory_syn.sv): Wraps `xor_distributed_memory`

## Legacy GUI Project (`syn.xpr`)

[`syn.xpr`](syn.xpr) is kept for interactive Vivado IDE inspection and targets Artix-7 (`xc7a200tiffg1156-1L`) by default. Prefer [`synth.tcl`](synth.tcl) / `make synth` for scripted benchmarking, `USE_XPM=1` sweeps, and UltraScale+ (`xcvu47p-fsvh2892-3-e`) builds.
