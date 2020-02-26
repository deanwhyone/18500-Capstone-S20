/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages the region to the left of the
 * playfield, showing the currently held tetromino.
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module HoldPixelDriver
    import  DisplayPkg::*,
            GamePkg::*;
(
    input  logic [ 9:0] VGA_row,
    input  logic [ 9:0] VGA_col,

    input  tile_type_t  hold_piece_type,

    output logic [23:0] output_color,
    output logic        active
);
    tile_type_t  tile_type      [HOLD_ROWS][HOLD_COLS];
    logic [ 4:0] origin_row;
    logic [ 4:0] origin_col;

    logic [ 4:0] tile_rows      [4];
    logic [ 4:0] tile_cols      [4];

    always_comb begin
        origin_row = 5'd2;
        origin_col = 5'd2;
        if (hold_piece_type == I) begin
            origin_row = 5'd3;
        end
    end

    always_comb begin
        for (int i = 0; i < HOLD_ROWS; i++) begin
            for (int j = 0; j < HOLD_COLS; j++) begin
                tile_type[i][j] = BLANK;
            end
        end
        for (int i = 0; i < 4; i++) begin
            tile_type[tile_rows[i]][tile_cols[i]] = hold_piece_type;
        end
    end

    always_comb begin
        // default inactive and blank output
        active = 1'b0;
        output_color = TILE_BLANK_COLOR;
        // colorize tiles based on input
        for (int i = 0; i < HOLD_ROWS; i++) begin
            for (int j = 0; j < HOLD_COLS; j++) begin
                if (VGA_row >= (HOLD_VSTART + TILE_HEIGHT * i)      &&
                    VGA_row < (HOLD_VSTART + TILE_HEIGHT * (i + 1)) &&
                    VGA_col >= (HOLD_HSTART + TILE_WIDTH * j)       &&
                    VGA_col < (HOLD_HSTART + TILE_WIDTH * (j + 1))) begin
                    active = 1'b1;
                    case (tile_type[i][j])
                        I:          output_color = TETROMINO_I_COLOR;
                        O:          output_color = TETROMINO_O_COLOR;
                        T:          output_color = TETROMINO_T_COLOR;
                        J:          output_color = TETROMINO_J_COLOR;
                        L:          output_color = TETROMINO_L_COLOR;
                        S:          output_color = TETROMINO_S_COLOR;
                        Z:          output_color = TETROMINO_Z_COLOR;
                        default:    output_color = TILE_BLANK_COLOR;
                    endcase
                end
            end
        end
    end

    FallingTetrominoRender ftr_next_inst (
        .origin_row         (origin_row),
        .origin_col         (origin_col),
        .falling_type       (hold_piece_type),
        .falling_orientation(ORIENTATION_0),
        .tile_row           (tile_rows),
        .tile_col           (tile_cols)
    );
endmodule // HoldPixelDriver