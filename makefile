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

RTL_SRCS := $(wildcard rtl/*.sv)
PYTEST ?= $(if $(wildcard .venv/bin/pytest),.venv/bin/pytest,pytest)
VERILATOR_FLAGS := -Wall -y rtl
ifeq ($(TRACE),1)
VERILATOR_FLAGS += --trace-fst +define+TRACE
endif

RUN_TARGETS := $(addprefix run_,$(TBS))

.PHONY: sim lvt_sim lvt_pipelined_sim simple_dual_port_memory_wrapper_sim test lint_syn clean $(RUN_TARGETS)

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

clean:
	rm -rf obj_dir build
