`timescale 1ns/1ps

module lab3_tr #(
    parameter integer MUX_WIDTH = 15,
    parameter integer SLOT_TICKS = 24_000,
    parameter integer BLANK_TICKS = 240,
    parameter integer SCAN_WIDTH = 25,
    parameter integer ROW_TICKS = 48_000,
    parameter integer DEBOUNCE_WIDTH = 3,
    parameter integer STABLE_SCANS = 5
) (
    input  logic       reset_n,
    input  logic       scan_enable,
    input  logic [3:0] col_n,

    output logic [6:0] seg_n,
    output logic [1:0] digit_n,
    output logic [3:0] row_drive,
    output logic [3:0] led
);

    logic clk;
    logic reset;
    logic [3:0] reset_sync_n;
    logic [3:0] col_sync_n;

    logic [15:0] keys;
    logic scan_valid;

    logic [15:0] stable_keys;
    logic stable_valid;

    logic any_key;
    logic one_key;
    logic [3:0] key_code;

    logic [3:0] hex_left;
    logic [3:0] hex_right;
    logic [3:0] selected_hex;

    logic [MUX_WIDTH-1:0] mux_count;
    logic digit_select;
    logic active_window;

    // Generate the 48 MHz FPGA clock.
    HSOSC #(
        .CLKHF_DIV("0b00")
    ) oscillator (
        .CLKHFPU(1'b1),
        .CLKHFEN(1'b1),
        .CLKHF(clk)
    );

    // Synchronize the external reset button.
    // Reuse the two-stage synchronizer for the replicated reset signal.
    column_synchronizer reset_synchronizer (
        .clk(clk),
        .reset(1'b0),
        .col_n({4{reset_n}}),
        .col_sync_n(reset_sync_n)
    );

    assign reset = ~reset_sync_n[0];

    // Synchronize the active-low keypad column inputs.
    column_synchronizer keypad_inputs (
        .clk(clk),
        .reset(reset),
        .col_n(col_n),
        .col_sync_n(col_sync_n)
    );

    // Continuously scan all four keypad rows.
    keypad_scanner #(
        .WIDTH(SCAN_WIDTH),
        .ROW_TICKS(ROW_TICKS)
    ) scanner (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .col_sync_n(col_sync_n),
        .row_drive(row_drive),
        .keys(keys),
        .scan_valid(scan_valid)
    );

    // Debounce complete keypad readings.
    keypad_debouncer #(
        .COUNT_WIDTH(DEBOUNCE_WIDTH),
        .STABLE_SCANS(STABLE_SCANS)
    ) debouncer (
        .clk(clk),
        .reset(reset),
        .scan_valid(scan_valid),
        .keys(keys),
        .stable_keys(stable_keys),
        .stable_valid(stable_valid)
    );

    // Convert a single pressed key to its hexadecimal value.
    key_decoder decoder (
        .keys(stable_keys),
        .any_key(any_key),
        .one_key(one_key),
        .key_code(key_code)
    );

    // Accept new presses and store the last two digits.
    keypad_controller controller (
        .clk(clk),
        .reset(reset),
        .stable_valid(stable_valid),
        .any_key(any_key),
        .one_key(one_key),
        .key_code(key_code),
        .hex_left(hex_left),
        .hex_right(hex_right)
    );

    // Reuse the Lab 2 counter for display multiplexing.
    blink_counter #(
        .WIDTH(MUX_WIDTH),
        .MAX_COUNT(SLOT_TICKS - 1)
    ) mux_counter (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .count(mux_count),
        .blink(digit_select)
    );

    // Select the digit currently being displayed.
    assign selected_hex = digit_select ? hex_right : hex_left;

    hex_to_seven_segment display_decoder (
        .hex_value(selected_hex),
        .segments(seg_n)
    );

    // Blank both digits briefly around each display transition.
    assign active_window =
        !reset &&
        (mux_count >= BLANK_TICKS) &&
        (mux_count < SLOT_TICKS - BLANK_TICKS);

    // Drive the active-low PNP digit enables.
    assign digit_n[0] = ~(active_window && !digit_select);
    assign digit_n[1] = ~(active_window &&  digit_select);

    // Show the synchronized column activity on the LEDs.
    assign led = ~col_sync_n;

endmodule