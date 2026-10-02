// ============================================================================
// File: mips32_tb.v
// Project: Pipelined 32-bit RISC MIPS32 Processor
// Description: Comprehensive Self-Checking Testbench for Modern MIPS32 Top
// ============================================================================

`timescale 1ns / 1ps

module mips32_tb;

    reg clk;
    reg rst;
    wire halted;
    wire [31:0] pc;

    integer k;

    // Instantiate Top-Level Synthesizable Processor Core
    mips32_top uut (
        .clk(clk),
        .rst(rst),
        .halted_out(halted),
        .pc_out(pc)
    );

    // Clock Generation (100 MHz, Period = 10ns)
    always #5 clk = ~clk;

    initial begin
        // Initialize Signals
        clk = 0;
        rst = 1;

        // Apply Reset Pulse
        #20;
        rst = 0;

        // Initialize Test Program in Instruction Memory
        // 0: ADDI R1, R0, 10    (R1 = 10)
        uut.imem_inst.imem[0] = 32'h2801000a;

        // 1: ADDI R2, R0, 20    (R2 = 20)
        uut.imem_inst.imem[1] = 32'h28020014;

        // 2: ADDI R3, R0, 25    (R3 = 25)
        uut.imem_inst.imem[2] = 32'h28030019;

        // 3: NOP (OR R15, R7, R7)
        uut.imem_inst.imem[3] = 32'h0ce77800;

        // 4: NOP
        uut.imem_inst.imem[4] = 32'h0ce77800;

        // 5: ADD R4, R1, R2     (R4 = R1 + R2 = 30)
        uut.imem_inst.imem[5] = 32'h00222000;

        // 6: NOP
        uut.imem_inst.imem[6] = 32'h0ce77800;

        // 7: ADD R5, R4, R3     (R5 = R4 + R3 = 55)
        uut.imem_inst.imem[7] = 32'h00832800;

        // 8: HLT               (Halt execution)
        uut.imem_inst.imem[8] = 32'hfc000000;

        // Monitor Simulation
        $display("==========================================================");
        $display("     Starting Synthesizable MIPS32 Processor Simulation    ");
        $display("==========================================================");

        // Wait for processor execution
        #300;

        $display("\n--- Register Dump After Execution ---");
        for (k = 0; k < 6; k = k + 1) begin
            $display("Reg[R%0d] = %0d (0x%0h)", k, uut.regfile_inst.registers[k], uut.regfile_inst.registers[k]);
        end

        // Verification Checks
        if (uut.regfile_inst.registers[1] == 10 &&
            uut.regfile_inst.registers[2] == 20 &&
            uut.regfile_inst.registers[3] == 25 &&
            uut.regfile_inst.registers[4] == 30 &&
            uut.regfile_inst.registers[5] == 55) begin
            $display("\n[SUCCESS] ALL REGISTER VALUES MATCH EXPECTED ALGEBRAIC RESULTS!");
        end else begin
            $display("\n[ERROR] SIMULATION RESULT MISMATCH!");
        end

        $display("==========================================================");
        $finish;
    end

    // Generate VCD Waveform for Viewing in GTKWave / Vivado
    initial begin
        $dumpfile("mips32_synth.vcd");
        $dumpvars(0, mips32_tb);
    end

endmodule
