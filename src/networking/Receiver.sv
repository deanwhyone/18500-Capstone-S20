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
	output logic 				send_ready_ACK,
	output logic 				ack_received,
	output logic 				ack_seqNum,
	output logic	   			update_opponent_data,
	output logic [GBG_BITS-1:0] opponent_garbage,
	output tile_type_t 			opponent_hold,
	output tile_type_t 			opponent_piece_queue	[NEXT_PIECES_COUNT],
	output tile_type_t 			opponent_playfield		[PLAYFIELD_ROWS][PLAYFIELD_COLS],
	output logic	   			opponent_ready,
	output logic	   			opponent_lost,
	output logic 				receive_done
);
	//Serial data receiver signals
	logic receive_start;
	//logic receive_done;
	logic receive_done_0, receive_done_1, receive_done_2, receive_done_3;
	assign receive_done = receive_done_0 & receive_done_1 & receive_done_2 & receive_done_3;

	logic [ENC_DATA_BITS-1:0] enc_data_0, enc_data_1, enc_data_2, enc_data_3;

	//handshake signals
	logic receive_start_h;
	logic receive_done_h;

	logic [ENC_HEAD_BITS-1:0] enc_data_h;

	//FSMs
	DataReceiverFSM data_FSM (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_done(receive_done),
		.game_active(game_active),
		.receive_start(receive_start)
	);

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

	logic seqNum;
	assign ack_seqNum = seqNum;

	//TODO decoders
	assign dec_data_0 = enc_data_0[ENC_DATA_BITS-9:0];
	assign dec_data_1 = enc_data_1[ENC_DATA_BITS-9:0];
	assign dec_data_2 = enc_data_2[ENC_DATA_BITS-9:0];
	assign dec_data_3 = enc_data_3[ENC_DATA_BITS-9:0];

	assign data_packet = {dec_data_0, dec_data_1, dec_data_2, dec_data_3};
	assign hnd_packet  = dec_data_h;

	//rising edge detector for receive_done, used to detect when to update output signals
	logic receive_done_posedge;
	logic receive_done_delay;
	always_ff @(posedge clk) begin
		receive_done_delay <= receive_done;
	end
	assign receive_done_posedge = receive_done & ~receive_done_delay;

	//update_opponent_data should be asserted one cycle after receive_done as output 
	//data takes one cycle to update
	always_ff @(posedge clk, negedge rst_l) begin
		if(!rst_l) update_opponent_data <= 'b0;
		else update_opponent_data <= receive_done_posedge;
	end

	//convert packed arrays to unpacked outputs for game logic
	tile_type_t 	piece_queue_unpacked[NEXT_PIECES_COUNT];
	tile_type_t 	playfield_unpacked	[PLAYFIELD_ROWS][PLAYFIELD_COLS];
	genvar i;
	generate
		for(i = 0; i < NEXT_PIECES_COUNT; i++) begin:unpack_pq_0
			assign piece_queue_unpacked[i] = tile_type_t'(data_packet.piece_queue[4*i + 3 : 4*i]);
		end
	endgenerate

	genvar n, m;
	generate
		for(n = 0; n < PLAYFIELD_ROWS; n++) begin:unpack_playfield_0
			for(m = 0; m < PLAYFIELD_COLS; m++) begin:unpack_playfield_1
				assign playfield_unpacked[n][m] = tile_type_t'(data_packet.playfield[4*PLAYFIELD_COLS*n + 4*m + 3 : 4*PLAYFIELD_COLS*n + 4*m]);
			end
		end
	endgenerate

	//Data Packet Logic
	always_ff @(posedge clk, negedge rst_l) begin
		if(!rst_l) begin
			opponent_garbage	 <= 'b0;
			opponent_hold		 <=  BLANK;
			opponent_lost		 <= 'b0;
			opponent_ready 		 <= 'b0;
			opponent_piece_queue <= '{NEXT_PIECES_COUNT{BLANK}};
			opponent_playfield 	 <= '{PLAYFIELD_ROWS{'{PLAYFIELD_COLS{BLANK}}}};
			seqNum 				 <= 'b0;
			send_ready_ACK		 <= 'b0;
		end 
		else if(receive_done_posedge) begin
			//Sequence number check - if they match, increment seqNum and update outputs
			if(data_packet.seqNum == seqNum) begin
				opponent_garbage	 <= data_packet.garbage;
				opponent_hold		 <= tile_type_t'(data_packet.hold);
				opponent_lost		 <= 'b0;
				opponent_ready 		 <= 'b0;
				opponent_piece_queue <= piece_queue_unpacked;
				opponent_playfield 	 <= playfield_unpacked;
				seqNum 				 <= seqNum + 1'b1;
				send_ready_ACK		 <= 1'b1;
			end
		end
		//make send_ready_ACK a 1-cycle pulse
		else if(send_ready_ACK == 1'b1) begin
			send_ready_ACK <= 1'b0;
		end
	end

	//TODO opponent lost/ready

	//rising edge detector for receive_done_h, used to detect when to update output signals
	logic receive_done_h_posedge;
	logic receive_done_h_delay;
	always_ff @(posedge clk) begin
		receive_done_h_delay <= receive_done_h;
	end
	assign receive_done_h_posedge = receive_done_h & ~receive_done_h_delay;


	always_ff @(posedge clk, negedge rst_l) begin
		if(!rst_l) begin
			ack_received <= 'b0;
		end 
		else if(receive_done_h_posedge) begin
			if((hnd_packet.pid == 1'b1) && (hnd_packet.pid_n == 1'b0)) begin
				ack_received <= 1'b1;
			end
		end
		//make ack_received a 1-cycle pulse
		else if(ack_received == 1'b1) begin
			ack_received <= 1'b0;
		end
	end

endmodule // Receiver