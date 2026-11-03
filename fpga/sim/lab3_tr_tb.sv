`timescale 1ns/1ps

module lab3_tr_tb;

    logic reset_n = 0;
    logic scan_enable = 1;
    logic [15:0] pressed = 0;
    logic [3:0] col_n;

    wire [6:0] seg_n;
    wire [1:0] digit_n;
    wire [3:0] row_drive;
    wire [3:0] led;

    logic saw_left = 0;
    logic saw_right = 0;
    logic saw_blank = 0;

    // Shortened timing keeps simulation fast.
    lab3_tr #(
        .MUX_WIDTH(5),
        .SLOT_TICKS(16),
        .BLANK_TICKS(2),
        .SCAN_WIDTH(6),
        .ROW_TICKS(8),
        .DEBOUNCE_WIDTH(2),
        .STABLE_SCANS(3)
    ) dut (
        .reset_n(reset_n),
        .scan_enable(scan_enable),
        .col_n(col_n),
        .seg_n(seg_n),
        .digit_n(digit_n),
        .row_drive(row_drive),
        .led(led)
    );

    // Model ideal keypad contacts for the selected row.
    // Tests below use at most two simultaneous keys, avoiding ghost loops.
    always_comb begin
        col_n = 4'b1111;

        if (row_drive[3]) col_n = col_n & ~pressed[3:0];
        if (row_drive[2]) col_n = col_n & ~pressed[7:4];
        if (row_drive[1]) col_n = col_n & ~pressed[11:8];
        if (row_drive[0]) col_n = col_n & ~pressed[15:12];
    end

    function automatic [6:0] segments_for(input logic [3:0] value);
        case (value)
            4'h0: segments_for = 7'b1000000;
            4'h1: segments_for = 7'b1111001;
            4'h2: segments_for = 7'b0100100;
            4'h3: segments_for = 7'b0110000;
            4'h4: segments_for = 7'b0011001;
            4'h5: segments_for = 7'b0010010;
            4'h6: segments_for = 7'b0000010;
            4'h7: segments_for = 7'b1111000;
            4'h8: segments_for = 7'b0000000;
            4'h9: segments_for = 7'b0010000;
            4'hA: segments_for = 7'b0001000;
            4'hB: segments_for = 7'b0000011;
            4'hC: segments_for = 7'b1000110;
            4'hD: segments_for = 7'b0100001;
            4'hE: segments_for = 7'b0000110;
            4'hF: segments_for = 7'b0001110;
        endcase
    endfunction

    // Check the physical display outputs throughout the test.
    always @(posedge dut.clk) begin
        #1;

        if (!dut.reset && reset_n) begin
            case (digit_n)
                2'b10: begin
                    saw_left = 1;
                    if (seg_n !== segments_for(dut.hex_left))
                        $fatal(1, "Incorrect left-digit segments.");
                end

                2'b01: begin
                    saw_right = 1;
                    if (seg_n !== segments_for(dut.hex_right))
                        $fatal(1, "Incorrect right-digit segments.");
                end

                2'b11: saw_blank = 1;

                default:
                    $fatal(1, "Both digits enabled or unknown digit control.");
            endcase

            if (led !== ~dut.col_sync_n)
                $fatal(1, "Column LEDs do not match synchronized columns.");
        end
    end

    // Allow more than enough time for scanning and debounce.
    task automatic settle;
        repeat (240) @(negedge dut.clk);
    endtask

    task automatic check_digits(input logic [7:0] expected);
        #1;
        if ({dut.hex_left, dut.hex_right} !== expected)
            $fatal(1, "Expected display %h, got %h.",
                   expected, {dut.hex_left, dut.hex_right});
    endtask

    // Change contacts asynchronously relative to the FPGA clock.
    task automatic set_keys(input logic [15:0] value);
        @(negedge dut.clk);
        #3;
        pressed = value;
    endtask

    task automatic release_keys;
        set_keys(0);
        settle();
    endtask

    initial begin
        $dumpfile("lab3_tr_tb.vcd");
        $dumpvars(0, lab3_tr_tb);

        repeat (8) @(negedge dut.clk);
        reset_n = 1;
        settle();
        check_digits(8'h00);

        // Bounce near clock edges, then settle on key 1.
        @(negedge dut.clk);
        #10 pressed = 16'h0001;
        #2  pressed = 0;
        #17 pressed = 16'h0001;
        #4  pressed = 0;
        #23 pressed = 16'h0001;

        settle();
        check_digits(8'h01);

        // Holding the key must not produce additional digits.
        settle();
        check_digits(8'h01);

        // Bounce during release.
        set_keys(0);
        #13 pressed = 16'h0001;
        #19 pressed = 0;
        settle();
        check_digits(8'h01);

        set_keys(16'h0020); // Key 5.
        settle();
        check_digits(8'h15);
        release_keys();

        set_keys(16'h8000); // Key D.
        settle();
        check_digits(8'h5D);
        release_keys();

        // Star and pound represent E and F.
        set_keys(16'h1000);
        settle();
        check_digits(8'hDE);
        release_keys();

        set_keys(16'h4000);
        settle();
        check_digits(8'hEF);
        release_keys();

        // Two keys pressed together should not enter a digit.
        set_keys(16'h0021); // Keys 1 and 5, different rows/columns.
        settle();
        check_digits(8'hEF);

        // Keep only key 5 pressed.
        set_keys(16'h0020);
        settle();
        check_digits(8'hF5);
        release_keys();

        // Press 1 first, then add 5 while holding 1.
        set_keys(16'h0001);
        settle();
        check_digits(8'h51);

        set_keys(16'h0021);
        settle();
        check_digits(8'h51);

        // Release 1: the remaining 5 should be registered.
        set_keys(16'h0020);
        settle();
        check_digits(8'h15);
        release_keys();

        // Confirm the current top scans even with scan_enable low.
        scan_enable = 0;
        set_keys(16'h0002); // Key 2.
        settle();
        check_digits(8'h52);
        release_keys();

        // Reset the complete design.
        reset_n = 0;
        repeat (8) @(negedge dut.clk);
        check_digits(8'h00);
        reset_n = 1;
        settle();

        if (!saw_left || !saw_right || !saw_blank)
            $fatal(1, "Display multiplexing coverage incomplete.");

        $display("PASS: lab3_tr_tb");
        $finish;
    end

    // Catch a stopped oscillator or a stalled test.
    initial begin
        #1000000;
        $fatal(1, "Top-level test timed out.");
    end

endmodule