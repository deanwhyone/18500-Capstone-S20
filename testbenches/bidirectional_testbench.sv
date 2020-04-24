/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * Simulation testbench for synchronization
 */
 `default_nettype none

module Bidirectional_testbench
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
();

	logic clk, clk_gpio, rst_l, send_ready, send_Ready_slave, send_ready_ACK, send_ready_ACK_slave, 
		  send_game_lost, send_game_lost_slave, game_active_slave
	logic update_data, update_data_slave, ack_received, ack_received_slave, ack_seqNum, ack_seqNum_slave;
	logic send_done, send_done_slave, send_done_h, send_done_h_slave, sender_seqNum, sender_seqNum_slave;

	logic opponent_ready, opponent_lost, opponent_ready_slave, opponent_lost_slave;
	logic [GBG_BITS-1:0] garbage, opponent_garbage, garbage_slave, opponent_garbage_slave;
	tile_type_t hold, opponent_hold, hold_slave, opponent_hold_slave;
	tile_type_t piece_queue	[NEXT_PIECES_COUNT], opponent_piece_queue[NEXT_PIECES_COUNT], 
				piece_queue_slave[NEXT_PIECES_COUNT], opponent_piece_queue_slave[NEXT_PIECES_COUNT];
	tile_type_t playfield 	[PLAYFIELD_ROWS][PLAYFIELD_COLS], opponent_playfield[PLAYFIELD_ROWS][PLAYFIELD_COLS],
				playfield_slave [PLAYFIELD_ROWS][PLAYFIELD_COLS], opponent_playfield_slave[PLAYFIELD_ROWS][PLAYFIELD_COLS];

	logic mosi_h, mosi_0, mosi_1, mosi_2, mosi_3;
	logic miso_h, miso_0, miso_1, miso_2, miso_3;

	logic player_ready, player_unready, player_ready_slave, player_unready_slave;
    logic top_out, top_out_slave;
    logic ingame, gamelost, ingame_slave, gamelost_slave;

	logic update_opponent_data, update_opponent_data_slave;
	logic receive_done, receive_done_slave;
	logic [3:0] packets_received_cnt, acks_received_cnt, packets_received_cnt_slave, acks_received_cnt_slave;

	default clocking cb_main @(posedge clk); endclocking

	SenderFSM send_fsm_master(.clk(clk), .rst_l(rst_l), .player_ready(player_ready), 
                       .player_unready(player_unready), .top_out(top_out), 
                       .ACK_received(ack_received), .game_end(opponent_lost),
                       .send_ready(send_ready), .send_game_lost(send_game_lost),
                       .game_active(game_active));

	Sender s_master(.clk_gpio(clk), .serial_out_h(mosi_h), .serial_out_0(mosi_0), .serial_out_1(mosi_1),
                    .serial_out_2(mosi_2), .serial_out_3(mosi_3), .send_ready_ACK(send_ready || send_ready_ACK), .*);
	
	Receiver r_master(.clk_gpio(clk), .serial_in_h(miso_h), .serial_in_0(miso_0), .serial_in_1(miso_1), 
				 .serial_in_2(miso_2), .serial_in_3(miso_3), .send_ready_ACK(send_ack), 
				 .ack_received(ack_received), .ack_seqNum(ack_seqNum), .*);

	SenderFSM send_fsm_slave(.clk(clk), .rst_l(rst_l), .player_ready(player_ready_slave), 
                       .player_unready(player_unready_slave), .top_out(top_out_slave), 
                       .ACK_received(ack_received_slave), .game_end(opponent_lost_slave),
                       .send_ready(send_ready_slave), .send_game_lost(send_game_lost_slave),
                       .game_active(game_active_slave));

	Sender s_slave(.clk_gpio(clk), .serial_out_h(miso_h), .serial_out_0(miso_0), .serial_out_1(miso_1),
                    .serial_out_2(miso_2), .serial_out_3(miso_3), .send_ready_ACK(send_ready_slave || send_ready_ACK_slave),
                    .send_game_lost(send_game_lost_slave), .game_active(game_active_slave), .update_data(update_data_slave),
                    .garbage(garbage_slave), .hold(hold_slave), .piece_queue(piece_queue_slave), .playfield(playfield_slave),
                    .ack_received(ack_received_slave), .ack_seqNum(ack_seqNum_slave), .send_done(send_done_slave), 
                    .send_done_h(send_done_h_slave), .sender_seqNum(sender_seqNum_slave));
	
	Receiver r_slave(.clk_gpio(clk), .game_active(game_active_slave), .serial_in_h(mosi_h), .serial_in_0(mosi_0), .serial_in_1(mosi_1), 
				 .serial_in_2(mosi_2), .serial_in_3(mosi_3), .send_ready_ACK(send_ack_slave), 
				 .ack_received(ack_received_slave), .ack_seqNum(ack_seqNum_slave), .update_opponent_data(update_opponent_data_slave),
				 .opponent_garbage(opponent_garbage_slave), .opponent_hold(opponent_hold_slave), 
				 .opponent_piece_queue(opponent_piece_queue_slave), .opponent_playfield(opponent_playfield_slave),
				 .opponent_ready(opponent_ready_slave), .opponent_lost(opponent_lost_slave), .receive_done(receive_done_slave), 
				 .packets_received_cnt(packets_received_cnt_slave), .acks_received_cnt(acks_received_cnt_slave));


	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk;
	end

	task doReset;
		rst_l = 1'b1;
		rst_l <= 1'b0;
		#1 rst_l <= 1'b1;
	endtask : doReset

	task updateData;
		update_data <= 1'b1;
		##1 update_data <= 1'b0;
	endtask : updateData

	/*task sendAck;
		send_ready_ACK <= 1'b1;
		##1 send_ready_ACK <= 1'b0;
	endtask

	task sendGE;
		send_game_lost <= 1'b1;
		##1 send_game_lost <= 1'b0;
	endtask

	function displayDataPacket;
		$display("seq num: %b, garbage: %0d, hold: %b, piece_queue: %h\nplayfield: %h", 
			s.data_packet.seqNum, s.data_packet.garbage, s.data_packet.hold,
			s.data_packet.piece_queue, s.data_packet.playfield);
	endfunction

	function displayHndPacket;
		$display("handshake packet: %b", s.hnd_packet);
	endfunction

	function displayHndState;
		$display("send_start_h: %b, mosi_h: %b, sent_count: %0d, send_done: %b", 
			s.send_start_h, mosi_h, s.serial_sender_h.sent_count, send_done_h);
	endfunction

	function displayReceivedPacket;
		$display("seq num: %b, garbage: %0d, hold: %b, piece_queue: %h\nplayfield: %h", 
			r.data_packet.seqNum, r.data_packet.garbage, r.data_packet.hold,
			r.data_packet.piece_queue, r.data_packet.playfield);
	endfunction

	function displayReceivedHndPacket;
		$display("seq num: %b, seq num_n: %b, pid: %b, pid_n: %b", 
			r.hnd_packet.seqNum, r.hnd_packet.seqNum_n, r.hnd_packet.pid, r.hnd_packet.pid_n);
	endfunction*/


	initial begin
		update_data = 1'b0;
		garbage = 1;
		hold = I;
		update_data_slave = 1'b0;
		garbage_slave = 1;
		hold_slave = I;
		for(int i = 0; i < NEXT_PIECES_COUNT; i++) begin
			piece_queue[i] = I;
			piece_queue_slave[i] = I;
		end
		for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                playfield[i][j] = I;
                playfield_slave[i][j] = I;
            end
        end

        doReset;
		##1;

		player_ready = 1'b1;
		player_ready_slave = 1'b1;
		##1;
		for(int i = 0; i < 200; i++) begin
			##1;
		end
		$finish();
	end


endmodule // Bidirectional_testbench