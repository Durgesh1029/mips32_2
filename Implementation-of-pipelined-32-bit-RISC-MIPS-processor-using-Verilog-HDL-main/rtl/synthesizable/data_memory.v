// ============================================================================
// File: data_memory.v
// Project: Pipelined 32-bit RISC MIPS32 Processor
// Description: Synthesizable 1024-Word Data Memory (RAM)
// ============================================================================

module data_memory #(
    parameter MEM_SIZE = 1024
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire        mem_write,
    input  wire        mem_read,
    output wire [31:0] read_data
);

    reg [31:0] dmem [0:MEM_SIZE-1];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                dmem[i] <= 32'd0;
            end
        end else if (mem_write) begin
            dmem[addr[9:0]] <= write_data;
        end
    end

    assign read_data = (mem_read) ? dmem[addr[9:0]] : 32'd0;

endmodule
