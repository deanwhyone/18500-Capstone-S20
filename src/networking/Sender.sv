/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 *								Sender.sv
 * Overall sender module to encode and transmit data serially across 5 wires.
 * Receives inputs from game logic, receiver, control FSM. On update_data, 
 * constructs, divides, and encodes packets, passing them to individual serial
 * data senders for each line. Includes individual sender modules and their 
 * control FSMs, as well as packet construction logic.
 * 
 * INPUTS:
 *  - clk 				clock
 *  - clk_gpio			GPIO clock for serial senders
 *  - rst_l				reset
 *  - send_ready_ACK	indicates ACK should be sent over handshake line, 
 *  - send_game_lost	indicates game end should be sent over handshake line
 *  - game_active 		indicates game is in progress, do nothing if not high
 *  - update_data		1-cycle pulse, indicates there is fresh data on garbage, 
 *						hold, piece_queue, playfield.
 *  - garbage			number of garbage lines being sent
 *  - hold				content of player hold register
 *  - piece_queue		content of player piece queue
 *	- playfield			content of player playfield
 *  - ack_received		indicates an ACK was received
 * 
 * OUTPUTS:
 *  - serial_out_h		serial data out for handshaking line
 *  - serial_out_0		serial data out for data 0 line
 *  - serial_out_1		serial data out for data 1 line
 *  - serial_out_2		serial data out for data 2 line
 *  - serial_out_3		serial data out for data 3 line
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
	input  logic 				send_ready_ACK,
	input  logic				send_game_lost,
	input  logic		  		game_active,
	input  logic       			update_data,
	input  logic [GBG_BITS-1:0] garbage,
	input  tile_type_t 			hold,
	input  tile_type_t 			piece_queue	[NEXT_PIECES_COUNT],
	input  tile_type_t 			playfield 	[PLAYFIELD_ROWS][PLAYFIELD_COLS],
	input  logic 				ack_received,
	input  logic 				ack_seqNum,
	output logic 	  			serial_out_h,
	output logic 	  			serial_out_0,
	output logic 	  			serial_out_1,
	output logic 	  			serial_out_2,
	output logic 	  			serial_out_3,
	output logic 	  			send_done,
	output logic 	  			send_done_h,
	output logic 				sender_seqNum
);
	//Serial data sender signals
	logic send_start;
	logic update_data_done;
	//logic send_done;
	logic send_done_0, send_done_1, send_done_2, send_done_3;
	assign send_done = send_done_0 & send_done_1 & send_done_2 & send_done_3;

	//Serial handshake sender signals
	logic send_start_h;
	//logic send_done_h;

	//timeout counter
	logic timeout, timeout_cnt_en;
	logic [7:0] timeout_cnt;

	//Packets
	data_pkt_t 				  data_packet;
	logic [ENC_DATA_BITS-1:0] enc_data_0, enc_data_1, enc_data_2, enc_data_3;
	hnd_head_t 				  hnd_packet;
	logic [ENC_HEAD_BITS-1:0] enc_data_h;

	//timeout counter
	counter #(.WIDTH(8)) timeout_counter (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.en(timeout_cnt_en & !timeout),
		.load(timeout || ack_received),
		.up(1'b1),
		.D(8'b0),
		.Q(timeout_cnt)
	);
	assign timeout = (timeout_cnt >= TIMEOUT_CYCLES);

	//FSMs
	DataSenderFSM   data_FSM (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.timeout(timeout),
		.ack_received(ack_received),
		.send_done(send_done),
		.game_active(game_active),
		.update_data_done(update_data_done),
		.timeout_cnt_en(timeout_cnt_en),
		.send_start(send_start)
	);

	//Serial senders
	HandshakeSender serial_sender_h (
		.clk(clk_gpio), 
		.rst_l(rst_l), 
		.send_start(send_start_h),
		.game_active(game_active),
		.data_in(enc_data_h),
		.send_done(send_done_h),
		.serial_out(serial_out_h)
	);

	DataSender 		serial_sender_0 (
		.clk(clk_gpio), 
		.rst_l(rst_l), 
		.send_start(send_start), 
		.game_active(game_active),
		.data_in(enc_data_0),
		.send_done(send_done_0), 
		.serial_out(serial_out_0)
	);

	DataSender 		serial_sender_1 (
		.clk(clk_gpio), 
		.rst_l(rst_l), 
		.send_start(send_start), 
		.game_active(game_active),
		.data_in(enc_data_1),
		.send_done(send_done_1), 
		.serial_out(serial_out_1)
	);

	DataSender 		serial_sender_2 (
		.clk(clk_gpio), 
		.rst_l(rst_l), 
		.send_start(send_start), 
		.game_active(game_active),
		.data_in(enc_data_2),
		.send_done(send_done_2), 
		.serial_out(serial_out_2)
	);

	DataSender 		serial_sender_3 ( 
		.clk(clk_gpio), 
		.rst_l(rst_l), 
		.send_start(send_start), 
		.game_active(game_active),
		.data_in(enc_data_3),
		.send_done(send_done_3), 
		.serial_out(serial_out_3)
	);

	logic seqNum;

	//TODO encoders
	assign enc_data_0 = {9'b0, data_packet[835:627]};
	assign enc_data_1 = {9'b0, data_packet[626:418]};
	assign enc_data_2 = {9'b0, data_packet[417:209]};
	assign enc_data_3 = {9'b0, data_packet[208:0]};
	assign enc_data_h = {4'b0, hnd_packet};

	//Convert unpacked inputs to packed arrays
	logic [799:0] playfield_packed;
	logic [23:0]  piece_queue_packed;
	genvar i, j;
	generate
		for(i = 0; i < NEXT_PIECES_COUNT; i++) begin:pack_pq_0
			for(j = 0; j < 4; j++) begin:pack_pq_1
				assign piece_queue_packed[4*i + j] = piece_queue[i][j];
			end
		end
	endgenerate

	genvar n, m, k;
	generate
		for(n = 0; n < PLAYFIELD_ROWS; n++) begin:pack_playfield_0
			for(m = 0; m < PLAYFIELD_COLS; m++) begin:pack_playfield_1
				for(k = 0; k < 4; k++) begin:pack_playfield_2
					assign playfield_packed[4*PLAYFIELD_COLS*n + 4*m + k] = playfield[n][m][k];
				end
			end
		end
	endgenerate

	assign sender_seqNum = seqNum;

	//data packet logic
	always_ff @(posedge clk, negedge rst_l) begin
		if(!rst_l) begin
			data_packet  	 <= 'b0;
			seqNum 		 	 <= 'b0;
			update_data_done <= 'b0;
		end
		//update data packet
		else if(update_data) begin
			seqNum <= seqNum + 1;
			data_packet.seqNum <= {4{seqNum}};
			data_packet.garbage <= garbage;
			data_packet.hold <= hold;
			data_packet.piece_queue <= piece_queue_packed;
			data_packet.playfield <= playfield_packed;
			update_data_done <= 1'b1;
		end
		else if(update_data_done) begin
			update_data_done <= 1'b0;
		end
	end

	//handshake packet logic
	always_ff @(posedge clk, negedge rst_l) begin
		if(!rst_l) begin
			hnd_packet <= 'b0;
			send_start_h <= 'b0;
		end
		//deassert send start so its a 1-cycle pulse
		else if(send_start_h == 1'b1) begin
			send_start_h <= 1'b0;
		end
		//update handshake packet and assert send start
		else if(send_ready_ACK) begin
			hnd_packet   <= {1'b1, ack_seqNum, 1'b0, ~ack_seqNum};
			send_start_h <= 1'b1;
		end
		else if(send_game_lost) begin
			hnd_packet   <= {1'b0, ack_seqNum, 1'b1, ~ack_seqNum};
			send_start_h <= 1'b1;
		end
	end

endmodule // Sender