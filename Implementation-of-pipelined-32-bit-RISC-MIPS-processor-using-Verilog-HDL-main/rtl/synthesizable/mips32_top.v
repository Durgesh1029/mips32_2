// ============================================================================
// File: mips32_top.v
// Project: Pipelined 32-bit RISC MIPS32 Processor
// Description: Top-Level Synthesizable 5-Stage Pipelined MIPS32 Core
//              Includes Hazard Detection & Data Forwarding Unit
// ============================================================================

module mips32_top (
    input  wire        clk,
    input  wire        rst,
    output wire        halted_out,
    output wire [31:0] pc_out
);

    // ------------------------------------------------------------------------
    // Internal Registers & Signals
    // ------------------------------------------------------------------------
    reg  [31:0] pc;
    reg         halted;
    wire        taken_branch;

    // IF Stage Wires
    wire [31:0] if_ir;
    wire [31:0] if_npc;

    // IF/ID Register Wires
    wire [31:0] if_id_ir;
    wire [31:0] if_id_npc;

    // ID Stage Wires
    wire [31:0] id_a;
    wire [31:0] id_b;
    wire [31:0] id_imm;
    wire [2:0]  id_type;
    wire        illegal_inst;

    // ID/EX Register Wires
    wire [31:0] id_ex_ir;
    wire [31:0] id_ex_npc;
    wire [31:0] id_ex_a;
    wire [31:0] id_ex_b;
    wire [31:0] id_ex_imm;
    wire [2:0]  id_ex_type;

    // EX Stage Wires & Forwarding
    wire [1:0]  forward_a;
    wire [1:0]  forward_b;
    reg  [31:0] ex_alu_a_in;
    reg  [31:0] ex_alu_b_in;
    wire [31:0] ex_alu_out;
    wire        ex_zero_flag;
    reg  [31:0] ex_alu_result;
    reg         ex_cond;

    // EX/MEM Register Wires
    wire [31:0] ex_mem_ir;
    wire [31:0] ex_mem_b;
    wire [31:0] ex_mem_alu_out;
    wire        ex_mem_cond;
    wire [2:0]  ex_mem_type;

    // MEM Stage Wires
    wire [31:0] mem_lmd;
    wire        mem_write_en;
    wire        mem_read_en;

    // MEM/WB Register Wires
    wire [31:0] mem_wb_ir;
    wire [31:0] mem_wb_alu_out;
    wire [31:0] mem_wb_lmd;
    wire [2:0]  mem_wb_type;

    // WB Stage Wires
    reg  [4:0]  wb_reg_addr;
    reg  [31:0] wb_reg_data;
    reg         wb_reg_write_en;

    // Forwarding Destination Wires
    reg  [4:0]  ex_mem_dest;
    reg         ex_mem_regwrite;
    reg  [4:0]  mem_wb_dest;
    reg         mem_wb_regwrite;

    // Opcodes & Instruction Types
    parameter ADD   = 6'b000000, SUB   = 6'b000001, AND   = 6'b000010, OR    = 6'b000011;
    parameter SLT   = 6'b000100, MUL   = 6'b000101, HLT   = 6'b111111;
    parameter LW    = 6'b001000, SW    = 6'b001001;
    parameter ADDI  = 6'b001010, SUBI  = 6'b001011, SLTI  = 6'b001100;
    parameter BNEQZ = 6'b001101, BEQZ  = 6'b001110;

    parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011, BRANCH = 3'b100, HALT = 3'b101;

    assign halted_out = halted;
    assign pc_out     = pc;

    // Branch Taken Logic
    assign taken_branch = ((ex_mem_ir[31:26] == BEQZ  &&  ex_mem_cond) ||
                           (ex_mem_ir[31:26] == BNEQZ && !ex_mem_cond));

    // ========================================================================
    // STAGE 1: INSTRUCTION FETCH (IF)
    // ========================================================================
    always @(posedge clk) begin
        if (rst) begin
            pc     <= 32'd0;
            halted <= 1'b0;
        end else if (!halted) begin
            if (taken_branch) begin
                pc <= ex_mem_alu_out + 32'd1;
            end else begin
                pc <= pc + 32'd1;
            end

            if (mem_wb_type == HALT && mem_wb_ir != 32'd0) begin
                halted <= 1'b1;
            end
        end
    end

    assign if_npc = (taken_branch) ? (ex_mem_alu_out + 32'd1) : (pc + 32'd1);

    instruction_memory imem_inst (
        .clk(clk),
        .pc(pc),
        .instruction(if_ir)
    );

    if_id_reg if_id_inst (
        .clk(clk),
        .rst(rst),
        .flush(taken_branch),
        .in_ir(if_ir),
        .in_npc(if_npc),
        .out_ir(if_id_ir),
        .out_npc(if_id_npc)
    );

    // ========================================================================
    // STAGE 2: INSTRUCTION DECODE & REGISTER FETCH (ID)
    // ========================================================================
    control_unit control_inst (
        .opcode(if_id_ir[31:26]),
        .inst_type(id_type),
        .illegal_inst(illegal_inst)
    );

    register_file regfile_inst (
        .clk(clk),
        .rst(rst),
        .read_reg1(if_id_ir[25:21]), // rs
        .read_reg2(if_id_ir[20:16]), // rt (Fixed bug: previously read rs twice)
        .write_reg(wb_reg_addr),
        .write_data(wb_reg_data),
        .write_en(wb_reg_write_en),
        .read_data1(id_a),
        .read_data2(id_b)
    );

    assign id_imm = {{16{if_id_ir[15]}}, if_id_ir[15:0]};

    id_ex_reg id_ex_inst (
        .clk(clk),
        .rst(rst),
        .in_ir(if_id_ir),
        .in_npc(if_id_npc),
        .in_a(id_a),
        .in_b(id_b),
        .in_imm(id_imm),
        .in_type(id_type),
        .out_ir(id_ex_ir),
        .out_npc(id_ex_npc),
        .out_a(id_ex_a),
        .out_b(id_ex_b),
        .out_imm(id_ex_imm),
        .out_type(id_ex_type)
    );

    // ========================================================================
    // HAZARD DETECTION & DATA FORWARDING DECODING
    // ========================================================================
    always @(*) begin
        // EX/MEM Register Write & Destination
        if (ex_mem_type == RR_ALU) begin
            ex_mem_dest     = ex_mem_ir[15:11];
            ex_mem_regwrite = 1'b1;
        end else if (ex_mem_type == RM_ALU || ex_mem_type == LOAD) begin
            ex_mem_dest     = ex_mem_ir[20:16];
            ex_mem_regwrite = 1'b1;
        end else begin
            ex_mem_dest     = 5'd0;
            ex_mem_regwrite = 1'b0;
        end

        // MEM/WB Register Write & Destination
        if (mem_wb_type == RR_ALU) begin
            mem_wb_dest     = mem_wb_ir[15:11];
            mem_wb_regwrite = 1'b1;
        end else if (mem_wb_type == RM_ALU || mem_wb_type == LOAD) begin
            mem_wb_dest     = mem_wb_ir[20:16];
            mem_wb_regwrite = 1'b1;
        end else begin
            mem_wb_dest     = 5'd0;
            mem_wb_regwrite = 1'b0;
        end
    end

    hazard_unit hazard_inst (
        .id_ex_rs(id_ex_ir[25:21]),
        .id_ex_rt(id_ex_ir[20:16]),
        .ex_mem_dest(ex_mem_dest),
        .ex_mem_regwrite(ex_mem_regwrite),
        .mem_wb_dest(mem_wb_dest),
        .mem_wb_regwrite(mem_wb_regwrite),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // ========================================================================
    // STAGE 3: EXECUTION (EX)
    // ========================================================================
    always @(*) begin
        // Operand A Forwarding Mux
        case (forward_a)
            2'b10:   ex_alu_a_in = ex_mem_alu_out;
            2'b01:   ex_alu_a_in = wb_reg_data;
            default: ex_alu_a_in = id_ex_a;
        endcase

        // Operand B Forwarding Mux
        if (id_ex_type == RR_ALU) begin
            case (forward_b)
                2'b10:   ex_alu_b_in = ex_mem_alu_out;
                2'b01:   ex_alu_b_in = wb_reg_data;
                default: ex_alu_b_in = id_ex_b;
            endcase
        end else begin
            ex_alu_b_in = id_ex_imm;
        end
    end

    alu alu_inst (
        .a(ex_alu_a_in),
        .b(ex_alu_b_in),
        .op_code(id_ex_ir[31:26]),
        .alu_out(ex_alu_out),
        .zero_flag(ex_zero_flag)
    );

    always @(*) begin
        if (id_ex_type == BRANCH) begin
            ex_alu_result = id_ex_npc + id_ex_imm;
            ex_cond       = (ex_alu_a_in == 32'd0);
        end else begin
            ex_alu_result = ex_alu_out;
            ex_cond       = 1'b0;
        end
    end

    ex_mem_reg ex_mem_inst (
        .clk(clk),
        .rst(rst),
        .in_ir(id_ex_ir),
        .in_b(id_ex_b),
        .in_alu_out(ex_alu_result),
        .in_cond(ex_cond),
        .in_type(id_ex_type),
        .out_ir(ex_mem_ir),
        .out_b(ex_mem_b),
        .out_alu_out(ex_mem_alu_out),
        .out_cond(ex_mem_cond),
        .out_type(ex_mem_type)
    );

    // ========================================================================
    // STAGE 4: MEMORY ACCESS (MEM)
    // ========================================================================
    assign mem_write_en = (ex_mem_type == STORE) && (!taken_branch);
    assign mem_read_en  = (ex_mem_type == LOAD);

    data_memory dmem_inst (
        .clk(clk),
        .rst(rst),
        .addr(ex_mem_alu_out),
        .write_data(ex_mem_b),
        .mem_write(mem_write_en),
        .mem_read(mem_read_en),
        .read_data(mem_lmd)
    );

    mem_wb_reg mem_wb_inst (
        .clk(clk),
        .rst(rst),
        .in_ir(ex_mem_ir),
        .in_alu_out(ex_mem_alu_out),
        .in_lmd(mem_lmd),
        .in_type(ex_mem_type),
        .out_ir(mem_wb_ir),
        .out_alu_out(mem_wb_alu_out),
        .out_lmd(mem_wb_lmd),
        .out_type(mem_wb_type)
    );

    // ========================================================================
    // STAGE 5: WRITE BACK (WB)
    // ========================================================================
    always @(*) begin
        wb_reg_write_en = 1'b0;
        wb_reg_addr     = 5'd0;
        wb_reg_data     = 32'd0;

        if (!taken_branch) begin
            case (mem_wb_type)
                RR_ALU: begin
                    wb_reg_write_en = 1'b1;
                    wb_reg_addr     = mem_wb_ir[15:11]; // rd
                    wb_reg_data     = mem_wb_alu_out;
                end
                RM_ALU: begin
                    wb_reg_write_en = 1'b1;
                    wb_reg_addr     = mem_wb_ir[20:16]; // rt
                    wb_reg_data     = mem_wb_alu_out;
                end
                LOAD: begin
                    wb_reg_write_en = 1'b1;
                    wb_reg_addr     = mem_wb_ir[20:16]; // rt
                    wb_reg_data     = mem_wb_lmd;
                end
                default: begin
                    wb_reg_write_en = 1'b0;
                end
            endcase
        end
    end

endmodule
