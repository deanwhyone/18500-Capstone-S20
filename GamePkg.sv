/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This package contains useful constants intended to inform the game aspects
 * of the Tetris implementation. We are using the SRS guideline for kick tables
 * as written in the Tetri Wiki at https://tetris.wiki/Super_Rotation_System
 */
`default_nettype none

package GamePkg;
    // kick tables
    parameter TEST_POSITIONS = 5;

    // non-I tetromino wall kicks
    parameter integer WK_NON_I_0R [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{-1, 1}, '{0, -2}, '{-1, -2}};
    parameter integer WK_NON_I_R0 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{1, -1}, '{0, 2}, '{1, 2}};
    parameter integer WK_NON_I_R2 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{1, -1}, '{0, 2}, '{1, 2}};
    parameter integer WK_NON_I_2R [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{-1, 1}, '{0, -2}, '{-1, -2}};
    parameter integer WK_NON_I_2L [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{1, 1}, '{0, -2}, '{1, -2}};
    parameter integer WK_NON_I_L2 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{-1, -1}, '{0, 2}, '{-1, 2}};
    parameter integer WK_NON_I_L0 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{-1, -1}, '{0, 2}, '{-1, 2}};
    parameter integer WK_NON_I_0L [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{1, 1}, '{0, -2}, '{1, -2}};

    // I tetromino wall kicks
    parameter integer WK_I_0R [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-2, 0}, '{1, 0}, '{-2, -1}, '{1, 2}};
    parameter integer WK_I_R0 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{2, 0}, '{-1, 0}, '{2, 1}, '{-1, -2}};
    parameter integer WK_I_R2 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{2, 0}, '{-1, 2}, '{2, -1}};
    parameter integer WK_I_2R [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{-2, 0}, '{1, -2}, '{-2, 1}};
    parameter integer WK_I_2L [TEST_POSITIONS][2] =
        '{'{0, 0}, '{2, 0}, '{-1, 0}, '{2, 1}, '{-1, -2}};
    parameter integer WK_I_L2 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-2, 0}, '{1, 0}, '{-2, -1}, '{1, 2}};
    parameter integer WK_I_L0 [TEST_POSITIONS][2] =
        '{'{0, 0}, '{1, 0}, '{-2, 0}, '{1, -2}, '{-2, 1}};
    parameter integer WK_I_0L [TEST_POSITIONS][2] =
        '{'{0, 0}, '{-1, 0}, '{2, 0}, '{-1, 2}, '{2, -1}};
endpackage // GamePkg