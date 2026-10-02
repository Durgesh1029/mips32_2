// ============================================================================
// File: register_file.v
// Project: Pipelined 32-bit RISC MIPS32 Processor
// Description: Synthesizable 32x32 Register File with Internal WB Forwarding
// ============================================================================

module register_file (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  read_reg1,  // rs address
    input  wire [4:0]  read_reg2,  // rt address
    input  wire [4:0]  write_reg,  // rd/rt write address
    input  wire [31:0] write_data, // Data to write
    input  wire        write_en,   // Write enable signal
    output wire [31:0] read_data1, // rs read data
    output wire [31:0] read_data2  // rt read data
);

    reg [31:0] registers [0:31];
    integer i;

    // Synchronous Reset & Write Operation
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end else if (write_en && (write_reg != 5'd0)) begin
            registers[write_reg] <= write_data;
        end
    end

    // Asynchronous Read Ports with R0 hardwired to 0 & Internal Write-Through Forwarding
    assign read_data1 = (read_reg1 == 5'd0) ? 32'd0 :
                        (write_en && (read_reg1 == write_reg)) ? write_data :
                        registers[read_reg1];

    assign read_data2 = (read_reg2 == 5'd0) ? 32'd0 :
                        (write_en && (read_reg2 == write_reg)) ? write_data :
                        registers[read_reg2];

endmodule
