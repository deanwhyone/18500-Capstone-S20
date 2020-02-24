/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This package contains useful constants intended to inform the boundaries
 * and sizes of various elements on the display
 */
`default_nettype none

`ifndef DISPLAY_PKG_READ
`define DISPLAY_PKG_READ

package DisplayPkg;
    parameter VGA_WIDTH                 = 640;
    parameter VGA_HEIGHT                = 480;

    parameter PLAYFIELD_ROWS            = 20;
    parameter PLAYFIELD_COLS            = 10;

    parameter PLAYFIELD_HSTART          = 240;
    parameter PLAYFIELD_HEND            = 400;
    parameter PLAYFIELD_VSTART          = 60;
    parameter PLAYFIELD_VEND            = 460;

    parameter TILE_WIDTH                =
        (PLAYFIELD_HEND - PLAYFIELD_HSTART) / PLAYFIELD_COLS;
    parameter TILE_HEIGHT               =
        (PLAYFIELD_VEND - PLAYFIELD_VSTART) / PLAYFIELD_ROWS;

    parameter BORDER_HSTART             = PLAYFIELD_HSTART - 5;
    parameter BORDER_HEND               = PLAYFIELD_HEND + 5;
    parameter BORDER_VSTART             = PLAYFIELD_VSTART - 5;
    parameter BORDER_VEND               = PLAYFIELD_VEND + 5;

    parameter NEXT_ROWS                 = 19;
    parameter NEXT_COLS                 = 6;

    parameter NEXT_HSTART               = PLAYFIELD_HEND + 5;
    parameter NEXT_HEND                 = NEXT_HSTART + NEXT_COLS * TILE_WIDTH;
    parameter NEXT_VSTART               = PLAYFIELD_VSTART;
    parameter NEXT_VEND                 = NEXT_VSTART + NEXT_ROWS * TILE_HEIGHT;

    parameter LC_HSTART                 = BORDER_HSTART - 100;
    parameter LC_HEND                   = BORDER_HSTART;
    parameter LC_VSTART                 = PLAYFIELD_VEND - 48;
    parameter LC_VEND                   = PLAYFIELD_VEND;

    parameter TIMER_HSTART              = LC_HSTART;
    parameter TIMER_HEND                = LC_HEND;
    parameter TIMER_VSTART              = LC_VSTART - 16;
    parameter TIMER_VEND                = LC_VSTART;

    parameter BG_COLOR                  = 24'h40_4040;
    parameter BORDER_COLOR              = 24'hff_ffff;
    parameter TILE_BLANK_COLOR          = 24'h00_0000;
    parameter TILE_GARBAGE_COLOR        = 24'haa_aaaa;
    parameter TILE_GHOST_COLOR          = 24'h80_8080;
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

    function int countSetBits;
        input logic [PLAYFIELD_ROWS - 1:0] bits;
        int set_bit_count;
        set_bit_count = 0;
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            set_bit_count = set_bit_count + bits[i];
        end
        return set_bit_count;
    endfunction
endpackage // DisplayPkg

`endif