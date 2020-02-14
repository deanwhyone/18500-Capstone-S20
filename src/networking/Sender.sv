/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 *								Sender.sv
 * Overall sender module to encode and transmit data serially across 5 wires
 * Interfaces with game logic
 *
 **/
 `default_nettype none

module Sender
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
(
	input  logic 	  			clk,
	input  logic 	  			clk_gpio,
	input  logic 	 			rst_l,
	input  logic		  		player_ready,
	input  logic       			update_data,
	input  logic [GBG_BITS-1:0] garbage,
	input  tile_type_t 			hold,
	input  tile_type_t 			piece_queue	[NEXT_PIECES],
	input  tile_type_t 			playfield 	[PLAYFIELD_ROWS][PLAYFIELD_COLS],
	input  logic		  		top_out,
	output logic 	  			serial_out_h,
	output logic 	  			serial_out_0,
	output logic 	  			serial_out_1,
	output logic 	  			serial_out_2,
	output logic 	  			serial_out_3
);

endmodule // Sender