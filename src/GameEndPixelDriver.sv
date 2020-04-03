/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages the end game screens for the game,
 * the game won screen and game lost screen.
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module GameEndPixelDriver
    import  DisplayPkg::*,
            GamePkg::*;
(
    input  logic            clk,
    input  logic [ 9:0]     VGA_row,
    input  logic [ 9:0]     VGA_col,
    input  game_screens_t   tetris_screen,
    input  logic [ 4:0]     time_hours,
    input  logic [ 5:0]     time_minutes,
    input  logic [ 5:0]     time_seconds,
    input  logic [ 3:0]     time_deciseconds,
    input  logic [ 3:0]     time_centiseconds,
    input  logic [ 3:0]     time_milliseconds,
    input  logic [ 9:0]     lines_cleared,
    input  logic [ 9:0]     lines_sent,

    output logic [23:0]     output_color,
    output logic            active
);
    localparam IMAGE_ROWS       = 200;
    localparam IMAGE_COLS       = 200;
    localparam IMAGE_ORIGIN_ROW = 100;
    localparam IMAGE_ORIGIN_COL = 146;

    localparam WIN_LENGTH_1     = 5;    // KUDOS
    localparam WIN_LENGTH_2     = 3;    // YOU
    localparam WIN_LENGTH_3     = 4;    // HAVE
    localparam WIN_LENGTH_4     = 3;    // WON

    localparam SORRY_LENGTH_1   = 5;    // SORRY
    localparam SORRY_LENGTH_2   = 6;    // BETTER
    localparam SORRY_LENGTH_3   = 4;    // LUCK
    localparam SORRY_LENGTH_4   = 4;    // NEXT
    localparam SORRY_LENGTH_5   = 4;    // TIME

    localparam TIME_LENGTH_1    = 4;    // TIME
    localparam TIME_LENGTH_2    = 7;    // ELAPSED
    localparam STATS_ORIGIN_ROW = 315;
    localparam STATS_ORIGIN_COL = 153;

    localparam LINES_LENGTH_1   = 5;
    localparam LINES_LENGTH_2   = 7;
    localparam LINES_LENGTH_3   = 4;

    localparam RETURN_LENGTH_1  = 5;    // PRESS
    localparam RETURN_LENGTH_2  = 4;    // KEY2
    localparam RETURN_LENGTH_3  = 2;    // TO
    localparam RETURN_LENGTH_4  = 6;    // RETURN
    localparam RETURN_LENGTH_5  = 2;    // TO
    localparam RETURN_LENGTH_6  = 5;    // START
    localparam RETURN_LENGTH_7  = 6;    // SCREEN

    logic [ 9:0]    VGA_row_LA;
    logic [ 9:0]    VGA_col_LA;
    logic [ 9:0]    VGA_relative_row;
    logic [ 9:0]    VGA_relative_col;
    logic [16:0]    image_addr;
    logic [23:0]    image_win_color;
    logic [23:0]    image_loss_color;

    logic [ 7:0]    win_1               [WIN_LENGTH_1];
    logic [ 7:0]    win_2               [WIN_LENGTH_2];
    logic [ 7:0]    win_3               [WIN_LENGTH_3];
    logic [ 7:0]    win_4               [WIN_LENGTH_4];

    logic [ 7:0]    sorry_1             [SORRY_LENGTH_1];
    logic [ 7:0]    sorry_2             [SORRY_LENGTH_2];
    logic [ 7:0]    sorry_3             [SORRY_LENGTH_3];
    logic [ 7:0]    sorry_4             [SORRY_LENGTH_4];
    logic [ 7:0]    sorry_5             [SORRY_LENGTH_5];

    logic [ 7:0]    time_1              [TIME_LENGTH_1];
    logic [ 7:0]    time_2              [TIME_LENGTH_2];

    logic [ 7:0]    word_lines          [LINES_LENGTH_1];
    logic [ 7:0]    word_cleared        [LINES_LENGTH_2];
    logic [ 7:0]    word_sent           [LINES_LENGTH_3];

    logic [ 7:0]    time_minutes_tens;
    logic [ 7:0]    time_minutes_ones;
    logic [ 7:0]    time_seconds_tens;
    logic [ 7:0]    time_seconds_ones;

    logic [ 7:0]    lc_hundreds_digit;
    logic [ 7:0]    lc_tens_digit;
    logic [ 7:0]    lc_ones_digit;
    logic [ 7:0]    ls_hundreds_digit;
    logic [ 7:0]    ls_tens_digit;
    logic [ 7:0]    ls_ones_digit;

    logic [ 7:0]    return_1            [RETURN_LENGTH_1];
    logic [ 7:0]    return_2            [RETURN_LENGTH_2];
    logic [ 7:0]    return_3            [RETURN_LENGTH_3];
    logic [ 7:0]    return_4            [RETURN_LENGTH_4];

    logic [WIN_LENGTH_1     - 1:0]  actives_win_1;
    logic [WIN_LENGTH_2     - 1:0]  actives_win_2;
    logic [WIN_LENGTH_3     - 1:0]  actives_win_3;
    logic [WIN_LENGTH_4     - 1:0]  actives_win_4;

    logic [SORRY_LENGTH_1   - 1:0]  actives_sorry_1;
    logic [SORRY_LENGTH_2   - 1:0]  actives_sorry_2;
    logic [SORRY_LENGTH_3   - 1:0]  actives_sorry_3;
    logic [SORRY_LENGTH_4   - 1:0]  actives_sorry_4;
    logic [SORRY_LENGTH_5   - 1:0]  actives_sorry_5;

    logic [TIME_LENGTH_1    - 1:0]  actives_time_1;
    logic [TIME_LENGTH_2    - 1:0]  actives_time_2;

    logic [LINES_LENGTH_1   - 1:0]  actives_lines_lc;
    logic [LINES_LENGTH_1   - 1:0]  actives_lines_ls;
    logic [LINES_LENGTH_2   - 1:0]  actives_cleared;
    logic [LINES_LENGTH_3   - 1:0]  actives_sent;

    logic                           time_hours_active;
    logic                           time_minutes_tens_active;
    logic                           time_minutes_ones_active;
    logic                           time_seconds_tens_active;
    logic                           time_seconds_ones_active;
    logic                           time_deciseconds_active;
    logic                           time_centiseconds_active;
    logic                           time_milliseconds_active;
    logic                           space_hm_active;
    logic                           space_ms_active;
    logic                           space_sp_active;

    logic                           active_lc_hundreds;
    logic                           active_lc_tens;
    logic                           active_lc_ones;
    logic                           active_ls_hundreds;
    logic                           active_ls_tens;
    logic                           active_ls_ones;

    logic [RETURN_LENGTH_1  - 1:0]  actives_return_1;
    logic [RETURN_LENGTH_2  - 1:0]  actives_return_2;
    logic [RETURN_LENGTH_3  - 1:0]  actives_return_3;
    logic [RETURN_LENGTH_4  - 1:0]  actives_return_4;

    logic                           active_char;

    always_comb begin
        win_1           = '{"K", "U", "D", "O", "S"};
        win_2           = '{"Y", "O", "U"};
        win_3           = '{"H", "A", "V", "E"};
        win_4           = '{"W", "O", "N"};

        sorry_1         = '{"S", "O", "R", "R", "Y"};
        sorry_2         = '{"B", "E", "T", "T", "E", "R"};
        sorry_3         = '{"L", "U", "C", "K"};
        sorry_4         = '{"N", "E", "X", "T"};
        sorry_5         = '{"T", "I", "M", "E"};

        time_1          = '{"T", "I", "M", "E"};
        time_2          = '{"E", "L", "A", "P", "S", "E", "D"};

        word_lines      = '{"L", "I", "N", "E", "S"};
        word_cleared    = '{"C", "L", "E", "A", "R", "E", "D"};
        word_sent       = '{"S", "E", "N", "T"};

        return_1        = '{"P", "R", "E", "S", "S"};
        return_2        = '{"K", "E", "Y", "3"};
        return_3        = '{"T", "O"};
        return_4        = '{"R", "E", "T", "U", "R", "N"};
    end

    genvar g;
    generate
        for (g = 0; g < WIN_LENGTH_1; g++) begin : STRING_WIN_1_G
            AlphanumeralRender #(
                .SCALE      (8),
                .ORIGIN_ROW (100),
                .ORIGIN_COL (IMAGE_COLS + IMAGE_ORIGIN_COL + 14 + 56 * g)
            ) ar_win_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (win_1[g]),
                .active     (actives_win_1[g])
            );
        end
        for (g = 0; g < WIN_LENGTH_2; g++) begin : STRING_WIN_2_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (160),
                .ORIGIN_COL (IMAGE_COLS + IMAGE_ORIGIN_COL + 14 + 28 * g)
            ) ar_win_2_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (win_2[g]),
                .active     (actives_win_2[g])
            );
        end
        for (g = 0; g < WIN_LENGTH_3; g++) begin : STRING_WIN_3_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (160),
                .ORIGIN_COL (IMAGE_COLS + IMAGE_ORIGIN_COL + 4 * 28 + 28 * g)
            ) ar_win_3_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (win_3[g]),
                .active     (actives_win_3[g])
            );
        end
        for (g = 0; g < WIN_LENGTH_4; g++) begin : STRING_WIN_4_G
            AlphanumeralRender #(
                .SCALE      (8),
                .ORIGIN_ROW (190),
                .ORIGIN_COL (IMAGE_COLS + IMAGE_ORIGIN_COL + 14 + 56 * g)
            ) ar_win_4_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (win_4[g]),
                .active     (actives_win_4[g])
            );
        end

        for (g = 0; g < SORRY_LENGTH_1; g++) begin : STRING_SORRY_1_G
            AlphanumeralRender #(
                .SCALE      (8),
                .ORIGIN_ROW (100),
                .ORIGIN_COL (IMAGE_COLS + IMAGE_ORIGIN_COL + 14 + 56 * g)
            ) ar_sorry_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (sorry_1[g]),
                .active     (actives_sorry_1[g])
            );
        end
        for (g = 0; g < SORRY_LENGTH_2; g++) begin : STRING_SORRY_2_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (160),
                .ORIGIN_COL (IMAGE_COLS + IMAGE_ORIGIN_COL + 14 + 28 * g)
            ) ar_sorry_2_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (sorry_2[g]),
                .active     (actives_sorry_2[g])
            );
        end
        for (g = 0; g < SORRY_LENGTH_3; g++) begin : STRING_SORRY_3_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (190),
                .ORIGIN_COL (IMAGE_COLS + IMAGE_ORIGIN_COL + 14 + 28 * g)
            ) ar_sorry_3_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (sorry_3[g]),
                .active     (actives_sorry_3[g])
            );
        end
        for (g = 0; g < SORRY_LENGTH_4; g++) begin : STRING_SORRY_4_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (190),
                .ORIGIN_COL (IMAGE_COLS + IMAGE_ORIGIN_COL + 5 * 28 + 28 * g)
            ) ar_sorry_4_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (sorry_4[g]),
                .active     (actives_sorry_4[g])
            );
        end
        for (g = 0; g < SORRY_LENGTH_5; g++) begin : STRING_SORRY_5_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (220),
                .ORIGIN_COL (IMAGE_COLS + IMAGE_ORIGIN_COL + 14 + 28 * g)
            ) ar_sorry_5_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (sorry_5[g]),
                .active     (actives_sorry_5[g])
            );
        end

        for (g = 0; g < TIME_LENGTH_1; g++) begin : STRING_TIME_1_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (STATS_ORIGIN_ROW),
                .ORIGIN_COL (STATS_ORIGIN_COL + 14 * g)
            ) ar_time_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (time_1[g]),
                .active     (actives_time_1[g])
            );
        end
        for (g = 0; g < TIME_LENGTH_2; g++) begin : STRING_TIME_2_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (STATS_ORIGIN_ROW),
                .ORIGIN_COL (STATS_ORIGIN_COL + 4 * 14 + 1 * 14 + 14 * g)
            ) ar_time_2_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (time_2[g]),
                .active     (actives_time_2[g])
            );
        end
    endgenerate

    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW),
        .ORIGIN_COL (STATS_ORIGIN_COL + 14 * 14)
    ) ar_hours_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'(time_hours) + 8'h30),
        .active     (time_hours_active)
    );
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW),
        .ORIGIN_COL (STATS_ORIGIN_COL + 15 * 14)
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
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW),
        .ORIGIN_COL (STATS_ORIGIN_COL + 16 * 14)
    ) ar_minutes_tens_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (time_minutes_tens + 8'h30),
        .active     (time_minutes_tens_active)
    );
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW),
        .ORIGIN_COL (STATS_ORIGIN_COL + 17 * 14)
    ) ar_minutes_ones_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (time_minutes_ones + 8'h30),
        .active     (time_minutes_ones_active)
    );
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW),
        .ORIGIN_COL (STATS_ORIGIN_COL + 18 * 14)
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
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW),
        .ORIGIN_COL (STATS_ORIGIN_COL + 19 * 14)
    ) ar_second_tens_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (time_seconds_tens + 8'h30),
        .active     (time_seconds_tens_active)
    );
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW),
        .ORIGIN_COL (STATS_ORIGIN_COL + 20 * 14)
    ) ar_second_ones_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (time_seconds_ones + 8'h30),
        .active     (time_seconds_ones_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (STATS_ORIGIN_ROW + 6),
        .ORIGIN_COL (STATS_ORIGIN_COL + 21 * 14)
    ) ar_space_sp_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'h2e),
        .active     (space_sp_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (STATS_ORIGIN_ROW + 6),
        .ORIGIN_COL (STATS_ORIGIN_COL + 21 * 14 + 7)
    ) ar_decisecond_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'(time_deciseconds) + 8'h30),
        .active     (time_deciseconds_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (STATS_ORIGIN_ROW + 6),
        .ORIGIN_COL (STATS_ORIGIN_COL + 22 * 14)
    ) ar_centisecond_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'(time_centiseconds) + 8'h30),
        .active     (time_centiseconds_active)
    );
    AlphanumeralRender #(
        .SCALE      (1),
        .ORIGIN_ROW (STATS_ORIGIN_ROW + 6),
        .ORIGIN_COL (STATS_ORIGIN_COL + 22 * 14 + 7)
    ) ar_millisecond_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (8'(time_milliseconds) + 8'h30),
        .active     (time_milliseconds_active)
    );

    generate
        for (g = 0; g < LINES_LENGTH_1; g++) begin : STRING_LC_LINES_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (STATS_ORIGIN_ROW + 15),
                .ORIGIN_COL (STATS_ORIGIN_COL + 14 * g)
            ) ar_lc_lines_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_lines[g]),
                .active     (actives_lines_lc[g])
            );
        end
        for (g = 0; g < LINES_LENGTH_2; g++) begin : STRING_LC_CLEARED_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (STATS_ORIGIN_ROW + 15),
                .ORIGIN_COL (STATS_ORIGIN_COL + 6 * 14 + 14 * g)
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
        .ORIGIN_ROW (STATS_ORIGIN_ROW + 15),
        .ORIGIN_COL (STATS_ORIGIN_COL + 14 * 14)
    ) ar_lc_hundreds_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (lc_hundreds_digit + 8'h30),
        .active     (active_lc_hundreds)
    );

    assign lc_tens_digit = 8'((lines_cleared / 10'd10) % 10'd10);
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW + 15),
        .ORIGIN_COL (STATS_ORIGIN_COL + 15 * 14)
    ) ar_lc_tens_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (lc_tens_digit + 8'h30),
        .active     (active_lc_tens)
    );

    assign lc_ones_digit = 8'(lines_cleared % 10'd10);
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW + 15),
        .ORIGIN_COL (STATS_ORIGIN_COL + 16 * 14)
    ) ar_lc_ones_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (lc_ones_digit + 8'h30),
        .active     (active_lc_ones)
    );

    generate
        for (g = 0; g < LINES_LENGTH_1; g++) begin : STRING_LS_LINES_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (STATS_ORIGIN_ROW + 30),
                .ORIGIN_COL (STATS_ORIGIN_COL + 14 * g)
            ) ar_ls_lines_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_lines[g]),
                .active     (actives_lines_ls[g])
            );
        end
        for (g = 0; g < LINES_LENGTH_3; g++) begin : STRING_LS_SENT_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (STATS_ORIGIN_ROW + 30),
                .ORIGIN_COL (STATS_ORIGIN_COL + 6 * 14 + 14 * g)
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
        .ORIGIN_ROW (STATS_ORIGIN_ROW + 30),
        .ORIGIN_COL (STATS_ORIGIN_COL + 14 * 14)
    ) ar_ls_hundreds_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (ls_hundreds_digit + 8'h30),
        .active     (active_ls_hundreds)
    );

    assign ls_tens_digit = 8'((lines_sent / 10'd10) % 10'd10);
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW + 30),
        .ORIGIN_COL (STATS_ORIGIN_COL + 15 * 14)
    ) ar_ls_tens_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (ls_tens_digit + 8'h30),
        .active     (active_ls_tens)
    );

    assign ls_ones_digit = 8'(lines_sent % 10'd10);
    AlphanumeralRender #(
        .SCALE      (2),
        .ORIGIN_ROW (STATS_ORIGIN_ROW + 30),
        .ORIGIN_COL (STATS_ORIGIN_COL + 16 * 14)
    ) ar_ls_ones_inst (
        .VGA_row    (VGA_row),
        .VGA_col    (VGA_col),
        .character  (ls_ones_digit + 8'h30),
        .active     (active_ls_ones)
    );

    generate
        for (g = 0; g < RETURN_LENGTH_1; g++) begin : STRING_RETURN_1_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (450),
                .ORIGIN_COL (141 + 28 * g)
            ) ar_return_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (return_1[g]),
                .active     (actives_return_1[g])
            );
        end
        for (g = 0; g < RETURN_LENGTH_2; g++) begin : STRING_RETURN_2_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (450),
                .ORIGIN_COL (141 + 5 * 28 + 1 * 14 + 28 * g)
            ) ar_return_2_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (return_2[g]),
                .active     (actives_return_2[g])
            );
        end
        for (g = 0; g < RETURN_LENGTH_3; g++) begin : STRING_RETURN_3_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (450),
                .ORIGIN_COL (141 + 9 * 28 + 2 * 14 + 28 * g)
            ) ar_return_3_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (return_3[g]),
                .active     (actives_return_3[g])
            );
        end
        for (g = 0; g < RETURN_LENGTH_4; g++) begin : STRING_RETURN_4_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (450),
                .ORIGIN_COL (141 + 11 * 28 + 3 * 14 + 28 * g)
            ) ar_return_4_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (return_4[g]),
                .active     (actives_return_4[g])
            );
        end
    endgenerate

    always_comb begin
        active_char =       (|actives_time_1)           ||
                            (|actives_time_2)           ||
                            time_hours_active           ||
                            time_minutes_tens_active    ||
                            time_minutes_ones_active    ||
                            time_seconds_tens_active    ||
                            time_seconds_ones_active    ||
                            time_deciseconds_active     ||
                            time_centiseconds_active    ||
                            time_milliseconds_active    ||
                            space_hm_active             ||
                            space_ms_active             ||
                            space_sp_active             ||
                            (|actives_lines_lc)         ||
                            (|actives_cleared)          ||
                            active_lc_hundreds          ||
                            active_lc_tens              ||
                            active_lc_ones              ||
                            (|actives_lines_ls)         ||
                            (|actives_sent)             ||
                            active_ls_hundreds          ||
                            active_ls_tens              ||
                            active_ls_ones              ||
                            (|actives_return_1)         ||
                            (|actives_return_2)         ||
                            (|actives_return_3)         ||
                            (|actives_return_4);
        if (tetris_screen == GAME_WON) begin
            active_char =   active_char                 ||
                            (|actives_win_1)            ||
                            (|actives_win_2)            ||
                            (|actives_win_3)            ||
                            (|actives_win_4);
        end else begin
            active_char =   active_char                 ||
                            (|actives_sorry_1)          ||
                            (|actives_sorry_2)          ||
                            (|actives_sorry_3)          ||
                            (|actives_sorry_4)          ||
                            (|actives_sorry_5);
        end
    end

    game_won_rom game_won_rom_inst (
        .clock      (clk),
        .address    (image_addr),
        .q          (image_win_color)
    );

    game_loss_rom game_loss_rom_inst (
        .clock      (clk),
        .address    (image_addr),
        .q          (image_loss_color)
    );

    always_comb begin
        VGA_relative_row    = VGA_row_LA - 10'(IMAGE_ORIGIN_ROW);
        VGA_relative_col    = VGA_col_LA - 10'(IMAGE_ORIGIN_COL);
        image_addr          = 17'(VGA_relative_row) * 17'(IMAGE_COLS) +
                              17'(VGA_relative_col);
    end

    always_comb begin
        VGA_row_LA = VGA_row;
        VGA_col_LA = VGA_col + 10'd1;
        if (VGA_col_LA == SVGA_WIDTH) begin
            VGA_row_LA = VGA_row + 10'd1;
            if (VGA_col_LA == SVGA_HEIGHT) begin
                VGA_row_LA = '0;
            end
            VGA_col_LA = '0;
        end
    end

    always_comb begin
        active          = 1'b1;
        output_color    = BG_COLOR;

        if ((VGA_row >= IMAGE_ORIGIN_ROW) &&
            (VGA_col >= IMAGE_ORIGIN_COL) &&
            (VGA_row <  IMAGE_ORIGIN_ROW + IMAGE_ROWS) &&
            (VGA_col <  IMAGE_ORIGIN_COL + IMAGE_COLS)) begin

            output_color =  (tetris_screen == GAME_WON) ?
                            image_win_color : image_loss_color;
        end else if (active_char) begin
            output_color = 24'hff_ffff;
        end
    end
endmodule // GameEndPixelDriver