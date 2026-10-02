# 🏗️ Pipelined 32-bit RISC MIPS32 Processor Architecture

## 📌 Overview

This document describes the microarchitecture of the **5-Stage Pipelined 32-bit RISC MIPS32 Processor**, designed for RTL simulation and FPGA synthesis in Xilinx Vivado.

---

## 📐 5-Stage Pipeline Block Diagram

```text
     +---------------+      +---------------+      +---------------+      +---------------+      +---------------+
     |  IF (Fetch)   | ---> |  ID (Decode)  | ---> | EX (Execute)  | ---> |  MEM (Memory) | ---> | WB (Writeback)|
     +---------------+      +---------------+      +---------------+      +---------------+      +---------------+
             |                      |                      |                      |                      |
             v                      v                      v                      v                      v
     [Instr Memory]         [Register File]            [ALU]              [Data Memory]          [Reg Write]
             |                      |                      ^                      |                      |
             +---- (IF_ID) ---------+---- (ID_EX) ---------+---- (EX_MEM) --------+---- (MEM_WB) --------+
                                                           |
                                                   [Hazard & Forward]
```

---

## 🔄 Pipeline Stages Breakdown

### 1. Instruction Fetch (IF)
- **Program Counter (PC)**: 32-bit register incremented by 1 (word addressing) or updated to branch target if a branch condition evaluates true in EX stage.
- **Instruction Memory (IMEM)**: 1024-word memory block providing instruction word based on current PC.
- **IF/ID Register**: Holds `IR` (32-bit Instruction Register) and `NPC` (Next PC) for the Decode stage.

### 2. Instruction Decode & Register Fetch (ID)
- **Control Unit**: Decodes 6-bit Opcode (`IR[31:26]`) into instruction types (`RR_ALU`, `RM_ALU`, `LOAD`, `STORE`, `BRANCH`, `HALT`).
- **Register File**: 32x32-bit dual-read register bank ($R0$ hardwired to 0).
  - Operand A (`rs`): `IR[25:21]`
  - Operand B (`rt`): `IR[20:16]`
- **Sign Extender**: Converts 16-bit immediate (`IR[15:0]`) to 32-bit sign-extended immediate.
- **ID/EX Register**: Holds `A`, `B`, `Imm`, `IR`, `NPC`, `inst_type`.

### 3. Execution (EX)
- **Arithmetic Logic Unit (ALU)**: Performs 32-bit operations (ADD, SUB, AND, OR, SLT, MUL).
- **Hazard & Forwarding Unit**: Solves Read-After-Write (RAW) data hazards by forwarding ALU results directly from `EX/MEM` or `MEM/WB` stages to ALU inputs (`forward_a`, `forward_b`).
- **Branch Target Adder**: Computes branch target address (`NPC + Imm`).
- **EX/MEM Register**: Holds `ALUOut`, `B`, `cond` (zero flag), `IR`, `inst_type`.

### 4. Memory Access (MEM)
- **Data Memory (DMEM)**: 1024-word RAM block accessed for `LOAD` (LW) and `STORE` (SW) instructions.
- **Branch Decision Logic**: Flushes pipeline if branch condition (`BEQZ` / `BNEQZ`) is satisfied.
- **MEM/WB Register**: Holds `ALUOut`, `LMD` (Loaded Memory Data), `IR`, `inst_type`.

### 5. Write Back (WB)
- **Register Write Port**: Writes ALU result or Loaded Data back to target register:
  - `RR_ALU` (R-type): Target = `IR[15:11]` (`rd`)
  - `RM_ALU` / `LOAD` (I-type): Target = `IR[20:16]` (`rt`)
- **Processor Halt**: Asserts `halted` signal when `HLT` opcode (`6'b111111`) is executed.

---

## 📊 Supported Instruction Set Architecture (ISA)

| Instruction | Opcode (`31:26`) | Format | Type | Description |
| :--- | :---: | :---: | :---: | :--- |
| **ADD** | `000000` | R-Type | `RR_ALU` | `Reg[rd] = Reg[rs] + Reg[rt]` |
| **SUB** | `000001` | R-Type | `RR_ALU` | `Reg[rd] = Reg[rs] - Reg[rt]` |
| **AND** | `000002` | R-Type | `RR_ALU` | `Reg[rd] = Reg[rs] & Reg[rt]` |
| **OR** | `000003` | R-Type | `RR_ALU` | `Reg[rd] = Reg[rs] \| Reg[rt]` |
| **SLT** | `000004` | R-Type | `RR_ALU` | `Reg[rd] = (Reg[rs] < Reg[rt]) ? 1 : 0` |
| **MUL** | `000005` | R-Type | `RR_ALU` | `Reg[rd] = Reg[rs] * Reg[rt]` |
| **LW** | `001000` | I-Type | `LOAD` | `Reg[rt] = Mem[Reg[rs] + Imm]` |
| **SW** | `001001` | I-Type | `STORE` | `Mem[Reg[rs] + Imm] = Reg[rt]` |
| **ADDI** | `001010` | I-Type | `RM_ALU` | `Reg[rt] = Reg[rs] + Imm` |
| **SUBI** | `001011` | I-Type | `RM_ALU` | `Reg[rt] = Reg[rs] - Imm` |
| **SLTI** | `001100` | I-Type | `RM_ALU` | `Reg[rt] = (Reg[rs] < Imm) ? 1 : 0` |
| **BNEQZ** | `001101` | I-Type | `BRANCH` | `Branch to (NPC + Imm) if Reg[rs] != 0` |
| **BEQZ** | `001110` | I-Type | `BRANCH` | `Branch to (NPC + Imm) if Reg[rs] == 0` |
| **HLT** | `111111` | J-Type | `HALT` | Halt Processor Execution |

---

## ⚡ Data Forwarding Unit (Hazard Resolution)

Without data forwarding, executing dependent back-to-back instructions requires inserting 2 NOP (stall) cycles:

```text
ADDI R1, R0, 10
ADD  R4, R1, R2   <-- Requires R1 value immediately!
```

Our **Hazard Forwarding Unit** detects when an instruction in the `EX/MEM` or `MEM/WB` stage is writing to a register needed by the `EX` stage, bypassing the register file writeback delay:

- **EX-to-EX Forwarding**: Bypasses `EX_MEM_ALUOut` directly to ALU Operand A/B.
- **MEM-to-EX Forwarding**: Bypasses `MEM_WB_WriteData` directly to ALU Operand A/B.
