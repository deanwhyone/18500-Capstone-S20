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

module LinesClearedPixelDriver
    import  DisplayPkg::*,
            GamePkg::*;
(
    input  logic [ 9:0]     VGA_row,
    input  logic [ 9:0]     VGA_col,
    output logic [23:0]     output_color,
    output logic            active
);
    localparam WORD_LENGTH_1 = 5;
    localparam WORD_LENGTH_2 = 8;

    logic [ 7:0]                word_1          [WORD_LENGTH_1];
    logic [ 7:0]                word_2          [WORD_LENGTH_2];

    logic [WORD_LENGTH_1 - 1:0] actives_1;
    logic [WORD_LENGTH_2 - 1:0] actives_2;
    logic                       active_char;

    always_comb begin
        word_1 = '{"L", "I", "N", "E", "S"};
        word_2 = '{"C", "L", "E", "A", "R", "E", "D", ":"};
    end

    genvar g;
    generate
        for (g = 0; g < WORD_LENGTH_1; g++) begin : STRING_LINES_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (LC_VSTART),
                .ORIGIN_COL (LC_HSTART + 15 * g)
            ) ar_inst_lines (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_1[g]),
                .active     (actives_1[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_2; g++) begin : STRING_CLEARED_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (LC_VSTART + 50),
                .ORIGIN_COL (LC_HSTART + 15 * g)
            ) ar_inst_lines (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_2[g]),
                .active     (actives_2[g])
            );
        end
    endgenerate

    always_comb begin
        active_char = (|actives_1) || (|actives_2);

    end

    always_comb begin
        output_color    = BG_COLOR;
        if (active_char) begin
            output_color = 24'hff_ffff;
        end
    end

    always_comb begin
        active = 1'b0;
        if (VGA_row >= LC_VSTART &&
            VGA_row <  LC_VEND   &&
            VGA_col >= LC_HSTART &&
            VGA_col <  LC_HEND) begin

            active = 1'b1;
        end
    end
endmodule // LinesClearedPixelDriver