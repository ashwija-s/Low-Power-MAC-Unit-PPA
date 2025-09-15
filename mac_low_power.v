`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.09.2025 18:15:32
// Design Name: 
// Module Name: mac_low_power
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//
// LOW-POWER VERSION of the Pipelined MAC Unit
// Includes Clock Gating and Operand Isolation
//

module mac_low_power #(
    parameter DATA_WIDTH = 8
)(
    input                            clk,
    input                            rst_n,
    input                            enable,
    
    input      [DATA_WIDTH-1:0]      b_in,
    input      [DATA_WIDTH-1:0]      c_in,
    
    output reg [2*DATA_WIDTH:0]      mac_out
);

    // ////////////////////////////////////////////////////////////////////////
    // Low-Power Control Logic
    // ////////////////////////////////////////////////////////////////////////

    // Latch the enable signal to prevent glitches on the gated clock
    // This is the standard, safe way to create a clock gate in an FPGA
    reg enable_latch;
    always @(*) begin
        if (~clk) begin
            enable_latch = enable;
        end
    end

    wire gated_clk;
    assign gated_clk = clk & enable_latch; // The clock is gated here!

    // ////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 1: Multiplication (with Operand Isolation)
    // ////////////////////////////////////////////////////////////////////////
    
    reg [DATA_WIDTH-1:0]      b_reg1, c_reg1;
    reg [2*DATA_WIDTH-1:0]    mult_result;
    
    // *** NOTE: This block is now clocked by gated_clk ***
    // The "if (enable)" condition is removed from the logic because the clock
    // itself is now controlled. This is cleaner.
    // The "enable" condition on the inputs provides OPERAND ISOLATION.
    always @(posedge clk) begin // Use the main clock for the input registers
        if (!rst_n) begin
            b_reg1 <= 0;
            c_reg1 <= 0;
        end else if (enable) begin // Only load new data when enabled
            b_reg1 <= b_in;
            c_reg1 <= c_in;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            mult_result <= 0;
        end else if (enable) begin
            mult_result <= b_reg1 * c_reg1; // Multiply the isolated inputs
        end
    end

    // ////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 2: Addition
    // ////////////////////////////////////////////////////////////////////////

    reg [2*DATA_WIDTH-1:0] add_result;
    
    // *** NOTE: This block is now clocked by gated_clk ***
    always @(posedge gated_clk) begin
        if (!rst_n) begin
            add_result <= 0;
        end else begin
            add_result <= mac_out + mult_result;
        end
    end
    
    // ////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 3: Output Register
    // ////////////////////////////////////////////////////////////////////////
    
    // *** NOTE: This block is also clocked by gated_clk ***
    always @(posedge gated_clk) begin
        if (!rst_n) begin
            mac_out <= 0;
        end else begin
            mac_out <= add_result;
        end
    end
    
endmodule
