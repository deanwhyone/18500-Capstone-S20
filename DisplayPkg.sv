/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This package contains useful constants intended to inform the boundaries
 * and sizes of various elements on the display
 */
`default_nettype none

package DisplayPkg;
    parameter VGA_WIDTH                 = 640;
    parameter VGA_HEIGHT                = 480;

    parameter PLAYFIELD_COLS            = 10;
    parameter PLAYFIELD_ROWS            = 20;

    parameter PLAYFIELD_HSTART          = 240;
    parameter PLAYFIELD_HEND            = 400;
    parameter PLAYFIELD_VSTART          = 60;
    parameter PLAYFIELD_VEND            = 460;

    parameter TILE_WIDTH                =
        (PLAYFIELD_HEND - PLAYFIELD_HSTART) / PLAYFIELD_COLS;
    parameter TILE_HEIGHT               =
        (PLAYFIELD_VEND - PLAYFIELD_VSTART) / PLAYFIELD_ROWS;

    parameter BG_COLOR                  = 24'h10_1010;
    parameter TILE_COLOR                = 24'h00_0000;
    parameter GRID_COLOR                = 24'h20_2020;
    parameter TETROMINO_I_COLOR         = 24'h00_fdff;
    parameter TETROMINO_O_COLOR         = 24'hff_ff00;
    parameter TETROMINO_T_COLOR         = 24'hff_00ff;
    parameter TETROMINO_J_COLOR         = 24'h00_00ff;
    parameter TETROMINO_L_COLOR         = 24'hff_8000;
    parameter TETROMINO_S_COLOR         = 24'h00_ff00;
    parameter TETROMINO_Z_COLOR         = 24'hff_0000;

    typedef enum logic [3:0] {
        BLANK,
        GARBAGE,
        GHOST,
        I,
        O,
        T,
        J,
        L,
        S,
        Z
    } tile_type_t;

endpackage // DisplayPkg