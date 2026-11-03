`timescale 1ns/1ps

module column_synchronizer_tb;

    logic clk = 0;
    logic reset = 1;
    logic [3:0] col_n = 4'b1111;
    wire [3:0] col_sync_n;

    always #5 clk = ~clk;

    column_synchronizer dut (
        .clk(clk),
        .reset(reset),
        .col_n(col_n),
        .col_sync_n(col_sync_n)
    );

    // Advance one clock and allow nonblocking assignments to finish.
    task automatic tick;
        @(posedge clk);
        #1;
    endtask

    initial begin
        $dumpfile("column_synchronizer_tb.vcd");
        $dumpvars(0, column_synchronizer_tb);

        tick();
        if (col_sync_n !== 4'b1111)
            $fatal(1, "Reset did not clear the synchronizer.");

        @(negedge clk);
        reset = 0;

        // Change the input between clock edges.
        #2;
        col_n = 4'b1110;

        tick();
        if (col_sync_n !== 4'b1111)
            $fatal(1, "Input passed through in only one clock.");

        tick();
        if (col_sync_n !== 4'b1110)
            $fatal(1, "Input did not pass through after two clocks.");

        // Change the input shortly before a rising edge.
        @(negedge clk);
        #4;
        col_n = 4'b0101;

        tick();
        if (col_sync_n !== 4'b1110)
            $fatal(1, "Second input passed through too early.");

        tick();
        if (col_sync_n !== 4'b0101)
            $fatal(1, "Second input was not synchronized.");

        // Reset while a key is active.
        @(negedge clk);
        reset = 1;
        tick();

        if (col_sync_n !== 4'b1111)
            $fatal(1, "Reset failed with an active input.");

        $display("PASS: column_synchronizer_tb");
        $finish;
    end

endmodule