`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.09.2025 18:14:02
// Design Name: 
// Module Name: pipelined_mac
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
// A Parameterized, 3-Stage Pipelined Multiply-Accumulate (MAC) Unit
//

module pipelined_mac #(
    // --- Parameters ---
    // Make our design reusable by parameterizing the data widths
    parameter DATA_WIDTH = 8 
)(
    // --- Ports ---
    input                            clk,      // System Clock
    input                            rst_n,    // Active-low synchronous reset
    input                            enable,   // Enable signal for the operation
    
    input      [DATA_WIDTH-1:0]      b_in,     // Multiplier operand B
    input      [DATA_WIDTH-1:0]      c_in,     // Multiplier operand C
    
    output reg [2*DATA_WIDTH:0]      mac_out   // MAC output A + (B*C)
);

    // ////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 1: Multiplication
    // ////////////////////////////////////////////////////////////////////////
    
    // Registers to hold the inputs for the first pipeline stage
    reg [DATA_WIDTH-1:0]      b_reg1, c_reg1;
    reg [2*DATA_WIDTH-1:0]    mult_result; // B*C result

    always @(posedge clk) begin
        if (!rst_n) begin
            b_reg1 <= 0;
            c_reg1 <= 0;
            mult_result <= 0;
        end else if (enable) begin // Only load new data when enabled
            b_reg1 <= b_in;
            c_reg1 <= c_in;
            mult_result <= b_in * c_in; // Perform the multiplication here
        end
    end

    // ////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 2: Addition
    // ////////////////////////////////////////////////////////////////////////

    // Registers to hold the values for the second pipeline stage
    // Note: The new accumulator input is the previous mac_out value
    reg [2*DATA_WIDTH-1:0] add_result;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            add_result <= 0;
        end else if (enable) begin
            // Perform the addition: Previous Result + New Multiplication
            add_result <= mac_out + mult_result;
        end
    end
    
    // ////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 3: Output Register
    // ////////////////////////////////////////////////////////////////////////
    
    // The final registered output for timing stability
    always @(posedge clk) begin
        if (!rst_n) begin
            mac_out <= 0;
        end else if (enable) begin
            mac_out <= add_result;
        end
    end
    
endmodule
