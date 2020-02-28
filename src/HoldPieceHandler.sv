/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module registers the hold piece and clears on game start. Holds blank
 * until a hold input is received which causes the tiles either
 * 1. Swap if a hold piece is registered
 * 2. Load a new piece is there is no hold piece registered
 */
`default_nettype none

module HoldPieceHandler
    import DisplayPkg::*;
(
    input  logic        clk,
    input  logic        rst_l,
    input  logic        hold_input,
    input  logic        game_start,
    input  logic        new_tetromino,
    input  tile_type_t  falling_type,
    output logic        hold_valid,
    output logic        bag_fetch,
    output logic        hold_swap,
    output tile_type_t  hold_piece_type
);
    logic hold_reg_en;

    enum logic {VALID, INVALID} state, next_state;

    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            state   <= VALID;
        end else begin
            state   <= next_state;
        end
    end

    always_comb begin
        hold_reg_en = 1'b0;
        next_state  = state;
        case (state)
            VALID: begin
                if (hold_input) begin
                    next_state  = INVALID;
                    hold_reg_en = 1'b1;
                end
            end
            INVALID: begin
                if (new_tetromino) begin
                    next_state = VALID;
                end
            end
        endcase
    end

    assign hold_valid   = state == VALID;
    assign bag_fetch    = hold_input && hold_piece_type == BLANK;
    assign hold_swap    = hold_input && hold_piece_type != BLANK;

    register #(
        .WIDTH      ($bits(tile_type_t)),
        .RESET_VAL  (BLANK)
    ) hold_reg_inst (
        .clk    (clk),
        .en     (hold_reg_en),
        .rst_l  (rst_l),
        .clear  (game_start),
        .D      (falling_type),
        .Q      (hold_piece_type)
    );
endmodule // HoldPieceHandler