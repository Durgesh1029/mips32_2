// ============================================================================
// File: pipeline_registers.v
// Project: Pipelined 32-bit RISC MIPS32 Processor
// Description: Synthesizable Inter-Stage Pipeline Registers
//              (IF/ID, ID/EX, EX/MEM, MEM/WB)
// ============================================================================

// ----------------------------------------------------------------------------
// IF/ID Pipeline Register
// ----------------------------------------------------------------------------
module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,
    input  wire [31:0] in_ir,
    input  wire [31:0] in_npc,
    output reg  [31:0] out_ir,
    output reg  [31:0] out_npc
);
    always @(posedge clk) begin
        if (rst || flush) begin
            out_ir  <= 32'd0;
            out_npc <= 32'd0;
        end else begin
            out_ir  <= in_ir;
            out_npc <= in_npc;
        end
    end
endmodule

// ----------------------------------------------------------------------------
// ID/EX Pipeline Register
// ----------------------------------------------------------------------------
module id_ex_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] in_ir,
    input  wire [31:0] in_npc,
    input  wire [31:0] in_a,
    input  wire [31:0] in_b,
    input  wire [31:0] in_imm,
    input  wire [2:0]  in_type,
    output reg  [31:0] out_ir,
    output reg  [31:0] out_npc,
    output reg  [31:0] out_a,
    output reg  [31:0] out_b,
    output reg  [31:0] out_imm,
    output reg  [2:0]  out_type
);
    always @(posedge clk) begin
        if (rst) begin
            out_ir   <= 32'd0;
            out_npc  <= 32'd0;
            out_a    <= 32'd0;
            out_b    <= 32'd0;
            out_imm  <= 32'd0;
            out_type <= 3'd5; // HALT default
        end else begin
            out_ir   <= in_ir;
            out_npc  <= in_npc;
            out_a    <= in_a;
            out_b    <= in_b;
            out_imm  <= in_imm;
            out_type <= in_type;
        end
    end
endmodule

// ----------------------------------------------------------------------------
// EX/MEM Pipeline Register
// ----------------------------------------------------------------------------
module ex_mem_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] in_ir,
    input  wire [31:0] in_b,
    input  wire [31:0] in_alu_out,
    input  wire        in_cond,
    input  wire [2:0]  in_type,
    output reg  [31:0] out_ir,
    output reg  [31:0] out_b,
    output reg  [31:0] out_alu_out,
    output reg         out_cond,
    output reg  [2:0]  out_type
);
    always @(posedge clk) begin
        if (rst) begin
            out_ir      <= 32'd0;
            out_b       <= 32'd0;
            out_alu_out <= 32'd0;
            out_cond    <= 1'b0;
            out_type    <= 3'd5; // HALT default
        end else begin
            out_ir      <= in_ir;
            out_b       <= in_b;
            out_alu_out <= in_alu_out;
            out_cond    <= in_cond;
            out_type    <= in_type;
        end
    end
endmodule

// ----------------------------------------------------------------------------
// MEM/WB Pipeline Register
// ----------------------------------------------------------------------------
module mem_wb_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] in_ir,
    input  wire [31:0] in_alu_out,
    input  wire [31:0] in_lmd,
    input  wire [2:0]  in_type,
    output reg  [31:0] out_ir,
    output reg  [31:0] out_alu_out,
    output reg  [31:0] out_lmd,
    output reg  [2:0]  out_type
);
    always @(posedge clk) begin
        if (rst) begin
            out_ir      <= 32'd0;
            out_alu_out <= 32'd0;
            out_lmd     <= 32'd0;
            out_type    <= 3'd5; // HALT default
        end else begin
            out_ir      <= in_ir;
            out_alu_out <= in_alu_out;
            out_lmd     <= in_lmd;
            out_type    <= in_type;
        end
    end
endmodule
