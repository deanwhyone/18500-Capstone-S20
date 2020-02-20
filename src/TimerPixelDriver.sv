/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages the region to the left of the
 * playfield, the time elapsed in game.
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module TimerPixelDriver
    import  DisplayPkg::*,
            GamePkg::*;
(
    input  logic [ 9:0]     VGA_row,
    input  logic [ 9:0]     VGA_col,
    input  logic [ 4:0]     time_hours,
    input  logic [ 5:0]     time_minutes,
    input  logic [ 5:0]     time_seconds,
    input  logic [ 3:0]     time_deciseconds,
    input  logic [ 3:0]     time_centiseconds,
    input  logic [ 3:0]     time_milliseconds,

    output logic [23:0]     output_color,
    output logic            active
);
    logic [ 7:0]    time_minutes_tens;
    logic [ 7:0]    time_minutes_ones;
    logic [ 7:0]    time_seconds_tens;
    logic [ 7:0]    time_seconds_ones;

    logic           time_hours_active;
    logic           time_minutes_tens_active;
    logic           time_minutes_ones_active;
    logic           time_seconds_tens_active;
    logic           time_seconds_ones_active;
    logic           time_deciseconds_active;
    logic           time_centiseconds_active;
    logic           time_milliseconds_active;
    logic           space_hm_active;
    logic           space_ms_active;
    logic           space_sp_active;


    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART)
    ) ar_hours_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'(time_hours) + 8'h30),
        .active     (time_hours_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART + 8)
    ) ar_space_hm_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'h3a),
        .active     (space_hm_active)
    );
    always_comb begin
        time_minutes_tens = 8'd0;
        if (time_minutes >= 6'd10 && time_minutes < 6'd20) begin
            time_minutes_tens = 8'd1;
        end else if (time_minutes >= 6'd20 && time_minutes < 6'd30) begin
            time_minutes_tens = 8'd2;
        end else if (time_minutes >= 6'd30 && time_minutes < 6'd40) begin
            time_minutes_tens = 8'd3;
        end else if (time_minutes >= 6'd40 && time_minutes < 6'd50) begin
            time_minutes_tens = 8'd4;
        end else if (time_minutes >= 6'd50 && time_minutes < 6'd60) begin
            time_minutes_tens = 8'd5;
        end
    end
    assign time_minutes_ones = time_minutes % 8'd10;

    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART + 16)
    ) ar_minutes_tens_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (time_minutes_tens + 8'h30),
        .active     (time_minutes_tens_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART + 24)
    ) ar_minutes_ones_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (time_minutes_ones + 8'h30),
        .active     (time_minutes_ones_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART + 32)
    ) ar_space_ms_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'h3a),
        .active     (space_ms_active)
    );
    always_comb begin
        time_seconds_tens = 8'd0;
        if (time_seconds >= 6'd10 && time_seconds < 6'd20) begin
            time_seconds_tens = 8'd1;
        end else if (time_seconds >= 6'd20 && time_seconds < 6'd30) begin
            time_seconds_tens = 8'd2;
        end else if (time_seconds >= 6'd30 && time_seconds < 6'd40) begin
            time_seconds_tens = 8'd3;
        end else if (time_seconds >= 6'd40 && time_seconds < 6'd50) begin
            time_seconds_tens = 8'd4;
        end else if (time_seconds >= 6'd50 && time_seconds < 6'd60) begin
            time_seconds_tens = 8'd5;
        end
    end
    assign time_seconds_ones = time_seconds % 8'd10;

    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART + 40)
    ) ar_second_tens_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (time_seconds_tens + 8'h30),
        .active     (time_seconds_tens_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART + 48)
    ) ar_second_ones_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (time_seconds_ones + 8'h30),
        .active     (time_seconds_ones_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART + 56)
    ) ar_space_sp_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'h2e),
        .active     (space_sp_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART + 64)
    ) ar_decisecond_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'(time_deciseconds) + 8'h30),
        .active     (time_deciseconds_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART + 72)
    ) ar_centisecond_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'(time_centiseconds) + 8'h30),
        .active     (time_centiseconds_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (TIMER_VSTART),
        .ORIGIN_COL (TIMER_HSTART + 80)
    ) ar_millisecond_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'(time_milliseconds) + 8'h30),
        .active     (time_milliseconds_active)
    );

    always_comb begin
        output_color = BG_COLOR;
        if (time_hours_active           ||
            time_minutes_tens_active    ||
            time_minutes_ones_active    ||
            time_seconds_tens_active    ||
            time_seconds_ones_active    ||
            time_deciseconds_active     ||
            time_centiseconds_active    ||
            time_milliseconds_active    ||
            space_hm_active             ||
            space_ms_active             ||
            space_sp_active) begin

            output_color = 24'hff_ffff;
        end
    end

    always_comb begin
        active = 1'b0;
        if (VGA_row >= TIMER_VSTART &&
            VGA_row <  TIMER_VEND   &&
            VGA_col >= TIMER_HSTART &&
            VGA_col <  TIMER_HEND) begin

            active = 1'b1;
        end
    end
endmodule // TimerPixelDriver