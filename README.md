# 🚀 Implementation of Pipelined 32-Bit RISC MIPS Processor in Verilog HDL

[![Verilog](https://img.shields.io/badge/Language-Verilog_HDL-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Xilinx Vivado](https://img.shields.io/badge/EDA-Xilinx_Vivado-orange.svg)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Python Simulator](https://img.shields.io/badge/Simulation-Python_3.14-green.svg)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An advanced, synthesizable **5-Stage Pipelined 32-bit RISC MIPS Processor** written in **Verilog HDL**. Designed for academic study and production FPGA synthesis in **Xilinx Vivado**.

For full source code, modules, testbenches, and synthesis scripts, see the main project folder:
📁 [**`Implementation-of-pipelined-32-bit-RISC-MIPS-processor-using-Verilog-HDL-main`**](./Implementation-of-pipelined-32-bit-RISC-MIPS-processor-using-Verilog-HDL-main)

---

## 📌 Project Features

- **Single Master Clock & Reset**: Converted original textbook 2-phase clock model (`clk1`, `clk2`) into synthesizable single-clock (`clk`) + synchronous reset (`rst`) logic.
- **Hazard Forwarding Unit**: Solves Read-After-Write (RAW) data hazards across `EX/MEM` and `MEM/WB` stages.
- **Vivado TCL Synthesis**: Includes automated build script (`synth/vivado_synth.tcl`) and XDC timing constraints (`synth/constraints.xdc`).
- **Python Verification Engine**: Cross-platform cycle-accurate simulator (`sim/run_sim.py`) that dumps cycle traces and verifies register outputs.

---

## 👤 Author & Acknowledgments

- **Author**: Durgesh
- **Institution**: [Your College / University Name]
- **Date**: October 3, 2026
