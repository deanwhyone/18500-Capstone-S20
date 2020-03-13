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
    input  logic [ 9:0]     VGA_row,
    input  logic [ 9:0]     VGA_col,
    input  tile_type_t      tile_type           [PLAYFIELD_ROWS][PLAYFIELD_COLS],
    input  tile_type_t      next_pieces_queue   [NEXT_PIECES_COUNT],
    input  logic [ 9:0]     lines_cleared,
    input  logic [ 9:0]     lines_sent,
    input  logic            tspin_detected,
    input  logic            testpattern_active,
    input  game_screens_t   tetris_screen,
    input  logic [ 4:0]     time_hours,
    input  logic [ 5:0]     time_minutes,
    input  logic [ 5:0]     time_seconds,
    input  logic [ 3:0]     time_deciseconds,
    input  logic [ 3:0]     time_centiseconds,
    input  logic [ 3:0]     time_milliseconds,
    input  tile_type_t      hold_piece_type,
    input  logic            hold_piece_valid,
    input  logic [ 4:0]     pending_garbage,
    output logic [23:0]     output_color
);

    logic [23:0]    pfpd_output_color;
    logic           pfpd_active;
    logic [23:0]    npd_output_color;
    logic           npd_active;
    logic [23:0]    hpd_output_color;
    logic           hpd_active;
    logic [23:0]    lpd_output_color;
    logic           lpd_active;
    logic [23:0]    tpd_output_color;
    logic           tpd_active;
    logic [23:0]    ppd_output_color;
    logic           ppd_active;

    logic [23:0]    pfpd_output_color_lan;
    logic           pfpd_active_lan;
    logic [23:0]    npd_output_color_lan;
    logic           npd_active_lan;
    logic [23:0]    hpd_output_color_lan;
    logic           hpd_active_lan;

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
                    if (VGA_row >= BORDER_USER_VSTART &&
                        VGA_row <  BORDER_USER_VEND   &&
                        VGA_col >= BORDER_USER_HSTART &&
                        VGA_col <  BORDER_USER_HEND) begin

                        output_color    = BORDER_COLOR;
                        if (tspin_detected) begin
                            output_color = BORDER_COLOR_ALT;
                        end
                    end
                    if (VGA_row >= BORDER_LAN_VSTART &&
                        VGA_row <  BORDER_LAN_VEND   &&
                        VGA_col >= BORDER_LAN_HSTART &&
                        VGA_col <  BORDER_LAN_HEND) begin

                        output_color    = BORDER_COLOR;
                        if (tspin_detected) begin
                            output_color = BORDER_COLOR_ALT;
                        end
                    end
                    // use the PFPD to light up tiles in the playfield
                    if (pfpd_active) begin
                        output_color    = pfpd_output_color;
                    end
                    // use the NPD to light up tiles in the next tile area
                    if (npd_active) begin
                        output_color    = npd_output_color;
                    end
                    // use the HPD to render the hold piece
                    if (hpd_active) begin
                        output_color    = hpd_output_color;
                    end
                    // use the lpd to render the lines cleared info box
                    if (lpd_active) begin
                        output_color    = lpd_output_color;
                    end
                    // use the TPD to render the timer
                    if (tpd_active) begin
                        output_color    = tpd_output_color;
                    end
                    // use the PPD to render the pending lines of garbage
                    if (ppd_active) begin
                        output_color    = ppd_output_color;
                    end
                    // opponent HUD
                    if (pfpd_active_lan) begin
                        output_color    = pfpd_output_color_lan;
                    end
                    if (npd_active_lan) begin
                        output_color    = npd_output_color_lan;
                    end
                    if (hpd_active_lan) begin
                        output_color    = hpd_output_color_lan;
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

    // PFPD module
    PlayfieldPixelDriver #(
        .HSTART(PF_USER_HSTART),
        .VSTART(PF_USER_VSTART)
    ) pfpd_inst (
        .VGA_row        (VGA_row),
        .VGA_col        (VGA_col),
        .tile_type      (tile_type),
        .output_color   (pfpd_output_color),
        .active         (pfpd_active)
    );
    // NPD module
    NextPixelDriver #(
        .HSTART(NEXT_USER_HSTART),
        .VSTART(NEXT_USER_VSTART)
    ) npd_inst (
        .VGA_row        (VGA_row),
        .VGA_col        (VGA_col),
        .pieces_queue   (next_pieces_queue),
        .output_color   (npd_output_color),
        .active         (npd_active)
    );
    // HPD module
    HoldPixelDriver #(
        .HSTART(HOLD_USER_HSTART),
        .VSTART(HOLD_USER_VSTART)
    ) hpd_inst (
        .VGA_row            (VGA_row),
        .VGA_col            (VGA_col),
        .hold_piece_type    (hold_piece_type),
        .output_color       (hpd_output_color),
        .active             (hpd_active)
    );
    // LPD module
    LinesPixelDriver lpd_inst (
        .VGA_row        (VGA_row),
        .VGA_col        (VGA_col),
        .lines_cleared  (lines_cleared),
        .lines_sent     (lines_sent),
        .output_color   (lpd_output_color),
        .active         (lpd_active)
    );
    // TPD module
    TimerPixelDriver tpd_inst (
        .VGA_row            (VGA_row),
        .VGA_col            (VGA_col),
        .time_hours         (time_hours),
        .time_minutes       (time_minutes),
        .time_seconds       (time_seconds),
        .time_deciseconds   (time_deciseconds),
        .time_centiseconds  (time_centiseconds),
        .time_milliseconds  (time_milliseconds),
        .output_color       (tpd_output_color),
        .active             (tpd_active)
    );
    // PPD module
    PendingPixelDriver #(
        .HSTART (PENDING_HSTART),
        .HEND   (PENDING_HEND),
        .VSTART (PENDING_VSTART),
        .VEND   (PENDING_VEND)
    ) ppd_inst (
        .VGA_row        (VGA_row),
        .VGA_col        (VGA_col),
        .pending_garbage(pending_garbage),
        .output_color   (ppd_output_color),
        .active         (ppd_active)
    );

    // Opponent HUD

    // PFPD module
    PlayfieldPixelDriver #(
        .HSTART(PF_LAN_HSTART),
        .VSTART(PF_LAN_VSTART)
    ) pfpd_lan_inst (
        .VGA_row        (VGA_row),
        .VGA_col        (VGA_col),
        .tile_type      ('{20{'{10{BLANK}}}}),
        .output_color   (pfpd_output_color_lan),
        .active         (pfpd_active_lan)
    );
    // NPD module
    NextPixelDriver #(
        .HSTART(NEXT_LAN_HSTART),
        .VSTART(NEXT_LAN_VSTART)
    ) npd_lan_inst (
        .VGA_row        (VGA_row),
        .VGA_col        (VGA_col),
        .pieces_queue   ('{NEXT_PIECES_COUNT{T}}),
        .output_color   (npd_output_color_lan),
        .active         (npd_active_lan)
    );
    // HPD module
    HoldPixelDriver #(
        .HSTART(HOLD_LAN_HSTART),
        .VSTART(HOLD_LAN_VSTART)
    ) hpd_lan_inst (
        .VGA_row            (VGA_row),
        .VGA_col            (VGA_col),
        .hold_piece_type    (tile_type_t'(T)),
        .output_color       (hpd_output_color_lan),
        .active             (hpd_active_lan)
    );
endmodule // GraphicsTop