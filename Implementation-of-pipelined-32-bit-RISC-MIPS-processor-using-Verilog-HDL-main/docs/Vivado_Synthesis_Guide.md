# 🛠️ Xilinx Vivado RTL Synthesis & Optimization Guide

## 🚨 Why the Original Textbook Code (`pipe_MIPS32.v`) Failed Vivado Synthesis

The original MIPS32 Verilog code sourced from course textbooks (`verilog_isg.pdf`) was written strictly as a **behavioral simulation model** and is **non-synthesizable** on standard FPGA/ASIC tools (Xilinx Vivado, Intel Quartus, Yosys).

Here is a detailed breakdown of the synthesis failures in the original code:

| Issue | Original Code (`pipe_MIPS32.v`) | Why Vivado Failed | Modern Fix (`mips32_top.v`) |
| :--- | :--- | :--- | :--- |
| **Dual Clocking** | Used two non-overlapping clock edges (`clk1`, `clk2`). | FPGAs do not support inter-dependent 2-phase clock latches. | Converted to single master clock (`clk`) with edge-triggered registers. |
| **Missing Reset** | Lacked a top-level `reset` signal; relied on testbench force assignments. | Uninitialized flip-flops and undefined reset states in hardware synthesis. | Added synchronous active-high reset (`rst`) to all registers. |
| **Delay Control (`#2`)** | Used `#2` gate delay statements inside procedural assignments (`<= #2`). | Hardware synthesis tools ignore or throw syntax errors for `#delay` statements in RTL logic. | Removed all `#delay` statements; timing is governed by clock constraints. |
| **Unified Memory Array** | Single memory `Mem[0:1023]` accessed asynchronously in IF (`Mem[PC]`) and MEM stage (`Mem[EX_MEM_ALUOut]`). | Vivado cannot infer Block RAM (BRAM) for a single memory block accessed concurrently across multiple pipeline stages without dual ports. | Separated into dedicated **Instruction Memory (`instruction_memory.v`)** and **Data Memory (`data_memory.v`)**. |
| **Testbench Hierarchical Force** | Testbench initialized registers via `mips.Reg[k] = k; mips.HALTED = 0;`. | Internal module registers cannot be force-written by testbench initial blocks during FPGA synthesis. | Standardized memory initialization via synthesizable arrays and top-level reset signals. |
| **Register B Bug** | Line 55 had `ID_EX_B <= Reg[IF_ID_IR[25:21]];` (fetching `rs` twice instead of `rt`). | Caused operand B to incorrectly read register `rs` instead of `rt`. | Fixed to `ID_EX_B <= Reg[IF_ID_IR[20:16]];` (`rt`). |

---

## 🚀 How to Run Synthesis in Xilinx Vivado

### Option 1: Using Vivado GUI

1. Launch **Xilinx Vivado**.
2. Click **Create Project** -> Select **RTL Project**.
3. Add Verilog source files from `rtl/synthesizable/`:
   - `mips32_top.v`
   - `alu.v`
   - `register_file.v`
   - `control_unit.v`
   - `instruction_memory.v`
   - `data_memory.v`
   - `pipeline_registers.v`
   - `hazard_unit.v`
4. Add Constraint file from `synth/constraints.xdc`.
5. Select Target FPGA Part: **Artix-7 `xc7a35tcpg236-1`** (or Basys 3 / Nexys A7).
6. Set `mips32_top` as the **Top Module**.
7. Click **Run Synthesis** -> **Run Implementation** -> **Generate Bitstream**.

---

### Option 2: Using Vivado TCL Batch Mode (Automated)

Run the included TCL build script directly from your terminal or Vivado Command Prompt:

```bash
# Navigate to project folder
cd Implementation-of-pipelined-32-bit-RISC-MIPS-processor-using-Verilog-HDL

# Run Vivado in batch mode
vivado -mode batch -source synth/vivado_synth.tcl
```

### Generated Synthesis Outputs:
- **`reports/utilization_report.txt`**: LUT, Flip-Flop, and BRAM resource usage.
- **`reports/timing_report.txt`**: Setup/hold slack, critical path analysis.
- **`out/mips32_post_synth_netlist.v`**: Synthesized gate-level Verilog netlist.
