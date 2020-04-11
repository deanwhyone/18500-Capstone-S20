/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 *								DataReceiverFSM.sv
 * Control FSM for the data receivers. 
 *
 * INPUTS:
 *  - clk 				GPIO clock
 *  - rst_l				reset
 *  - receive_done		indicates a full packet has been received
 *  - game_active		indicates game is in progress
 *
 * OUTPUTS:
 *	- receive_start		1-cycle pulse on state transition, indicates data_out can
 *					    be cleared and to begin listening for a new packet
 *
 * STATES:
 *  - IDLE				idle state, remain here unless game is active
 *  - RECEIVE 			receive state, assert receive_start upon transition 
 *						into this state. Move to wait upon receive_done
 *  - WAIT				wait state, move back to receive on the next cycle
 **/
 `default_nettype none

module DataReceiverFSM
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
(
	input  logic clk,
	input  logic rst_l,
	input  logic receive_done,
	input  logic game_active,
	output logic receive_start
);
	typedef enum logic [1:0] {
		IDLE, 
		RECEIVE,
		WAIT
	} dataReceiver_states_t;

	dataReceiver_states_t state, next_state;

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
    				next_state    = RECEIVE;
    				receive_start = 1'b1;
    			end
    			else begin
    				next_state    = IDLE;
    				receive_start = 1'b0;
    			end
    		end
    		RECEIVE: begin
    			if(!game_active) begin
    				next_state    = IDLE;
    				receive_start = 1'b0;
    			end
    			else if(receive_done) begin
    				next_state    = WAIT;
    				receive_start = 1'b0;
    			end
    			else begin
    				next_state    = RECEIVE;
    				receive_start = 1'b0;
    			end
    		end
    		WAIT: begin
    			if(!game_active) begin
    				next_state    = IDLE;
    				receive_start = 1'b0;
    			end
    			else begin
    				next_state    = RECEIVE;
    				receive_start = 1'b1;
    			end
    		end
    	endcase // state
    end

endmodule : DataReceiverFSM
