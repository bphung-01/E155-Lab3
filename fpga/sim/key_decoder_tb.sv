`timescale 1ns/1ps

module key_decoder_tb;

    logic [15:0] keys = 0;
    wire any_key;
    wire one_key;
    wire [3:0] key_code;

    integer number_pressed;
    integer selected_bit;
    logic [3:0] expected_code;

    key_decoder dut (
        .keys(keys),
        .any_key(any_key),
        .one_key(one_key),
        .key_code(key_code)
    );

    // Expected hexadecimal values in row-major order.
    function automatic [3:0] code_for_bit(input integer index);
        case (index)
             0: code_for_bit = 4'h1;
             1: code_for_bit = 4'h2;
             2: code_for_bit = 4'h3;
             3: code_for_bit = 4'hA;
             4: code_for_bit = 4'h4;
             5: code_for_bit = 4'h5;
             6: code_for_bit = 4'h6;
             7: code_for_bit = 4'hB;
             8: code_for_bit = 4'h7;
             9: code_for_bit = 4'h8;
            10: code_for_bit = 4'h9;
            11: code_for_bit = 4'hC;
            12: code_for_bit = 4'hE;
            13: code_for_bit = 4'h0;
            14: code_for_bit = 4'hF;
            15: code_for_bit = 4'hD;
            default: code_for_bit = 0;
        endcase
    endfunction

    initial begin
        $dumpfile("key_decoder_tb.vcd");
        $dumpvars(0, key_decoder_tb);

        // Exhaustively test all possible keypad patterns.
        for (integer pattern = 0; pattern < 65536; pattern++) begin
            keys = pattern;
            number_pressed = 0;
            selected_bit = 0;

            for (integer bit_index = 0; bit_index < 16; bit_index++) begin
                if (keys[bit_index]) begin
                    number_pressed++;
                    selected_bit = bit_index;
                end
            end

            expected_code = (number_pressed == 1) ?
                            code_for_bit(selected_bit) : 4'h0;

            #1;

            if (any_key !== (number_pressed != 0))
                $fatal(1, "any_key failed for %h.", keys);

            if (one_key !== (number_pressed == 1))
                $fatal(1, "one_key failed for %h.", keys);

            if (key_code !== expected_code)
                $fatal(1, "key_code failed for %h.", keys);
        end

        $display("PASS: key_decoder_tb");
        $finish;
    end

endmodule