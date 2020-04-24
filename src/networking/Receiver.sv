/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 *								Receiver.sv
 * Overall receiver module to decode and receive data serially across 5 wires.
 * Takes inputs from GPIO, control FSM. Outputs to game logic and sender. 
 * When game is active, listens for syncword on transmission wires. Decodes
 * and reconstructs received packets. On completion, asserts a send signal for
 * the sender, or update_opponent_data for the game logic.
 *
 * INPUTS:
 *  - clk 					clock
 *  - clk_gpio				GPIO clock for serial receivers
 *  - rst_l					reset
 *  - game_active 			indicates game is in progress, do nothing if not high
 *	- serial_in_h 			serial data in for handshaking line
 *	- serial_in_0 			serial data in for data 0 line
 *	- serial_in_1			serial data in for data 1 line
 *	- serial_in_2			serial data in for data 2 line
 *	- serial_in_3 			serial data in for data 3 line
 * 
 * OUTPUTS:
 *  - send_ready_ACK		indicates ACK should be sent over handshake line
 *  - send_game_lost		indicates game end should be sent over handshake line
 *  - ack_received			indicates an ACK was received
 *  - ack_seqNum			sequence number of received data packet + 1, provided 
 *							for sender to include with handshake packet
 *  - update_opponent_data	1-cycle pulse, indicates there is fresh data on garbage, 
 *							hold, piece_queue, playfield.
 *  - opponent_garbage		number of garbage lines being sent
 *  - opponent_hold			content of opponent's hold register
 *  - opponent_piece_queue	content of opponent's piece queue
 *	- opponent_playfield	content of opponent's playfield
 *  - opponent_ready		indicates opponent is ready to begin game
 * 	- opponent_lost			indicates opponent topped out
 *  - receive_done 			data receive complete signal for testbench purposes
 *  - packets_received_cnt	received packets counter for testbench purposes
 *  - acks_received_cnt		received acks counter for testbench purposes
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
	output logic 				receive_done,
	output logic [3:0]			packets_received_cnt,
	output logic [3:0]			acks_received_cnt
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

	DataReceiverFSM hnd_FSM (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_done(receive_done_h),
		.game_active(game_active),
		.receive_start(receive_start_h)
	);

	//Serial Receivers
	HandshakeReceiver serial_receiver_h (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_start(receive_start_h),
        .game_active(game_active),
		.serial_in(serial_in_h),
		.data_out(enc_data_h),
		.receive_done(receive_done_h)
	);

	DataReceiver serial_receiver_0 (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_start(receive_start),
        .game_active(game_active),
		.serial_in(serial_in_0),
		.data_out(enc_data_0),
		.receive_done(receive_done_0)
	);

	DataReceiver serial_receiver_1 (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_start(receive_start),
        .game_active(game_active),
		.serial_in(serial_in_1),
		.data_out(enc_data_1),
		.receive_done(receive_done_1)
	);

	DataReceiver serial_receiver_2 (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_start(receive_start),
        .game_active(game_active),
		.serial_in(serial_in_2),
		.data_out(enc_data_2),
		.receive_done(receive_done_2)
	);

	DataReceiver serial_receiver_3 (
		.clk(clk_gpio),
		.rst_l(rst_l),
		.receive_start(receive_start),
        .game_active(game_active),
		.serial_in(serial_in_3),
		.data_out(enc_data_3),
		.receive_done(receive_done_3)
	);

	//decoded data
	logic [PAR_DATA_BITS-1:0] dec_data_0, dec_data_1, dec_data_2, dec_data_3;
	logic [HEAD_BITS-1:0] dec_data_h;
	data_pkt_t data_packet;
	hnd_head_t hnd_packet;	

    logic send_ACK, send_ready;
    assign send_ready_ACK = send_ACK || send_ready;

	logic seqNum, received_seqNum;
	assign ack_seqNum = seqNum;

	//TODO decoders
	assign dec_data_0 = enc_data_0[ENC_DATA_BITS-9:0];
	assign dec_data_1 = enc_data_1[ENC_DATA_BITS-9:0];
	assign dec_data_2 = enc_data_2[ENC_DATA_BITS-9:0];
	assign dec_data_3 = enc_data_3[ENC_DATA_BITS-9:0];
	assign dec_data_h = enc_data_h[ENC_HEAD_BITS-4:0];

	assign data_packet = {dec_data_0, dec_data_1, dec_data_2, dec_data_3};
	assign hnd_packet  = dec_data_h;

	//rising edge detector for receive_done, used to detect when to update output signals
	logic receive_done_posedge;
	logic receive_done_delay;
	always_ff @(posedge clk) begin
		receive_done_delay <= receive_done;
	end
	assign receive_done_posedge = receive_done & ~receive_done_delay;

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
			opponent_piece_queue <= '{NEXT_PIECES_COUNT{BLANK}};
			opponent_playfield 	 <= '{PLAYFIELD_ROWS{'{PLAYFIELD_COLS{BLANK}}}};
			seqNum 				 <= 'b0;
			send_ACK		     <= 'b0;
			update_opponent_data <= 'b0;
			packets_received_cnt <= 'b0;
		end 
		else if(!game_active) begin
			opponent_garbage	 <= 'b0;
			opponent_hold		 <=  BLANK;
			opponent_piece_queue <= '{NEXT_PIECES_COUNT{BLANK}};
			opponent_playfield 	 <= '{PLAYFIELD_ROWS{'{PLAYFIELD_COLS{BLANK}}}};
			seqNum 				 <= 'b0;
			send_ACK		     <= 'b0;
			update_opponent_data <= 'b0;
			packets_received_cnt <= 'b0;
		end
		else if(receive_done_posedge) begin
			//Sequence number check - if they match, increment seqNum and update outputs
			if(received_seqNum == seqNum) begin
				opponent_garbage	 <= data_packet.garbage;
				opponent_hold		 <= tile_type_t'(data_packet.hold);
				opponent_piece_queue <= piece_queue_unpacked;
				opponent_playfield 	 <= playfield_unpacked;
				seqNum 				 <= seqNum + 1'b1;
				send_ACK		     <= 1'b1;
				update_opponent_data <= 1'b1;
				packets_received_cnt <= packets_received_cnt + 1'b1;
			end
		end
		//make send_ACK and update_opponent_data 1-cycle pulses
		else if((send_ACK == 1'b1) && (update_opponent_data == 1'b1)) begin
			send_ACK <= 1'b0;
			update_opponent_data <= 1'b0;
		end
	end

    //seqNum decoder
    logic [2:0] seqNum_set_bits;
    always_comb begin
        seqNum_set_bits = data_packet.seqNum[0] + data_packet.seqNum[1] + data_packet.seqNum[2] + data_packet.seqNum[3];
        received_seqNum = (seqNum_set_bits >= 2) ? 1'b1 : 1'b0;
    end

	//rising edge detector for receive_done_h, used to detect when to update output signals
	logic receive_done_h_posedge;
	logic receive_done_h_delay;
	always_ff @(posedge clk) begin
		receive_done_h_delay <= receive_done_h;
	end
	assign receive_done_h_posedge = receive_done_h & ~receive_done_h_delay;

	always_ff @(posedge clk, negedge rst_l) begin
		if(!rst_l) begin
			ack_received      <= 1'b0;
            opponent_lost     <= 1'b0;
            send_ready        <= 1'b0;
            acks_received_cnt <= 4'b0;
		end 
		else if(!game_active) begin
			ack_received      <= 1'b0;
            opponent_lost     <= 1'b0;
            send_ready        <= 1'b0;
            acks_received_cnt <= 4'b0;
		end
		else if(receive_done_h_posedge) begin
			//check if ack
			if((hnd_packet.pid == 1'b1) && (hnd_packet.pid_n == 1'b0)) begin
				ack_received <= 1'b1;
				acks_received_cnt <= acks_received_cnt + 1'b1;
			end
            //check if game end
            else if((hnd_packet.pid == 1'b0) && (hnd_packet.pid_n == 1'b1)) begin
                opponent_lost <= 1'b1;
                send_ready <= 1'b1;
            end
		end
		//make ack_received a 1-cycle pulse
		else if(ack_received == 1'b1) begin
			ack_received <= 1'b0;
		end
	end

	assign opponent_ready = ack_received;

endmodule // Receiver