/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 * Top level receiver testbench. Switch 17 resets, switch 16 
 * must be kept high for the game to be active. GPIO clock 
 * frequency is 100kHz. Leftmost hex display is the number
 * of garbage lines received. Middle is the current sequence
 * number. Second to the right is total acks received, rightmost
 * is total data packets received.
 * 
 **/

`default_nettype none

module ReceiverTop
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
(
	input  logic 		CLOCK_50,
	input  logic [17:0] SW,
	input  logic [3:0]  KEY,
	input  logic [0:35] GPIO,
    output logic [17:0] LEDR,
    output logic [6:0]  HEX0,
    output logic [6:0]  HEX1,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX4
);
    logic clk, clk_gpio, rst_l, game_active, ack_seqNum;
    logic receive_done;
    logic opponent_ready, opponent_lost;
    logic [GBG_BITS-1:0] opponent_garbage;
    tile_type_t opponent_hold;
    tile_type_t opponent_piece_queue[NEXT_PIECES_COUNT];
    tile_type_t opponent_playfield[PLAYFIELD_ROWS][PLAYFIELD_COLS];
    logic serial_in_h, serial_in_0, serial_in_1, serial_in_2, serial_in_3;

    logic receiver_send_ack, receiver_ack_received, receiver_ack_seqNum, update_opponent_data;

    logic [3:0] packets_received_cnt, acks_received_cnt;

    Receiver receiver_inst(.serial_in_h(serial_in_h), .serial_in_0(serial_in_0), .serial_in_1(serial_in_1), 
                 .serial_in_2(serial_in_2), .serial_in_3(serial_in_3), .send_ready_ACK(receiver_send_ack), 
                 .ack_received(receiver_ack_received), .ack_seqNum(receiver_ack_seqNum), .*);

	assign clk         = CLOCK_50;

    always_comb begin
        rst_l          = !SW[17];
        game_active    = SW[16];
    end

    assign clk_gpio    = GPIO[10];
    assign serial_in_h = GPIO[11];
    assign serial_in_0 = GPIO[12];
    assign serial_in_1 = GPIO[13];
    assign serial_in_2 = GPIO[14];
    assign serial_in_3 = GPIO[15];

    always_comb begin
    	LEDR[17] = 'b0;
        LEDR[16] = game_active;
        LEDR[15:2] = 'b0;
        LEDR[1] = receive_done;
        LEDR[0] = update_opponent_data;
    end

    BCDtoSevenSegment sevenseg4(.bcd(opponent_garbage), .seg(HEX4));
    BCDtoSevenSegment sevenseg0(.bcd(packets_received_cnt), .seg(HEX0));
    BCDtoSevenSegment sevenseg1(.bcd(acks_received_cnt), .seg(HEX1));

    BCDtoSevenSegment sevenSeg2(.bcd({3'b0, receiver_ack_seqNum}), .seg(HEX2));




endmodule : ReceiverTop