/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 * Master board top level testbench.
 * 
 **/

`default_nettype none

module MasterTop
    import NetworkPkg::*,
           DisplayPkg::*,
           GamePkg::*;
(
    input  logic        CLOCK_50,
    input  logic [17:0] SW,
    input  logic [3:0]  KEY,
    inout        [35:0] GPIO,
    output logic [17:0] LEDR,
    output logic [6:0]  HEX0,
    output logic [6:0]  HEX1,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX4,
    output logic [6:0]  HEX5,
    output logic [6:0]  HEX6
);
    logic clk, clk_gpio, rst_l, send_ready_ACK, send_ready, send_game_lost, game_active, update_data, ack_received, ack_seqNum;
    logic [GBG_BITS-1:0] garbage;
    tile_type_t hold;
    tile_type_t piece_queue [NEXT_PIECES_COUNT];
    tile_type_t playfield   [PLAYFIELD_ROWS][PLAYFIELD_COLS];
    logic mosi_h, mosi_0, mosi_1, mosi_2, mosi_3;
    logic send_done, send_done_h;
    logic sender_seqNum;
    tile_type_t playfield_piece;

    logic player_ready, player_unready;
    logic top_out;
    logic ingame, gamelost;

    SenderFSM send_fsm(.clk(clk), .rst_l(rst_l), .player_ready(player_ready), 
                       .player_unready(player_unready), .top_out(top_out), 
                       .ACK_received(ack_received), .game_end(opponent_lost),
                       .send_ready(send_ready), .send_game_lost(send_game_lost),
                       .game_active(game_active));

    Sender sender_inst(.serial_out_h(mosi_h), .serial_out_0(mosi_0), .serial_out_1(mosi_1),
                       .serial_out_2(mosi_2), .serial_out_3(mosi_3), .send_ready_ACK(send_ready || send_ready_ACK), .*);


    logic receive_done;
    logic opponent_ready, opponent_lost;
    logic [GBG_BITS-1:0] opponent_garbage;
    tile_type_t opponent_hold;
    tile_type_t opponent_piece_queue[NEXT_PIECES_COUNT];
    tile_type_t opponent_playfield[PLAYFIELD_ROWS][PLAYFIELD_COLS];
    logic miso_h, miso_0, miso_1, miso_2, miso_3;

    logic update_opponent_data;

    logic [3:0] packets_received_cnt, acks_received_cnt;

    Receiver receiver_inst(.send_ready_ACK(send_ready_ACK), .ack_received(ack_received), 
                           .ack_seqNum(ack_seqNum), .serial_in_h(miso_h),
                           .serial_in_0(miso_0), .serial_in_1(miso_1), 
                           .serial_in_2(miso_2), .serial_in_3(miso_3), .*);

    ClkDivider(.clk(clk), .rst_l(rst_l), .clk_100kHz(clk_gpio));

    assign clk          = CLOCK_50;

    always_comb begin
        rst_l           = !SW[17];
        player_ready    = SW[16];
        garbage[3:0]    = SW[3:0];
        playfield_piece = tile_type_t'(SW[7:4]);

        for(int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for(int j = 0; j < PLAYFIELD_COLS; j++) begin
                playfield[i][j] = playfield_piece;
            end
        end
    end

    always_comb begin
        GPIO[0]  = clk_gpio;
        GPIO[1]  = mosi_h;
        GPIO[2]  = mosi_0;
        GPIO[3]  = mosi_1;
        GPIO[4]  = mosi_2;
        GPIO[5]  = mosi_3;
        GPIO[6]  = miso_h;
        GPIO[7]  = miso_0;
        GPIO[8]  = miso_1;
        GPIO[9]  = miso_2;
        GPIO[10] = miso_3;
    end

    assign update_data    = !KEY[3];
    assign top_out        = !KEY[1];

    always_comb begin
        LEDR[17] = 'b0;
        LEDR[16] = game_active;
        LEDR[15:5] = 'b0;
        LEDR[4] = gamelost;
        LEDR[3] = ingame;
        LEDR[2] = receive_done;
        LEDR[1] = send_done_h;
        LEDR[0] = send_done;
    end


    BCDtoSevenSegment sevenseg0(.bcd(packets_received_cnt), .seg(HEX0));
    BCDtoSevenSegment sevenseg1(.bcd(acks_received_cnt), .seg(HEX1));

    BCDtoSevenSegment sevenSeg2(.bcd({3'b0, ack_seqNum}), .seg(HEX2));
    BCDtoSevenSegment sevenSeg3(.bcd({3'b0, sender_seqNum}), .seg(HEX3));
    BCDtoSevenSegment sevenseg4(.bcd(opponent_garbage), .seg(HEX4));
    BCDtoSevenSegment sevenseg6(.bcd(garbage), .seg(HEX6));


endmodule : MasterTop