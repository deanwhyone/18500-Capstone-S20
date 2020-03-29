/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * Simulation testbench for sender module
 */
 `default_nettype none

module Sender_testbench
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
();
	logic clk, clk_gpio, rst_l, send_ready_ACK, send_game_lost, game_active, update_data, ack_received, ack_seqNum;
	logic [GBG_BITS-1:0] garbage;
	tile_type_t hold;
	tile_type_t piece_queue	[NEXT_PIECES_COUNT];
	tile_type_t playfield 	[PLAYFIELD_ROWS][PLAYFIELD_COLS];
	logic serial_out_h, serial_out_0, serial_out_1, serial_out_2, serial_out_3;

	default clocking cb_main @(posedge clk); endclocking

	Sender dut(.clk_gpio(clk), .*);

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

	function displayDataPacket;
		$display("seq num: %b, garbage: %0d, hold: %b, piece_queue: %h\nplayfield: %h", 
			dut.data_packet.seqNum, dut.data_packet.garbage, dut.data_packet.hold,
			dut.data_packet.piece_queue, dut.data_packet.playfield);
	endfunction

	function displayHndPacket;
		$display("handshake packet: %b", dut.hnd_packet);
	endfunction

	function displayHndState;
		$display("send_start_h: %b, serial_out_h: %b, sent_count: %0d, send_done: %b", 
			dut.send_start_h, serial_out_h, dut.serial_sender_h.sent_count, dut.send_done_h);
	endfunction

	initial begin
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
		displayDataPacket();

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
        displayDataPacket();

        garbage = 8;
		hold = T;
		for(int i = 0; i < NEXT_PIECES_COUNT; i++) begin
			piece_queue[i] = T;
		end
		for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                playfield[i][j] = T;
            end
        end
        updateData;
        ##1;
        displayDataPacket();
        ##1;
        sendAck;
        displayHndPacket();
        displayHndState();
        for(int i = 0; i < 20; i++) begin
        	##1;
        	displayHndState();
        end
		$finish();
	end


endmodule // Sender_testbench