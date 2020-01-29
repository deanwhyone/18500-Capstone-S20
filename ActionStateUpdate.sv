/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module takes the current origin, type, and orientation of the falling
 * tetromino and outputs the state changes necessary for each potential input
 * option from the user. Since hard drop is computed, the module also uses a FTR
 * to output coordinates for the ghost piece.
 *
 * Noting a functionality necessary for another module:
 * A separate module will take the new origin, type, and orientation of the
 * falling tetromino and output the validity of this new state along with
 * adjustments to the state (for rotations). Will use the current locked state
 * to evaluate the validity of each input option and outputs that as well. This
 * should be used to arm each user input option.
 */
`default_nettype none

module ActionStateUpdate
    import DisplayPkg::*,
           GamePkg::*;
(
    input  logic [ 4:0]                 origin_row,
    input  logic [ 4:0]                 origin_col,
    input  tile_type_t                  falling_type_in,
    input  orientation_t                falling_orientation,
    input  logic [PLAYFIELD_COLS-1:0][ 3:0] locked_state    [PLAYFIELD_ROWS],

    output logic [ 4:0]                 rotate_R_row,
    output logic [ 4:0]                 rotate_R_col,
    output orientation_t                rotate_R_orientation,

    output logic [ 4:0]                 rotate_L_row,
    output logic [ 4:0]                 rotate_L_col,
    output orientation_t                rotate_L_orientation,

    output logic [ 4:0]                 move_R_row,
    output logic [ 4:0]                 move_R_col,
    output orientation_t                move_R_orientation,

    output logic [ 4:0]                 move_L_row,
    output logic [ 4:0]                 move_L_col,
    output orientation_t                move_L_orientation,

    output logic [ 4:0]                 soft_drop_row,
    output logic [ 4:0]                 soft_drop_col,
    output orientation_t                soft_drop_orientation,

    output logic [ 4:0]                 hard_drop_row,
    output logic [ 4:0]                 hard_drop_col,
    output orientation_t                hard_drop_orientation,

    output logic [ 4:0]                 ghost_rows      [4],
    output logic [ 4:0]                 ghost_cols      [4]
);

    // rotation right
    always_comb begin
        rotate_R_row = origin_row;
        rotate_R_col = origin_col;
        case (falling_orientation)
            ORIENTATION_0: rotate_R_orientation = ORIENTATION_R;
            ORIENTATION_R: rotate_R_orientation = ORIENTATION_2;
            ORIENTATION_2: rotate_R_orientation = ORIENTATION_L;
            ORIENTATION_L: rotate_R_orientation = ORIENTATION_0;
        endcase
    end

    // rotation left
    always_comb begin
        rotate_L_row = origin_row;
        rotate_L_col = origin_col;
        case (falling_orientation)
            ORIENTATION_0: rotate_L_orientation = ORIENTATION_L;
            ORIENTATION_R: rotate_L_orientation = ORIENTATION_0;
            ORIENTATION_2: rotate_L_orientation = ORIENTATION_R;
            ORIENTATION_L: rotate_L_orientation = ORIENTATION_2;
        endcase
    end

    // move right
    always_comb begin
        move_R_row              = origin_row;
        move_R_col              = origin_col + 5'd1;
        move_R_orientation      = falling_orientation;
    end

    // move left
    always_comb begin
        move_L_row              = origin_row;
        move_L_col              = origin_col - 5'd1;
        move_L_orientation      = falling_orientation;
    end

    // soft drop
    always_comb begin
        soft_drop_row           = origin_row + 5'd1;
        soft_drop_col           = origin_col;
        soft_drop_orientation   = falling_orientation;
    end

    // hard drop
    always_comb begin
        hard_drop_orientation   = falling_orientation;
        hard_drop_col           = origin_col;
        hard_drop_row = origin_row;
        // figuring out what row to hard drop the tetromino to
        case (falling_type_in)
            I: begin
                case (hard_drop_orientation)
                    ORIENTATION_0: begin
                        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd2]) == BLANK) begin

                                hard_drop_row = i[4:0] + 5'd1;
                            end
                        end
                    end
                    ORIENTATION_R: begin
                        for (int i = 2; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i - 2][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK) begin

                                hard_drop_row = i[4:0] - 5'd1;
                            end
                        end
                    end
                    ORIENTATION_2: begin
                        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd2]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_L: begin
                        for (int i = 2; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i - 2][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col - 5'd1]) == BLANK) begin
                                hard_drop_row = i[4:0] - 5'd1;
                            end
                        end
                    end
                endcase
            end
            O: begin
                for (int i = 1; i < PLAYFIELD_ROWS; i++) begin
                    if (orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                        orientation_t'(locked_state[i - 1][hard_drop_col - 5'd1]) == BLANK &&
                        orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                        orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK) begin

                        hard_drop_row = i[4:0];
                    end
                end
            end
            T: begin
                case (hard_drop_orientation)
                    ORIENTATION_0: begin
                        for (int i = 1; i < PLAYFIELD_ROWS; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_R: begin
                        for (int i = 1; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_2: begin
                        for (int i = 0; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_L: begin
                        for (int i = 1; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                endcase
            end
            J: begin
                case (hard_drop_orientation)
                    ORIENTATION_0: begin
                        for (int i = 1; i < PLAYFIELD_ROWS; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_R: begin
                        for (int i = 1; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_2: begin
                        for (int i = 0; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col + 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_L: begin
                        for (int i = 1; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col - 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                endcase
            end
            L: begin
                case (hard_drop_orientation)
                    ORIENTATION_0: begin
                        for (int i = 1; i < PLAYFIELD_ROWS; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_R: begin
                        for (int i = 1; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_2: begin
                        for (int i = 0; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_L: begin
                        for (int i = 1; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                endcase
            end
            S: begin
                case (hard_drop_orientation)
                    ORIENTATION_0: begin
                        for (int i = 1; i < PLAYFIELD_ROWS; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col + 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_R: begin
                        for (int i = 1; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col + 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_2: begin
                        for (int i = 0; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col - 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_L: begin
                        for (int i = 1; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col - 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                endcase
            end
            Z: begin
                case (hard_drop_orientation)
                    ORIENTATION_0: begin
                        for (int i = 1; i < PLAYFIELD_ROWS; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_R: begin
                        for (int i = 1; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col + 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_2: begin
                        for (int i = 0; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col + 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col + 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                    ORIENTATION_L: begin
                        for (int i = 1; i < PLAYFIELD_ROWS - 1; i++) begin
                            if (orientation_t'(locked_state[i][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i - 1][hard_drop_col]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col - 5'd1]) == BLANK &&
                                orientation_t'(locked_state[i + 1][hard_drop_col - 5'd1]) == BLANK) begin

                                hard_drop_row = i[4:0];
                            end
                        end
                    end
                endcase
            end
            default:            hard_drop_row = origin_row;
        endcase
    end

    // generate ghost tiles
    FallingTetrominoRender ftr_ghost_inst (
        .origin_row             (hard_drop_row),
        .origin_col             (hard_drop_col),
        .falling_type_in        (falling_type_in),
        .falling_orientation    (hard_drop_orientation),
        .falling_type_out       (),
        .tile_row               (ghost_rows),
        .tile_col               (ghost_cols)
    );
endmodule // ActionStateUpdate