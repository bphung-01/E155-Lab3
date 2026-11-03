`timescale 1ns/1ps

module keypad_debouncer_tb;

    logic clk = 0;
    logic reset = 1;
    logic scan_valid = 0;
    logic [15:0] keys = 0;

    wire [15:0] stable_keys;
    wire stable_valid;

    integer accepted_changes = 0;

    always #5 clk = ~clk;

    keypad_debouncer #(
        .COUNT_WIDTH(2),
        .STABLE_SCANS(3)
    ) dut (
        .clk(clk),
        .reset(reset),
        .scan_valid(scan_valid),
        .keys(keys),
        .stable_keys(stable_keys),
        .stable_valid(stable_valid)
    );

    // Count accepted readings and check pulse width.
    logic previous_valid = 0;

    always @(posedge clk) begin
        #1;
        if (reset) begin
            accepted_changes = 0;
            previous_valid = 0;
        end
        else begin
            if (stable_valid && previous_valid)
                $fatal(1, "stable_valid lasted longer than one clock.");

            if (stable_valid)
                accepted_changes++;

            previous_valid = stable_valid;
        end
    end

    // Deliver one complete scanner reading.
    task automatic sample(input logic [15:0] value);
        @(negedge clk);
        keys = value;
        scan_valid = 1;

        @(negedge clk);
        scan_valid = 0;

        repeat (2) @(negedge clk);
    endtask

    initial begin
        $dumpfile("keypad_debouncer_tb.vcd");
        $dumpvars(0, keypad_debouncer_tb);

        repeat (2) @(negedge clk);
        reset = 0;

        // Bouncing press: none of these readings lasts long enough.
        sample(16'h0001);
        sample(16'h0000);
        sample(16'h0001);
        sample(16'h0000);

        if (stable_keys !== 0 || accepted_changes != 0)
            $fatal(1, "Bounce was incorrectly accepted.");

        // First reading establishes the candidate.
        sample(16'h0001);
        sample(16'h0001);
        sample(16'h0001);

        if (stable_keys !== 0)
            $fatal(1, "Candidate was accepted too early.");

        sample(16'h0001);

        if (stable_keys !== 16'h0001 || accepted_changes != 1)
            $fatal(1, "Stable press was not accepted.");

        // Holding a key must not generate repeated changes.
        repeat (6) sample(16'h0001);

        if (accepted_changes != 1)
            $fatal(1, "Held key generated repeated events.");

        // Changing keys without scan_valid must have no effect.
        @(negedge clk);
        keys = 16'hFFFF;
        repeat (10) @(negedge clk);

        if (stable_keys !== 16'h0001)
            $fatal(1, "Debouncer accepted data without scan_valid.");

        // Bouncing release must not clear the stable reading.
        sample(0);
        sample(16'h0001);
        sample(0);
        sample(16'h0001);

        if (stable_keys !== 16'h0001)
            $fatal(1, "Release bounce was accepted.");

        repeat (4) sample(0);

        if (stable_keys !== 0 || accepted_changes != 2)
            $fatal(1, "Stable release failed.");

        // Verify that debounce tracks the entire key pattern.
        sample(16'h0002);
        sample(16'h0002);
        sample(16'h0004); // Different candidate restarts the timer.
        sample(16'h0004);
        sample(16'h0004);

        if (stable_keys !== 0)
            $fatal(1, "Candidate change did not restart debounce.");

        sample(16'h0004);

        if (stable_keys !== 16'h0004)
            $fatal(1, "Replacement candidate was not accepted.");

        // Reset clears an accepted key.
        @(negedge clk);
        reset = 1;
        @(negedge clk);

        if (stable_keys !== 0 || stable_valid !== 0)
            $fatal(1, "Debouncer reset failed.");

        $display("PASS: keypad_debouncer_tb");
        $finish;
    end

endmodule