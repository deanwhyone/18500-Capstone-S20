/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This is the top module for the graphics drivers. This uses the current row
 * and col that the VGA module is loading and outputs the relevant color as
 * provided by the various drivers used.
 */
`default_nettype none

module GraphicsTop
    import DisplayPkg::*,
           GamePkg::*;
(
    input  logic            clk,
    input  logic [ 9:0]     VGA_row,
    input  logic [ 9:0]     VGA_col,
    input  tile_type_t      tile_type           [PLAYFIELD_ROWS][PLAYFIELD_COLS],
    input  tile_type_t      next_pieces_queue   [NEXT_PIECES_COUNT],
    input  logic            testpattern_active,
    input  game_screens_t   tetris_screen,
    output logic [23:0]     output_color
);

    logic [23:0]    ppd_output_color;
    logic           ppd_active;
    logic [23:0]    npd_output_color;
    logic           npd_active;

    always_comb begin
        output_color    = BG_COLOR;
        if (!testpattern_active) begin
            unique case (tetris_screen)
                START_SCREEN: begin
                    if (VGA_row < 10'd240) begin
                        output_color    = TETROMINO_I_COLOR;
                    end
                end
                SPRINT_MODE: begin
                    // border color
                    if (VGA_row >= BORDER_VSTART && VGA_row < BORDER_VEND &&
                        VGA_col >= BORDER_HSTART && VGA_col < BORDER_HEND) begin
                        output_color    = BORDER_COLOR;
                    end
                    // use the PPD to light up tiles in the playfield
                    if (ppd_active) begin
                        output_color    = ppd_output_color;
                    end
                    // use the NPD to light up tiles in the next tile area
                    if (npd_active) begin
                        output_color    = npd_output_color;
                    end
                end
                MP_READY: begin
                    if (VGA_row < 10'd240) begin
                        output_color    = TETROMINO_T_COLOR;
                    end
                end
                MP_MODE: begin
                    if (VGA_row < 10'd240) begin
                        output_color    = TETROMINO_T_COLOR;
                    end
                end
                GAME_WON: begin
                    if (VGA_row < 10'd240) begin
                        output_color    = TETROMINO_S_COLOR;
                    end
                end
                GAME_LOST: begin
                    if (VGA_row < 10'd240) begin
                        output_color    = TETROMINO_Z_COLOR;
                    end
                end
            endcase

        end else begin
            // default to generating test pattern
            if (VGA_row < 10'd240) begin
                if ((VGA_col < 10'd160) ||
                    (VGA_col >= 10'd320 && VGA_col < 10'd480)) begin
                    output_color[23:16] = 8'd255;
                end

                if (VGA_col < 10'd320) begin
                    output_color[15:8] = 8'd255;
                end

                if ((VGA_col < 10'd80) ||
                    (VGA_col >= 10'd160 && VGA_col < 10'd240) ||
                    (VGA_col >= 10'd320 && VGA_col < 10'd400) ||
                    (VGA_col >= 10'd480 && VGA_col < 10'd560)) begin
                    output_color[7:0] = 8'd255;
                end
            end
        end
    end

    // PPD module
    PlayfieldPixelDriver ppd_inst (
        .VGA_row        (VGA_row),
        .VGA_col        (VGA_col),
        .tile_type      (tile_type),
        .output_color   (ppd_output_color),
        .active         (ppd_active)
    );
    // NPD module
    NextPixelDriver npd_inst (
        .VGA_row        (VGA_row),
        .VGA_col        (VGA_col),
        .pieces_queue   (next_pieces_queue),
        .output_color   (npd_output_color),
        .active         (npd_active)
    );
endmodule // GraphicsTop