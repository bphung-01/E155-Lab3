`timescale 1ns/1ps

module keypad_scanner_tb;

    localparam integer ROW_TICKS = 8;

    logic clk = 0;
    logic reset = 1;
    logic enable = 1;

    logic [15:0] pressed = 16'h8421;
    logic [3:0] col_sync_n;

    wire [3:0] row_drive;
    wire [15:0] keys;
    wire scan_valid;

    integer phase;
    integer row_index;
    logic [3:0] expected_row;

    always #5 clk = ~clk;

    keypad_scanner #(
        .WIDTH(6),
        .ROW_TICKS(ROW_TICKS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .col_sync_n(col_sync_n),
        .row_drive(row_drive),
        .keys(keys),
        .scan_valid(scan_valid)
    );

    // Model the column reading for the selected row.
    // Synchronization is tested separately and in the top-level test.
    always_comb begin
        case (row_drive)
            4'b1000: col_sync_n = ~pressed[3:0];
            4'b0100: col_sync_n = ~pressed[7:4];
            4'b0010: col_sync_n = ~pressed[11:8];
            4'b0001: col_sync_n = ~pressed[15:12];
            default: col_sync_n = 4'b1111;
        endcase
    end

    initial begin
        $dumpfile("keypad_scanner_tb.vcd");
        $dumpvars(0, keypad_scanner_tb);

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Check row order, row duration, and completed scan timing.
        for (integer n = 0; n < 3 * 4 * ROW_TICKS; n++) begin
            phase = n % (4 * ROW_TICKS);
            row_index = phase / ROW_TICKS;
            expected_row = 4'b1000 >> row_index;

            if (row_drive !== expected_row)
                $fatal(1, "Incorrect row selection at cycle %0d.", n);

            @(posedge clk);
            #1;

            if (scan_valid !== (phase == 4 * ROW_TICKS - 1))
                $fatal(1, "Incorrect scan_valid timing.");

            if (scan_valid && keys !== pressed)
                $fatal(1, "Incorrect key snapshot: %h.", keys);

            @(negedge clk);
        end

        // Pause at the start of a frame.
        enable = 0;

        repeat (10) begin
            @(posedge clk);
            #1;
            if (row_drive !== 4'b1000 || scan_valid !== 0)
                $fatal(1, "Scanner did not pause correctly.");
        end

        // Resume with no pressed keys.
        @(negedge clk);
        pressed = 0;
        enable = 1;

        @(posedge scan_valid);
        #1;
        if (keys !== 0)
            $fatal(1, "Released keys were not cleared.");

        $display("PASS: keypad_scanner_tb");
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "Scanner test timed out.");
    end

endmodule