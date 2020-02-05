/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This package contains useful constants intended to inform the game aspects
 * of the Tetris implementation. We are using the SRS guideline for kick tables
 * as written in the Tetri Wiki at https://tetris.wiki/Super_Rotation_System
 */
`default_nettype none

`ifndef GAME_PKG_READ
`define GAME_PKG_READ

package GamePkg;
    // tetromino orientations
    typedef enum logic [1:0] {
        ORIENTATION_0,  // spawn state
        ORIENTATION_R,  // right rotation from spawn state
        ORIENTATION_2,  // double rotation from spawn state
        ORIENTATION_L   // left rotation from spawn state
    } orientation_t;

    // kick tables
    parameter TEST_POSITIONS = 5;

    // non-I tetromino wall kicks
    parameter integer WK_NON_I_0R [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{-1, -1}, '{0, 2}, '{-1, 2}};
    parameter integer WK_NON_I_R0 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{1, 1}, '{0, -2}, '{1, -2}};
    parameter integer WK_NON_I_R2 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{1, 1}, '{0, -2}, '{1, -2}};
    parameter integer WK_NON_I_2R [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{-1, -1}, '{0, 2}, '{-1, 2}};
    parameter integer WK_NON_I_2L [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{1, -1}, '{0, 2}, '{1, 2}};
    parameter integer WK_NON_I_L2 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{-1, 1}, '{0, -2}, '{-1, -2}};
    parameter integer WK_NON_I_L0 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{-1, 1}, '{0, -2}, '{-1, -2}};
    parameter integer WK_NON_I_0L [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{1, -1}, '{0, 2}, '{1, 2}};

    // I tetromino wall kicks
    parameter integer WK_I_0R [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-2, 0}, '{1, 0}, '{-2, 1}, '{1, -2}};
    parameter integer WK_I_R0 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{2, 0}, '{-1, 0}, '{2, -1}, '{-1, 2}};
    parameter integer WK_I_R2 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{2, 0}, '{-1, -2}, '{2, 1}};
    parameter integer WK_I_2R [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{-2, 0}, '{1, 2}, '{-2, -1}};
    parameter integer WK_I_2L [TEST_POSITIONS][2] =
        '{'{0, 0}, '{2, 0}, '{-1, 0}, '{2, -1}, '{-1, 2}};
    parameter integer WK_I_L2 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-2, 0}, '{1, 0}, '{-2, 1}, '{1, -2}};
    parameter integer WK_I_L0 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{-2, 0}, '{1, 2}, '{-2, -1}};
    parameter integer WK_I_0L [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{2, 0}, '{-1, -2}, '{2, 1}};

    parameter logic [30:0] SEEDS [4] = '{31'h5eed_cafe,
                                         31'h0b57_ac1e,
                                         31'h0dec_0de5,
                                         31'h0ca5_cade};

    parameter NEXT_PIECES_COUNT         = 6;
endpackage // GamePkg

`endif