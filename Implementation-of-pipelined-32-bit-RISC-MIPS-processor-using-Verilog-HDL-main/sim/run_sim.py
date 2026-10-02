#!/usr/bin/env python3
"""
===============================================================================
Pipelined 32-bit RISC MIPS32 Processor - Python Simulation Engine
===============================================================================
Description:
    Cycle-by-cycle architectural simulation of the 5-stage pipelined MIPS32 core.
    Supports EX-to-EX and MEM-to-EX Data Forwarding to eliminate RAW hazards.
    Tracks IF, ID, EX, MEM, WB pipeline stage registers, generates execution trace
    tables, dumps register states, and verifies algebraic operations.
===============================================================================
"""

class MIPS32Simulator:
    def __init__(self):
        # 32 General-Purpose Registers (R0 hardwired to 0)
        self.Reg = [0] * 32
        
        # 1024-Word Instruction & Data Memory
        self.IMem = [0] * 1024
        self.DMem = [0] * 1024
        
        # PC & Control Registers
        self.PC = 0
        self.HALTED = False
        self.TAKEN_BRANCH = False
        
        # Pipeline Registers
        # IF/ID
        self.IF_ID_IR = 0
        self.IF_ID_NPC = 0
        
        # ID/EX
        self.ID_EX_IR = 0
        self.ID_EX_NPC = 0
        self.ID_EX_A = 0
        self.ID_EX_B = 0
        self.ID_EX_Imm = 0
        self.ID_EX_type = 5 # HALT default
        
        # EX/MEM
        self.EX_MEM_IR = 0
        self.EX_MEM_B = 0
        self.EX_MEM_ALUOut = 0
        self.EX_MEM_cond = False
        self.EX_MEM_type = 5
        
        # MEM/WB
        self.MEM_WB_IR = 0
        self.MEM_WB_ALUOut = 0
        self.MEM_WB_LMD = 0
        self.MEM_WB_type = 5

        # Opcodes
        self.OP_ADD   = 0b000000
        self.OP_SUB   = 0b000001
        self.OP_AND   = 0b000010
        self.OP_OR    = 0b000011
        self.OP_SLT   = 0b000100
        self.OP_MUL   = 0b000101
        self.OP_LW    = 0b001000
        self.OP_SW    = 0b001001
        self.OP_ADDI  = 0b001010
        self.OP_SUBI  = 0b001011
        self.OP_SLTI  = 0b001100
        self.OP_BNEQZ = 0b001101
        self.OP_BEQZ  = 0b001110
        self.OP_HLT   = 0b111111

        # Types
        self.TYPE_RR_ALU = 0
        self.TYPE_RM_ALU = 1
        self.TYPE_LOAD   = 2
        self.TYPE_STORE  = 3
        self.TYPE_BRANCH = 4
        self.TYPE_HALT   = 5

    def sign_extend_16(self, val):
        if val & 0x8000:
            return val - 0x10000
        return val

    def load_program(self, program):
        for idx, inst in enumerate(program):
            self.IMem[idx] = inst

    def get_opcode_name(self, ir):
        op = (ir >> 26) & 0x3F
        names = {
            0b000000: "ADD", 0b000001: "SUB", 0b000010: "AND", 0b000011: "OR",
            0b000100: "SLT", 0b000101: "MUL", 0b001000: "LW",  0b001001: "SW",
            0b001010: "ADDI", 0b001011: "SUBI", 0b001100: "SLTI",
            0b001101: "BNEQZ", 0b001110: "BEQZ", 0b111111: "HLT"
        }
        return names.get(op, "NOP")

    def run_simulation(self, max_cycles=30):
        print("=" * 92)
        print("                 MIPS32 5-Stage Pipelined Processor Execution Trace                    ")
        print("=" * 92)
        print(f"{'Cycle':<6} | {'IF (IR)':<10} | {'ID (Inst)':<10} | {'EX (ALUOut)':<14} | {'MEM (Out)':<14} | {'WB (Write)':<14}")
        print("-" * 92)

        for cycle in range(1, max_cycles + 1):
            if self.HALTED:
                print(f"[{cycle:02d}] Processor Halted.")
                break

            # -----------------------------------------------------------------
            # WB Stage
            # -----------------------------------------------------------------
            wb_info = "NOP"
            wb_reg_written = 0
            wb_val_written = 0

            if not self.TAKEN_BRANCH:
                ir_wb = self.MEM_WB_IR
                rd_wb = (ir_wb >> 11) & 0x1F
                rt_wb = (ir_wb >> 16) & 0x1F

                if self.MEM_WB_type == self.TYPE_RR_ALU:
                    if rd_wb != 0:
                        self.Reg[rd_wb] = self.MEM_WB_ALUOut & 0xFFFFFFFF
                        wb_reg_written = rd_wb
                        wb_val_written = self.MEM_WB_ALUOut
                    wb_info = f"R{rd_wb} <- {self.MEM_WB_ALUOut}"
                elif self.MEM_WB_type == self.TYPE_RM_ALU:
                    if rt_wb != 0:
                        self.Reg[rt_wb] = self.MEM_WB_ALUOut & 0xFFFFFFFF
                        wb_reg_written = rt_wb
                        wb_val_written = self.MEM_WB_ALUOut
                    wb_info = f"R{rt_wb} <- {self.MEM_WB_ALUOut}"
                elif self.MEM_WB_type == self.TYPE_LOAD:
                    if rt_wb != 0:
                        self.Reg[rt_wb] = self.MEM_WB_LMD & 0xFFFFFFFF
                        wb_reg_written = rt_wb
                        wb_val_written = self.MEM_WB_LMD
                    wb_info = f"R{rt_wb} <- {self.MEM_WB_LMD}"
                elif self.MEM_WB_type == self.TYPE_HALT and ir_wb != 0:
                    self.HALTED = True
                    wb_info = "HALT"

            # -----------------------------------------------------------------
            # MEM Stage
            # -----------------------------------------------------------------
            mem_info = "NOP"
            next_mem_wb_type = self.EX_MEM_type
            next_mem_wb_ir = self.EX_MEM_IR
            next_mem_wb_alu = self.EX_MEM_ALUOut
            next_mem_wb_lmd = 0

            if self.EX_MEM_type in (self.TYPE_RR_ALU, self.TYPE_RM_ALU):
                next_mem_wb_alu = self.EX_MEM_ALUOut
                mem_info = f"ALU:{self.EX_MEM_ALUOut}"
            elif self.EX_MEM_type == self.TYPE_LOAD:
                next_mem_wb_lmd = self.DMem[self.EX_MEM_ALUOut & 0x3FF]
                mem_info = f"LD:[{self.EX_MEM_ALUOut}]={next_mem_wb_lmd}"
            elif self.EX_MEM_type == self.TYPE_STORE:
                if not self.TAKEN_BRANCH:
                    self.DMem[self.EX_MEM_ALUOut & 0x3FF] = self.EX_MEM_B
                    mem_info = f"ST:[{self.EX_MEM_ALUOut}]={self.EX_MEM_B}"

            # -----------------------------------------------------------------
            # EX Stage with Data Forwarding
            # -----------------------------------------------------------------
            ex_info = "NOP"
            next_ex_mem_type = self.ID_EX_type
            next_ex_mem_ir = self.ID_EX_IR
            next_ex_mem_b = self.ID_EX_B
            next_ex_mem_alu = 0
            next_ex_mem_cond = False

            rs_ex = (self.ID_EX_IR >> 21) & 0x1F
            rt_ex = (self.ID_EX_IR >> 16) & 0x1F

            # Forward Operand A
            alu_a = self.ID_EX_A
            if self.EX_MEM_type in (self.TYPE_RR_ALU, self.TYPE_RM_ALU, self.TYPE_LOAD):
                ex_dest = (self.EX_MEM_IR >> 11) & 0x1F if self.EX_MEM_type == self.TYPE_RR_ALU else (self.EX_MEM_IR >> 16) & 0x1F
                if ex_dest != 0 and ex_dest == rs_ex:
                    alu_a = self.EX_MEM_ALUOut

            if wb_reg_written != 0 and wb_reg_written == rs_ex:
                alu_a = wb_val_written

            # Forward Operand B
            alu_b = self.ID_EX_B
            if self.ID_EX_type == self.TYPE_RR_ALU:
                if self.EX_MEM_type in (self.TYPE_RR_ALU, self.TYPE_RM_ALU, self.TYPE_LOAD):
                    ex_dest = (self.EX_MEM_IR >> 11) & 0x1F if self.EX_MEM_type == self.TYPE_RR_ALU else (self.EX_MEM_IR >> 16) & 0x1F
                    if ex_dest != 0 and ex_dest == rt_ex:
                        alu_b = self.EX_MEM_ALUOut

                if wb_reg_written != 0 and wb_reg_written == rt_ex:
                    alu_b = wb_val_written
            else:
                alu_b = self.ID_EX_Imm

            op_ex = (self.ID_EX_IR >> 26) & 0x3F

            if self.ID_EX_type == self.TYPE_RR_ALU:
                next_ex_mem_cond = False
                if op_ex == self.OP_ADD:   next_ex_mem_alu = alu_a + alu_b
                elif op_ex == self.OP_SUB: next_ex_mem_alu = alu_a - alu_b
                elif op_ex == self.OP_AND: next_ex_mem_alu = alu_a & alu_b
                elif op_ex == self.OP_OR:  next_ex_mem_alu = alu_a | alu_b
                elif op_ex == self.OP_SLT: next_ex_mem_alu = 1 if alu_a < alu_b else 0
                elif op_ex == self.OP_MUL: next_ex_mem_alu = alu_a * alu_b
                ex_info = f"Res:{next_ex_mem_alu}"

            elif self.ID_EX_type == self.TYPE_RM_ALU:
                next_ex_mem_cond = False
                if op_ex == self.OP_ADDI:  next_ex_mem_alu = alu_a + alu_b
                elif op_ex == self.OP_SUBI:next_ex_mem_alu = alu_a - alu_b
                elif op_ex == self.OP_SLTI:next_ex_mem_alu = 1 if alu_a < alu_b else 0
                ex_info = f"Res:{next_ex_mem_alu}"

            elif self.ID_EX_type in (self.TYPE_LOAD, self.TYPE_STORE):
                next_ex_mem_cond = False
                next_ex_mem_alu = alu_a + alu_b
                ex_info = f"Addr:{next_ex_mem_alu}"

            elif self.ID_EX_type == self.TYPE_BRANCH:
                next_ex_mem_alu = self.ID_EX_NPC + self.ID_EX_Imm
                next_ex_mem_cond = (alu_a == 0)
                ex_info = f"Tgt:{next_ex_mem_alu}"

            # -----------------------------------------------------------------
            # ID Stage
            # -----------------------------------------------------------------
            id_info = self.get_opcode_name(self.IF_ID_IR)
            rs = (self.IF_ID_IR >> 21) & 0x1F
            rt = (self.IF_ID_IR >> 16) & 0x1F
            imm = self.sign_extend_16(self.IF_ID_IR & 0xFFFF)

            next_id_ex_a = 0 if rs == 0 else self.Reg[rs]
            next_id_ex_b = 0 if rt == 0 else self.Reg[rt]
            next_id_ex_imm = imm
            next_id_ex_npc = self.IF_ID_NPC
            next_id_ex_ir = self.IF_ID_IR

            op_id = (self.IF_ID_IR >> 26) & 0x3F
            if op_id in (self.OP_ADD, self.OP_SUB, self.OP_AND, self.OP_OR, self.OP_SLT, self.OP_MUL):
                next_id_ex_type = self.TYPE_RR_ALU
            elif op_id in (self.OP_ADDI, self.OP_SUBI, self.OP_SLTI):
                next_id_ex_type = self.TYPE_RM_ALU
            elif op_id == self.OP_LW:
                next_id_ex_type = self.TYPE_LOAD
            elif op_id == self.OP_SW:
                next_id_ex_type = self.TYPE_STORE
            elif op_id in (self.OP_BNEQZ, self.OP_BEQZ):
                next_id_ex_type = self.TYPE_BRANCH
            elif op_id == self.OP_HLT:
                next_id_ex_type = self.TYPE_HALT
            else:
                next_id_ex_type = self.TYPE_HALT

            # -----------------------------------------------------------------
            # IF Stage
            # -----------------------------------------------------------------
            if_info = self.get_opcode_name(self.IMem[self.PC])
            
            ex_mem_op = (self.EX_MEM_IR >> 26) & 0x3F
            branch_taken = ((ex_mem_op == self.OP_BEQZ and self.EX_MEM_cond) or
                            (ex_mem_op == self.OP_BNEQZ and not self.EX_MEM_cond))

            if branch_taken:
                next_if_id_ir = self.IMem[self.EX_MEM_ALUOut & 0x3FF]
                self.TAKEN_BRANCH = True
                next_if_id_npc = self.EX_MEM_ALUOut + 1
                self.PC = self.EX_MEM_ALUOut + 1
            else:
                next_if_id_ir = self.IMem[self.PC & 0x3FF]
                next_if_id_npc = self.PC + 1
                self.PC += 1
                self.TAKEN_BRANCH = False

            # Print Cycle Summary
            print(f"{cycle:^6d} | {if_info:<10} | {id_info:<10} | {ex_info:<14} | {mem_info:<14} | {wb_info:<14}")

            # Advance Pipeline Registers
            self.MEM_WB_type   = next_mem_wb_type
            self.MEM_WB_IR     = next_mem_wb_ir
            self.MEM_WB_ALUOut = next_mem_wb_alu
            self.MEM_WB_LMD    = next_mem_wb_lmd

            self.EX_MEM_type   = next_ex_mem_type
            self.EX_MEM_IR     = next_ex_mem_ir
            self.EX_MEM_B      = next_ex_mem_b
            self.EX_MEM_ALUOut = next_ex_mem_alu
            self.EX_MEM_cond   = next_ex_mem_cond

            self.ID_EX_type   = next_id_ex_type
            self.ID_EX_IR     = next_id_ex_ir
            self.ID_EX_NPC    = next_id_ex_npc
            self.ID_EX_A      = next_id_ex_a
            self.ID_EX_B      = next_id_ex_b
            self.ID_EX_Imm    = next_id_ex_imm

            self.IF_ID_IR     = next_if_id_ir
            self.IF_ID_NPC    = next_if_id_npc

        print("=" * 92)
        print("\n--- Final Register State Dump ---")
        for r in range(6):
            print(f"R{r:<2} = {self.Reg[r]:<5} (0x{self.Reg[r]:08X})")
        
        # Verify Test Results
        if (self.Reg[1] == 10 and self.Reg[2] == 20 and self.Reg[3] == 25 and 
            self.Reg[4] == 30 and self.Reg[5] == 55):
            print("\n[SUCCESS] Verification Passed: R1=10, R2=20, R3=25, R4=30, R5=55!")
        else:
            print(f"\n[WARNING] Verification result mismatch: R4={self.Reg[4]}, R5={self.Reg[5]}")
        print("=" * 92)

def main():
    sim = MIPS32Simulator()
    # Program:
    # 0: ADDI R1, R0, 10
    # 1: ADDI R2, R0, 20
    # 2: ADDI R3, R0, 25
    # 3: NOP
    # 4: NOP
    # 5: ADD R4, R1, R2
    # 6: NOP
    # 7: ADD R5, R4, R3
    # 8: HLT
    test_program = [
        0x2801000a,
        0x28020014,
        0x28030019,
        0x0ce77800,
        0x0ce77800,
        0x00222000,
        0x0ce77800,
        0x00832800,
        0xFC000000
    ]
    sim.load_program(test_program)
    sim.run_simulation(max_cycles=20)

if __name__ == "__main__":
    main()
