/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module parameterizes the scaling and origin of rendered alphanumerals.
 * origin is the top left corner of the character. Scale is natural numbers
 * and the base size of the alphanumerals are 6x6 pixels
 */
`default_nettype none

module AlphanumeralRender # (
    parameter SCALE         = 1,
    parameter ORIGIN_ROW    = 0,
    parameter ORIGIN_COL    = 0
) (
    input  logic [ 9:0] VGA_row,
    input  logic [ 9:0] VGA_col,
    input  logic [ 7:0] character,

    output logic active
);
    localparam TYPE_WIDTH   = 6;

    logic [ 0:5] bitmap [6];
    logic [ 2:0] char_row_count;
    logic [ 2:0] char_col_count;

    always_comb begin
        active          = 1'b0;
        char_row_count  = '0;
        char_col_count  = '0;
        if ((VGA_row >= ORIGIN_ROW) &&
            (VGA_col >= ORIGIN_COL) &&
            (VGA_row <  ORIGIN_ROW + (TYPE_WIDTH * SCALE)) &&
            (VGA_col <  ORIGIN_COL + (TYPE_WIDTH * SCALE))) begin

            char_row_count = 3'((VGA_row - ORIGIN_ROW)/SCALE);
            char_col_count = 3'((VGA_col - ORIGIN_COL)/SCALE);
            active = bitmap[char_row_count][char_col_count];
        end
    end

    AlphanumeralBitMap ABM_inst (
        .character  (character),
        .bitmap     (bitmap)
    );
endmodule // AlphanumeralRender