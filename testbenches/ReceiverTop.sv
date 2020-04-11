`default_nettype none

module ReceiverTop
	import NetworkPkg::*,
		   DisplayPkg::*,
		   GamePkg::*;
(
	input  logic 		CLOCK_50,
	input  logic [17:0] SW,
	input  logic [3:0]  KEY,
	output logic [17:0] LEDR,
	output logic [0:35] GPIO,
    output logic [6:0]  HEX0,
    output logic [6:0]  HEX4,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX6
);
    logic clk, clk_gpio, rst_l, send_ready_ACK, send_game_lost, game_active, update_data, ack_received, ack_seqNum;
    logic send_done, send_done_h, receive_done;
    logic opponent_ready, opponent_lost;
    logic [GBG_BITS-1:0] garbage, opponent_garbage;
    tile_type_t hold, opponent_hold;
    tile_type_t piece_queue [NEXT_PIECES_COUNT], opponent_piece_queue[NEXT_PIECES_COUNT];
    tile_type_t playfield   [PLAYFIELD_ROWS][PLAYFIELD_COLS], opponent_playfield[PLAYFIELD_ROWS][PLAYFIELD_COLS];
    logic serial_out_h, serial_out_0, serial_out_1, serial_out_2, serial_out_3;

    logic receiver_send_ack, receiver_ack_received, receiver_ack_seqNum, update_opponent_data;

    logic [3:0] packets_received_cnt;

    logic sender_seqNum;

	Sender sender_inst(.*);

    Receiver receiver_inst(.serial_in_h(serial_out_h), .serial_in_0(serial_out_0), .serial_in_1(serial_out_1), 
                 .serial_in_2(serial_out_2), .serial_in_3(serial_out_3), .send_ready_ACK(receiver_send_ack), 
                 .ack_received(receiver_ack_received), .ack_seqNum(receiver_ack_seqNum), .*);

	assign clk      = CLOCK_50;
	assign clk_gpio = CLOCK_50;
    always_comb begin
        rst_l    = !SW[17];
        game_active = SW[16];
        garbage[3:0] = SW[3:0];
    end

    /*assign GPIO[10] = clk;
    assign GPIO[11] = serial_out_h;
    assign GPIO[12] = serial_out_0;
    assign GPIO[13] = serial_out_1;
    assign GPIO[14] = serial_out_2;
    assign GPIO[15] = serial_out_3;*/

    assign update_data = !KEY[3];
    assign send_ready_ACK = !KEY[2];
    assign send_game_lost = !KEY[1];

    always_comb begin
    	LEDR[17] = 'b0;
        LEDR[16] = game_active;
        LEDR[15:4] = 'b0;
        LEDR[3] = receive_done;
        LEDR[2] = update_opponent_data;
    	LEDR[1] = send_done_h;
    	LEDR[0] = send_done;
    end

    BCDtoSevenSegment sevenseg4(.bcd(opponent_garbage), .seg(HEX4));
    BCDtoSevenSegment sevenseg6(.bcd(garbage), .seg(HEX6));
    BCDtoSevenSegment sevenseg0(.bcd(packets_received_cnt), .seg(HEX0));

    BCDtoSevenSegment sevenSeg3(.bcd({3'b0, sender_seqNum}), .seg(HEX3));
    BCDtoSevenSegment sevenSeg2(.bcd({3'b0, receiver_ack_seqNum}), .seg(HEX2));




endmodule : ReceiverTop