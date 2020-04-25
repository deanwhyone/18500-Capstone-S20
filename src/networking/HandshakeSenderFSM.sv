/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 *							HandshakeSenderFSM.sv
 * Control FSM for the handshake sender.
 *
 * INPUTS:
 *  - clk 				GPIO clock
 *  - rst_l				reset
 *  - send_done			indicates all data has been sent
 *  - game_active		indicates game is in progress
 *  - update_data_done  indicates update date is complete, new data is on
 *                      data_in of sender so transition to send can occur
 *
 * OUTPUTS:
 *	- send_start		1-cycle pulse on state transition, indicates data can be
 *						loaded in and sending can begin
 *
 * STATES:
 *  - IDLE				idle state, remain here unless game is active
 *  - SEND 				send state, assert send_start upon transition into this
 *						state. Move to wait upon send_done
 *  - WAIT				wait state, move to send upon timeout or ack_received
 **/
 `default_nettype none

 module HandshakeSenderFSM
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
(
	input  logic clk,
	input  logic rst_l,
	input  logic send_done,
	input  logic game_active,
    input  logic update_data_done,
	output logic send_start
);

	typedef enum logic [1:0] {
		IDLE, 
		SEND,
		WAIT
	} hndSender_states_t;

	hndSender_states_t state, next_state;

	always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
    	unique case (state)
    		IDLE: begin
    			if(game_active && update_data_done) begin
    				next_state     = SEND;
    				send_start     = 1'b1;
    			end
    			else begin
    				next_state     = IDLE;
    				send_start 	   = 1'b0;
    			end
    		end
    		SEND: begin
    			if(!game_active) begin
    				next_state     = IDLE;
    				send_start     = 1'b0;
    			end
    			else if(send_done) begin
    				next_state     = WAIT;
    				send_start     = 1'b0;
    			end
    			else begin
    				next_state     = SEND;
    				send_start     = 1'b0;
    			end
    		end
    		WAIT: begin
    			if(!game_active) begin
    				next_state     = IDLE;
    				send_start     = 1'b0;
    			end
    			else if(update_data_done) begin
    				next_state     = SEND;
    				send_start     = 1'b1;
    			end
    			else begin
    				next_state     = WAIT;
    				send_start     = 1'b0;
    			end
    		end
    	endcase // state
    end

endmodule : HandshakeSenderFSM