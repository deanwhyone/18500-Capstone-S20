/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages the playfield exclusively.
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module PlayfieldPixelDriver
    import DisplayPkg::*;
#(
    parameter HSTART,
    parameter VSTART
) (
    input  logic [ 9:0] VGA_row,
    input  logic [ 9:0] VGA_col,

    input  tile_type_t  playfield_data  [PLAYFIELD_ROWS][PLAYFIELD_COLS],

    output logic [23:0] output_color,
    output logic        active
);

    always_comb begin
        // default inactive and blank output
        active = 1'b0;
        output_color = TILE_BLANK_COLOR;
        // colorize tiles based on input
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                if (VGA_row >= (VSTART + TILE_HEIGHT * i)       &&
                    VGA_row < (VSTART + TILE_HEIGHT * (i + 1))  &&
                    VGA_col >= (HSTART + TILE_WIDTH * j)        &&
                    VGA_col < (HSTART + TILE_WIDTH * (j + 1))) begin
                    active = 1'b1;
                    case (playfield_data[i][j])
                        GARBAGE:    output_color = TILE_GARBAGE_COLOR;
                        GHOST:      output_color = TILE_GHOST_COLOR;
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

endmodule // PlayfieldPixelDriver