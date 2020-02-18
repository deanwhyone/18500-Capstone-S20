/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This is a SVGA interface that follows the standard SVGA protocol for
 * 800x600 display @ 72 fps. This is largely adapted from the VGA module given
 * in 18240 Lab 5 for Mastermind.
 */
`default_nettype none

module SVGA (
    output logic [ 9:0] row,
    output logic [ 9:0] col,
    output logic        HS,
    output logic        VS,
    output logic        blank,
    input  logic        clk,
    input  logic        reset
);

    logic [10:0]    col_count;
    logic           col_clear;
    logic           col_enable;
    logic [ 9:0]    row_count;
    logic           row_clear;
    logic           row_enable;
    logic           h_blank;
    logic           v_blank;

    // Row counter counts from 0 to 665
    //     count of   0 - 599 is display time
    //     count of 600 - 636 is front porch
    //     count of 637 - 642 is VS=0 pulse width
    //     count of 643 - 665 is back porch

    simple_counter #(
        .WIDTH  (10)
    ) row_counter (
        .Q      (row_count),
        .en     (row_enable),
        .clr    (row_clear),
        .clk    (clk),
        .reset  (reset)
    );

    assign row        = row_count;
    assign row_clear  = (row_count >= 10'd665);
    assign row_enable = (col_count == 11'd1039);
    assign VS         = (row_count >= 10'd637) && (row_count < 10'd643);
    assign v_blank    = (row_count >= 10'd600);

    // Col counter counts from 0 to 1039
    //     count of    0 -  799 is display time
    //     count of  800 -  855 is front porch
    //     count of  856 -  975 is HS=0 pulse width
    //     count of  976 - 1039 is back porch

    simple_counter #(
        .WIDTH  (11)
    ) col_counter (
        .Q      (col_count),
        .en     (col_enable),
        .clr    (col_clear),
        .clk    (clk),
        .reset  (reset)
    );

    assign col        = col_count[9:0];
    assign col_clear  = (col_count >= 11'd1039);
    assign col_enable = 1'b1;
    assign HS         = (col_count >= 11'd856) && (col_count < 11'd976);
    assign h_blank    = col_count >= 11'd800;

    assign blank      = h_blank | v_blank;

endmodule // SVGA

/*****************************************************************
 *
 *                    Library modules
 *
 *****************************************************************/

/** BRIEF
 *  Outputs whether a value lies between [low, high].
 */
module range_check #(
    parameter WIDTH = 4'd10
) (
    input  logic [WIDTH-1:0] val,
    input  logic [WIDTH-1:0] low,
    input  logic [WIDTH-1:0] high,
    output logic             is_between
);

    assign is_between = (val >= low) & (val <= high);

endmodule: range_check

/** BRIEF
 *  Outputs whether a value lies between [low, low + delta].
 */
module offset_check #(
    parameter WIDTH = 4'd10
) (
    input  logic [WIDTH-1:0] val,
    input  logic [WIDTH-1:0] low,
    input  logic [WIDTH-1:0] delta,
    output logic             is_between
);

    assign is_between = ((val >= low) & (val < (low+delta)));

endmodule: offset_check

/** BRIEF
 *  Simple up counter with synchronous clear and enable.
 *  Clear takes precedence over enable.
 */
module simple_counter #(
    parameter WIDTH = 4'd8
) (
    output logic [WIDTH-1:0] Q,
    input  logic             clk,
    input  logic             en,
    input  logic             clr,
    input  logic             reset
);

    always_ff @(posedge clk, posedge reset)
        if (reset)
            Q <= 'b0;
        else if (clr)
            Q <= 'b0;
        else if (en)
            Q <= (Q + 1'b1);

endmodule: simple_counter
