# Non-project out-of-context Vivado synthesis script for mpm
# Usage:
#   vivado -mode batch -nojournal -nolog -source syn/synth.tcl \
#     -tclargs <top> <part> <width> <depth> <ports> <clk_ns> <out_dir> [use_xpm] [run_impl]

set top      [expr {$argc > 0 ? [lindex $argv 0] : "xor_bram_memory_pipelined"}]
set part     [expr {$argc > 1 ? [lindex $argv 1] : "xcvu47p-fsvh2892-3-e"}]
set width    [expr {$argc > 2 ? [lindex $argv 2] : 32}]
set depth    [expr {$argc > 3 ? [lindex $argv 3] : 1024}]
set ports    [expr {$argc > 4 ? [lindex $argv 4] : 4}]
set clk_ns   [expr {$argc > 5 ? [lindex $argv 5] : 2.5}]
set out_dir  [expr {$argc > 6 ? [lindex $argv 6] : "syn/out/${top}_${ports}p"}]
set use_xpm  [expr {$argc > 7 ? [lindex $argv 7] : ([info exists ::env(MPM_USE_XPM)] ? $::env(MPM_USE_XPM) : 0)}]
set run_impl [expr {$argc > 8 ? [lindex $argv 8] : ([info exists ::env(MPM_RUN_IMPL)] ? $::env(MPM_RUN_IMPL) : 0)}]

if {[llength [get_parts -quiet $part]] == 0} {
  set fallback_part "xc7a200tiffg1156-1L"
  if {[llength [get_parts -quiet $fallback_part]] > 0} {
    puts "WARNING: Requested part '$part' is not installed in this Vivado instance; falling back to '$fallback_part'."
    set resolved_part $fallback_part
  } else {
    puts "ERROR: Requested part '$part' and fallback part '$fallback_part' are not installed in this Vivado instance."
    exit 1
  }
} else {
  set resolved_part $part
}

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file dirname $script_dir]

create_project -in_memory -part $resolved_part
set_property XPM_LIBRARIES {XPM_MEMORY} [current_project]

set manifest_path [file join $repo_root rtl mpm.f]
set fp [open $manifest_path r]
while {[gets $fp raw_line] >= 0} {
  set line [string trim $raw_line]
  if {$line eq "" || [string match "#*" $line]} {
    continue
  }
  read_verilog -sv [file join $repo_root $line]
}
close $fp

read_verilog -sv [file join $repo_root rtl simple_dual_port_memory_xilinx.sv]

set syn_wrapper [file join $repo_root syn "${top}.sv"]
if {[file exists $syn_wrapper]} {
  read_verilog -sv $syn_wrapper
}

auto_detect_xpm

set generic_args [list -generic WIDTH=$width -generic DEPTH=$depth -generic PORTS=$ports]
set xpm_tops [list xor_memory xor_bram_memory_pipelined xor_asymmetric_memory xor_bram_memory_pipelined_syn]
if {[lsearch -exact $xpm_tops $top] >= 0} {
  lappend generic_args -generic USE_XPM=$use_xpm
}

synth_design -top $top -part $resolved_part -mode out_of_context {*}$generic_args
create_clock -name clk -period $clk_ns [get_ports clk]

if {$run_impl == 1} {
  opt_design
  place_design
  route_design
}

file mkdir $out_dir
report_utilization -file [file join $out_dir utilization.rpt]
report_timing_summary -delay_type max -max_paths 5 -file [file join $out_dir timing_summary.rpt]

set timing_paths [get_timing_paths -max_paths 1 -setup -quiet]
set wns ""
if {[llength $timing_paths] > 0} {
  set wns [get_property SLACK $timing_paths]
}

if {$wns ne "" && ($clk_ns - $wns) > 0} {
  set fmax_mhz [format "%.2f" [expr {1000.0 / ($clk_ns - $wns)}]]
} else {
  if {$wns eq ""} {
    set wns "N/A"
  }
  set fmax_mhz "N/A"
}

set summary_lines [list \
  "top:      $top" \
  "part:     $resolved_part" \
  "width:    $width" \
  "depth:    $depth" \
  "ports:    $ports" \
  "use_xpm:  $use_xpm" \
  "clk_ns:   $clk_ns" \
  "wns_ns:   $wns" \
  "fmax_mhz: $fmax_mhz" \
]

set summary_text [join $summary_lines "\n"]
set summary_fp [open [file join $out_dir summary.txt] w]
puts $summary_fp $summary_text
close $summary_fp

puts "=== Synthesis Summary ==="
puts $summary_text
