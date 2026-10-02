// ============================================================================
// File: alu.v
// Project: Pipelined 32-bit RISC MIPS32 Processor
// Description: Synthesizable 32-bit Arithmetic Logic Unit (ALU)
// ============================================================================

module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [5:0]  op_code,
    output reg  [31:0] alu_out,
    output wire        zero_flag
);

    // MIPS32 Opcode Definitions
    parameter ADD   = 6'b000000;
    parameter SUB   = 6'b000001;
    parameter AND   = 6'b000010;
    parameter OR    = 6'b000011;
    parameter SLT   = 6'b000100;
    parameter MUL   = 6'b000101;
    parameter ADDI  = 6'b001010;
    parameter SUBI  = 6'b001011;
    parameter SLTI  = 6'b001100;
    parameter LW    = 6'b001000;
    parameter SW    = 6'b001001;

    always @(*) begin
        case (op_code)
            ADD, ADDI, LW, SW: alu_out = a + b;
            SUB, SUBI:        alu_out = a - b;
            AND:              alu_out = a & b;
            OR:               alu_out = a | b;
            SLT, SLTI:        alu_out = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            MUL:              alu_out = a * b;
            default:          alu_out = 32'h00000000;
        endcase
    end

    assign zero_flag = (a == 32'd0);

endmodule
