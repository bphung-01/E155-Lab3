`timescale 1ns/1ps

module keypad_controller_tb;

    logic clk = 0;
    logic reset = 1;
    logic stable_valid = 0;
    logic any_key = 0;
    logic one_key = 0;
    logic [3:0] key_code = 0;

    wire [3:0] hex_left;
    wire [3:0] hex_right;

    always #5 clk = ~clk;

    keypad_controller dut (
        .clk(clk),
        .reset(reset),
        .stable_valid(stable_valid),
        .any_key(any_key),
        .one_key(one_key),
        .key_code(key_code),
        .hex_left(hex_left),
        .hex_right(hex_right)
    );

    // Supply one accepted keypad-state change.
    task automatic report(
        input logic any_pressed,
        input logic exactly_one,
        input logic [3:0] code
    );
        @(negedge clk);
        any_key = any_pressed;
        one_key = exactly_one;
        key_code = code;
        stable_valid = 1;

        @(negedge clk);
        stable_valid = 0;
    endtask

    task automatic check_digits(input logic [7:0] expected);
        #1;
        if ({hex_left, hex_right} !== expected)
            $fatal(1, "Expected %h, got %h.",
                   expected, {hex_left, hex_right});
    endtask

    initial begin
        $dumpfile("keypad_controller_tb.vcd");
        $dumpvars(0, keypad_controller_tb);

        repeat (2) @(negedge clk);
        reset = 0;
        check_digits(8'h00);

        report(1, 1, 4'h1);
        check_digits(8'h01);

        // Repeated reports of the held key must not repeat the digit.
        repeat (3) report(1, 1, 4'h1);
        check_digits(8'h01);

        // Release and press the same key again.
        report(0, 0, 0);
        report(1, 1, 4'h1);
        check_digits(8'h11);

        report(0, 0, 0);
        report(1, 1, 4'hA);
        check_digits(8'h1A);

        // Additional keys do not change the display.
        report(1, 0, 0);
        check_digits(8'h1A);

        // Register the single key remaining after multiple keys.
        report(1, 1, 4'h5);
        check_digits(8'hA5);

        // Multiple keys from the idle state are ignored.
        report(0, 0, 0);
        report(1, 0, 0);
        check_digits(8'hA5);

        report(1, 1, 4'hD);
        check_digits(8'h5D);

        // A stable replacement key is accepted.
        report(1, 1, 4'h2);
        check_digits(8'hD2);

        // Inputs without stable_valid must not change the digits.
        @(negedge clk);
        key_code = 4'hF;
        repeat (5) @(negedge clk);
        check_digits(8'hD2);

        reset = 1;
        @(negedge clk);
        check_digits(8'h00);

        $display("PASS: keypad_controller_tb");
        $finish;
    end

endmodule