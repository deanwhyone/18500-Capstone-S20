/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages the region to the left of the
 * playfield, the number of lines the player cleared.
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module LinesPixelDriver
    import  DisplayPkg::*,
            GamePkg::*;
(
    input  logic [ 9:0]     VGA_row,
    input  logic [ 9:0]     VGA_col,
    input  logic [ 9:0]     lines_cleared,
    input  logic [ 9:0]     lines_sent,
    output logic [23:0]     output_color,
    output logic            active
);
    localparam WORD_LENGTH_1 = 5;
    localparam WORD_LENGTH_2 = 7;
    localparam WORD_LENGTH_3 = 4;

    logic [ 7:0]                word_lines          [WORD_LENGTH_1];
    logic [ 7:0]                word_cleared        [WORD_LENGTH_2];
    logic [ 7:0]                word_sent           [WORD_LENGTH_3];

    logic [ 7:0]                lc_hundreds_digit;
    logic [ 7:0]                lc_tens_digit;
    logic [ 7:0]                lc_ones_digit;

    logic [ 7:0]                ls_hundreds_digit;
    logic [ 7:0]                ls_tens_digit;
    logic [ 7:0]                ls_ones_digit;

    logic [WORD_LENGTH_1 - 1:0] actives_lines_lc;
    logic [WORD_LENGTH_1 - 1:0] actives_lines_ls;
    logic [WORD_LENGTH_2 - 1:0] actives_cleared;
    logic [WORD_LENGTH_3 - 1:0] actives_sent;
    logic                       active_lc_hundreds;
    logic                       active_lc_tens;
    logic                       active_lc_ones;
    logic                       active_ls_hundreds;
    logic                       active_ls_tens;
    logic                       active_ls_ones;
    logic                       active_char;

    always_comb begin
        word_lines      = '{"L", "I", "N", "E", "S"};
        word_cleared    = '{"C", "L", "E", "A", "R", "E", "D"};
        word_sent       = '{"S", "E", "N", "T"};
    end

    genvar g;
    generate
        for (g = 0; g < WORD_LENGTH_1; g++) begin : STRING_LC_LINES_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (LINES_VSTART),
                .ORIGIN_COL (LINES_HSTART + 14 * g)
            ) ar_lc_lines_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_lines[g]),
                .active     (actives_lines_lc[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_2; g++) begin : STRING_LC_CLEARED_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (LINES_VSTART + 15),
                .ORIGIN_COL (LINES_HSTART + 14 * g)
            ) ar_lc_cleared_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_cleared[g]),
                .active     (actives_cleared[g])
            );
        end
    endgenerate

    assign lc_hundreds_digit = 8'(lines_cleared / 10'd100);
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (LINES_VSTART + 30),
        .ORIGIN_COL (LINES_HSTART)
    ) ar_lc_hundreds_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (lc_hundreds_digit + 8'h30),
        .active     (active_lc_hundreds)
    );

    assign lc_tens_digit = 8'((lines_cleared / 10'd10) % 10'd10);
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (LINES_VSTART + 30),
        .ORIGIN_COL (LINES_HSTART + 14)
    ) ar_lc_tens_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (lc_tens_digit + 8'h30),
        .active     (active_lc_tens)
    );

    assign lc_ones_digit = 8'(lines_cleared % 10'd10);
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (LINES_VSTART + 30),
        .ORIGIN_COL (LINES_HSTART + 28)
    ) ar_lc_ones_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (lc_ones_digit + 8'h30),
        .active     (active_lc_ones)
    );

    generate
        for (g = 0; g < WORD_LENGTH_1; g++) begin : STRING_LS_LINES_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (LINES_VSTART + 45),
                .ORIGIN_COL (LINES_HSTART + 14 * g)
            ) ar_ls_lines_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_lines[g]),
                .active     (actives_lines_ls[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_3; g++) begin : STRING_LS_SENT_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (LINES_VSTART + 60),
                .ORIGIN_COL (LINES_HSTART + 14 * g)
            ) ar_ls_cleared_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_sent[g]),
                .active     (actives_sent[g])
            );
        end
    endgenerate

    assign ls_hundreds_digit = 8'(lines_sent / 10'd100);
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (LINES_VSTART + 75),
        .ORIGIN_COL (LINES_HSTART)
    ) ar_ls_hundreds_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (ls_hundreds_digit + 8'h30),
        .active     (active_ls_hundreds)
    );

    assign ls_tens_digit = 8'((lines_sent / 10'd10) % 10'd10);
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (LINES_VSTART + 75),
        .ORIGIN_COL (LINES_HSTART + 14)
    ) ar_ls_tens_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (ls_tens_digit + 8'h30),
        .active     (active_ls_tens)
    );

    assign ls_ones_digit = 8'(lines_sent % 10'd10);
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (LINES_VSTART + 75),
        .ORIGIN_COL (LINES_HSTART + 28)
    ) ar_ls_ones_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (ls_ones_digit + 8'h30),
        .active     (active_ls_ones)
    );

    always_comb begin
        active_char =   (|actives_lines_lc) ||
                        (|actives_cleared)  ||
                        active_lc_hundreds  ||
                        active_lc_tens      ||
                        active_lc_ones      ||
                        (|actives_lines_ls) ||
                        (|actives_sent)     ||
                        active_ls_hundreds  ||
                        active_ls_tens      ||
                        active_ls_ones;
    end

    always_comb begin
        output_color    = BG_COLOR;
        if (active_char) begin
            output_color = 24'hff_ffff;
        end
    end

    always_comb begin
        active = 1'b0;
        if (VGA_row >= LINES_VSTART &&
            VGA_row <  LINES_VEND   &&
            VGA_col >= LINES_HSTART &&
            VGA_col <  LINES_HEND) begin

            active = 1'b1;
        end
    end
endmodule // LinesPixelDriver