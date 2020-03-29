/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 *								DataSenderFSM.sv
 * Control FSM for the data senders. Interfaces with timeout counter and serial
 * data senders.
 *
 * INPUTS:
 *  - clk 				GPIO clock
 *  - rst_l				reset
 *  - timeout 			indicates timeout, no ACK received. Resend data
 *  - ack_received		indicates an ACK was received, can send again
 *  - send_done			indicates all data has been sent
 *  - game_active		indicates game is in progress
 *
 * OUTPUTS:
 *  - timeout_cnt_en	enable signal for timeout counter
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

 module DataSenderFSM
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
(
	input  logic clk,
	input  logic rst_l,
	input  logic timeout,
	input  logic ack_received,
	input  logic send_done,
	input  logic game_active,
	output logic timeout_cnt_en,
	output logic send_start
);

	typedef enum logic [1:0] {
		IDLE, 
		SEND,
		WAIT
	} dataSender_states_t;

	dataSender_states_t state, next_state;

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
    			if(game_active) begin
    				next_state     = SEND;
    				timeout_cnt_en = 1'b0;
    				send_start     = 1'b1;
    			end
    			else begin
    				next_state     = IDLE;
    				timeout_cnt_en = 1'b0;
    				send_start 	   = 1'b0;
    			end
    		end
    		SEND: begin
    			if(!game_active) begin
    				next_state     = IDLE;
    				timeout_cnt_en = 1'b0;
    				send_start     = 1'b0;
    			end
    			else if(send_done) begin
    				next_state     = WAIT;
    				timeout_cnt_en = 1'b1;
    				send_start     = 1'b0;
    			end
    			else begin
    				next_state     = SEND;
    				timeout_cnt_en = 1'b0;
    				send_start     = 1'b0;
    			end
    		end
    		WAIT: begin
    			if(!game_active) begin
    				next_state     = IDLE;
    				timeout_cnt_en = 1'b0;
    				send_start     = 1'b0;
    			end
    			else if(timeout || ack_received) begin
    				next_state     = SEND;
    				timeout_cnt_en = 1'b0;
    				send_start     = 1'b1;
    			end
    			else begin
    				next_state     = WAIT;
    				timeout_cnt_en = 1'b1;
    				send_start     = 1'b0;
    			end
    		end
    	endcase // state
    end

endmodule : DataSenderFSM