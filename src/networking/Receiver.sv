/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * Overall receiver module to decode and receive data serially across 5 wires
 * Interfaces with game logic
 * 
 **/
 `default_nettype none

module Receiver
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
(
	input  logic 	   			clk,
	input  logic		   		clk_gpio,
	input  logic 	   			rst_l,
	input  logic 	   			serial_in_h,
	input  logic 	   			serial_in_0,
	input  logic 	   			serial_in_1,
	input  logic 	   			serial_in_2,
	input  logic 	   			serial_in_3,
	output logic	   			update_opponent_data,
	output logic [GBG_BITS-1:0] opponent_garbage,
	output tile_type_t 			opponent_hold,
	output tile_type_t 			opponent_piece_queue	[NEXT_PIECES],
	output tile_type_t 			opponent_playfield		[PLAYFIELD_ROWS][PLAYFIELD_COLS],
	output logic	   			opponent_ready,
	output logic	   			opponent_lost
);

endmodule // Receiver