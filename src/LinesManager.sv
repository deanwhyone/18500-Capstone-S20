/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module manages the lines cleared and lines sent logic. This can be used
 * to display to the user and also inform the loading bar for the garbage lines
 *
 * This module also handles combos, and B2B
 */
`default_nettype none

module LinesManager
    import DisplayPkg::*;
(
    input  logic        clk,
    input  logic        rst_l,
    input  logic        game_start,
    input  logic        lines_full      [PLAYFIELD_ROWS],
    output logic [ 9:0] lines_cleared
);
    logic [ 9:0]    lines_to_clear;
    logic           lines_cleared_en;

    logic [ 9:0]    lines_sent;
    logic [ 9:0]    lines_sent_incr;

    // handle line clearing logic
    always_comb begin
        lines_cleared_en    = 1'b0;
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            lines_cleared_en = lines_cleared_en | lines_full[i];
        end
        lines_to_clear      = lines_cleared + countSetBits(lines_full);
    end

    // register holds lines cleared for the pending game
    register #(
        .WIDTH  ($bits(lines_cleared))
    ) lines_cleared_reg_inst (
        .clk    (clk),
        .en     (lines_cleared_en),
        .rst_l  (rst_l),
        .clear  (game_start),
        .D      (lines_to_clear),
        .Q      (lines_cleared)
    );

    // register holds lines cleared for the pending game
    register #(
        .WIDTH  ($bits(lines_cleared))
    ) lines_sent_reg_inst (
        .clk    (clk),
        .en     (lines_cleared_en),
        .rst_l  (rst_l),
        .clear  (game_start),
        .D      (lines_sent_incr),
        .Q      (lines_sent)
    );
endmodule // LinesManager