/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module manages how to load garbage lines into the playfield by
 * tracking the number of new garbage lines that are being sent. Also manages
 * garbage of the *network* player such that the local lines being sent cancel
 * the lines received before sending the overflow over to the opponent.
 */
`default_nettype none

module GarbageManager
    import GamePkg::*;
(
    input  logic        clk,
    input  logic        rst_l,
    input  logic        game_start,
    input  logic        network_valid,
    input  logic        load_garbage,
    input  logic [ 9:0] lines_network_new,
    input  logic        valid_local,
    input  logic [ 9:0] lines_local_new,
    output logic [ 9:0] lines_to_pf,
    output logic [ 9:0] lines_to_network,
    output logic        lines_send,
    output logic        lines_load
);
    enum logic {IDLE, LOAD} state, next_state;

    logic [31:0] garbage_timer;
    logic        garbage_timer_cl;
    logic [ 9:0] lines_to_pf_update;
    logic        lines_to_pf_cl;
    logic [ 9:0] lines_to_lan_update;
    logic        lines_to_lan_cl;

    logic [ 4:0] garbage_tick;
    logic        garbage_tick_ld;
    logic        garbage_tick_en;

    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state          = state;
        garbage_timer_cl    = 1'b0;
        lines_to_pf_cl      = 1'b0;
        lines_load          = 1'b0;
        garbage_tick_ld     = 1'b1;
        case (state)
            IDLE: begin
                if (garbage_timer >= GARBAGE_DELAY) begin
                    next_state          = LOAD;
                    garbage_timer_cl    = 1'b1;
                end
            end
            LOAD: begin
                garbage_timer_cl = 1'b1;
                if (load_garbage) begin
                    garbage_tick_ld = 1'b0;
                    if (10'(garbage_tick) < lines_to_pf) begin
                        lines_load = 1'b1;
                    end else begin
                        next_state      = IDLE;
                        lines_to_pf_cl  = 1'b1;
                    end
                end
            end
        endcase
    end

    always_comb begin
        lines_to_lan_cl     = 1'b0;
        lines_send          = 1'b0;
        if (garbage_timer == 694445) begin // 1 frame at 72 hz
            lines_to_lan_cl = 1'b1;
            lines_send      = 1'b1;
        end
    end

    always_comb begin
        lines_to_pf_update  = lines_to_pf;
        lines_to_lan_update = lines_to_network;

        if (valid_local) begin
            lines_to_lan_update = lines_to_lan_update + lines_local_new;
        end
        if (network_valid) begin
            lines_to_pf_update = lines_to_pf_update + lines_network_new;
        end

        if (lines_to_pf_update > lines_to_lan_update) begin
            lines_to_pf_update  = lines_to_pf_update - lines_to_lan_update;
            lines_to_lan_update = '0;
        end else begin
            lines_to_pf_update  = '0;
            lines_to_lan_update = lines_to_lan_update - lines_to_pf_update;
        end
    end

    register #(
        .WIDTH      ($bits(lines_to_pf))
    ) lines_to_pf_reg_inst (
        .clk    (clk),
        .en     (1'b1),
        .rst_l  (rst_l),
        .clear  (lines_to_pf_cl || game_start),
        .D      (lines_to_pf_update),
        .Q      (lines_to_pf)
    );
    register #(
        .WIDTH      ($bits(lines_to_network))
    ) lines_to_lan_reg_inst (
        .clk    (clk),
        .en     (1'b1),
        .rst_l  (rst_l),
        .clear  (lines_to_lan_cl || game_start),
        .D      (lines_to_lan_update),
        .Q      (lines_to_network)
    );

    counter #(
        .WIDTH  ($bits(garbage_tick))
    ) garbage_tick_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (1'b1),
        .load   (garbage_tick_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (garbage_tick)
    );

    counter #(
        .WIDTH  ($bits(garbage_timer))
    ) garbage_timer_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (lines_to_pf != '0),
        .load   (garbage_timer_cl || game_start),
        .up     (1'b1),
        .D      ('0),
        .Q      (garbage_timer)
    );
endmodule // GarbageManager