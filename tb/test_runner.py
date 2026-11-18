from pathlib import Path
import pytest

try:
    from cocotb_tools.runner import get_runner
except ImportError:
    from cocotb.runner import get_runner

ROOT_DIR = Path(__file__).resolve().parent.parent
RTL_DIR = ROOT_DIR / "rtl"
TB_DIR = ROOT_DIR / "tb"
BUILD_ROOT = ROOT_DIR / "build"

MODULES = [
    (0, "xor_memory"),
    (1, "xor_bram_memory_pipelined"),
    (2, "xor_distributed_memory"),
    (3, "xor_distributed_memory_pipelined"),
    (4, "lvt_memory"),
    (5, "lvt_memory_pipelined"),
]

PORT_COUNTS = [2, 3, 4, 5, 8]

RTL_SOURCES = [
    RTL_DIR / "dual_port_memory.sv",
    RTL_DIR / "simple_distributed_ram.sv",
    RTL_DIR / "simple_dual_port_memory.sv",
    RTL_DIR / "simple_dual_port_memory_wrapper.sv",
    RTL_DIR / "xor_memory.sv",
    RTL_DIR / "xor_bram_memory_pipelined.sv",
    RTL_DIR / "xor_distributed_memory.sv",
    RTL_DIR / "xor_distributed_memory_pipelined.sv",
    RTL_DIR / "lvt_memory.sv",
    RTL_DIR / "lvt_memory_pipelined.sv",
    TB_DIR / "cocotb_mpm_wrapper.sv",
]


@pytest.mark.parametrize("module_id,module_name", MODULES, ids=[m[1] for m in MODULES])
@pytest.mark.parametrize("ports", PORT_COUNTS, ids=[f"P{p}" for p in PORT_COUNTS])
def test_mpm_randomized(module_id: int, module_name: str, ports: int) -> None:
    width = 8
    depth = 64
    build_dir = BUILD_ROOT / f"cocotb_{module_name}_p{ports}"

    runner = get_runner("verilator")
    runner.build(
        sources=RTL_SOURCES,
        hdl_toplevel="cocotb_mpm_wrapper",
        parameters={
            "MODULE_ID": module_id,
            "WIDTH": width,
            "DEPTH": depth,
            "PORTS": ports,
        },
        build_args=["-Wall", "-y", str(RTL_DIR)],
        build_dir=build_dir,
        always=False,
    )
    runner.test(
        hdl_toplevel="cocotb_mpm_wrapper",
        test_module="test_mpm",
        build_dir=build_dir,
        test_dir=build_dir,
        results_xml=str(build_dir / "results.xml"),
        extra_env={
            "PYTHONPATH": str(TB_DIR),
            "MPM_MODULE_ID": str(module_id),
            "MPM_WIDTH": str(width),
            "MPM_DEPTH": str(depth),
            "MPM_PORTS": str(ports),
        },
    )
