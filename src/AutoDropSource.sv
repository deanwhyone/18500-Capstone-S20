/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module generates a "soft drop" input periodically to replicate autodrop
 * behavior in Tetris. This period is reset if the player manually inputs a
 * soft drop themselves. However, autodrop inputs do not trigger the soft drop
 * cooldown.
 *
 * auto_drop output is single cycle pulse, akin to the other handled user inputs
 *
 * Falling speed is based off the NES implementation of tetris where tetrominos
 * fall progressively faster
 *
 * NES Level    : Time  == Cycle Count  :   Our Level
 * Lv 0         : 0.80s == 40_000_000   :   Lv 00
 * Lv 1         : 0.72s == 36_000_000   :   Lv 01
 * Lv 2         : 0.63s == 31_500_000   :   Lv 02
 * Lv 3         : 0.55s == 27_500_000   :   Lv 03
 * Lv 4         : 0.47s == 23_500_000   :   Lv 04
 * Lv 5         : 0.38s == 19_000_000   :   Lv 05
 * Lv 6         : 0.30s == 15_000_000   :   Lv 06
 * Lv 7         : 0.22s == 11_000_000   :   Lv 07
 * Lv 8         : 0.13s ==  6_500_000   :   Lv 08
 * Lv 9         : 0.10s ==  5_000_000   :   Lv 09
 * Lv10 - Lv12  : 0.08s ==  4_000_000   :   Lv 10
 * Lv13 - Lv15  : 0.07s ==  4_500_000   :   Lv 11
 * Lv16 - Lv18  : 0.05s ==  2_500_000   :   Lv 12
 * Lv19 - Lv28  : 0.03s ==  1_500_000   :   Lv 13
 * Lv29+        : 0.02s ==  1_000_000   :   Lv 14
 */
`default_nettype none

module AutoDropSource
    import GamePkg::*;
(
    input  logic            clk,
    input  logic            rst_l,
    input  logic            soft_drop,
    input  logic            soft_drop_valid,
    input  game_screens_t   tetris_screen,
    output logic            auto_drop
);
    localparam GRAVITY_LV00 = 40_000_000;
    localparam GRAVITY_LV01 = 36_000_000;
    localparam GRAVITY_LV02 = 31_500_000;
    localparam GRAVITY_LV03 = 27_500_000;
    localparam GRAVITY_LV04 = 23_500_000;
    localparam GRAVITY_LV05 = 19_000_000;
    localparam GRAVITY_LV06 = 15_000_000;
    localparam GRAVITY_LV07 = 11_000_000;
    localparam GRAVITY_LV08 =  6_500_000;
    localparam GRAVITY_LV09 =  5_000_000;
    localparam GRAVITY_LV10 =  4_000_000;
    localparam GRAVITY_LV11 =  4_500_000;
    localparam GRAVITY_LV12 =  2_500_000;
    localparam GRAVITY_LV13 =  1_500_000;
    localparam GRAVITY_LV14 =  1_000_000;


    logic [31:0]    auto_drop_cd;
    logic           auto_drop_cd_en;
    logic           auto_drop_cd_ld;

    logic [31:0]    gravity_choice;

    always_comb begin
        gravity_choice = GRAVITY_LV00;
    end

    always_comb begin
        auto_drop_cd_en =   tetris_screen == SPRINT_MODE ||
                            tetris_screen == MP_MODE;
        auto_drop_cd_ld =   (auto_drop_cd == gravity_choice) || soft_drop;
        auto_drop       =   auto_drop_cd == gravity_choice && soft_drop_valid;
    end

    counter #(
        .WIDTH  ($bits(auto_drop_cd))
    ) action_cd_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (auto_drop_cd_en),
        .load   (auto_drop_cd_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (auto_drop_cd)
    );
endmodule // AutoDropSource