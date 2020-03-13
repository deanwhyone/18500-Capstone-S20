/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages the region to the left of the
 * playfield, showing the number of pending garbage that the player will have
 * loaded into their playfield in a graphical manner.
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module PendingPixelDriver
    import DisplayPkg::*;
#(
    parameter HSTART,
    parameter HEND,
    parameter VSTART,
    parameter VEND
) (
    input  logic [ 9:0] VGA_row,
    input  logic [ 9:0] VGA_col,

    input  logic [ 4:0] pending_garbage,

    output logic [23:0] output_color,
    output logic        active
);
    assign output_color = TETROMINO_Z_COLOR;

    always_comb begin
        active = 1'b0;
        if (VGA_row >= VSTART   &&
            VGA_row <  VEND     &&
            VGA_col >= HSTART   &&
            VGA_col <  HEND     &&
            VGA_row >= (VEND - (PENDING_TICK * pending_garbage))) begin

            active = 1'b1;
        end
    end
endmodule // PendingPixelDriver