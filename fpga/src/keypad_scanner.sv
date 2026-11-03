`timescale 1ns/1ps

module keypad_scanner #(
    parameter integer WIDTH = 25,
    parameter integer ROW_TICKS = 48_000
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic [3:0]  col_sync_n,
    output logic [3:0]  row_drive,
    output logic [15:0] keys = 16'h0000,
    output logic        scan_valid = 1'b0
);

    logic [WIDTH-1:0] scan_count;
    logic [11:0] sampled_keys = 12'h000;

    // Reuse the Lab 2 counter to time all four rows.
    blink_counter #(
        .WIDTH(WIDTH),
        .MAX_COUNT(4 * ROW_TICKS - 1)
    ) scan_counter (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .count(scan_count),
        .blink()
    );

    // Select one row at a time, starting with the top row.
    assign row_drive =
        (scan_count < ROW_TICKS)     ? 4'b1000 :
        (scan_count < 2 * ROW_TICKS) ? 4'b0100 :
        (scan_count < 3 * ROW_TICKS) ? 4'b0010 :
                                      4'b0001;

    // Sample each row near the end of its selection period.
    always_ff @(posedge clk) begin
        if (reset) begin
            sampled_keys <= 12'h000;
            keys         <= 16'h0000;
            scan_valid   <= 1'b0;
        end
        else begin
            scan_valid <= 1'b0; // Default to no completed scan.

            if (enable) begin
                if (scan_count == ROW_TICKS - 1) begin
                    sampled_keys[3:0] <= ~col_sync_n;
                end
                else if (scan_count == 2 * ROW_TICKS - 1) begin
                    sampled_keys[7:4] <= ~col_sync_n;
                end
                else if (scan_count == 3 * ROW_TICKS - 1) begin
                    sampled_keys[11:8] <= ~col_sync_n;
                end
                else if (scan_count == 4 * ROW_TICKS - 1) begin
                    // Combine the last row with the first three rows.
                    keys <= {~col_sync_n, sampled_keys};

                    scan_valid <= 1'b1; // Pulse once per complete scan.
                end
            end
        end
    end

endmodule