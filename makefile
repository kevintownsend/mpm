TBS := \
	lvt_memory_tb \
	lvt_memory_pipelined_tb \
	simple_dual_port_memory_wrapper_tb \
	xor_memory_tb \
	xor_distributed_memory_tb \
	xor_bram_memory_pipelined_tb \
	xor_distributed_memory_pipelined_tb \
	xor_asymmetric_memory_tb

SYN_TOPS := \
	lvt_memory_syn \
	lvt_memory_syn_pipelined \
	xor_bram_memory_pipelined_syn \
	xor_distributed_memory_syn

YOSYS_TOPS := \
	xor_memory \
	xor_bram_memory_pipelined \
	xor_distributed_memory \
	xor_distributed_memory_pipelined \
	lvt_memory \
	lvt_memory_pipelined \
	xor_asymmetric_memory

RTL_SRCS := $(wildcard rtl/*.sv)
PYTEST ?= $(if $(wildcard .venv/bin/pytest),.venv/bin/pytest,pytest)
VIVADO ?= $(if $(wildcard /home/kevin/Xilinx/2025.1/Vivado/bin/vivado),/home/kevin/Xilinx/2025.1/Vivado/bin/vivado,vivado)
VERIBLE_LINT ?= verible-verilog-lint
VERIBLE_FMT ?= verible-verilog-format
SV2V ?= sv2v
YOSYS ?= yosys

SYNTH_TOP ?= xor_bram_memory_pipelined
SYNTH_PART ?= xcvu47p-fsvh2892-3-e
SYNTH_WIDTH ?= 32
SYNTH_DEPTH ?= 1024
SYNTH_PORTS ?= 4
SYNTH_CLK_NS ?= 2.5
USE_XPM ?= 0
SYNTH_OUT_DIR ?= syn/out/$(SYNTH_TOP)_$(SYNTH_PORTS)p_xpm$(USE_XPM)

VERILATOR_FLAGS := -Wall -y rtl
ifeq ($(TRACE),1)
VERILATOR_FLAGS += --trace-fst +define+TRACE
endif

RUN_TARGETS := $(addprefix run_,$(TBS))

.PHONY: sim lvt_sim lvt_pipelined_sim simple_dual_port_memory_wrapper_sim test lint_syn lint_style synth_yosys synth clean $(RUN_TARGETS)

sim: $(RUN_TARGETS)

lvt_sim: run_lvt_memory_tb

lvt_pipelined_sim: run_lvt_memory_pipelined_tb

simple_dual_port_memory_wrapper_sim: run_simple_dual_port_memory_wrapper_tb

define TB_RULES
build/$(1)/V$(1): tb/$(1).sv $$(RTL_SRCS) makefile
	mkdir -p build/$(1)
	verilator $$(VERILATOR_FLAGS) --binary --Mdir build/$(1) --top-module $(1) $$<

run_$(1): build/$(1)/V$(1)
	$$<
endef

$(foreach tb,$(TBS),$(eval $(call TB_RULES,$(tb))))

test:
	$(PYTEST) -v tb/test_runner.py

lint_syn:
	@for top in $(SYN_TOPS); do \
		verilator -Wall -y rtl --lint-only --top-module $$top syn/$$top.sv || exit 1; \
	done

lint_style:
	$(VERIBLE_LINT) --rules_config=.rules.verible_lint rtl/*.sv syn/*.sv
	$(VERIBLE_FMT) --flagfile=.verible_format --verify --inplace rtl/*.sv syn/*.sv

synth_yosys:
	mkdir -p build
	$(SV2V) $$(cat rtl/mpm.f) > build/mpm_v2k.v
	@for top in $(YOSYS_TOPS); do \
		echo "=== Yosys synth_xilinx: $$top ==="; \
		$(YOSYS) -q -p "read_verilog build/mpm_v2k.v; hierarchy -check -top $$top; proc; synth_xilinx -top $$top; select -assert-none t:\$$dlatch*" || exit 1; \
	done

synth:
	$(VIVADO) -mode batch -nojournal -nolog -source syn/synth.tcl -tclargs $(SYNTH_TOP) $(SYNTH_PART) $(SYNTH_WIDTH) $(SYNTH_DEPTH) $(SYNTH_PORTS) $(SYNTH_CLK_NS) $(SYNTH_OUT_DIR) $(USE_XPM)

clean:
	rm -rf obj_dir build
