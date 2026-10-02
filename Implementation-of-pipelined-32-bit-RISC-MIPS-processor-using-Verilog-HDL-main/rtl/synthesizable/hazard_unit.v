// ============================================================================
// File: hazard_unit.v
// Project: Pipelined 32-bit RISC MIPS32 Processor
// Description: Data Forwarding and Hazard Detection Unit
//              Resolves Read-After-Write (RAW) data hazards by forwarding
//              ALU results from EX/MEM and MEM/WB stages to the EX stage.
// ============================================================================

module hazard_unit (
    input  wire [4:0] id_ex_rs,       // Source register 1 in EX stage
    input  wire [4:0] id_ex_rt,       // Source register 2 in EX stage
    input  wire [4:0] ex_mem_dest,    // Destination register in EX/MEM stage
    input  wire       ex_mem_regwrite,// Register write enable in EX/MEM stage
    input  wire [4:0] mem_wb_dest,    // Destination register in MEM/WB stage
    input  wire       mem_wb_regwrite,// Register write enable in MEM/WB stage
    output reg  [1:0] forward_a,      // Forwarding mux select for ALU Operand A
    output reg  [1:0] forward_b       // Forwarding mux select for ALU Operand B
);

    // Forwarding Mux Select Encoding:
    // 2'b00 : No Forwarding (Use register value from ID/EX)
    // 2'b10 : Forward from EX/MEM Stage (ALU Output)
    // 2'b01 : Forward from MEM/WB Stage (Memory Data or ALU Output)

    // Operand A Forwarding Logic
    always @(*) begin
        if (ex_mem_regwrite && (ex_mem_dest != 5'd0) && (ex_mem_dest == id_ex_rs)) begin
            forward_a = 2'b10; // EX/MEM Hazard
        end else if (mem_wb_regwrite && (mem_wb_dest != 5'd0) && (mem_wb_dest == id_ex_rs)) begin
            forward_a = 2'b01; // MEM/WB Hazard
        end else begin
            forward_a = 2'b00; // No Hazard
        end
    end

    // Operand B Forwarding Logic
    always @(*) begin
        if (ex_mem_regwrite && (ex_mem_dest != 5'd0) && (ex_mem_dest == id_ex_rt)) begin
            forward_b = 2'b10; // EX/MEM Hazard
        end else if (mem_wb_regwrite && (mem_wb_dest != 5'd0) && (mem_wb_dest == id_ex_rt)) begin
            forward_b = 2'b01; // MEM/WB Hazard
        end else begin
            forward_b = 2'b00; // No Hazard
        end
    end

endmodule
