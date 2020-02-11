/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module takes the new origin, type, and orientation of the
 * falling tetromino per state update and outputs the validity of each action,
 * with kicks for rotations. Will use the current locked state to evaluate the
 * validity of each input option and outputs that as well. Hard drop is not
 * present here as hard drop is always valid, by implementation. These valid
 * signals should be used to arm each user input option.
 */
`default_nettype none

module StateUpdateValid
    import DisplayPkg::*,
           GamePkg::*;
(
    input  tile_type_t                  falling_type,

    input  logic [ 4:0]                 rotate_R_row,
    input  logic [ 4:0]                 rotate_R_col,
    input  orientation_t                rotate_R_orientation,

    input  logic [ 4:0]                 rotate_L_row,
    input  logic [ 4:0]                 rotate_L_col,
    input  orientation_t                rotate_L_orientation,

    input  logic [ 4:0]                 move_R_row,
    input  logic [ 4:0]                 move_R_col,
    input  orientation_t                move_R_orientation,

    input  logic [ 4:0]                 move_L_row,
    input  logic [ 4:0]                 move_L_col,
    input  orientation_t                move_L_orientation,

    input  logic [ 4:0]                 soft_drop_row,
    input  logic [ 4:0]                 soft_drop_col,
    input  orientation_t                soft_drop_orientation,

    input  logic [ 3:0]                 locked_state    [PLAYFIELD_ROWS][PLAYFIELD_COLS],

    output logic                        rotate_R_valid,
    output logic [ 4:0]                 rotate_R_row_kick,
    output logic [ 4:0]                 rotate_R_col_kick,

    output logic                        rotate_L_valid,
    output logic [ 4:0]                 rotate_L_row_kick,
    output logic [ 4:0]                 rotate_L_col_kick,

    output logic                        move_R_valid,

    output logic                        move_L_valid,

    output logic                        soft_drop_valid
);

    logic [ 4:0] rotate_R_row_kicked    [TEST_POSITIONS];
    logic [ 4:0] rotate_R_col_kicked    [TEST_POSITIONS];

    logic [ 4:0] rotate_L_row_kicked    [TEST_POSITIONS];
    logic [ 4:0] rotate_L_col_kicked    [TEST_POSITIONS];

    logic [ 4:0] rotate_R_rows          [TEST_POSITIONS][4];
    logic [ 4:0] rotate_R_cols          [TEST_POSITIONS][4];

    logic [ 4:0] rotate_L_rows          [TEST_POSITIONS][4];
    logic [ 4:0] rotate_L_cols          [TEST_POSITIONS][4];

    logic [TEST_POSITIONS-1:0]  rotate_R_valid_TEST;
    logic [TEST_POSITIONS-1:0]  rotate_L_valid_TEST;

    logic [ 4:0] move_R_rows            [4];
    logic [ 4:0] move_R_cols            [4];

    logic [ 4:0] move_L_rows            [4];
    logic [ 4:0] move_L_cols            [4];

    logic [ 4:0] soft_drop_rows         [4];
    logic [ 4:0] soft_drop_cols         [4];

    genvar g;
    generate
        for (g = 0; g < TEST_POSITIONS; g++) begin : wall_kick_test_G
            always_comb begin
                case (rotate_R_orientation)
                    ORIENTATION_0: begin
                        if (falling_type == I) begin
                            rotate_R_row_kicked[g] = rotate_R_row + 5'(WK_I_L0[g][1]);
                            rotate_R_col_kicked[g] = rotate_R_col + 5'(WK_I_L0[g][0]);
                        end else begin
                            rotate_R_row_kicked[g] = rotate_R_row + 5'(WK_NON_I_L0[g][1]);
                            rotate_R_col_kicked[g] = rotate_R_col + 5'(WK_NON_I_L0[g][0]);
                        end
                    end
                    ORIENTATION_R: begin
                        if (falling_type == I) begin
                            rotate_R_row_kicked[g] = rotate_R_row + 5'(WK_I_0R[g][1]);
                            rotate_R_col_kicked[g] = rotate_R_col + 5'(WK_I_0R[g][0]);
                        end else begin
                            rotate_R_row_kicked[g] = rotate_R_row + 5'(WK_NON_I_0R[g][1]);
                            rotate_R_col_kicked[g] = rotate_R_col + 5'(WK_NON_I_0R[g][0]);
                        end
                    end
                    ORIENTATION_2: begin
                        if (falling_type == I) begin
                            rotate_R_row_kicked[g] = rotate_R_row + 5'(WK_I_R2[g][1]);
                            rotate_R_col_kicked[g] = rotate_R_col + 5'(WK_I_R2[g][0]);
                        end else begin
                            rotate_R_row_kicked[g] = rotate_R_row + 5'(WK_NON_I_R2[g][1]);
                            rotate_R_col_kicked[g] = rotate_R_col + 5'(WK_NON_I_R2[g][0]);
                        end
                    end
                    ORIENTATION_L: begin
                        if (falling_type == I) begin
                            rotate_R_row_kicked[g] = rotate_R_row + 5'(WK_I_2L[g][1]);
                            rotate_R_col_kicked[g] = rotate_R_col + 5'(WK_I_2L[g][0]);
                        end else begin
                            rotate_R_row_kicked[g] = rotate_R_row + 5'(WK_NON_I_2L[g][1]);
                            rotate_R_col_kicked[g] = rotate_R_col + 5'(WK_NON_I_2L[g][0]);
                        end
                    end
                endcase
            end
            FallingTetrominoRender ftr_rotate_R_inst (
                .origin_row             (rotate_R_row_kicked[g]),
                .origin_col             (rotate_R_col_kicked[g]),
                .falling_type_in        (falling_type),
                .falling_orientation    (rotate_R_orientation),
                .tile_row               (rotate_R_rows[g]),
                .tile_col               (rotate_R_cols[g])
            );
            always_comb begin
                rotate_R_valid_TEST[g] = 1'b1;
                for (int i = 0; i < 4; i++) begin
                    if (rotate_R_rows[g][i] >= PLAYFIELD_ROWS ||
                        rotate_R_cols[g][i] >= PLAYFIELD_COLS ||
                        locked_state[rotate_R_rows[g][i]][rotate_R_cols[g][i]] != BLANK) begin

                        rotate_R_valid_TEST[g] = 1'b0;
                    end
                end
            end
            always_comb begin
                case (rotate_L_orientation)
                    ORIENTATION_0: begin
                        if (falling_type == I) begin
                            rotate_L_row_kicked[g] = rotate_L_row + 5'(WK_I_R0[g][1]);
                            rotate_L_col_kicked[g] = rotate_L_col + 5'(WK_I_R0[g][0]);
                        end else begin
                            rotate_L_row_kicked[g] = rotate_L_row + 5'(WK_NON_I_R0[g][1]);
                            rotate_L_col_kicked[g] = rotate_L_col + 5'(WK_NON_I_R0[g][0]);
                        end
                    end
                    ORIENTATION_R: begin
                        if (falling_type == I) begin
                            rotate_L_row_kicked[g] = rotate_L_row + 5'(WK_I_2R[g][1]);
                            rotate_L_col_kicked[g] = rotate_L_col + 5'(WK_I_2R[g][0]);
                        end else begin
                            rotate_L_row_kicked[g] = rotate_L_row + 5'(WK_NON_I_2R[g][1]);
                            rotate_L_col_kicked[g] = rotate_L_col + 5'(WK_NON_I_2R[g][0]);
                        end
                    end
                    ORIENTATION_2: begin
                        if (falling_type == I) begin
                            rotate_L_row_kicked[g] = rotate_L_row + 5'(WK_I_L2[g][1]);
                            rotate_L_col_kicked[g] = rotate_L_col + 5'(WK_I_L2[g][0]);
                        end else begin
                            rotate_L_row_kicked[g] = rotate_L_row + 5'(WK_NON_I_L2[g][1]);
                            rotate_L_col_kicked[g] = rotate_L_col + 5'(WK_NON_I_L2[g][0]);
                        end
                    end
                    ORIENTATION_L: begin
                        if (falling_type == I) begin
                            rotate_L_row_kicked[g] = rotate_L_row + 5'(WK_I_0L[g][1]);
                            rotate_L_col_kicked[g] = rotate_L_col + 5'(WK_I_0L[g][0]);
                        end else begin
                            rotate_L_row_kicked[g] = rotate_L_row + 5'(WK_NON_I_0L[g][1]);
                            rotate_L_col_kicked[g] = rotate_L_col + 5'(WK_NON_I_0L[g][0]);
                        end
                    end
                endcase
            end
            FallingTetrominoRender ftr_rotate_L_inst (
                .origin_row             (rotate_L_row_kicked[g]),
                .origin_col             (rotate_L_col_kicked[g]),
                .falling_type_in        (falling_type),
                .falling_orientation    (rotate_L_orientation),
                .tile_row               (rotate_L_rows[g]),
                .tile_col               (rotate_L_cols[g])
            );
            always_comb begin
                rotate_L_valid_TEST[g] = 1'b1;
                for (int i = 0; i < 4; i++) begin
                    if (rotate_L_rows[g][i] >= PLAYFIELD_ROWS ||
                        rotate_L_cols[g][i] >= PLAYFIELD_COLS ||
                        locked_state[rotate_L_rows[g][i]][rotate_L_cols[g][i]] != BLANK) begin

                        rotate_L_valid_TEST[g] = 1'b0;
                    end
                end
            end
        end
    endgenerate

    always_comb begin
        rotate_R_valid      = 1'b0;
        rotate_R_row_kick   = rotate_R_row;
        rotate_R_col_kick   = rotate_R_col;
        for (int i = 0; i < TEST_POSITIONS; i++) begin
            if (rotate_R_valid_TEST[i]) begin
                rotate_R_valid      = 1'b1;
                rotate_R_row_kick   = rotate_R_row_kicked[i];
                rotate_R_col_kick   = rotate_R_col_kicked[i];
                break;
            end
        end
        rotate_L_valid      = 1'b0;
        rotate_L_row_kick   = rotate_L_row;
        rotate_L_col_kick   = rotate_L_col;
        for (int i = 0; i < TEST_POSITIONS; i++) begin
            if (rotate_L_valid_TEST[i]) begin
                rotate_L_valid      = 1'b1;
                rotate_L_row_kick   = rotate_L_row_kicked[i];
                rotate_L_col_kick   = rotate_L_col_kicked[i];
                break;
            end
        end
    end

    FallingTetrominoRender ftr_move_R_inst (
        .origin_row             (move_R_row),
        .origin_col             (move_R_col),
        .falling_type_in        (falling_type),
        .falling_orientation    (move_R_orientation),
        .tile_row               (move_R_rows),
        .tile_col               (move_R_cols)
    );

    always_comb begin
        move_R_valid = 1'b1;
        for (int i = 0; i < 4; i++) begin
            if (move_R_cols[i] >= PLAYFIELD_COLS ||
                locked_state[move_R_rows[i]][move_R_cols[i]] != BLANK) begin

                move_R_valid = 1'b0;
            end
        end
    end

    FallingTetrominoRender ftr_move_L_inst (
        .origin_row             (move_L_row),
        .origin_col             (move_L_col),
        .falling_type_in        (falling_type),
        .falling_orientation    (move_L_orientation),
        .tile_row               (move_L_rows),
        .tile_col               (move_L_cols)
    );

    always_comb begin
        move_L_valid = 1'b1;
        for (int i = 0; i < 4; i++) begin
            if (move_L_cols[i] >= PLAYFIELD_COLS ||
                locked_state[move_L_rows[i]][move_L_cols[i]] != BLANK) begin

                move_L_valid = 1'b0;
            end
        end
    end

    FallingTetrominoRender ftr_soft_drop_inst (
        .origin_row             (soft_drop_row),
        .origin_col             (soft_drop_col),
        .falling_type_in        (falling_type),
        .falling_orientation    (soft_drop_orientation),
        .tile_row               (soft_drop_rows),
        .tile_col               (soft_drop_cols)
    );

    always_comb begin
        soft_drop_valid = 1'b1;
        for (int i = 0; i < 4; i++) begin
            if (soft_drop_rows[i] >= PLAYFIELD_ROWS ||
                locked_state[soft_drop_rows[i]][soft_drop_cols[i]] != BLANK) begin

                soft_drop_valid = 1'b0;
            end
        end
    end

endmodule // StateUpdateValid