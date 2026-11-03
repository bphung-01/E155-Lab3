`timescale 1ns/1ps

module hex_to_seven_segment_tb;

    logic [3:0] hex_value = 0;
    wire [6:0] segments;

    logic [6:0] expected [0:15];

    hex_to_seven_segment dut (
        .hex_value(hex_value),
        .segments(segments)
    );

    initial begin
        $dumpfile("hex_to_seven_segment_tb.vcd");
        $dumpvars(0, hex_to_seven_segment_tb);

        // Active-low segment order: GFEDCBA.
        expected[0]  = 7'b1000000;
        expected[1]  = 7'b1111001;
        expected[2]  = 7'b0100100;
        expected[3]  = 7'b0110000;
        expected[4]  = 7'b0011001;
        expected[5]  = 7'b0010010;
        expected[6]  = 7'b0000010;
        expected[7]  = 7'b1111000;
        expected[8]  = 7'b0000000;
        expected[9]  = 7'b0010000;
        expected[10] = 7'b0001000;
        expected[11] = 7'b0000011;
        expected[12] = 7'b1000110;
        expected[13] = 7'b0100001;
        expected[14] = 7'b0000110;
        expected[15] = 7'b0001110;

        for (integer value = 0; value < 16; value++) begin
            hex_value = value;
            #10;

            if (segments !== expected[value])
                $fatal(1, "Incorrect segment pattern for hex %h.",
                       hex_value);
        end

        // The decoder's default branch blanks unknown inputs.
        hex_value = 4'bxxxx;
        #10;

        if (segments !== 7'b1111111)
            $fatal(1, "Unknown input did not blank the display.");

        $display("PASS: hex_to_seven_segment_tb");
        $finish;
    end

endmodule