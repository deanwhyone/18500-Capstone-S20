`default_nettype none

module SenderTop
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
	logic [GBG_BITS-1:0] garbage;
	tile_type_t hold;
	tile_type_t piece_queue	[NEXT_PIECES_COUNT];
	tile_type_t playfield 	[PLAYFIELD_ROWS][PLAYFIELD_COLS];
	logic serial_out_h, serial_out_0, serial_out_1, serial_out_2, serial_out_3;

    logic send_done, send_done_h;

	Sender sender_inst(.*);

	assign clk      = CLOCK_50;
	assign clk_gpio = CLOCK_50;
    assign rst_l    = !SW[17];
    assign game_active = SW[16];

    assign GPIO[10] = clk;
    assign GPIO[11] = serial_out_h;
    assign GPIO[12] = serial_out_0;
    assign GPIO[13] = serial_out_1;
    assign GPIO[14] = serial_out_2;
    assign GPIO[15] = serial_out_3;

    assign update_data = !KEY[3];
    assign send_ready_ACK = !KEY[2];
    assign send_game_lost = !KEY[1];

    always_comb begin
    	LEDR[17:3] = 'b0;
        LEDR[2] = game_active;
    	LEDR[1] = send_done_h;
    	LEDR[0] = send_done;
    end


endmodule : SenderTop