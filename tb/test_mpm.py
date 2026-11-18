import os
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

MODULE_NAMES = {
    0: "xor_memory",
    1: "xor_bram_memory_pipelined",
    2: "xor_distributed_memory",
    3: "xor_distributed_memory_pipelined",
    4: "lvt_memory",
    5: "lvt_memory_pipelined",
}

READ_LATENCY = {
    0: 1,
    1: 2,
    2: 0,
    3: 2,
    4: 1,
    5: 2,
}

WRITE_COOLDOWN = {
    0: 0,
    1: 0,
    2: 0,
    3: 1,
    4: 0,
    5: 1,
}


def pack_words(values: list[int], bit_width: int) -> int:
    mask = (1 << bit_width) - 1
    packed = 0
    for idx, val in enumerate(values):
        packed |= (val & mask) << (idx * bit_width)
    return packed


def pack_bits(bits: list[int]) -> int:
    packed = 0
    for idx, bit in enumerate(bits):
        if bit:
            packed |= 1 << idx
    return packed


def unpack_words(packed: int, count: int, bit_width: int) -> list[int]:
    mask = (1 << bit_width) - 1
    return [(packed >> (idx * bit_width)) & mask for idx in range(count)]


async def clear_inputs(dut) -> None:
    dut.addr_flat.value = 0
    dut.d_flat.value = 0
    dut.en_flat.value = 0


async def drive_write(
    dut,
    addrs: list[int],
    datas: list[int],
    ens: list[int],
    golden: list[int],
    addr_w: int,
    width: int,
    write_cooldown: int,
) -> None:
    dut.addr_flat.value = pack_words(addrs, addr_w)
    dut.d_flat.value = pack_words(datas, width)
    dut.en_flat.value = pack_bits(ens)

    for p, en in enumerate(ens):
        if en:
            golden[addrs[p]] = datas[p]

    await FallingEdge(dut.clk)

    for _ in range(write_cooldown):
        await clear_inputs(dut)
        await FallingEdge(dut.clk)


async def verify_read_burst(
    dut,
    read_vecs: list[list[int]],
    golden: list[int],
    ports: int,
    addr_w: int,
    width: int,
    read_latency: int,
    label: str,
) -> None:
    if not read_vecs:
        return

    if read_latency == 0:
        for cycle, addrs in enumerate(read_vecs):
            dut.addr_flat.value = pack_words(addrs, addr_w)
            dut.d_flat.value = 0
            dut.en_flat.value = 0
            await Timer(1, unit="ns")
            actual = unpack_words(dut.q_flat.value.to_unsigned(), ports, width)
            for p in range(ports):
                exp = golden[addrs[p]]
                assert actual[p] == exp, (
                    f"{label} cycle {cycle} port {p}: addr={addrs[p]} expected={exp:#x}, got={actual[p]:#x}"
                )
            await FallingEdge(dut.clk)
        return

    pending: list[tuple[list[int], list[int]]] = []
    total_steps = len(read_vecs) + read_latency - 1
    for step in range(total_steps):
        if step < len(read_vecs):
            addrs = read_vecs[step]
            dut.addr_flat.value = pack_words(addrs, addr_w)
            dut.d_flat.value = 0
            dut.en_flat.value = 0
            pending.append((addrs, [golden[a] for a in addrs]))
        else:
            await clear_inputs(dut)

        await FallingEdge(dut.clk)

        if step + 1 >= read_latency:
            req_addrs, expected = pending.pop(0)
            actual = unpack_words(dut.q_flat.value.to_unsigned(), ports, width)
            for p in range(ports):
                assert actual[p] == expected[p], (
                    f"{label} step {step} port {p}: addr={req_addrs[p]} "
                    f"expected={expected[p]:#x}, got={actual[p]:#x}"
                )


@cocotb.test()
async def random_multiport_scoreboard_test(dut) -> None:
    module_id = int(os.environ.get("MPM_MODULE_ID", dut.MODULE_ID.value.to_unsigned()))
    width = int(os.environ.get("MPM_WIDTH", dut.WIDTH.value.to_unsigned()))
    depth = int(os.environ.get("MPM_DEPTH", dut.DEPTH.value.to_unsigned()))
    ports = int(os.environ.get("MPM_PORTS", dut.PORTS.value.to_unsigned()))

    mod_name = MODULE_NAMES[module_id]
    read_latency = READ_LATENCY[module_id]
    write_cooldown = WRITE_COOLDOWN[module_id]
    addr_w = (depth - 1).bit_length()
    data_mask = (1 << width) - 1

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await clear_inputs(dut)
    await FallingEdge(dut.clk)

    golden = [0] * depth
    rng = random.Random(0xC0C07B + module_id * 100 + ports)

    # Phase A: Directed concurrent multi-port writes, per-port self-reads, and cross-port reads.
    init_addrs = [(p * 3 + 1) % depth for p in range(ports)]
    init_datas = [((0xA0 + p * 17) & data_mask) or 1 for p in range(ports)]
    await drive_write(dut, init_addrs, init_datas, [1] * ports, golden, addr_w, width, write_cooldown)

    # Check self-read on each port while all other ports read distinct addresses.
    self_read_vecs = []
    for p in range(ports):
        vec = [((init_addrs[(p + 1) % ports] + k + 7) % depth) for k in range(ports)]
        vec[p] = init_addrs[p]
        self_read_vecs.append(vec)
    await verify_read_burst(
        dut, self_read_vecs, golden, ports, addr_w, width, read_latency, f"{mod_name}(P={ports}) self-read"
    )

    # Cross-port rotated reads and shared-address collision read.
    rotated = [init_addrs[(p + 1) % ports] for p in range(ports)]
    shared = [init_addrs[0]] * ports
    await verify_read_burst(
        dut, [rotated, shared], golden, ports, addr_w, width, read_latency, f"{mod_name}(P={ports}) cross-read"
    )

    # Phase B: 250 constrained-random multi-port write/read rounds.
    for round_idx in range(250):
        num_writers = rng.randint(1, ports)
        writer_ports = rng.sample(range(ports), num_writers)
        write_addrs_set = rng.sample(range(depth), num_writers)

        addrs = [rng.randrange(depth) for _ in range(ports)]
        datas = [rng.randrange(1 << width) for _ in range(ports)]
        ens = [0] * ports
        for w_port, w_addr in zip(writer_ports, write_addrs_set):
            addrs[w_port] = w_addr
            ens[w_port] = 1

        await drive_write(dut, addrs, datas, ens, golden, addr_w, width, write_cooldown)

        # Periodically overwrite on immediately adjacent cycles when hardware allows it.
        if write_cooldown == 0 and (round_idx % 3 == 0):
            rot_addrs = [rng.randrange(depth) for _ in range(ports)]
            rot_datas = [rng.randrange(1 << width) for _ in range(ports)]
            rot_ens = [0] * ports
            rot_writers = [((w + 1) % ports) for w in writer_ports]
            for w_port, w_addr in zip(rot_writers, write_addrs_set):
                rot_addrs[w_port] = w_addr
                rot_ens[w_port] = 1
            await drive_write(dut, rot_addrs, rot_datas, rot_ens, golden, addr_w, width, write_cooldown)

        # Burst of 1..3 back-to-back read vectors covering written & random addresses.
        burst_len = rng.randint(1, 3)
        read_vecs = []
        for b in range(burst_len):
            vec = [rng.randrange(depth) for _ in range(ports)]
            if b == 0:
                # Guarantee at least one recently written address is read on a different port.
                probe_port = (writer_ports[0] + 1) % ports
                vec[probe_port] = write_addrs_set[0]
            read_vecs.append(vec)

        await verify_read_burst(
            dut,
            read_vecs,
            golden,
            ports,
            addr_w,
            width,
            read_latency,
            f"{mod_name}(P={ports}) rand#{round_idx}",
        )
