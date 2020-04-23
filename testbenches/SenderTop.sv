/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * Top level sender testbench. Switch 17 resets, Switch 16 enables loading in
 * tetrominos, low will load in a pre-set pattern. SW[15:14] indicate tetromino
 * orientation. SW[13:10] indicates the tetromino being loaded.
 * Key 3 will send a packet. GPIO clock frequency is 100kHz. Leftmost
 * hex display is the number of garbage lines being sent,
 * middle display is the current sequence number. Switches 3-0 toggle
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

    logic [ 4:0]    ftr_tile_rows       [4];
    logic [ 4:0]    ftr_tile_cols       [4];

	Sender sender_inst (.*);

    ClkDivider clk_divider_inst (
        .clk        (clk),
        .rst_l      (rst_l),
        .clk_100kHz (clk_gpio)
    );

	assign clk          = CLOCK_50;

    DelayedAutoShiftFSM DAS_send_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (!KEY[3]),
        .action_valid   (1'b1),
        .action_out     (update_data)
    );

    always_comb begin
        rst_l           = !SW[17];
        game_active     = 1'b1;
        garbage[3:0]    = SW[3:0];
    end

    assign GPIO[0] = clk_gpio;
    assign GPIO[1] = serial_out_h;
    assign GPIO[2] = serial_out_0;
    assign GPIO[3] = serial_out_1;
    assign GPIO[4] = serial_out_2;
    assign GPIO[5] = serial_out_3;

    assign send_ready_ACK = !KEY[2];
    assign send_game_lost = !KEY[1];

    always_comb begin
    	LEDR[17] = update_data;
        LEDR[16] = game_active;
        LEDR[15:2] = 'b0;
        LEDR[1] = send_done_h;
        LEDR[0] = send_done;
    end

    HEXtoSevenSegment sevenseg6 (
        .bch    (garbage),
        .segment(HEX6)
    );
    HEXtoSevenSegment sevenSeg3 (
        .bch    ({3'b0, sender_seqNum}),
        .segment(HEX3)
    );

    // drive playfield with test values to send over network
    always_comb begin
        // default to empty playfield
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                playfield[i][j] = BLANK;
            end
        end
        if (SW[16]) begin
            for (int i = 0; i < 4; i++) begin
                playfield[ftr_tile_rows[i]][ftr_tile_cols[i]] = tile_type_t'(SW[13:10]);
            end
        end else begin
            for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
                for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                    case ((i + j) % 8)
                        0:  playfield[i][j] = BLANK;
                        1:  playfield[i][j] = I;
                        2:  playfield[i][j] = O;
                        3:  playfield[i][j] = T;
                        4:  playfield[i][j] = J;
                        5:  playfield[i][j] = L;
                        6:  playfield[i][j] = S;
                        7:  playfield[i][j] = Z;
                    endcase
                end
            end
        end
    end

    // FTR module
    FallingTetrominoRender ftr_inst (
        .origin_row             (5'd10),
        .origin_col             (5'd4),
        .falling_type           (tile_type_t'(SW[13:10])),
        .falling_orientation    (orientation_t'(SW[15:14])),
        .tile_row               (ftr_tile_rows),
        .tile_col               (ftr_tile_cols)
    );
endmodule // SenderTop