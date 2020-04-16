/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 * Top level sender testbench. Switch 17 resets, switch 16 
 * must be kept high for the game to be active. Key 3 will 
 * send a packet. GPIO clock frequency is 100kHz. Leftmost
 * hex display is the number of garbage lines being sent, 
 * middle display is the current sequence number. Switches
 * 7-4 toggle the piece filling the playfield, 3-0 toggle 
 * the number of garbage lines to send.
 * 
 **/

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

    tile_type_t playfield_piece;

	Sender sender_inst(.*);

    ClkDivider(.clk(clk), .rst_l(rst_l), .clk_100kHz(clk_gpio));

	assign clk          = CLOCK_50;

    always_comb begin
        rst_l           = !SW[17];
        game_active     = SW[16];
        garbage[3:0]    = SW[3:0];
        playfield_piece = tile_type_t'(SW[7:4]);

        for(int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for(int j = 0; j < PLAYFIELD_COLS; j++) begin
                playfield[i][j] = playfield_piece;
            end
        end
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