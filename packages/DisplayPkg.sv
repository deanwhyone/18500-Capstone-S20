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
    parameter SVGA_WIDTH            = 800;
    parameter SVGA_HEIGHT           = 600;
    parameter REFRESH_CLK_CYCLES    = 694445;

    parameter PLAYFIELD_ROWS        = 20;
    parameter PLAYFIELD_COLS        = 10;

    parameter PF_USER_HSTART        = 130;
    parameter PF_USER_HEND          = 330;
    parameter PF_USER_VSTART        = 80;
    parameter PF_USER_VEND          = 560;

    parameter PF_LAN_HSTART         = 510;
    parameter PF_LAN_HEND           = 710;
    parameter PF_LAN_VSTART         = PF_USER_VSTART;
    parameter PF_LAN_VEND           = PF_USER_VEND;

    parameter TILE_WIDTH            =
        (PF_USER_HEND - PF_USER_HSTART) / PLAYFIELD_COLS;
    parameter TILE_HEIGHT           =
        (PF_USER_VEND - PF_USER_VSTART) / PLAYFIELD_ROWS;
    parameter MINI_TILE_WIDTH       = TILE_WIDTH / 2;
    parameter MINI_TILE_HEIGHT      = TILE_HEIGHT / 2;

    parameter BORDER_USER_PF_HSTART = PF_USER_HSTART - 10;
    parameter BORDER_USER_PF_HEND   = PF_USER_HEND + 10;
    parameter BORDER_USER_PF_VSTART = PF_USER_VSTART - 10;
    parameter BORDER_USER_PF_VEND   = PF_USER_VEND + 10;

    parameter BORDER_LAN_PF_HSTART  = PF_LAN_HSTART - 10;
    parameter BORDER_LAN_PF_HEND    = PF_LAN_HEND + 10;
    parameter BORDER_LAN_PF_VSTART  = PF_LAN_VSTART - 10;
    parameter BORDER_LAN_PF_VEND    = PF_LAN_VEND + 10;

    parameter NEXT_ROWS             = 19;
    parameter NEXT_COLS             = 6;

    parameter NEXT_USER_HSTART      = BORDER_USER_PF_HEND;
    parameter NEXT_USER_HEND        = NEXT_USER_HSTART + NEXT_COLS * MINI_TILE_WIDTH;
    parameter NEXT_USER_VSTART      = PF_USER_VSTART;
    parameter NEXT_USER_VEND        = NEXT_USER_VSTART + NEXT_ROWS * MINI_TILE_HEIGHT;

    parameter NEXT_LAN_HSTART       = BORDER_LAN_PF_HEND;
    parameter NEXT_LAN_HEND         = NEXT_LAN_HSTART + NEXT_COLS * MINI_TILE_WIDTH;
    parameter NEXT_LAN_VSTART       = PF_LAN_VSTART;
    parameter NEXT_LAN_VEND         = NEXT_LAN_VSTART + NEXT_ROWS * MINI_TILE_HEIGHT;

    parameter BORDER_USER_N_HSTART  = NEXT_USER_HSTART - 10;
    parameter BORDER_USER_N_HEND    = NEXT_USER_HEND + 10;
    parameter BORDER_USER_N_VSTART  = NEXT_USER_VSTART - 10;
    parameter BORDER_USER_N_VEND    = NEXT_USER_VEND + 10;

    parameter BORDER_LAN_N_HSTART   = NEXT_LAN_HSTART - 10;
    parameter BORDER_LAN_N_HEND     = NEXT_LAN_HEND + 10;
    parameter BORDER_LAN_N_VSTART   = NEXT_LAN_VSTART - 10;
    parameter BORDER_LAN_N_VEND     = NEXT_LAN_VEND + 10;

    parameter HOLD_ROWS             = 4;
    parameter HOLD_COLS             = 6;

    parameter HOLD_USER_HSTART      = BORDER_USER_PF_HSTART - HOLD_COLS * MINI_TILE_WIDTH;
    parameter HOLD_USER_HEND        = BORDER_USER_PF_HSTART;
    parameter HOLD_USER_VSTART      = PF_USER_VSTART;
    parameter HOLD_USER_VEND        = HOLD_USER_VSTART + HOLD_ROWS * MINI_TILE_HEIGHT;

    parameter HOLD_LAN_HSTART       = BORDER_LAN_PF_HSTART - HOLD_COLS * MINI_TILE_WIDTH;
    parameter HOLD_LAN_HEND         = BORDER_LAN_PF_HSTART;
    parameter HOLD_LAN_VSTART       = PF_LAN_VSTART;
    parameter HOLD_LAN_VEND         = HOLD_LAN_VSTART + HOLD_ROWS * MINI_TILE_HEIGHT;

    parameter BORDER_USER_H_HSTART  = HOLD_USER_HSTART - 10;
    parameter BORDER_USER_H_HEND    = HOLD_USER_HEND + 10;
    parameter BORDER_USER_H_VSTART  = HOLD_USER_VSTART - 10;
    parameter BORDER_USER_H_VEND    = HOLD_USER_VEND + 10;

    parameter BORDER_LAN_H_HSTART   = HOLD_LAN_HSTART - 10;
    parameter BORDER_LAN_H_HEND     = HOLD_LAN_HEND + 10;
    parameter BORDER_LAN_H_VSTART   = HOLD_LAN_VSTART - 10;
    parameter BORDER_LAN_H_VEND     = HOLD_LAN_VEND + 10;

    parameter LINES_HSTART          = BORDER_USER_PF_HSTART - 100;
    parameter LINES_HEND            = BORDER_USER_PF_HSTART;
    parameter LINES_VSTART          = PF_USER_VEND - 100;
    parameter LINES_VEND            = PF_USER_VEND;

    parameter TIMER_HSTART          = LINES_HSTART;
    parameter TIMER_HEND            = LINES_HEND;
    parameter TIMER_VSTART          = LINES_VSTART - 20;
    parameter TIMER_VEND            = LINES_VSTART;

    parameter PENDING_HSTART        = BORDER_USER_PF_HSTART - 30;
    parameter PENDING_HEND          = BORDER_USER_PF_HSTART;
    parameter PENDING_VSTART        = BORDER_USER_H_VEND;
    parameter PENDING_VEND          = TIMER_VSTART - 10;
    parameter PENDING_HEIGHT        = PENDING_VEND - PENDING_VSTART;
    parameter PENDING_TICK          = PENDING_HEIGHT / 20;

    parameter FRAMES_HSTART         = 0;
    parameter FRAMES_HEND           = 45;
    parameter FRAMES_VSTART         = 0;
    parameter FRAMES_VEND           = 15;

    parameter BG_COLOR              = 24'h40_4040;
    parameter BORDER_COLOR          = 24'hff_ffff;
    parameter BORDER_COLOR_ALT      = 24'h00_ffff;
    parameter TILE_BLANK_COLOR      = 24'h00_0000;
    parameter TILE_GARBAGE_COLOR    = 24'haa_aaaa;
    parameter TILE_GHOST_COLOR      = 24'h80_8080;
    parameter TETROMINO_I_COLOR     = 24'h00_ffff;
    parameter TETROMINO_O_COLOR     = 24'hff_ff00;
    parameter TETROMINO_T_COLOR     = 24'hff_00ff;
    parameter TETROMINO_J_COLOR     = 24'h00_00ff;
    parameter TETROMINO_L_COLOR     = 24'hff_8000;
    parameter TETROMINO_S_COLOR     = 24'h00_ff00;
    parameter TETROMINO_Z_COLOR     = 24'hff_0000;

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
        input logic bits [PLAYFIELD_ROWS];
        int set_bit_count;
        set_bit_count = 0;
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            set_bit_count = set_bit_count + bits[i];
        end
        return set_bit_count;
    endfunction
endpackage // DisplayPkg

`endif