## ============================================================================
## File: constraints.xdc
## Project: Pipelined 32-bit RISC MIPS32 Processor
## Description: Xilinx Design Constraints (XDC) for Vivado Synthesis & Timing
## Target Device: Artix-7 (xc7a35tcpg236-1 / Generic FPGA)
## ============================================================================

# Define Master Clock (100 MHz -> 10.0 ns period)
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# Clock Uncertainty & Jitter
set_clock_uncertainty 0.200 [get_clocks clk]

# Input / Output Delay Constraints
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports rst]
set_input_delay -clock [get_clocks clk] -min 0.500 [get_ports rst]

set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports halted_out]
set_output_delay -clock [get_clocks clk] -min 0.500 [get_ports halted_out]

set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports pc_out*]
set_output_delay -clock [get_clocks clk] -min 0.500 [get_ports pc_out*]
