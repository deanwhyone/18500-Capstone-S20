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
	output logic [0:35] GPIO
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

	Sender sender_inst(.*);

    /*input  logic              clk,
    input  logic                clk_gpio,
    input  logic                rst_l,
    input  logic                game_active,
    input  logic                serial_in_h,
    input  logic                serial_in_0,
    input  logic                serial_in_1,
    input  logic                serial_in_2,
    input  logic                serial_in_3,
    output logic                send_ready_ACK,
    output logic                ack_received,
    output logic                ack_seqNum,
    output logic                update_opponent_data,
    output logic [GBG_BITS-1:0] opponent_garbage,
    output tile_type_t          opponent_hold,
    output tile_type_t          opponent_piece_queue    [NEXT_PIECES_COUNT],
    output tile_type_t          opponent_playfield      [PLAYFIELD_ROWS][PLAYFIELD_COLS],
    output logic                opponent_ready,
    output logic                opponent_lost*/
    Receiver receiver_inst(.serial_in_h(serial_out_h), .serial_in_0(serial_out_0), .serial_in_1(serial_out_1), 
                 .serial_in_2(serial_out_2), .serial_in_3(serial_out_3), .send_ready_ACK(receiver_send_ack), 
                 .ack_received(receiver_ack_received), .ack_seqNum(receiver_ack_seqNum), .*);

	assign clk      = CLOCK_50;
	assign clk_gpio = CLOCK_50;
    assign rst_l    = !SW[17];
    assign game_active = SW[16];

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


endmodule : ReceiverTop