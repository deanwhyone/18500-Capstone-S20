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
    input  logic        falling_piece_lock,
    input  logic        tspin_detected,
    input  logic        lines_full          [PLAYFIELD_ROWS],
    output logic [ 9:0] lines_cleared,
    output logic [ 9:0] lines_sent,
    output logic [ 9:0] lines_to_send,
    output logic        new_lines_valid,
    output logic [ 4:0] combo_count
);
    enum logic {BREAK, COMBO}       state_combo, nstate_combo;
    enum logic {LOCK_WAIT, CHECK}   state_check, nstate_check;
    enum logic {NONE, B2B}          state_b2b, nstate_b2b;

    logic [ 9:0]    lines_to_clear;
    logic           lines_cleared_en;

    logic           combo_en;
    logic           combo_cl;
    logic [ 9:0]    combo_incr;

    logic [ 9:0]    b2b_incr;

    logic [ 9:0]    lines_sent_new;
    logic [ 9:0]    lines_to_send_pipe;

    logic           new_lines_valid_pipe;

    // handle line clearing logic
    always_comb begin
        lines_cleared_en    = 1'b0;
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            lines_cleared_en = lines_cleared_en || lines_full[i];
        end
        lines_to_clear = 10'(countSetBits(lines_full));
    end

    // register holds lines cleared for the pending game
    register #(
        .WIDTH  ($bits(lines_cleared))
    ) lines_cleared_reg_inst (
        .clk    (clk),
        .en     (lines_cleared_en),
        .rst_l  (rst_l),
        .clear  (game_start),
        .D      (lines_cleared + lines_to_clear),
        .Q      (lines_cleared)
    );

    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            state_combo <= BREAK;
            state_check <= LOCK_WAIT;
            state_b2b   <= NONE;
        end else begin
            state_combo <= nstate_combo;
            state_check <= nstate_check;
            state_b2b   <= nstate_b2b;
        end
    end
    always_comb begin
        combo_en        = 1'b0;
        combo_cl        = 1'b0;
        nstate_combo    = state_combo;
        if (state_check == CHECK) begin
            if (lines_cleared_en) begin
                combo_en        = (state_combo == COMBO);
                nstate_combo    = COMBO;
            end else begin
                combo_cl        = 1'b1;
                nstate_combo    = BREAK;
            end
        end
    end

    assign nstate_check = (falling_piece_lock) ? CHECK : LOCK_WAIT;

    always_comb begin
        nstate_b2b = state_b2b;
        if (falling_piece_lock) begin
            if ((lines_to_clear == 10'd4) || tspin_detected) begin
                nstate_b2b = B2B;
            end else begin
                nstate_b2b = NONE;
            end
        end
    end

    assign b2b_incr = (state_b2b == B2B) ? 10'd1 : 10'd0;

    always_comb begin
        combo_incr = 10'd0;
        if (combo_count >= 1 && combo_count < 3) begin
            combo_incr = 10'd1;
        end else if (combo_count >= 3 && combo_count < 5) begin
            combo_incr = 10'd2;
        end else if (combo_count >= 5 && combo_count < 7) begin
            combo_incr = 10'd3;
        end else if (combo_count >= 7 && combo_count < 10) begin
            combo_incr = 10'd4;
        end else if (combo_count >= 10) begin
            combo_incr = 10'd5;
        end
    end

    counter #(
        .WIDTH  ($bits(combo_count))
    ) combo_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (combo_en),
        .load   (combo_cl || game_start),
        .up     (1'b1),
        .D      ('0),
        .Q      (combo_count)
    );

    always_comb begin
        if (tspin_detected) begin
            lines_to_send_pipe = (lines_to_clear + 10'd1) << 1;
        end else begin
            if (lines_to_clear == 5'd2) begin
                lines_to_send_pipe = 10'd1;
            end else if (lines_to_clear == 5'd3) begin
                lines_to_send_pipe = 10'd2;
            end else if (lines_to_clear == 5'd4) begin
                lines_to_send_pipe = 10'd4;
            end else begin
                lines_to_send_pipe = 10'd0;
            end
        end

        lines_to_send_pipe = lines_to_send_pipe + combo_incr + b2b_incr;
    end

    assign lines_sent_new       = lines_sent + lines_to_send_pipe;
    assign new_lines_valid_pipe = lines_to_send_pipe != lines_sent_new;

    // register holds lines cleared for the pending game
    register #(
        .WIDTH  ($bits(lines_cleared))
    ) lines_sent_reg_inst (
        .clk    (clk),
        .en     (lines_cleared_en),
        .rst_l  (rst_l),
        .clear  (game_start),
        .D      (lines_sent_new),
        .Q      (lines_sent)
    );
    // pipelining the lines_to_send and valid signal for timing
    register #(
        .WIDTH  ($bits(lines_to_send) + 1)
    ) lines_to_send_reg_inst (
        .clk    (clk),
        .en     (1'b1),
        .rst_l  (rst_l),
        .clear  (1'b0),
        .D      ({lines_to_send_pipe, new_lines_valid_pipe}),
        .Q      ({lines_to_send, new_lines_valid})
    );
endmodule // LinesManager