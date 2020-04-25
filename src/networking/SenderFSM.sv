/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 *								SenderFSM.sv
 * Control FSM for the sender. Interfaces with game logic, receiver, sender.
 * Tracks game state and game start/end synchronization.
 *
 * INPUTS:
 *  - clk 				GPIO clock
 *  - rst_l				reset
 *  - player_ready 		indicates player has initiated multiplayer game, send 
 *						ACK until game start
 *  - player_unready	indicates player has cancelled multiplayer game
 *  - top_out			indicates game has ended (player lost), from game logic
 *  - ACK_received		indicates an ACK has been received from the opponent
 *						and the game can begin
 *  - game_end			indicates game has ended (player won), from receiver
 *
 * OUTPUTS:
 *  - send_ready     	indicates ACK should be sent over handshake line
 *  - send_game_lost	indicates game end should be sent over handshake line
 *  - game_active		indicates game is in progress, also asserted in ready
 *                      state so ACKs can be sent
 *
 * STATES:
 *  - IDLE				idle state, do nothing until player readies for
 * 						multiplayer game
 *  - GAME_READY		ready state, send ACK over handshake line until an ACK
 *						is received from the opponent, then start the game
 *  - IN_GAME			in-progress game state, assert game_active
 *  - GAME_LOST 		game over state, send GAME END over handshake line 
 *						until an ACK is received from the opponent, then return
 *						to IDLE
 *  - GAME_WON          game won state, wait WIN_TIMEOUT_CYCLES then return to idle
 **/
 `default_nettype none

module SenderFSM
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
(
	input  logic clk,
	input  logic rst_l,
	input  logic player_ready,
	input  logic player_unready,
	input  logic top_out,
	input  logic ACK_received,
	input  logic game_end,
    input  logic timeout,
	output logic send_ready,
	output logic send_game_lost,
	output logic game_active,
    output logic ingame,
    output logic gamelost,
    output logic gameready
);

	typedef enum logic [2:0] {
		IDLE, 
		GAME_READY, 
		IN_GAME, 
		GAME_LOST,
        GAME_WON
	} sender_states_t;

	sender_states_t state, next_state;

	always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    //output logic
    always_comb begin
    	unique case (state)
    		IDLE: begin
    			send_ready     = 1'b0;
    			send_game_lost = 1'b0;
    			game_active    = 1'b0;
                ingame         = 1'b0;
                gamelost       = 1'b0;
                gameready      = 1'b0;
    		end
    		GAME_READY: begin
    			send_ready     = 1'b1;
    			send_game_lost = 1'b0;
    			game_active    = 1'b1;
                ingame         = 1'b0;
                gamelost       = 1'b0;
                gameready      = 1'b1;
    		end
    		IN_GAME: begin
    			send_ready     = 1'b0;
    			send_game_lost = 1'b0;
    			game_active    = 1'b1;
                ingame         = 1'b1;
                gamelost       = 1'b0;
                gameready      = 1'b0;
    		end
    		GAME_LOST: begin
    			send_ready     = 1'b0;
    			send_game_lost = 1'b1;
    			game_active    = 1'b1;
                ingame         = 1'b0;
                gamelost       = 1'b1;
                gameready      = 1'b0;
    		end
            GAME_WON: begin
                send_ready     = 1'b1;
                send_game_lost = 1'b0;
                game_active    = 1'b1;
                ingame         = 1'b0;
                gamelost       = 1'b0;
                gameready      = 1'b0;
            end
    	endcase // state
    end

    //next state logic
    always_comb begin
    	unique case (state)
    		IDLE: begin
    			if(player_ready) 
    				next_state = GAME_READY;
    			else
    				next_state = IDLE;
    		end
    		GAME_READY: begin
    			if(player_unready)
    				next_state = IDLE;
    			else if(ACK_received)
    				next_state = IN_GAME;
    			else
    				next_state = GAME_READY;
    		end
    		IN_GAME: begin
    			if(game_end)
    				next_state = GAME_WON;
    			else if(top_out)
    				next_state = GAME_LOST;
    			else
    				next_state = IN_GAME;
    		end
    		GAME_LOST: begin
    			if(ACK_received)
    				next_state = IDLE;
    			else
    				next_state = GAME_LOST;
    		end
            GAME_WON: begin
                if(timeout)
                    next_state = IDLE;
                else
                    next_state = GAME_WON;
            end
    	endcase // state
    end

endmodule : SenderFSM