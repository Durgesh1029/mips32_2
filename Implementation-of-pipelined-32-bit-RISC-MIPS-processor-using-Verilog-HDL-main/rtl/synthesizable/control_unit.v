// ============================================================================
// File: control_unit.v
// Project: Pipelined 32-bit RISC MIPS32 Processor
// Description: Synthesizable Control Unit for MIPS32 Instruction Decoding
// ============================================================================

module control_unit (
    input  wire [5:0] opcode,
    output reg  [2:0] inst_type,
    output reg        illegal_inst
);

    // Instruction Type Classifications
    parameter RR_ALU = 3'b000; // Register-Register ALU
    parameter RM_ALU = 3'b001; // Register-Immediate ALU
    parameter LOAD   = 3'b010; // Memory Load (LW)
    parameter STORE  = 3'b011; // Memory Store (SW)
    parameter BRANCH = 3'b100; // Conditional Branch (BEQZ, BNEQZ)
    parameter HALT   = 3'b101; // Halt Execution (HLT)

    // Opcode Encoding
    parameter ADD   = 6'b000000;
    parameter SUB   = 6'b000001;
    parameter AND   = 6'b000010;
    parameter OR    = 6'b000011;
    parameter SLT   = 6'b000100;
    parameter MUL   = 6'b000101;
    parameter LW    = 6'b001000;
    parameter SW    = 6'b001001;
    parameter ADDI  = 6'b001010;
    parameter SUBI  = 6'b001011;
    parameter SLTI  = 6'b001100;
    parameter BNEQZ = 6'b001101;
    parameter BEQZ  = 6'b001110;
    parameter HLT   = 6'b111111;

    always @(*) begin
        illegal_inst = 1'b0;
        case (opcode)
            ADD, SUB, AND, OR, SLT, MUL: inst_type = RR_ALU;
            ADDI, SUBI, SLTI:            inst_type = RM_ALU;
            LW:                          inst_type = LOAD;
            SW:                          inst_type = STORE;
            BNEQZ, BEQZ:                 inst_type = BRANCH;
            HLT:                         inst_type = HALT;
            default: begin
                inst_type = HALT;
                illegal_inst = 1'b1;
            end
        endcase
    end

endmodule
