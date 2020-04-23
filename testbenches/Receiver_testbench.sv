/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * Simulation testbench for receiver module
 */
 `default_nettype none

module Receiver_testbench
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
();
	/*input  logic 	   			clk,
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
	output logic [3:0]			acks_received_cnt*/


	logic clk, clk_gpio, rst_l, send_ready_ACK, send_game_lost, game_active, update_data, ack_received, ack_seqNum;
	logic send_done, send_done_h, sender_seqNum;
	logic opponent_ready, opponent_lost;
	logic [GBG_BITS-1:0] garbage, opponent_garbage;
	tile_type_t hold, opponent_hold;
	tile_type_t piece_queue	[NEXT_PIECES_COUNT], opponent_piece_queue[NEXT_PIECES_COUNT];
	tile_type_t playfield 	[PLAYFIELD_ROWS][PLAYFIELD_COLS], opponent_playfield[PLAYFIELD_ROWS][PLAYFIELD_COLS];
	logic serial_out_h, serial_out_0, serial_out_1, serial_out_2, serial_out_3;

	logic receiver_send_ack, receiver_ack_received, receiver_ack_seqNum, update_opponent_data;
	logic receive_done;
	logic [3:0] packets_received_cnt, acks_received_cnt;

	default clocking cb_main @(posedge clk); endclocking

	Sender s(.clk_gpio(clk), .*);
	Receiver dut(.clk_gpio(clk), .serial_in_h(serial_out_h), .serial_in_0(serial_out_0), .serial_in_1(serial_out_1), 
				 .serial_in_2(serial_out_2), .serial_in_3(serial_out_3), .send_ready_ACK(receiver_send_ack), 
				 .ack_received(receiver_ack_received), .ack_seqNum(receiver_ack_seqNum), .*);

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

	task sendAck;
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
		$display("send_start_h: %b, serial_out_h: %b, sent_count: %0d, send_done: %b", 
			s.send_start_h, serial_out_h, s.serial_sender_h.sent_count, send_done_h);
	endfunction

	function displayReceivedPacket;
		$display("seq num: %b, garbage: %0d, hold: %b, piece_queue: %h\nplayfield: %h", 
			dut.data_packet.seqNum, dut.data_packet.garbage, dut.data_packet.hold,
			dut.data_packet.piece_queue, dut.data_packet.playfield);
	endfunction

	function displayReceivedHndPacket;
		$display("seq num: %b, seq num_n: %b, pid: %b, pid_n: %b", 
			dut.hnd_packet.seqNum, dut.hnd_packet.seqNum_n, dut.hnd_packet.pid, dut.hnd_packet.pid_n);
	endfunction


	initial begin
		//initialize sender
		send_ready_ACK = 1'b0;
		send_game_lost = 1'b0;
		game_active = 1'b1;
		ack_received = 1'b0;
		ack_seqNum = 1'b0;
		update_data = 1'b0;
		garbage = 1;
		hold = I;
		for(int i = 0; i < NEXT_PIECES_COUNT; i++) begin
			piece_queue[i] = I;
		end
		for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                playfield[i][j] = I;
            end
        end
		doReset;
		##1;
		updateData;
		##1;
		$display("sent packet:");
		displayDataPacket();
		while(!dut.receive_done) begin
			##1;
		end
		##1;
		$display("received packet:");
		displayReceivedPacket();
		##1;
		garbage = 5;
		hold = O;
		for(int i = 0; i < NEXT_PIECES_COUNT; i++) begin
			piece_queue[i] = O;
		end
		for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                playfield[i][j] = O;
            end
        end
        updateData;
        ##1;
        $display("sent packet:");
        displayDataPacket();
		while(!dut.receive_done) begin
			##1;
		end
		##1;
		$display("received packet:");
		displayReceivedPacket();
		for(int i = 0; i < 1000; i++) begin
			##1;
		end
		doReset;
		##1;
		sendAck;
		while(!dut.receive_done_h) begin
			##1;
		end
		$display("received handshake packet: ");
		displayReceivedHndPacket;
		##1;
		sendGE;
		while(!dut.receive_done_h) begin
			##1;
		end
		$display("received handshake packet: ");
		displayReceivedHndPacket;
		$finish();

	end


endmodule // Receiver_testbench