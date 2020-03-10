/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages alerting the user when a tspin is
 * detected.
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module TSpinPixelDriver
    import DisplayPkg::*;
#(
    parameter HSTART,
    parameter HEND,
    parameter VSTART,
    parameter VEND
) (
    input  logic [ 9:0]     VGA_row,
    input  logic [ 9:0]     VGA_col,
    input  logic            tspin_detected,
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
        word_1 = '{"T", "S", "P", "I", "N"};
        word_2 = '{"D", "E", "T", "E", "C", "T", "E", "D"};
    end

    genvar g;
    generate
        for (g = 0; g < WORD_LENGTH_1; g++) begin : STRING_TSPIN_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (VSTART),
                .ORIGIN_COL (HSTART + 14 * g)
            ) tspin_lines_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_1[g]),
                .active     (actives_1[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_2; g++) begin : STRING_DETECTED_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (VSTART + 15),
                .ORIGIN_COL (HSTART + 14 * g)
            ) tspin_cleared_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_2[g]),
                .active     (actives_2[g])
            );
        end
    endgenerate

    assign active_char = (|actives_1) || (|actives_2);

    always_comb begin
        output_color = BG_COLOR;
        if (tspin_detected && active_char) begin
            output_color = 24'hff_ffff;
        end
    end

    always_comb begin
        active = 1'b0;
        if (VGA_row >= VSTART &&
            VGA_row <  VEND   &&
            VGA_col >= HSTART &&
            VGA_col <  HEND) begin

            active = 1'b1;
        end
    end
endmodule //TSpinPixelDriver