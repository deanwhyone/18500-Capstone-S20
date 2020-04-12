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
	output logic [0:35] GPIO,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX6
);
    logic clk, clk_gpio, rst_l, send_ready_ACK, send_game_lost, game_active, update_data, ack_received, ack_seqNum;
	logic [GBG_BITS-1:0] garbage;
	tile_type_t hold;
	tile_type_t piece_queue	[NEXT_PIECES_COUNT];
	tile_type_t playfield 	[PLAYFIELD_ROWS][PLAYFIELD_COLS];
	logic serial_out_h, serial_out_0, serial_out_1, serial_out_2, serial_out_3;

    logic send_done, send_done_h;

    logic sender_seqNum;

	Sender sender_inst(.*);

    ClkDivider(.clk(clk), .rst_l(rst_l), .clk_100kHz(clk_gpio));

	assign clk      = CLOCK_50;

    always_comb begin
        rst_l    = !SW[17];
        game_active = SW[16];
        garbage[3:0] = SW[3:0];
    end

    assign GPIO[10] = clk_gpio;
    assign GPIO[11] = serial_out_h;
    assign GPIO[12] = serial_out_0;
    assign GPIO[13] = serial_out_1;
    assign GPIO[14] = serial_out_2;
    assign GPIO[15] = serial_out_3;

    assign update_data = !KEY[3];
    assign send_ready_ACK = !KEY[2];
    assign send_game_lost = !KEY[1];

    always_comb begin
    	LEDR[17] = 'b0;
        LEDR[16] = game_active;
        LEDR[15:2] = 'b0;
        LEDR[1] = send_done_h;
        LEDR[0] = send_done;
    end


    BCDtoSevenSegment sevenseg6(.bcd(garbage), .seg(HEX6));

    BCDtoSevenSegment sevenSeg3(.bcd({3'b0, sender_seqNum}), .seg(HEX3));


endmodule : SenderTop