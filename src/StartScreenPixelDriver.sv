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
    localparam LOGO_ROWS        = 187;
    localparam LOGO_COLS        = 269;
    localparam LOGO_ORIGIN_ROW  = 412;
    localparam LOGO_ORIGIN_COL  = 530;

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

    logic                           active_char;

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
    end

    genvar g;
    generate
        for (g = 0; g < WORD_LENGTH_1; g++) begin : STRING_WORD_1_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (0),
                .ORIGIN_COL (0 + 14 * g)
            ) ar_word_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_1[g]),
                .active     (actives_word_1[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_2; g++) begin : STRING_WORD_2_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (15),
                .ORIGIN_COL (0 + 14 * g)
            ) ar_word_2_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_2[g]),
                .active     (actives_word_2[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_3; g++) begin : STRING_WORD_3_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (30),
                .ORIGIN_COL (0 + 14 * g)
            ) ar_word_3_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_3[g]),
                .active     (actives_word_3[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_4; g++) begin : STRING_WORD_4_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (45),
                .ORIGIN_COL (0 + 14 * g)
            ) ar_word_4_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_4[g]),
                .active     (actives_word_4[g])
            );
        end
        for (g = 0; g < WORD_LENGTH_5; g++) begin : STRING_WORD_5_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (60),
                .ORIGIN_COL (0 + 14 * g)
            ) ar_word_5_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (word_5[g]),
                .active     (actives_word_5[g])
            );
        end

        for (g = 0; g < CREDIT_LENGTH_1; g++) begin : STRING_CREDIT_1_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (75),
                .ORIGIN_COL (0 + 14 * g)
            ) ar_credit_1_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (credit_1[g]),
                .active     (actives_credit_1[g])
            );
        end
        for (g = 0; g < CREDIT_LENGTH_2; g++) begin : STRING_CREDIT_2_G
            AlphanumeralRender #(
                .SCALE      (2),
                .ORIGIN_ROW (90),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (105),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (120),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (135),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (150),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (165),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (180),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (195),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (210),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (225),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (240),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (255),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (270),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (285),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (300),
                .ORIGIN_COL (0 + 14 * g)
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
                .ORIGIN_ROW (315),
                .ORIGIN_COL (0 + 14 * g)
            ) ar_thank_6L_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (thank_6L[g]),
                .active     (actives_thank_6L[g])
            );
        end
    endgenerate

    always_comb begin
        active_char =   (|actives_word_1)       ||
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
    end

    always_comb begin
        active          = 1'b1;
        output_color    = BG_COLOR;

        if ((VGA_row >= LOGO_ORIGIN_ROW) &&
            (VGA_col >= LOGO_ORIGIN_COL) &&
            (VGA_row <  LOGO_ORIGIN_ROW + LOGO_ROWS) &&
            (VGA_col <  LOGO_ORIGIN_COL + LOGO_COLS)) begin

            output_color = logo_color;
        end else if (active_char) begin
            output_color = 24'hff_ffff;
        end
    end
endmodule // StartScreenPixelDriver