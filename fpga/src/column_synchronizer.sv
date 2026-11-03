`timescale 1ns/1ps

module column_synchronizer (
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] col_n,
    output logic [3:0] col_sync_n = 4'b1111
);

    logic [3:0] col_first_n = 4'b1111;

    // Pass each asynchronous column through two flip-flops.
    always_ff @(posedge clk) begin
        if (reset) begin
            col_first_n <= 4'b1111;
            col_sync_n  <= 4'b1111;
        end
        else begin
            col_first_n <= col_n;       // First synchronization stage.
            col_sync_n  <= col_first_n; // Second synchronization stage.
        end
    end

endmodule