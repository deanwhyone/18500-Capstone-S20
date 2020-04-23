/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages the region at the top left of the
 * screen, showing the current frame count.
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module FramesPixelDriver
    import DisplayPkg::*;
#(
    parameter HSTART,
    parameter HEND,
    parameter VSTART,
    parameter VEND
) (
    input  logic [ 9:0] VGA_row,
    input  logic [ 9:0] VGA_col,

    input  logic [ 7:0] frame_count,

    output logic [23:0] output_color,
    output logic        active
);

    logic active_char;
    logic [ 7:0] frame_hundreds_digit;
    logic [ 7:0] frame_tens_digit;
    logic [ 7:0] frame_ones_digit;
    logic        active_hundreds_digit;
    logic        active_tens_digit;
    logic        active_ones_digit;

    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (VSTART),
        .ORIGIN_COL (HSTART)
    ) ar_frame_hundreds_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (frame_hundreds_digit + 8'h30),
        .active     (active_hundreds_digit)
    );
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (VSTART),
        .ORIGIN_COL (HSTART + 15)
    ) ar_frame_tens_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (frame_tens_digit + 8'h30),
        .active     (active_tens_digit)
    );
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (VSTART),
        .ORIGIN_COL (HSTART + 30)
    ) ar_frame_ones_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (frame_ones_digit + 8'h30),
        .active     (active_ones_digit)
    );
    always_comb begin
        frame_hundreds_digit    = 8'(frame_count / 10'd100);
        frame_tens_digit        = 8'((frame_count / 10'd10) % 10'd10);
        frame_ones_digit        = 8'(frame_count % 10'd10);
    end

    always_comb begin
        active_char =   active_hundreds_digit   ||
                        active_tens_digit       ||
                        active_ones_digit;
    end

    always_comb begin
        output_color    = BG_COLOR;
        if (active_char) begin
            output_color = 24'hff_ffff;
        end
    end

    always_comb begin
        active = 1'b0;
        if (VGA_row >= VSTART   &&
            VGA_row <  VEND     &&
            VGA_col >= HSTART   &&
            VGA_col <  HEND) begin

            active = 1'b1;
        end
    end
endmodule // FramesPixelDriver