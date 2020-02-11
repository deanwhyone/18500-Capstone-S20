/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages the region to the right of the
 * playfield, showing the next tetrominos the player will receive.
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module NextPixelDriver
    import  DisplayPkg::*,
            GamePkg::*;
(
    input  logic [ 9:0] VGA_row,
    input  logic [ 9:0] VGA_col,

    input  tile_type_t  pieces_queue    [NEXT_PIECES_COUNT],

    output logic [23:0] output_color,
    output logic        active
);

    tile_type_t  tile_type      [NEXT_ROWS][NEXT_COLS];
    logic [ 4:0] origin_row     [NEXT_PIECES_COUNT];
    logic [ 4:0] origin_col     [NEXT_PIECES_COUNT];

    logic [ 4:0] tile_rows      [NEXT_PIECES_COUNT][4];
    logic [ 4:0] tile_cols      [NEXT_PIECES_COUNT][4];

    always_comb begin
        for (int i = 0; i < NEXT_ROWS; i++) begin
            for (int j = 0; j < NEXT_COLS; j++) begin
                tile_type[i][j] = BLANK;
            end
        end
        for (int i = 0; i < NEXT_PIECES_COUNT; i++) begin
            for (int j = 0; j < 4; j++) begin
                tile_type[tile_rows[i][j]][tile_cols[i][j]] = pieces_queue[i];
            end
        end
    end

    always_comb begin
        for (int i = 0; i < NEXT_PIECES_COUNT; i++) begin
            origin_row[i] = 5'(3 * i + 2);
            origin_col[i] = 5'd2;
            if (pieces_queue[i] == I) begin
                origin_row[i] = origin_row[i] + 5'd1;
                origin_col[i] = origin_col[i] + 5'd1;
            end
            if (pieces_queue[i] == O) begin
                origin_col[i] = origin_col[i] + 5'd1;
            end
        end
    end

    always_comb begin
        // default inactive and blank output
        active = 1'b0;
        output_color = TILE_BLANK_COLOR;
        // colorize tiles based on input
        for (int i = 0; i < NEXT_ROWS; i++) begin
            for (int j = 0; j < NEXT_COLS; j++) begin
                if (VGA_row >= (NEXT_VSTART + TILE_HEIGHT * i) &&
                    VGA_row < (NEXT_VSTART + TILE_HEIGHT * (i + 1)) &&
                    VGA_col >= (NEXT_HSTART + TILE_WIDTH * j) &&
                    VGA_col < (NEXT_HSTART + TILE_WIDTH * (j + 1))) begin
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

    genvar g;
    generate
        for (g = 0; g < NEXT_PIECES_COUNT; g++) begin : NEXT_RENDER_G
            FallingTetrominoRender ftr_next_inst (
                .origin_row         (origin_row[g]),
                .origin_col         (origin_col[g]),
                .falling_type_in    (pieces_queue[g]),
                .falling_orientation(ORIENTATION_0),
                .tile_row           (tile_rows[g]),
                .tile_col           (tile_cols[g])
            );
        end
    endgenerate

endmodule // NextPixelDriver