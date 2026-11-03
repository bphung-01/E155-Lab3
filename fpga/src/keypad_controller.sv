`timescale 1ns/1ps

module keypad_controller (
    input  logic       clk,
    input  logic       reset,
    input  logic       stable_valid,
    input  logic       any_key,
    input  logic       one_key,
    input  logic [3:0] key_code,
    output logic [3:0] hex_left = 4'h0,
    output logic [3:0] hex_right = 4'h0
);

    typedef enum logic [1:0] {
        READY,
        HELD,
        MULTIPLE
    } state_t;

    state_t state = READY;
    state_t next_state;

    logic accept_key;
    logic [3:0] held_key = 4'h0;

    // Decide whether to accept a key and select the next state.
    always_comb begin
        next_state = state;
        accept_key = 1'b0;

        if (stable_valid) begin
            case (state)
                READY: begin
                    if (one_key) begin
                        accept_key = 1'b1;
                        next_state = HELD;
                    end
                    else if (any_key) begin
                        next_state = MULTIPLE;
                    end
                end

                HELD: begin
                    if (!any_key) begin
                        next_state = READY; // The key was released.
                    end
                    else if (!one_key) begin
                        next_state = MULTIPLE;
                    end
                    else if (key_code != held_key) begin
                        // A different key replaced the previous key.
                        accept_key = 1'b1;
                    end
                end

                MULTIPLE: begin
                    if (!any_key) begin
                        next_state = READY;
                    end
                    else if (one_key) begin
                        // Register the remaining key once.
                        accept_key = 1'b1;
                        next_state = HELD;
                    end
                end

                default: begin
                    next_state = READY;
                end
            endcase
        end
    end

    // Store the state and update the displayed digits.
    always_ff @(posedge clk) begin
        if (reset) begin
            state     <= READY;
            held_key  <= 4'h0;
            hex_left  <= 4'h0;
            hex_right <= 4'h0;
        end
        else begin
            state <= next_state;

            if (accept_key) begin
                hex_left  <= hex_right; // Move the previous digit left.
                hex_right <= key_code;  // Put the newest digit on the right.
                held_key  <= key_code;
            end
        end
    end

endmodule