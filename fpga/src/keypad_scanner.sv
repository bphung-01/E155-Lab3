// Four row scan: 1000 -> 0100 -> 0010 -> 0001 -> repeat.
// row_drive[3] selects physical row 1; bit 0 selects physical row 4.
// A HIGH FPGA output enables an NPN, pulling its keypad row LOW.
// Author: add your name and email. Prepared with AI assistance, 2026-09-14.
`timescale 1ns/1ps
module keypad_scanner #(
    parameter integer WIDTH = 25,
    parameter integer ROW_TICKS = 6_000_000
) (
    input  logic clk,
    input  logic reset,
    input  logic enable,
    output logic [3:0] row_drive
);
    // Legal parameters: ROW_TICKS >= 1 and 4*ROW_TICKS <= 2**WIDTH.
    logic [WIDTH-1:0] scan_count;
    blink_counter #(.WIDTH(WIDTH), .MAX_COUNT(4*ROW_TICKS-1)) scan_counter (
        .clk(clk), .reset(reset), .enable(enable),
        .count(scan_count), .blink()
    );
    assign row_drive = (scan_count < ROW_TICKS)   ? 4'b1000 :
                       (scan_count < 2*ROW_TICKS) ? 4'b0100 :
                       (scan_count < 3*ROW_TICKS) ? 4'b0010 : 4'b0001;
endmodule
