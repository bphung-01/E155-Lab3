`timescale 1ns/1ps

module blink_counter_tb;

    logic clk = 0;
    logic reset = 1;
    logic enable = 1;

    wire [2:0] count;
    wire blink;

    integer expected_count = 0;
    logic expected_blink = 0;

    always #5 clk = ~clk;

    blink_counter #(
        .WIDTH(3),
        .MAX_COUNT(4)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .count(count),
        .blink(blink)
    );

    // Independently track the expected counter behavior.
    task automatic check_cycle;
        @(posedge clk);

        if (reset) begin
            expected_count = 0;
            expected_blink = 0;
        end
        else if (enable) begin
            if (expected_count == 4) begin
                expected_count = 0;
                expected_blink = ~expected_blink;
            end
            else begin
                expected_count++;
            end
        end

        #1;

        if (count !== expected_count || blink !== expected_blink)
            $fatal(1, "Counter mismatch: count=%0d blink=%b.",
                   count, blink);

        @(negedge clk);
    endtask

    initial begin
        $dumpfile("blink_counter_tb.vcd");
        $dumpvars(0, blink_counter_tb);

        check_cycle();
        reset = 0;

        repeat (13) check_cycle();

        enable = 0;
        repeat (5) check_cycle();

        enable = 1;
        repeat (12) check_cycle();

        // Reset takes priority even when counting is disabled.
        enable = 0;
        reset = 1;
        check_cycle();

        reset = 0;
        enable = 1;
        repeat (7) check_cycle();

        $display("PASS: blink_counter_tb");
        $finish;
    end

endmodule