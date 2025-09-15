`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.09.2025 13:16:35
// Design Name: 
// Module Name: mac_data_aware
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
// DATA-AWARE LOW-POWER Pipelined MAC Unit (Corrected)
// Automatically gates the clock when multiplier inputs are zero.
//

module mac_data_aware #(
    parameter DATA_WIDTH = 8
)(
    input                            clk,
    input                            rst_n,
    input                            enable, // The overall enable from the system
    
    input      [DATA_WIDTH-1:0]      b_in,
    input      [DATA_WIDTH-1:0]      c_in,
    
    output reg [2*DATA_WIDTH:0]      mac_out
);

    // ////////////////////////////////////////////////////////////////////////
    // Data-Aware Gating Logic (THE NOVEL PART)
    // ////////////////////////////////////////////////////////////////////////

    // We only need to perform a multiplication if the system has the MAC enabled
    // AND if both inputs are non-zero.
    wire is_mult_needed;
    assign is_mult_needed = enable && (b_in != 0) && (c_in != 0);

    // Latch the enable signal to prevent glitches on the gated clock
    reg final_enable_latch;
    always @(*) begin
        if (~clk) begin
            final_enable_latch = is_mult_needed;
        end
    end

    wire gated_clk;
    assign gated_clk = clk & final_enable_latch; // The clock is gated here!

    // ////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 1: Multiplication (with Operand Isolation)
    // ////////////////////////////////////////////////////////////////////////
    
    reg [DATA_WIDTH-1:0]      b_reg1, c_reg1;
    reg [2*DATA_WIDTH-1:0]    mult_result;
    
    always @(posedge clk) begin 
        if (!rst_n) begin
            b_reg1 <= 0;
            c_reg1 <= 0;
        end else if (enable) begin // Load inputs if the system wants to use the MAC
            b_reg1 <= b_in;
            c_reg1 <= c_in;
        end
    end

    // The multiplier is now clocked by our new DATA-AWARE gated clock.
    // It will only compute when necessary.
    always @(posedge gated_clk) begin
        if (!rst_n) begin
            mult_result <= 0;
        end else begin
            mult_result <= b_reg1 * c_reg1; 
        end
    end

    // ////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 2: Addition (Corrected)
    // ////////////////////////////////////////////////////////////////////////

    // *** FIX IS HERE ***
    // The add_operand logic is now a module-level wire defined with 'assign'.
    wire [2*DATA_WIDTH-1:0] add_operand;
    assign add_operand = is_mult_needed ? mult_result : 0;

    reg [2*DATA_WIDTH-1:0] add_result;
    
    // The adder must always run if the system enables the MAC,
    // because it might need to add zero (from a gated multiply) to the accumulator.
    always @(posedge clk) begin
        if (!rst_n) begin
            add_result <= 0;
        end else if (enable) begin
            add_result <= mac_out + add_operand;
        end
    end
    
    // ////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 3: Output Register
    // ////////////////////////////////////////////////////////////////////////
    
    always @(posedge clk) begin
        if (!rst_n) begin
            mac_out <= 0;
        end else if (enable) begin
            mac_out <= add_result;
        end
    end
    
endmodule

