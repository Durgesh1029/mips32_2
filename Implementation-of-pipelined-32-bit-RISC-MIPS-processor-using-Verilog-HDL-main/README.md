# 🚀 Implementation of Pipelined 32-Bit RISC MIPS Processor in Verilog HDL

[![Verilog](https://img.shields.io/badge/Language-Verilog_HDL-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Xilinx Vivado](https://img.shields.io/badge/EDA-Xilinx_Vivado-orange.svg)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Python Simulator](https://img.shields.io/badge/Simulation-Python_3.14-green.svg)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An advanced, synthesizable **5-Stage Pipelined 32-bit RISC MIPS Processor** written in **Verilog HDL**. Designed for academic study and production FPGA synthesis in **Xilinx Vivado**. 

This project bridges the gap between classic theoretical textbook designs and real-world, FPGA-synthesizable silicon design by adding single-clock edge-triggered register control, synchronous reset, separated memory banks, and an active **Hazard Forwarding Unit**.

---

## 📌 Key Highlights & Improvements over Original ISG Textbook Code

- **Fully Synthesizable in Xilinx Vivado**: Replaced original 2-phase non-synthesizable dual-clock (`clk1`, `clk2`) latches and `#delay` statements with a single edge-triggered clock (`clk`) and active-high synchronous reset (`rst`).
- **Data Forwarding & Hazard Resolution**: Includes a dedicated `hazard_unit.v` to resolve Read-After-Write (RAW) data hazards across `EX/MEM` and `MEM/WB` stages without inserting unnecessary stall cycles.
- **Fixed Register Fetch Bug**: Fixed an old bug present in the textbook code (where register $B$ was incorrectly fetching `rs` instead of `rt`).
- **Separated Memory Subsystem**: Modularized Instruction Memory (`instruction_memory.v`) and Data Memory (`data_memory.v`) to enable Block RAM (BRAM) inference on Xilinx FPGAs.
- **Cross-Platform Python Simulation Engine**: Includes a zero-dependency Python cycle-accurate simulator (`sim/run_sim.py`) that prints pipeline execution trace tables and verifies algebraic computations.

---

## 📐 5-Stage Pipeline Architecture

```text
  +-------------+      +-------------+      +-------------+      +-------------+      +-------------+
  |  IF Stage   | ---> |  ID Stage   | ---> |  EX Stage   | ---> | MEM Stage   | ---> |  WB Stage   |
  | (Fetch PC)  |      | (Decode/Reg)|      | (ALU Exec)  |      | (Data RAM)  |      | (WriteReg)  |
  +-------------+      +-------------+      +-------------+      +-------------+      +-------------+
         |                    |                    |                    |                    |
         v                    v                    v                    v                    v
    [Instr RAM]          [32x32 Reg]          [32-bit ALU]          [Data RAM]          [Reg Write]
         |                    |                    ^                    |                    |
         +---- (IF/ID) -------+---- (ID/EX) -------+---- (EX/MEM) ------+---- (MEM/WB) ------+
                                                   |
                                           [Hazard Forwarding]
```

### Pipeline Registers:
1. **IF/ID**: Holds 32-bit Instruction (`IR`) and Next Program Counter (`NPC`).
2. **ID/EX**: Holds Register Operands (`A`, `B`), Sign-extended Immediate (`Imm`), `IR`, `NPC`, and decoded instruction type.
3. **EX/MEM**: Holds `ALUOut`, Store Data (`B`), Zero Flag (`cond`), `IR`, and instruction type.
4. **MEM/WB**: Holds `ALUOut`, Loaded Memory Data (`LMD`), `IR`, and instruction type.

---

## 📂 Repository Directory Structure

```text
Implementation-of-pipelined-32-bit-RISC-MIPS-processor-using-Verilog-HDL/
├── README.md                      # Main Project Documentation & Quickstart
├── rtl/
│   ├── synthesizable/             # Modern Vivado-Synthesizable Verilog Modules
│   │   ├── mips32_top.v           # Top-Level Processor Core (Clock + Reset)
│   │   ├── alu.v                  # 32-bit Arithmetic Logic Unit
│   │   ├── register_file.v        # 32x32-bit Dual-Read Single-Write Register File
│   │   ├── control_unit.v         # Opcode Decoder & Control Unit
│   │   ├── hazard_unit.v          # EX/MEM & MEM/WB Data Forwarding Unit
│   │   ├── instruction_memory.v   # Synthesizable Instruction ROM/RAM
│   │   ├── data_memory.v          # Synthesizable Data RAM
│   │   └── pipeline_registers.v   # Inter-stage Pipeline Registers (IF/ID, ID/EX, EX/MEM, MEM/WB)
│   └── legacy/
│       └── pipe_MIPS32_book.v     # Original 2-phase non-synthesizable book code (for reference)
├── tb/
│   ├── mips32_tb.v                # Self-Checking Synthesizable Testbench
│   └── mips32_book_tb.v           # Legacy 2-Phase Clock Testbench
├── synth/
│   ├── vivado_synth.tcl           # Automated Vivado Synthesis & Implementation TCL Script
│   └── constraints.xdc            # Timing & Clock Constraints (100 MHz target)
├── sim/
│   └── run_sim.py                 # Cycle-Accurate Python Simulator & Trace Visualizer
└── docs/
    ├── Architecture.md            # Detailed Hardware Specs & Instruction Decoding
    └── Vivado_Synthesis_Guide.md  # Troubleshooting & Synthesis Guide
```

---

## 🧪 Simulation & Verification

### Option 1: Quick Python Cycle-Accurate Simulation (Recommended)

Run the Python simulation engine to view cycle-by-cycle pipeline trace tables and register dumps:

```bash
python sim/run_sim.py
```

#### Sample Execution Trace Output:
```text
============================================================================================
                 MIPS32 5-Stage Pipelined Processor Execution Trace                    
============================================================================================
Cycle  | IF (IR)    | ID (Inst)  | EX (ALUOut)    | MEM (Out)      | WB (Write)    
--------------------------------------------------------------------------------------------
  1    | ADDI       | ADD        | NOP            | NOP            | NOP           
  2    | ADDI       | ADDI       | Res:0          | NOP            | NOP           
  3    | ADDI       | ADDI       | Res:10         | ALU:0          | NOP           
  4    | OR         | ADDI       | Res:20         | ALU:10         | R0 <- 0       
  5    | OR         | OR         | Res:25         | ALU:20         | R1 <- 10      
  6    | ADD        | OR         | Res:0          | ALU:25         | R2 <- 20      
  7    | OR         | ADD        | Res:0          | ALU:0          | R3 <- 25      
  8    | ADD        | OR         | Res:30         | ALU:0          | R15 <- 0      
  9    | HLT        | ADD        | Res:0          | ALU:30         | R15 <- 0      
  10   | ADD        | HLT        | Res:55         | ALU:0          | R4 <- 30      
  11   | ADD        | ADD        | NOP            | ALU:55         | R15 <- 0      
  12   | ADD        | ADD        | Res:0          | NOP            | R5 <- 55      
  13   | ADD        | ADD        | Res:0          | ALU:0          | HALT          
[14] Processor Halted.
============================================================================================

--- Final Register State Dump ---
R0  = 0     (0x00000000)
R1  = 10    (0x0000000A)
R2  = 20    (0x00000014)
R3  = 25    (0x00000019)
R4  = 30    (0x0000001E)
R5  = 55    (0x00000037)

[SUCCESS] Verification Passed: R1=10, R2=20, R3=25, R4=30, R5=55!
```

---

### Option 2: Verilog Simulation with Icarus Verilog & GTKWave

If you have `iverilog` installed:

```bash
# Compile synthesizable RTL & Testbench
iverilog -o mips_sim tb/mips32_tb.v rtl/synthesizable/*.v

# Execute simulation
vvp mips_sim

# View timing waveform in GTKWave
gtkwave mips32_synth.vcd
```

---

## 🔨 Xilinx Vivado Synthesis & Implementation

### Running Automated Batch Synthesis:

Open Vivado Tcl Console or terminal:

```bash
vivado -mode batch -source synth/vivado_synth.tcl
```

This TCL script will automatically:
1. Synthesize the Verilog design using `mips32_top.v`.
2. Apply 100 MHz timing constraints from `synth/constraints.xdc`.
3. Perform logic optimization (`opt_design`), placement (`place_design`), and routing (`route_design`).
4. Generate FPGA resource utilization and timing slack reports under `reports/`.

For complete details on synthesis troubleshooting, see [`docs/Vivado_Synthesis_Guide.md`](docs/Vivado_Synthesis_Guide.md).

---

## 📜 Supported Instructions

- **Arithmetic & Logic**: `ADD`, `SUB`, `AND`, `OR`, `SLT`, `MUL`
- **Immediate Arithmetic**: `ADDI`, `SUBI`, `SLTI`
- **Memory Operations**: `LW` (Load Word), `SW` (Store Word)
- **Branch Operations**: `BEQZ` (Branch if Equal Zero), `BNEQZ` (Branch if Not Equal Zero)
- **System Control**: `HLT` (Halt Processor)

---

## 👤 Author & Acknowledgments

- **Author**: Durgesh
- **Institution**: [Your College / University Name]
- **Date**: October 3, 2026

---

## 📄 License

This project is released under the [MIT License](LICENSE).