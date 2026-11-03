`timescale 1ns/1ps

module keypad_debouncer #(
    parameter integer COUNT_WIDTH = 3,
    parameter integer STABLE_SCANS = 5
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        scan_valid,
    input  logic [15:0] keys,
    output logic [15:0] stable_keys = 16'h0000,
    output logic        stable_valid = 1'b0
);

    logic [15:0] candidate_keys = 16'h0000;
    logic [COUNT_WIDTH-1:0] stable_count;

    logic candidate_changed;
    logic timer_reset;
    logic timer_enable;

    // Compare a completed scan with the reading being debounced.
    assign candidate_changed =
        scan_valid && (keys != candidate_keys);

    // Restart the timer whenever the candidate changes.
    assign timer_reset = reset || candidate_changed;

    // Count matching scans only while a new reading is pending.
    assign timer_enable =
        scan_valid &&
        !candidate_changed &&
        (candidate_keys != stable_keys);

    // Five matching scan intervals give 20 ms with a 4 ms scan period.
    blink_counter #(
        .WIDTH(COUNT_WIDTH),
        .MAX_COUNT(STABLE_SCANS - 1)
    ) debounce_counter (
        .clk(clk),
        .reset(timer_reset),
        .enable(timer_enable),
        .count(stable_count),
        .blink()
    );

    // Publish a keypad reading after it remains stable.
    always_ff @(posedge clk) begin
        if (reset) begin
            candidate_keys <= 16'h0000;
            stable_keys    <= 16'h0000;
            stable_valid   <= 1'b0;
        end
        else begin
            stable_valid <= 1'b0; // Pulse only when a reading is accepted.

            if (scan_valid) begin
                if (candidate_changed) begin
                    candidate_keys <= keys; // Start checking this reading.
                end
                else if ((candidate_keys != stable_keys) &&
                         (stable_count == STABLE_SCANS - 1)) begin
                    stable_keys  <= candidate_keys;
                    stable_valid <= 1'b1;
                end
            end
        end
    end

endmodule