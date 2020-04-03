/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This drives the pixels of the VGA display by setting RGB values for each
 * pixel individually. This driver manages the menu screens for the game, the
 * start screen and ready screen for user selecting modes.
 *
 * As a general rule, use GEQ (unstrict) and LE (strict). This removes the space
 * between tiles without unncessary overlap and strangely sized tiles.
 */
`default_nettype none

module MenuScreenPixelDriver
    import  DisplayPkg::*,
            GamePkg::*;
(
    input  logic            clk,
    input  logic [ 9:0]     VGA_row,
    input  logic [ 9:0]     VGA_col,
    input  game_screens_t   tetris_screen,

    output logic [23:0]     output_color,
    output logic            active
);
    localparam LOGO_ROWS        = 187;
    localparam LOGO_COLS        = 282;
    localparam LOGO_ORIGIN_ROW  = 412;
    localparam LOGO_ORIGIN_COL  = 509;

    localparam QR_ORIGIN_ROW    = 439;
    localparam QR_ORIGIN_COL    = 269;
    localparam QR_DIM           = 37;
    localparam QR_SCALE         = 4;

    localparam WORD_LENGTH_1    = 1; // A
    localparam WORD_LENGTH_2    = 5; // FRAME
    localparam WORD_LENGTH_3    = 7; // PERFECT
    localparam WORD_LENGTH_4    = 4; // GAME
    localparam WORD_LENGTH_5    = 9; // ADVENTURE

    localparam CREDIT_LENGTH_1  = 4; // TEAM
    localparam CREDIT_LENGTH_2  = 2; // C1
    localparam CREDIT_LENGTH_3F = 5; // ALTON
    localparam CREDIT_LENGTH_3L = 5; // OLSON
    localparam CREDIT_LENGTH_4F = 8; // DEANYONE
    localparam CREDIT_LENGTH_4L = 2; // SU
    localparam CREDIT_LENGTH_5F = 4; // ERIC
    localparam CREDIT_LENGTH_5L = 4; // CHEN

    localparam THANK_LENGTH_1   = 7; // SPECIAL
    localparam THANK_LENGTH_2   = 6; // THANKS
    localparam THANK_LENGTH_3   = 2; // TO
    localparam THANK_LENGTH_4F  = 4; // BILL
    localparam THANK_LENGTH_4L  = 4; // NACE
    localparam THANK_LENGTH_5F  = 4; // JENS
    localparam THANK_LENGTH_5L  = 6; // ERTMAN
    localparam THANK_LENGTH_6F  = 7; // HAILANG
    localparam THANK_LENGTH_6L  = 4; // LIOU

    localparam SELECT_LENGTH_1  = 5; // PRESS
    localparam SELECT_LENGTH_2  = 4; // KEY2
    localparam SELECT_LENGTH_3  = 2; // TO
    localparam SELECT_LENGTH_4  = 5; // START
    localparam SELECT_LENGTH_5  = 6; // SPRINT
    localparam SELECT_LENGTH_6  = 4; // MODE
    localparam SELECT_LENGTH_7  = 5; // PRESS
    localparam SELECT_LENGTH_8  = 4; // KEY3
    localparam SELECT_LENGTH_9  = 2; // TO
    localparam SELECT_LENGTH_10 = 5; // READY
    localparam SELECT_LENGTH_11 = 2; // UP
    localparam SELECT_LENGTH_12 = 3; // FOR
    localparam SELECT_LENGTH_13 = 6; // BATTLE
    localparam SELECT_LENGTH_14 = 4; // MODE

    localparam READY_LENGTH_1   = 7; // WAITING
    localparam READY_LENGTH_2   = 3; // FOR
    localparam READY_LENGTH_3   = 8; // OPPONENT
    localparam READY_LENGTH_4   = 2; // TO
    localparam READY_LENGTH_5   = 5; // READY
    localparam READY_LENGTH_6   = 2; // UP
    localparam READY_LENGTH_7   = 5; // PRESS
    localparam READY_LENGTH_8   = 4; // KEY1
    localparam READY_LENGTH_9   = 2; // TO
    localparam READY_LENGTH_10  = 8; // WITHDRAW

    logic [ 9:0] VGA_row_LA;
    logic [ 9:0] VGA_col_LA;
    logic [ 9:0] VGA_relative_row;
    logic [ 9:0] VGA_relative_col;
    logic [16:0] rom_addr;
    logic [23:0] logo_color;

    logic [ 7:0] word_1             [WORD_LENGTH_1];
    logic [ 7:0] word_2             [WORD_LENGTH_2];
    logic [ 7:0] word_3             [WORD_LENGTH_3];
    logic [ 7:0] word_4             [WORD_LENGTH_4];
    logic [ 7:0] word_5             [WORD_LENGTH_5];

    logic [ 7:0] credit_1           [CREDIT_LENGTH_1];
    logic [ 7:0] credit_2           [CREDIT_LENGTH_2];
    logic [ 7:0] credit_3F          [CREDIT_LENGTH_3F];
    logic [ 7:0] credit_3L          [CREDIT_LENGTH_3L];
    logic [ 7:0] credit_4F          [CREDIT_LENGTH_4F];
    logic [ 7:0] credit_4L          [CREDIT_LENGTH_4L];
    logic [ 7:0] credit_5F          [CREDIT_LENGTH_5F];
    logic [ 7:0] credit_5L          [CREDIT_LENGTH_5L];

    logic [ 7:0] thank_1            [THANK_LENGTH_1];
    logic [ 7:0] thank_2            [THANK_LENGTH_2];
    logic [ 7:0] thank_3            [THANK_LENGTH_3];
    logic [ 7:0] thank_4F           [THANK_LENGTH_4F];
    logic [ 7:0] thank_4L           [THANK_LENGTH_4L];
    logic [ 7:0] thank_5F           [THANK_LENGTH_5F];
    logic [ 7:0] thank_5L           [THANK_LENGTH_5L];
    logic [ 7:0] thank_6F           [THANK_LENGTH_6F];
    logic [ 7:0] thank_6L           [THANK_LENGTH_6L];

    logic [ 7:0] select_1           [SELECT_LENGTH_1];
    logic [ 7:0] select_2           [SELECT_LENGTH_2];
    logic [ 7:0] select_3           [SELECT_LENGTH_3];
    logic [ 7:0] select_4           [SELECT_LENGTH_4];
    logic [ 7:0] select_5           [SELECT_LENGTH_5];
    logic [ 7:0] select_6           [SELECT_LENGTH_6];
    logic [ 7:0] select_7           [SELECT_LENGTH_7];
    logic [ 7:0] select_8           [SELECT_LENGTH_8];
    logic [ 7:0] select_9           [SELECT_LENGTH_9];
    logic [ 7:0] select_10          [SELECT_LENGTH_10];
    logic [ 7:0] select_11          [SELECT_LENGTH_11];
    logic [ 7:0] select_12          [SELECT_LENGTH_12];
    logic [ 7:0] select_13          [SELECT_LENGTH_13];
    logic [ 7:0] select_14          [SELECT_LENGTH_14];

    logic [ 7:0] ready_1             [READY_LENGTH_1];
    logic [ 7:0] ready_2             [READY_LENGTH_2];
    logic [ 7:0] ready_3             [READY_LENGTH_3];
    logic [ 7:0] ready_4             [READY_LENGTH_4];
    logic [ 7:0] ready_5             [READY_LENGTH_5];
    logic [ 7:0] ready_6             [READY_LENGTH_6];
    logic [ 7:0] ready_7             [READY_LENGTH_7];
    logic [ 7:0] ready_8             [READY_LENGTH_8];
    logic [ 7:0] ready_9             [READY_LENGTH_9];
    logic [ 7:0] ready_10            [READY_LENGTH_10];

    logic [WORD_LENGTH_1    - 1:0]  actives_word_1;
    logic [WORD_LENGTH_2    - 1:0]  actives_word_2;
    logic [WORD_LENGTH_3    - 1:0]  actives_word_3;
    logic [WORD_LENGTH_4    - 1:0]  actives_word_4;
    logic [WORD_LENGTH_5    - 1:0]  actives_word_5;

    logic [CREDIT_LENGTH_1  - 1:0]  actives_credit_1;
    logic [CREDIT_LENGTH_2  - 1:0]  actives_credit_2;
    logic [CREDIT_LENGTH_3F - 1:0]  actives_credit_3F;
    logic [CREDIT_LENGTH_3L - 1:0]  actives_credit_3L;
    logic [CREDIT_LENGTH_4F - 1:0]  actives_credit_4F;
    logic [CREDIT_LENGTH_4L - 1:0]  actives_credit_4L;
    logic [CREDIT_LENGTH_5F - 1:0]  actives_credit_5F;
    logic [CREDIT_LENGTH_5L - 1:0]  actives_credit_5L;

    logic [THANK_LENGTH_1   - 1:0]  actives_thank_1;
    logic [THANK_LENGTH_2   - 1:0]  actives_thank_2;
    logic [THANK_LENGTH_3   - 1:0]  actives_thank_3;
    logic [THANK_LENGTH_4F  - 1:0]  actives_thank_4F;
    logic [THANK_LENGTH_4L  - 1:0]  actives_thank_4L;
    logic [THANK_LENGTH_5F  - 1:0]  actives_thank_5F;
    logic [THANK_LENGTH_5L  - 1:0]  actives_thank_5L;
    logic [THANK_LENGTH_6F  - 1:0]  actives_thank_6F;
    logic [THANK_LENGTH_6L  - 1:0]  actives_thank_6L;

    logic [SELECT_LENGTH_1  - 1:0]  actives_select_1;
    logic [SELECT_LENGTH_2  - 1:0]  actives_select_2;
    logic [SELECT_LENGTH_3  - 1:0]  actives_select_3;
    logic [SELECT_LENGTH_4  - 1:0]  actives_select_4;
    logic [SELECT_LENGTH_5  - 1:0]  actives_select_5;
    logic [SELECT_LENGTH_6  - 1:0]  actives_select_6;
    logic [SELECT_LENGTH_7  - 1:0]  actives_select_7;
    logic [SELECT_LENGTH_8  - 1:0]  actives_select_8;
    logic [SELECT_LENGTH_9  - 1:0]  actives_select_9;
    logic [SELECT_LENGTH_10 - 1:0]  actives_select_10;
    logic [SELECT_LENGTH_11 - 1:0]  actives_select_11;
    logic [SELECT_LENGTH_12 - 1:0]  actives_select_12;
    logic [SELECT_LENGTH_13 - 1:0]  actives_select_13;
    logic [SELECT_LENGTH_14 - 1:0]  actives_select_14;

    logic [READY_LENGTH_1   - 1:0]  actives_ready_1;
    logic [READY_LENGTH_2   - 1:0]  actives_ready_2;
    logic [READY_LENGTH_3   - 1:0]  actives_ready_3;
    logic [READY_LENGTH_4   - 1:0]  actives_ready_4;
    logic [READY_LENGTH_5   - 1:0]  actives_ready_5;
    logic [READY_LENGTH_6   - 1:0]  actives_ready_6;
    logic [READY_LENGTH_7   - 1:0]  actives_ready_7;
    logic [READY_LENGTH_8   - 1:0]  actives_ready_8;
    logic [READY_LENGTH_9   - 1:0]  actives_ready_9;
    logic [READY_LENGTH_10  - 1:0]  actives_ready_10;

    logic                           active_char;

    logic [ 0:QR_DIM - 1]           qr_code_data;
    logic [ 5:0]                    qr_row_count;
    logic [ 5:0]                    qr_col_count;
    logic                           active_qr;


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
        VGA_relative_row    = VGA_row_LA - 10'(LOGO_ORIGIN_ROW);
        VGA_relative_col    = VGA_col_LA - 10'(LOGO_ORIGIN_COL);
        rom_addr            = 17'(VGA_relative_row) * 17'(LOGO_COLS) +
                              17'(VGA_relative_col);
    end

    logo_rom logo_rom_inst (
        .clock      (clk),
        .address    (rom_addr),
        .q          (logo_color)
    );

    always_comb begin
        word_1      = '{"A"};
        word_2      = '{"F", "R", "A", "M", "E"};
        word_3      = '{"P", "E", "R", "F", "E", "C", "T"};
        word_4      = '{"G", "A", "M", "E"};
        word_5      = '{"A", "D", "V", "E", "N", "T", "U", "R", "E"};
        credit_1    = '{"T", "E", "A", "M"};
        credit_2    = '{"C", "1"};
        credit_3F   = '{"A", "L", "T", "O", "N"};
        credit_3L   = '{"O", "L", "S", "O", "N"};
        credit_4F   = '{"D", "E", "A", "N", "Y", "O", "N", "E"};
        credit_4L   = '{"S", "U"};
        credit_5F   = '{"E", "R", "I", "C"};
        credit_5L   = '{"C", "H", "E", "N"};
        thank_1     = '{"S", "P", "E", "C", "I", "A", "L"};
        thank_2     = '{"T", "H", "A", "N", "K", "S"};
        thank_3     = '{"T", "O"};
        thank_4F    = '{"B", "I", "L", "L"};
        thank_4L    = '{"N", "A", "C", "E"};
        thank_5F    = '{"J", "E", "N", "S"};
        thank_5L    = '{"E", "R", "T", "M", "A", "N"};
        thank_6F    = '{"H", "A", "I", "L", "A", "N", "G"};
        thank_6L    = '{"L", "I", "O", "U"};
        select_1    = '{"P", "R", "E", "S", "S"};
        select_2    = '{"K", "E", "Y", "2"};
        select_3    = '{"T", "O"};
        select_4    = '{"S", "T", "A", "R", "T"};
        select_5    = '{"S", "P", "R", "I", "N", "T"};
        select_6    = '{"M", "O", "D", "E"};
        select_7    = '{"P", "R", "E", "S", "S"};
        select_8    = '{"K", "E", "Y", "3"};
        select_9    = '{"T", "O"};
        select_10   = '{"R", "E", "A", "D", "Y"};
        select_11   = '{"U", "P"};
        select_12   = '{"F", "O", "R"};
        select_13   = '{"B", "A", "T", "T", "L", "E"};
        select_14   = '{"M", "O", "D", "E"};
        ready_1     = '{"W", "A","I", "T", "I", "N", "G"};
        ready_2     = '{"F", "O","R"};
        ready_3     = '{"O", "P", "P", "O", "N", "E", "N", "T"};
        ready_4     = '{"T", "O"};
        ready_5     = '{"R", "E", "A", "D", "Y"};
        ready_6     = '{"U", "P"};
        ready_7     = '{"P", "R", "E", "S", "S"};
        ready_8     = '{"K", "E", "Y", "1"};
        ready_9     = '{"T", "O"};
        ready_10    = '{"W", "I", "T", "H", "D", "R", "A", "W"};
    end

    genvar g;
    generate
        for (g = 0; g < WORD_LENGTH_1; g++) begin : STRING_WORD_1_G
            AlphanumeralRender #(
                .SCALE      (8),
                .ORIGIN_ROW (10),
                .ORIGIN_COL (14 + 0 + 56 * g)
            ) ar_word_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_1[g]),
                .active     (actives_word_1[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_2; g++) begin : STRING_WORD_2_G
            AlphanumeralRender #(
                .SCALE      (8),
                .ORIGIN_ROW (10),
                .ORIGIN_COL (15 + 1 * 56 + 1 * 28 + 56 * g)
            ) ar_word_2_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_2[g]),
                .active     (actives_word_2[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_3; g++) begin : STRING_WORD_3_G
            AlphanumeralRender #(
                .SCALE      (8),
                .ORIGIN_ROW (10),
                .ORIGIN_COL (15 + 6 * 56 + 2 * 28 + 56 * g)
            ) ar_word_3_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_3[g]),
                .active     (actives_word_3[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_4; g++) begin : STRING_WORD_4_G
            AlphanumeralRender #(
                .SCALE      (8),
                .ORIGIN_ROW (10 + 60),
                .ORIGIN_COL (22 + 56 * g)
            ) ar_word_4_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_4[g]),
                .active     (actives_word_4[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_5; g++) begin : STRING_WORD_5_G
            AlphanumeralRender #(
                .SCALE      (8),
                .ORIGIN_ROW (10 + 60),
                .ORIGIN_COL (22 + 4 * 56 + 28 + 56 * g)
            ) ar_word_5_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_5[g]),
                .active     (actives_word_5[g])
            );
        end

        for (g = 0; g < CREDIT_LENGTH_1; g++) begin : STRING_CREDIT_1_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (439),
                .ORIGIN_COL (8 + 0 + 28 * g)
            ) ar_credit_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (credit_1[g]),
                .active     (actives_credit_1[g])
            );
        end
        for (g = 0; g < CREDIT_LENGTH_2; g++) begin : STRING_CREDIT_2_G
            AlphanumeralRender #(
                .SCALE      (4),
                .ORIGIN_ROW (439),
                .ORIGIN_COL (8 + 5 * 28 + 28 * g)
            ) ar_credit_2_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (credit_2[g]),
                .active     (actives_credit_2[g])
            );
        end
        for (g = 0; g < CREDIT_LENGTH_3F; g++) begin : STRING_CREDIT_3F_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (469),
                .ORIGIN_COL (8 + 0 + 14 * g)
            ) ar_credit_3F_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (credit_3F[g]),
                .active     (actives_credit_3F[g])
            );
        end
        for (g = 0; g < CREDIT_LENGTH_3L; g++) begin : STRING_CREDIT_3L_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (469),
                .ORIGIN_COL (8 + 6 * 14 + 14 * g)
            ) ar_credit_3L_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (credit_3L[g]),
                .active     (actives_credit_3L[g])
            );
        end
        for (g = 0; g < CREDIT_LENGTH_4F; g++) begin : STRING_CREDIT_4F_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (484),
                .ORIGIN_COL (8 + 14 * g)
            ) ar_credit_4F_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (credit_4F[g]),
                .active     (actives_credit_4F[g])
            );
        end
        for (g = 0; g < CREDIT_LENGTH_4L; g++) begin : STRING_CREDIT_4L_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (484),
                .ORIGIN_COL (8 + 9 * 14 + 14 * g)
            ) ar_credit_4L_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (credit_4L[g]),
                .active     (actives_credit_4L[g])
            );
        end
        for (g = 0; g < CREDIT_LENGTH_5F; g++) begin : STRING_CREDIT_5F_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (499),
                .ORIGIN_COL (8 + 0 + 14 * g)
            ) ar_credit_5F_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (credit_5F[g]),
                .active     (actives_credit_5F[g])
            );
        end
        for (g = 0; g < CREDIT_LENGTH_5L; g++) begin : STRING_CREDIT_5L_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (499),
                .ORIGIN_COL (8 + 5 * 14 + 14 * g)
            ) ar_credit_5L_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (credit_5L[g]),
                .active     (actives_credit_5L[g])
            );
        end

        for (g = 0; g < THANK_LENGTH_1; g++) begin : STRING_THANK_1_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (529),
                .ORIGIN_COL (8 + 0 + 14 * g)
            ) ar_thank_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (thank_1[g]),
                .active     (actives_thank_1[g])
            );
        end
        for (g = 0; g < THANK_LENGTH_2; g++) begin : STRING_THANK_2_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (529),
                .ORIGIN_COL (8 + 8 * 14 + 14 * g)
            ) ar_thank_2_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (thank_2[g]),
                .active     (actives_thank_2[g])
            );
        end
        for (g = 0; g < THANK_LENGTH_3; g++) begin : STRING_THANK_3_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (529),
                .ORIGIN_COL (8 + 15 * 14 + 14 * g)
            ) ar_thank_3_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (thank_3[g]),
                .active     (actives_thank_3[g])
            );
        end
        for (g = 0; g < THANK_LENGTH_4F; g++) begin : STRING_THANK_4F_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (544),
                .ORIGIN_COL (8 + 0 + 14 * g)
            ) ar_thank_4F_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (thank_4F[g]),
                .active     (actives_thank_4F[g])
            );
        end
        for (g = 0; g < THANK_LENGTH_4L; g++) begin : STRING_THANK_4L_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (544),
                .ORIGIN_COL (8 + 5 * 14 + 14 * g)
            ) ar_thank_4L_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (thank_4L[g]),
                .active     (actives_thank_4L[g])
            );
        end
        for (g = 0; g < THANK_LENGTH_5F; g++) begin : STRING_THANK_5F_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (559),
                .ORIGIN_COL (8 + 0 + 14 * g)
            ) ar_thank_5F_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (thank_5F[g]),
                .active     (actives_thank_5F[g])
            );
        end
        for (g = 0; g < THANK_LENGTH_5L; g++) begin : STRING_THANK_5L_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (559),
                .ORIGIN_COL (8 + 5 * 14 + 14 * g)
            ) ar_thank_5L_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (thank_5L[g]),
                .active     (actives_thank_5L[g])
            );
        end
        for (g = 0; g < THANK_LENGTH_6F; g++) begin : STRING_THANK_6F_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (574),
                .ORIGIN_COL (8 + 0 + 14 * g)
            ) ar_thank_6F_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (thank_6F[g]),
                .active     (actives_thank_6F[g])
            );
        end
        for (g = 0; g < THANK_LENGTH_6L; g++) begin : STRING_THANK_6L_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (574),
                .ORIGIN_COL (8 + 8 * 14 + 14 * g)
            ) ar_thank_6L_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (thank_6L[g]),
                .active     (actives_thank_6L[g])
            );
        end

        for (g = 0; g < SELECT_LENGTH_1; g++) begin : STRING_SELECT_1_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 14 * g)
            ) ar_select_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_1[g]),
                .active     (actives_select_1[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_2; g++) begin : STRING_SELECT_2_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 5 * 14 + 1 * 14 + 14 * g)
            ) ar_select_2_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_2[g]),
                .active     (actives_select_2[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_3; g++) begin : STRING_SELECT_3_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 9 * 14 + 2 * 14 + 14 * g)
            ) ar_select_3_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_3[g]),
                .active     (actives_select_3[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_4; g++) begin : STRING_SELECT_4_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 11 * 14 + 3 * 14 + 14 * g)
            ) ar_select_4_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_4[g]),
                .active     (actives_select_4[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_5; g++) begin : STRING_SELECT_5_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 16 * 14 + 4 * 14 + 14 * g)
            ) ar_select_5_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_5[g]),
                .active     (actives_select_5[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_6; g++) begin : STRING_SELECT_6_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 22 * 14 + 5 * 14 + 14 * g)
            ) ar_select_6_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_6[g]),
                .active     (actives_select_6[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_7; g++) begin : STRING_SELECT_7_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (127 + 14 * g)
            ) ar_select_7_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_7[g]),
                .active     (actives_select_7[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_8; g++) begin : STRING_SELECT_8_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (127 + 5 * 14 + 1 * 14 + 14 * g)
            ) ar_select_8_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_8[g]),
                .active     (actives_select_8[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_9; g++) begin : STRING_SELECT_9_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (127 + 9 * 14 + 2 * 14 + 14 * g)
            ) ar_select_9_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_9[g]),
                .active     (actives_select_9[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_10; g++) begin : STRING_SELECT_10_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (127 + 11 * 14 + 3 * 14 + 14 * g)
            ) ar_select_10_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_10[g]),
                .active     (actives_select_10[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_11; g++) begin : STRING_SELECT_11_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (127 + 16 * 14 + 4 * 14 + 14 * g)
            ) ar_select_11_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_11[g]),
                .active     (actives_select_11[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_12; g++) begin : STRING_SELECT_12_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (127 + 18 * 14 + 5 * 14 + 14 * g)
            ) ar_select_12_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_12[g]),
                .active     (actives_select_12[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_13; g++) begin : STRING_SELECT_13_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (127 + 21 * 14 + 6 * 14 + 14 * g)
            ) ar_select_13_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_13[g]),
                .active     (actives_select_13[g])
            );
        end
        for (g = 0; g < SELECT_LENGTH_14; g++) begin : STRING_SELECT_14_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (127 + 27 * 14 + 7 * 14 + 14 * g)
            ) ar_select_14_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (select_14[g]),
                .active     (actives_select_14[g])
            );
        end


        for (g = 0; g < READY_LENGTH_1; g++) begin : STRING_READY_1_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 14 * g)
            ) ar_ready_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (ready_1[g]),
                .active     (actives_ready_1[g])
            );
        end
        for (g = 0; g < READY_LENGTH_2; g++) begin : STRING_READY_2_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 7 * 14 + 1 * 14 + 14 * g)
            ) ar_ready_2_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (ready_2[g]),
                .active     (actives_ready_2[g])
            );
        end
        for (g = 0; g < READY_LENGTH_3; g++) begin : STRING_READY_3_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 10 * 14 + 2 * 14 + 14 * g)
            ) ar_ready_3_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (ready_3[g]),
                .active     (actives_ready_3[g])
            );
        end
        for (g = 0; g < READY_LENGTH_4; g++) begin : STRING_READY_4_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 18 * 14 + 3 * 14 + 14 * g)
            ) ar_ready_4_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (ready_4[g]),
                .active     (actives_ready_4[g])
            );
        end
        for (g = 0; g < READY_LENGTH_5; g++) begin : STRING_READY_5_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 20 * 14 + 4 * 14 + 14 * g)
            ) ar_ready_5_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (ready_5[g]),
                .active     (actives_ready_5[g])
            );
        end
        for (g = 0; g < READY_LENGTH_6; g++) begin : STRING_READY_6_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (176 + 25 * 14 + 5 * 14 + 14 * g)
            ) ar_ready_6_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (ready_6[g]),
                .active     (actives_ready_6[g])
            );
        end
        for (g = 0; g < READY_LENGTH_7; g++) begin : STRING_READY_7_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (176 + 14 * g)
            ) ar_ready_7_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (ready_7[g]),
                .active     (actives_ready_7[g])
            );
        end
        for (g = 0; g < READY_LENGTH_8; g++) begin : STRING_READY_8_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (176 + 5 * 14 + 1 * 14 + 14 * g)
            ) ar_ready_8_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (ready_8[g]),
                .active     (actives_ready_8[g])
            );
        end
        for (g = 0; g < READY_LENGTH_9; g++) begin : STRING_READY_9_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (176 + 9 * 14 + 2 * 14 + 14 * g)
            ) ar_ready_9_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (ready_9[g]),
                .active     (actives_ready_9[g])
            );
        end
        for (g = 0; g < READY_LENGTH_10; g++) begin : STRING_READY_10_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (260),
                .ORIGIN_COL (176 + 11 * 14 + 3 * 14 + 14 * g)
            ) ar_ready_10_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (ready_10[g]),
                .active     (actives_ready_10[g])
            );
        end
    endgenerate

    always_comb begin
        active_char =       (|actives_word_1)       ||
                            (|actives_word_2)       ||
                            (|actives_word_3)       ||
                            (|actives_word_4)       ||
                            (|actives_word_5)       ||
                            (|actives_credit_1)     ||
                            (|actives_credit_2)     ||
                            (|actives_credit_3F)    ||
                            (|actives_credit_3L)    ||
                            (|actives_credit_4F)    ||
                            (|actives_credit_4L)    ||
                            (|actives_credit_5F)    ||
                            (|actives_credit_5L)    ||
                            (|actives_thank_1)      ||
                            (|actives_thank_2)      ||
                            (|actives_thank_3)      ||
                            (|actives_thank_4F)     ||
                            (|actives_thank_4L)     ||
                            (|actives_thank_5F)     ||
                            (|actives_thank_5L)     ||
                            (|actives_thank_6F)     ||
                            (|actives_thank_6L);
        if (tetris_screen == START_SCREEN) begin
            active_char =   active_char             ||
                            (|actives_select_1)     ||
                            (|actives_select_2)     ||
                            (|actives_select_3)     ||
                            (|actives_select_4)     ||
                            (|actives_select_5)     ||
                            (|actives_select_6)     ||
                            (|actives_select_7)     ||
                            (|actives_select_8)     ||
                            (|actives_select_9)     ||
                            (|actives_select_10)    ||
                            (|actives_select_11)    ||
                            (|actives_select_12)    ||
                            (|actives_select_13)    ||
                            (|actives_select_14);
        end else if (tetris_screen == MP_READY) begin
            active_char =   active_char             ||
                            (|actives_ready_1)      ||
                            (|actives_ready_2)      ||
                            (|actives_ready_3)      ||
                            (|actives_ready_4)      ||
                            (|actives_ready_5)      ||
                            (|actives_ready_6)      ||
                            (|actives_ready_7)      ||
                            (|actives_ready_8)      ||
                            (|actives_ready_9)      ||
                            (|actives_ready_10);
        end
    end

    qr_rom qr_rom_inst (
        .clock      (clk),
        .address    (qr_row_count),
        .q          (qr_code_data)
    );

    assign qr_row_count    = 6'((VGA_row_LA - QR_ORIGIN_ROW)/QR_SCALE);
    assign qr_col_count    = 6'((VGA_col - QR_ORIGIN_COL)/QR_SCALE);

    always_comb begin
        active_qr       = 1'b0;
        if ((VGA_row_LA >= QR_ORIGIN_ROW) &&
            (VGA_col_LA >= QR_ORIGIN_COL) &&
            (VGA_row_LA <  QR_ORIGIN_ROW + QR_DIM * QR_SCALE) &&
            (VGA_col_LA <  QR_ORIGIN_COL + QR_DIM * QR_SCALE)) begin

            active_qr       = 1'b1;
        end
    end

    always_comb begin
        active          = 1'b1;
        output_color    = BG_COLOR;

        if ((VGA_row >= LOGO_ORIGIN_ROW) &&
            (VGA_col >= LOGO_ORIGIN_COL) &&
            (VGA_row <  LOGO_ORIGIN_ROW + LOGO_ROWS) &&
            (VGA_col <  LOGO_ORIGIN_COL + LOGO_COLS)) begin

            output_color = logo_color;
        end else if (active_qr) begin
            output_color = {24{qr_code_data[qr_col_count]}};
        end else if (active_char) begin
            output_color = 24'hff_ffff;
        end
    end
endmodule // MenuScreenPixelDriver