/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This FSM handles the screens that are displayed, from start screen to game
 * end screens. This state is output to the top module to be able to affect
 * which scene gets rendered to the user. This module will also detect top out
 * and receive a loss from the networked user.
 *
 * start_sprint - local player input. From start screen, user selects sprint
 *                mode to begin one-player race to 40 lines cleared
 * lines_cleared - register in TetrisTop holds number of lines cleared, used to
 *                 end sprint game mode
 * battle_ready - local player input. From start screen, user selects battle
 *                mode to ready up for 1v1. This needs to be communicated over
 *                network.
 * opponent_ready - communication over GPIO, networked player is ready in battle
 *                  mode. Move to MP_MODE if both local and networked players
 *                  are ready. Should consider giving user option to
 *                  un-ready.
 * opponent_lost - opponent tops out in MP_MODE, communicates over network that
 *                 the opponent has lost the game and local player has won.
 * top_out - local player tops out, and loses. This needs to be communicated
 *           over the network for the opponent to win.
 */
`default_nettype none

module GameScreensFSM
    import  GamePkg::*,
            DisplayPkg::*;
(
    input  logic            clk,
    input  logic            rst_l,
    input  logic [ 4:0]     falling_row,
    input  logic [ 4:0]     falling_col,
    input  orientation_t    falling_orientation,
    input  tile_type_t      falling_type,
    input  logic            falling_piece_lock,
    input  logic            start_sprint,
    input  logic [ 5:0]     lines_cleared,
    input  logic            battle_ready,
    input  logic            ready_withdraw,
    input  logic            opponent_ready,
    input  logic            opponent_lost,
    output logic            top_out,
    output logic            game_start,
    output logic            game_end,
    output game_screens_t   current_screen
);
    game_screens_t  state;
    game_screens_t  next_state;

    logic [ 4:0]    tile_row    [4];

    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            state <= START_SCREEN;
        end else begin
            state <= next_state;
        end
    end
    assign current_screen = state;

    always_comb begin
        next_state                      = state;
        game_start                      = 1'b0;
        game_end                        = 1'b0;
        unique case (state)
            START_SCREEN: begin
                if (start_sprint) begin
                    next_state          = SPRINT_MODE;
                    game_start          = 1'b1;
                end else if (battle_ready) begin
                    next_state          = MP_READY;
                end
            end
            SPRINT_MODE: begin
                if (top_out) begin
                    next_state          = GAME_LOST;
                    game_end            = 1'b1;
                end else if (lines_cleared >= 40) begin
                    next_state          = GAME_WON;
                    game_end            = 1'b1;
                end
            end
            MP_READY: begin
                if (opponent_ready) begin
                    next_state          = MP_MODE;
                    game_start          = 1'b1;
                end else if (ready_withdraw) begin
                    next_state = START_SCREEN;
                end
            end
            MP_MODE: begin
                if (top_out) begin
                    next_state          = GAME_LOST;
                    game_end            = 1'b1;
                end else if (opponent_lost) begin
                    next_state          = GAME_WON;
                    game_end            = 1'b1;
                end
            end
            GAME_WON: begin
                if (start_sprint || battle_ready) begin
                    next_state = START_SCREEN;
                end
            end
            GAME_LOST: begin
                if (start_sprint || battle_ready) begin
                    next_state = START_SCREEN;
                end
            end
        endcase
    end

    // due to overflow, we can detect top outs by the row at which the tetromino
    // is placed being greater than the PLAYFIELD_ROWS value (20)
    always_comb begin
        top_out = 1'b0;
        if (falling_piece_lock) begin
            for (int i = 0; i < 4; i++) begin
                if (tile_row[i] > PLAYFIELD_ROWS) begin
                    top_out = 1'b1;
                end
            end
        end
    end

    FallingTetrominoRender ftr_top_out_inst (
        .origin_row         (falling_row),
        .origin_col         (falling_col),
        .falling_type       (falling_type),
        .falling_orientation(falling_orientation),
        .tile_row           (tile_row),
        .tile_col           ()
    );
endmodule // GameScreensFSM