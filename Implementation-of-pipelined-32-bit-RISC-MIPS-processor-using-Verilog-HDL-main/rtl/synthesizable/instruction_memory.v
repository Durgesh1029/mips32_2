// ============================================================================
// File: instruction_memory.v
// Project: Pipelined 32-bit RISC MIPS32 Processor
// Description: Synthesizable 1024-Word Instruction Memory (ROM/RAM)
// ============================================================================

module instruction_memory #(
    parameter MEM_SIZE = 1024
)(
    input  wire        clk,
    input  wire [31:0] pc,
    output wire [31:0] instruction
);

    reg [31:0] imem [0:MEM_SIZE-1];

    // Asynchronous read for word-addressed PC
    assign instruction = imem[pc[9:0]];

endmodule
