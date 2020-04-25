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
    //sender signals
    logic clk, clk_gpio, rst_l, send_ready_ACK, send_ready, send_game_lost, game_active, update_data, ack_received, ack_seqNum;
    logic [GBG_BITS-1:0] garbage;
    tile_type_t hold;
    tile_type_t piece_queue [NEXT_PIECES_COUNT];
    tile_type_t playfield   [PLAYFIELD_ROWS][PLAYFIELD_COLS];
    logic mosi_h, mosi_0, mosi_1, mosi_2, mosi_3;
    logic send_done, send_done_h;
    logic sender_seqNum;
    tile_type_t playfield_piece;
    logic [3:0] acks_sent_cnt;

    //fsm signals
    logic player_ready, player_unready;
    logic top_out;
    logic ingame, gamelost, gameready, gamewon, idle;
    logic win_timeout;

    //receiver signals
    logic receive_done;
    logic opponent_ready, opponent_lost;
    logic [GBG_BITS-1:0] opponent_garbage;
    tile_type_t opponent_hold;
    tile_type_t opponent_piece_queue[NEXT_PIECES_COUNT];
    tile_type_t opponent_playfield[PLAYFIELD_ROWS][PLAYFIELD_COLS];
    logic miso_h, miso_0, miso_1, miso_2, miso_3;
    logic update_opponent_data;
    logic [3:0] packets_received_cnt, acks_received_cnt;

    //posedge detector for opponent_lost
    logic opponent_lost_posedge;
    logic opponent_lost_delay;
    always_ff @(posedge clk, negedge rst_l) begin
        if(!rst_l) begin
            opponent_lost_delay <= 'b0;
        end
        else begin
            opponent_lost_delay <= opponent_lost;
        end
    end
    assign opponent_lost_posedge = opponent_lost & ~opponent_lost_delay;

    logic [31:0] win_timeout_cnt;
    //win timeout counter
    counter #(.WIDTH(32)) win_counter (
        .clk(clk_gpio),
        .rst_l(rst_l),
        .en(opponent_lost),
        .load(opponent_lost_posedge),
        .up(1'b1),
        .D(32'b0),
        .Q(win_timeout_cnt)
    );
    assign win_timeout = (win_timeout_cnt >= WIN_TIMEOUT_CYCLES);

    SenderFSM send_fsm(.clk(clk), .rst_l(rst_l), .player_ready(player_ready), 
                       .player_unready(player_unready), .top_out(top_out), 
                       .ACK_received(ack_received), .game_end(opponent_lost),
                       .send_ready(send_ready), .send_game_lost(send_game_lost),
                       .game_active(game_active), .ingame(ingame), 
                       .gamelost(gamelost), .gameready(gameready), 
                       .timeout(win_timeout), .gamewon(gamewon), .idle(idle));

    Sender sender_inst(.clk(clk), .clk_gpio(clk_gpio), .rst_l(rst_l), .send_game_lost(send_game_lost),
                    .game_active(game_active), .update_data(update_data), .garbage(garbage), .hold(hold),
                    .piece_queue(piece_queue), .playfield(playfield), .ack_received(ack_received), .ack_seqNum(1'b1), 
                    .serial_out_h(mosi_h), .serial_out_0(mosi_0), .serial_out_1(mosi_1),
                    .serial_out_2(mosi_2), .serial_out_3(mosi_3), .send_ready_ACK(send_ready || send_ready_ACK),
                    .send_done(send_done), .send_done_h(send_done_h), .sender_seqNum(sender_seqNum),
                    .acks_sent_cnt(acks_sent_cnt));

    Receiver receiver_inst(.clk(clk), .clk_gpio(clk_gpio), .rst_l(rst_l), .game_active(game_active),
                           .send_ready_ACK(send_ready_ACK), .ack_received(ack_received), 
                           .ack_seqNum(ack_seqNum), .serial_in_h(miso_h),
                           .serial_in_0(miso_0), .serial_in_1(miso_1), 
                           .serial_in_2(miso_2), .serial_in_3(miso_3),
                           .update_opponent_data(update_opponent_data), .opponent_garbage(opponent_garbage),
                           .opponent_hold(opponent_hold), .opponent_playfield(opponent_playfield),
                           .opponent_ready(opponent_ready), .opponent_lost(opponent_lost),
                           .receive_done(receive_done), .packets_received_cnt(packets_received_cnt),
                           .acks_received_cnt(acks_received_cnt));

    /*Receiver receiver_inst(.send_ready_ACK(send_ready_ACK), .ack_received(ack_received), 
                           .ack_seqNum(ack_seqNum), .serial_in_h(miso_h),
                           .serial_in_0(miso_0), .serial_in_1(miso_1), 
                           .serial_in_2(miso_2), .serial_in_3(miso_3), .*);*/

    ClkDivider clkdv(.clk(clk), .rst_l(rst_l), .clk_100kHz(clk_gpio));

    assign clk          = CLOCK_50;

    always_comb begin
        rst_l           = !SW[17];
        player_ready    = SW[16];
        //game_active     = SW[16];
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
        GPIO[20] = mosi_h;
        GPIO[2]  = mosi_0;
        GPIO[3]  = mosi_1;
        GPIO[4]  = mosi_2;
        GPIO[5]  = mosi_3;
        miso_h = GPIO[30];
        miso_0 = GPIO[7];
        miso_1 = GPIO[8];
        miso_2 = GPIO[9];
        miso_3 = GPIO[10];
    end

    /*DelayedAutoShiftFSM DAS_send_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (!KEY[3]),
        .action_valid   (1'b1),
        .action_out     (update_data)
    );*/

    assign update_data = !KEY[3];

    DelayedAutoShiftFSM DAS_send_gameover (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (!KEY[1]),
        .action_valid   (1'b1),
        .action_out     (top_out)
    );

    //assign send_ready     = !KEY[2];
    //assign send_game_lost = !KEY[1];
    //assign ack_received   = !KEY[0];

    always_comb begin
        LEDR[17] = 'b0;
        LEDR[16] = game_active;
        LEDR[15:8] = 'b0;
        LEDR[7] = idle;
        LEDR[6] = gamewon;
        LEDR[5] = gameready;
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

    BCDtoSevenSegment sevenseg5(.bcd(acks_sent_cnt), .seg(HEX5));


endmodule : MasterTop