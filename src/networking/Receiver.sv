/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 *								Receiver.sv
 * Overall receiver module to decode and receive data serially across 5 wires.
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
	input  logic 				game_active,
	input  logic 	   			serial_in_h,
	input  logic 	   			serial_in_0,
	input  logic 	   			serial_in_1,
	input  logic 	   			serial_in_2,
	input  logic 	   			serial_in_3,
	output logic 				ack_received,
	output logic 				ack_seqNum,
	output logic	   			update_opponent_data,
	output logic [GBG_BITS-1:0] opponent_garbage,
	output tile_type_t 			opponent_hold,
	output tile_type_t 			opponent_piece_queue	[NEXT_PIECES],
	output tile_type_t 			opponent_playfield		[PLAYFIELD_ROWS][PLAYFIELD_COLS],
	output logic	   			opponent_ready,
	output logic	   			opponent_lost
);
	//Serial data receiver signals
	logic receive_start;
	logic receive_done;
	logic receive_done_0, receive_done_1, receive_done_2, receive_done_3;
	assign receive_done = receive_done_0 & receive_done_1 & receive_done_2 & receive_done_3;

	logic [ENC_DATA_BITS-1:0] enc_data_0, enc_data_1, enc_data_2, enc_data_3;

	//handshake signals
	logic receive_start_h;
	logic receive_done_h;

	logic [ENC_HEAD_BITS-1:0] enc_data_h;

	//FSMs

	//Serial Receivers
	HandshakeReceiver serial_receiver_h (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_start(receive_start_h),
		.serial_in(serial_in_h),
		.data_out(enc_data_h),
		.receive_done(receive_done_h)
	);

	DataReceiver serial_receiver_0 (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_start(receive_start),
		.serial_in(serial_in_0),
		.data_out(enc_data_0),
		.receive_done(receive_done_0)
	);

	DataReceiver serial_receiver_1 (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_start(receive_start),
		.serial_in(serial_in_1),
		.data_out(enc_data_1),
		.receive_done(receive_done_1)
	);

	DataReceiver serial_receiver_2 (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_start(receive_start),
		.serial_in(serial_in_2),
		.data_out(enc_data_2),
		.receive_done(receive_done_2)
	);

	DataReceiver serial_receiver_3 (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_start(receive_start),
		.serial_in(serial_in_3),
		.data_out(enc_data_3),
		.receive_done(receive_done_3)
	);

	//decoded data
	logic [PAR_DATA_BITS-1:0] dec_data_0, dec_data_1, dec_data_2, dec_data_3;
	logic [HEAD_BITS-1:0] dec_data_h;
	data_pkt_t data_packet;
	hnd_head_t hnd_packet;	

	//TODO decoders
	assign dec_data_0 = enc_data_0[ENC_DATA_BITS-9:0];
	assign dec_data_1 = enc_data_1[ENC_DATA_BITS-9:0];
	assign dec_data_2 = enc_data_2[ENC_DATA_BITS-9:0];
	assign dec_data_3 = enc_data_3[ENC_DATA_BITS-9:0];

	assign data_packet = {dec_data_0, dec_data_1, dec_data_2, dec_data_3};
	assign hnd_packet  = dec_data_h;

	always_ff @(posedge clk, negedge rst_l) begin
		if(!rst_l) begin
			ack_received		 <= 'b0;
			ack_seqNum		     <= 'b0;
			update_opponent_data <= 'b0;
			opponent_garbage	 <= 'b0;
			opponent_hold		 <= 'b0;
			opponent_lost		 <= 'b0;
			opponent_ready 		 <= 'b0;
			opponent_piece_queue <= 'b0;
			opponent_playfield 	 <= 'b0;
		end 
		else begin
		end
	end

endmodule // Receiver