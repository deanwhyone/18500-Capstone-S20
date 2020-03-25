/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages modern Tetris Logo
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module StartScreenPixelDriver
    import DisplayPkg::*;
(
    input  logic        clk,
    input  logic [ 9:0] VGA_row,
    input  logic [ 9:0] VGA_col,

    output logic [23:0] output_color,
    output logic        active
);
    parameter LOGO_ROWS        = 187;
    parameter LOGO_COLS        = 269;
    parameter LOGO_ORIGIN_ROW  = 100;
    parameter LOGO_ORIGIN_COL  = 100;

    logic [ 9:0] VGA_row_LA;
    logic [ 9:0] VGA_col_LA;
    logic [ 9:0] VGA_relative_row;
    logic [ 9:0] VGA_relative_col;
    logic [16:0] rom_addr;

    always_comb begin
        VGA_row_LA = VGA_row;
        VGA_col_LA = VGA_col + 10'd1;
        if (VGA_col_LA == SVGA_WIDTH) begin
            VGA_row_LA = VGA_row + 10'd1;
            VGA_col_LA = '0;
            if (VGA_col_LA == SVGA_HEIGHT) begin
                VGA_row_LA = '0;
            end
        end
    end

    always_comb begin
        VGA_relative_row    = VGA_row_LA - 10'(LOGO_ORIGIN_ROW);
        VGA_relative_col    = VGA_col_LA - 10'(LOGO_ORIGIN_COL);
        rom_addr            = 17'(VGA_relative_row) * 17'(LOGO_COLS) +
                              17'(VGA_relative_col);
    end

    logo_rom logo_rom_inst (
        .clock      (clk),
        .address    (rom_addr),
        .q          (output_color) // will be offset?
    );

    always_comb begin
        active = 1'b0;
        if ((VGA_row >= LOGO_ORIGIN_ROW) &&
            (VGA_col >= LOGO_ORIGIN_COL) &&
            (VGA_row <  LOGO_ORIGIN_ROW + LOGO_ROWS) &&
            (VGA_col <  LOGO_ORIGIN_COL + LOGO_COLS)) begin

            active = 1'b1;
        end
    end
endmodule // StartScreenPixelDriver