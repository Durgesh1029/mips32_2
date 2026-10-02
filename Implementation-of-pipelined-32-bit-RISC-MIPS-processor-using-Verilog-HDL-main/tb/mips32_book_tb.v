// ============================================================================
// File: mips32_book_tb.v
// Project: Pipelined 32-bit RISC MIPS32 Processor
// Reference: verilog_isg.pdf & coa_mearged_isg.pdf
// Description: Legacy 2-Phase Clock Testbench for original ISG book model
// ============================================================================

`timescale 1ns / 1ps

module mips32_book_tb;

    reg clk1, clk2;
    integer k;

    pipe_MIPS32_book mips (
        .clk1(clk1),
        .clk2(clk2)
    );

    // 2-Phase Non-Overlapping Clock Generator
    initial begin
        clk1 = 0; clk2 = 0;
        repeat (25) begin
            #5 clk1 = 1; #5 clk1 = 0;
            #5 clk2 = 1; #5 clk2 = 0;
        end
    end

    // Memory & Register Initialization
    initial begin
        for (k = 0; k < 32; k = k + 1)
            mips.Reg[k] = k;

        // Load instructions:
        // 0: ADDI R1, R0, 10
        // 1: ADDI R2, R0, 20
        // 2: ADDI R3, R0, 25
        // 3: NOP
        // 4: NOP
        // 5: ADD R4, R1, R2
        // 6: NOP
        // 7: ADD R5, R4, R3
        // 8: HLT
        mips.Mem[0] = 32'h2801000a;
        mips.Mem[1] = 32'h28020014;
        mips.Mem[2] = 32'h28030019;
        mips.Mem[3] = 32'h0ce77800;
        mips.Mem[4] = 32'h0ce77800;
        mips.Mem[5] = 32'h00222000;
        mips.Mem[6] = 32'h0ce77800;
        mips.Mem[7] = 32'h00832800;
        mips.Mem[8] = 32'hfc000000;
    end

    initial begin
        mips.HALTED = 0;
        mips.PC = 0;
        mips.TAKEN_BRANCH = 0;
    end

    initial begin
        #280;
        $display("=== Legacy 2-Phase Clock MIPS32 Output ===");
        for (k = 0; k < 6; k = k + 1)
            $display("R%1d = %2d", k, mips.Reg[k]);
    end

    initial begin
        $dumpfile("mips32_legacy.vcd");
        $dumpvars(0, mips32_book_tb);
    end

endmodule
