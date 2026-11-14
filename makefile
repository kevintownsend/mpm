.PHONY: sim lvt_sim lvt_pipelined_sim simple_dual_port_memory_wrapper_sim clean

sim: lvt_sim lvt_pipelined_sim simple_dual_port_memory_wrapper_sim
	verilator -Wall --binary --top-module xor_memory_tb xor_memory_tb.sv xor_memory.sv simple_dual_port_memory_wrapper.sv simple_dual_port_memory.sv
	obj_dir/Vxor_memory_tb
	verilator -Wall --binary --top-module xor_distributed_memory_tb xor_distributed_memory_tb.sv xor_distributed_memory.sv simple_distributed_ram.sv
	obj_dir/Vxor_distributed_memory_tb
	verilator -Wall --binary --top-module xor_bram_memory_pipelined_tb xor_bram_memory_pipelined_tb.sv xor_bram_memory_pipelined.sv simple_dual_port_memory_wrapper.sv simple_dual_port_memory.sv
	obj_dir/Vxor_bram_memory_pipelined_tb
	verilator -Wall --binary --top-module xor_distributed_memory_pipelined_tb xor_distributed_memory_pipelined_tb.sv xor_distributed_memory_pipelined.sv simple_distributed_ram.sv
	obj_dir/Vxor_distributed_memory_pipelined_tb

lvt_sim:
	verilator -Wall --binary --top-module lvt_memory_tb lvt_memory_tb.sv lvt_memory.sv xor_distributed_memory.sv simple_distributed_ram.sv dual_port_memory.sv
	obj_dir/Vlvt_memory_tb

lvt_pipelined_sim:
	verilator -Wall --binary --top-module lvt_memory_pipelined_tb lvt_memory_pipelined_tb.sv lvt_memory_pipelined.sv xor_distributed_memory_pipelined.sv simple_distributed_ram.sv dual_port_memory.sv
	obj_dir/Vlvt_memory_pipelined_tb

simple_dual_port_memory_wrapper_sim:
	verilator -Wall --binary --top-module simple_dual_port_memory_wrapper_tb simple_dual_port_memory_wrapper_tb.sv simple_dual_port_memory_wrapper.sv simple_dual_port_memory.sv
	obj_dir/Vsimple_dual_port_memory_wrapper_tb

clean:
	rm -rf obj_dir
