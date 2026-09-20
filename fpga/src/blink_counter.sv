`timescale 1ns/1ps
module blink_counter #(
    parameter integer WIDTH = 24,
    parameter integer MAX_COUNT = 9_999_999
) (
    input  logic clk,
    input  logic reset,
    input  logic enable,
    output logic [WIDTH-1:0] count = '0,
    output logic blink = 1'b0
);
    // Synchronous, active-high reset takes priority over enable.
    always_ff @(posedge clk) begin
        if (reset) begin
            count <= '0;
            blink <= 1'b0;
        end else if (enable) begin
            if (count == MAX_COUNT) begin
                count <= '0;
                blink <= ~blink;
            end else begin
                count <= count + 1'b1;
            end
        end
    end

    // synthesis translate_off
    initial begin
        if (WIDTH < 1 || WIDTH > 30 || MAX_COUNT < 0 ||
            MAX_COUNT >= 2.0**WIDTH)
            $fatal(1, "Invalid counter width or maximum.");
    end
    // synthesis translate_on
endmodule
