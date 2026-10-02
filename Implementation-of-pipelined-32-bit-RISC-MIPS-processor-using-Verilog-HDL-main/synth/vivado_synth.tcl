# ============================================================================
# File: vivado_synth.tcl
# Project: Pipelined 32-bit RISC MIPS32 Processor
# Description: Automated Xilinx Vivado Synthesis & Implementation Script
# Usage: vivado -mode batch -source synth/vivado_synth.tcl
# ============================================================================

# Step 1: Define Target Device & Output Directories
set PART_NAME "xc7a35tcpg236-1"
set REPORT_DIR "reports"
set OUTPUT_DIR "out"

file mkdir $REPORT_DIR
file mkdir $OUTPUT_DIR

puts "=========================================================="
puts "  Starting Vivado Synthesis for MIPS32 Pipelined Core    "
puts "=========================================================="

# Step 2: Read Synthesizable Verilog Source Files
read_verilog [glob rtl/synthesizable/*.v]

# Step 3: Read Timing Constraints
read_xdc synth/constraints.xdc

# Step 4: Run RTL Synthesis
puts "--> Running RTL Synthesis (synth_design)..."
synth_design -top mips32_top -part $PART_NAME -flatten_hierarchy rebuilt

# Write Post-Synthesis Netlist & Checkpoints
write_verilog -force $OUTPUT_DIR/mips32_post_synth_netlist.v
write_checkpoint -force $OUTPUT_DIR/post_synth.dcp

# Step 5: Run Optimization & Placement
puts "--> Running Logic Optimization (opt_design)..."
opt_design

puts "--> Running Placement (place_design)..."
place_design

puts "--> Running Routing (route_design)..."
route_design

# Step 6: Generate Performance & Utilization Reports
puts "--> Generating Utilization & Timing Reports..."
report_utilization -file $REPORT_DIR/utilization_report.txt
report_timing_summary -file $REPORT_DIR/timing_report.txt -max_paths 10
report_drc -file $REPORT_DIR/drc_report.txt

puts "=========================================================="
puts "  Vivado Synthesis Completed Successfully!                "
puts "  Reports saved to: $REPORT_DIR/                          "
puts "  Netlist saved to: $OUTPUT_DIR/mips32_post_synth_netlist.v"
puts "=========================================================="

exit
