/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module detects when a T-Spin has been achieved by the player. The
 * heuristic for detection is 3-corners with an immobility check, as suggested
 * in http://kitaru.1101b.com/tc/mini.html
 *
 * As named, the T-Spin is only detectable when the falling piece is a T
 * tetromino.
 *
 * tspin_detected is a latched output, it indicates whether the most recently
 * locked piece was a T-Spin. Updates on falling_piece_lock input.
 */
`default_nettype none

module TSpinDetector
    import  DisplayPkg::*,
            GamePkg::*;
(
    input  logic            clk,
    input  logic            rst_l,
    input  logic [ 4:0]     origin_row,
    input  logic [ 4:0]     origin_col,
    input  tile_type_t      falling_type,
    input  orientation_t    falling_orientation
    input  logic [ 3:0]     locked_state    [PLAYFIELD_ROWS][PLAYFIELD_COLS],
    input  logic            rotate_R,
    input  logic            rotate_L,
    input  logic            move_R,
    input  logic            move_L,
    input  logic            move_R_valid,
    input  logic            move_L_valid,
    input  logic            falling_piece_lock,
    output logic            tspin_detected
);
    enum logic {
        MOVE    = 1'b0,
        ROTATE  = 1'b1
    }       last_input_type;
    logic   immobile;
    logic   three_corners;
    logic   corners_filled   [4];

    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            last_input_type <= MOVE;
        end else begin
            if (rotate_R || rotate_L) begin
                last_input_type <= ROTATE;
            end else if (move_R || move_L) begin
                last_input_type <= MOVE;
            end
        end
    end

    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            tspin_detected <= 1'b0;
        end else begin
            if (falling_piece_lock) begin
                if (falling_type == T   &&
                    last_input_type     &&
                    three_corners       &&
                    immobile) begin

                    tspin_detected <= 1'b1;
                end else begin
                    tspin_detected <= 1'b0;
                end
            end // else maintain the same value
        end
    end

    // check three corners
    always_comb begin
        for (int i = 0; i < 4; i++) begin0
            corners_filled[i] = 1'b0;
        end
        if (locked_state[origin_row - 4'b1][origin_col - 4'b1] != BLANK ||
            origin_row == 4'b0                                          ||
            origin_col == 4'b0) begin

            corners_filled[0] = 1'b1;
        end
        if (locked_state[origin_row - 4'b1][origin_col + 4'b1] != BLANK ||
            origin_row == 4'b0                                          ||
            origin_col == 4'(PLAYFIELD_COLS - 1)) begin

            corners_filled[1] = 1'b1;
        end
        if (locked_state[origin_row + 4'b1][origin_col - 4'b1] != BLANK ||
            origin_row == 4'(PLAYFIELD_ROWS - 1)                        ||
            origin_col == 4'b0) begin
            corners_filled[2] = 1'b1;
        end
        if (locked_state[origin_row + 4'b1][origin_col + 4'b1] != BLANK ||
            origin_row == 4'(PLAYFIELD_ROWS - 1)                        ||
            origin_col == 4'(PLAYFIELD_COLS - 1)) begin
            corners_filled[3] = 1'b1;
        end

        if ((corners_filled[0] +
             corners_filled[1] +
             corners_filled[2] +
             corners_filled[3]) >= 3) begin

            three_corners = 1'b1;
        end else begin
            three_corners = 1'b0;
        end
    end

    // check immobile
    always_comb begin
        if (!move_R_valid && !move_L_valid) begin
            case (falling_orientation)
                ORIENTATION_R: begin
                    if (locked_state[origin_row - 4'd2][origin_col]         != BLANK &&
                        locked_state[origin_row - 4'd1][origin_col + 4'b1]  != BLANK) begin

                        immobile = 1'b1;
                    end
                end
                ORIENTATION_L: begin
                    if (locked_state[origin_row - 4'd2][origin_col]         != BLANK &&
                        locked_state[origin_row - 4'd1][origin_col - 4'b1]  != BLANK) begin

                        immobile = 1'b1;
                    end
                end
                // For ORIENTATION_0 and ORIENTATION_2, it is given that if the
                // three corner check passes, then the piece is upwards immobile
                default: immobile = 1'b1;
            endcase
        end else begin
            immobile = 1'b0;
        end
    end
endmodule // TSpinDetector