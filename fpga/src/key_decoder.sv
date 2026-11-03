`timescale 1ns/1ps

module key_decoder (
    input  logic [15:0] keys,
    output logic        any_key,
    output logic        one_key,
    output logic [3:0]  key_code
);

    assign any_key = |keys; // High when at least one key is pressed.

    // Decode only patterns containing exactly one pressed key.
    always_comb begin
        key_code = 4'h0;
        one_key  = 1'b1;

        case (keys)
            // Top row.
            16'h0001: key_code = 4'h1;
            16'h0002: key_code = 4'h2;
            16'h0004: key_code = 4'h3;
            16'h0008: key_code = 4'hA;

            // Second row.
            16'h0010: key_code = 4'h4;
            16'h0020: key_code = 4'h5;
            16'h0040: key_code = 4'h6;
            16'h0080: key_code = 4'hB;

            // Third row.
            16'h0100: key_code = 4'h7;
            16'h0200: key_code = 4'h8;
            16'h0400: key_code = 4'h9;
            16'h0800: key_code = 4'hC;

            // Bottom row.
            16'h1000: key_code = 4'hE; // Star key.
            16'h2000: key_code = 4'h0;
            16'h4000: key_code = 4'hF; // Pound key.
            16'h8000: key_code = 4'hD;

            // Reject no-key and multiple-key patterns.
            default: begin
                key_code = 4'h0;
                one_key  = 1'b0;
            end
        endcase
    end

endmodule