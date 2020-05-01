/* 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This is the top module for Tetris: a Frame Perfect Game Adventure.
 *
 * Usage notes are largely preserved from prior HW testbenches.
 * USAGE:
 * KEY[3] and KEY[1] are left and right
 *      move when SW[0] is low
 *      rotate when SW[0] is high
 * KEY[2] is softdrop
 * KEY[0] is
 *      hard drop when SW[0] is low
 *      hold when SW[0] is high
 * SW[14] enables the frame counter in the corner
 * SW[15] loads in the VGA testpattern when high, otherwise should run Tetris
 * SW[16] enables the external controller
 * SW[17] is a hard reset.
 *
 * LEDR[6:0] illuminate the state of the seven bag, each light represents a
 * different tetromino remaining the in the bag.
 *
 * HEX6~0 displays the input latency of the most recent input
 *
 * LEDR[17] indicates a T-spin is detected
 */

`default_nettype none

module TetrisTop
    import  DisplayPkg::*,
            GamePkg::*,
            NetworkPkg::*;
(
    input  logic        CLOCK_50,

    input  logic [17:0] SW,
    input  logic [ 3:0] KEY,
    // controller GPIO pins
    inout        [35:0] GPIO,
    output logic [17:0] LEDR,
    output logic [ 6:0] HEX0,
    output logic [ 6:0] HEX1,
    output logic [ 6:0] HEX2,
    output logic [ 6:0] HEX3,
    output logic [ 6:0] HEX4,
    output logic [ 6:0] HEX5,
    output logic [ 6:0] HEX7,

    output logic [ 7:0] VGA_R,
    output logic [ 7:0] VGA_G,
    output logic [ 7:0] VGA_B,

    output logic        VGA_CLK,
    output logic        VGA_SYNC_N,
    output logic        VGA_BLANK_N,
    output logic        VGA_HS,
    output logic        VGA_VS
);
    parameter GLOBAL_INPUT_CD   = 15;
    parameter IS_MASTER         = 0;

    // abstract clk, rst_l signal for uniformity
    logic  clk, rst_l;
    assign clk      = CLOCK_50;
    assign rst_l    = !SW[17];

    // declare local variables
    logic           rotate_R;
    logic           rotate_L;
    logic           move_R;
    logic           move_L;
    logic           soft_drop;
    logic           hard_drop;
    logic           hold;

    // abstract out physical pins
    logic           rotate_R_input;
    logic           rotate_L_input;
    logic           move_R_input;
    logic           move_L_input;
    logic           soft_drop_input;
    logic           hard_drop_input;
    logic           hold_input;

    logic           auto_drop;
    logic           state_update_user;

    logic           rotate_R_valid;
    logic           rotate_L_valid;
    logic           move_R_valid;
    logic           move_L_valid;
    logic           soft_drop_valid;
    logic           hold_valid;

    logic [ 3:0]    global_cd_count;
    logic           inputs_cool;

    logic [ 9:0]    VGA_row;
    logic [ 9:0]    VGA_col;
    logic           VGA_BLANK;

    tile_type_t     playfield_data          [PLAYFIELD_ROWS][PLAYFIELD_COLS];

    logic [ 4:0]    origin_row;
    logic [ 4:0]    origin_row_update;
    logic [ 4:0]    origin_col;
    logic [ 4:0]    origin_col_update;

    logic [ 4:0]    ftr_rows                [4];
    logic [ 4:0]    ftr_cols                [4];

    tile_type_t     falling_type;
    tile_type_t     falling_type_update;
    orientation_t   falling_orientation;
    orientation_t   falling_orientation_update;

    logic [ 4:0]    rotate_R_row_new;
    logic [ 4:0]    rotate_R_col_new;
    logic [ 4:0]    rotate_R_row_nk;
    logic [ 4:0]    rotate_R_col_nk;
    orientation_t   rotate_R_orientation_new;
    logic [ 4:0]    rotate_L_row_new;
    logic [ 4:0]    rotate_L_col_new;
    logic [ 4:0]    rotate_L_row_nk;
    logic [ 4:0]    rotate_L_col_nk;
    orientation_t   rotate_L_orientation_new;
    logic [ 4:0]    move_R_row_new;
    logic [ 4:0]    move_R_col_new;
    orientation_t   move_R_orientation_new;
    logic [ 4:0]    move_L_row_new;
    logic [ 4:0]    move_L_col_new;
    orientation_t   move_L_orientation_new;
    logic [ 4:0]    soft_drop_row_new;
    logic [ 4:0]    soft_drop_col_new;
    orientation_t   soft_drop_orientation_new;
    logic [ 4:0]    hard_drop_row_new;
    logic [ 4:0]    hard_drop_col_new;
    orientation_t   hard_drop_orientation_new;

    logic [ 4:0]    ghost_rows              [4];
    logic [ 4:0]    ghost_cols              [4];

    logic [ 3:0]    locked_state            [PLAYFIELD_ROWS][PLAYFIELD_COLS];

    logic           top_out;
    logic           game_start_tetris;
    logic           game_end_tetris;
    logic           opponent_game_end;
    logic           opponent_battle_ready;
    game_screens_t  tetris_screen;
    logic           status_in_game;

    tile_type_t     next_pieces_queue       [NEXT_PIECES_COUNT];
    logic [ 3:0]    random_src;
    logic           new_tetromino;
    logic           randomizer_race;

    tile_type_t     hold_piece_type;
    logic           hold_bag_fetch;
    logic           hold_swap;

    logic           falling_piece_lock;
    logic           new_lines_valid;

    logic           tspin_detected;

    logic [ 9:0]    lines_cleared;
    logic [ 9:0]    lines_sent;
    logic [ 9:0]    lines_to_send;
    logic           lines_full              [PLAYFIELD_ROWS];
    logic           lines_empty             [PLAYFIELD_ROWS];

    logic           load_garbage;
    logic           load_garbage_pf;
    logic           network_trigger;
    logic [ 9:0]    pending_garbage;
    logic [ 9:0]    garbage_attack;
    logic [ 3:0]    garbage_line            [PLAYFIELD_COLS];

    logic           network_valid;
    logic [ 9:0]    lines_network_new;
    logic           send_ready_ACK;
    logic           ack_received;
    logic           receiver_ack_seqNum;
    logic [ 3:0]    packets_received_cnt;

    logic           clk_gpio;
    logic           mosi_h;
    logic           mosi_0;
    logic           mosi_1;
    logic           mosi_2;
    logic           mosi_3;
    logic           miso_h;
    logic           miso_0;
    logic           miso_1;
    logic           miso_2;
    logic           miso_3;

    logic           player_ready;
    logic           opponent_lost_posedge;
    logic           send_ready;
    logic           send_game_lost;
    logic           game_active;
    logic           win_timeout;
    logic [ 9:0]    win_timeout_cnt;
    logic [ 9:0]    lose_timeout_cnt;
    logic           lose_timeout;
    logic           lose_timeout_en;

    tile_type_t     network_hold;
    tile_type_t     network_pq              [NEXT_PIECES_COUNT];
    tile_type_t     network_playfield       [PLAYFIELD_ROWS][PLAYFIELD_COLS];
    tile_type_t     opponent_hold;
    tile_type_t     opponent_pq             [NEXT_PIECES_COUNT];
    tile_type_t     opponent_playfield      [PLAYFIELD_ROWS][PLAYFIELD_COLS];

    logic           network_ready;
    logic           network_lost;
    logic           opponent_ready;
    logic           opponent_lost;
    logic           opponent_lost_delay;

    logic [ 4:0]    time_hours;
    logic           time_hours_en;
    logic           time_hours_ld;
    logic [ 5:0]    time_minutes;
    logic           time_minutes_en;
    logic           time_minutes_ld;
    logic [ 5:0]    time_seconds;
    logic           time_seconds_en;
    logic           time_seconds_ld;
    logic [ 3:0]    time_deciseconds;
    logic           time_deciseconds_en;
    logic           time_deciseconds_ld;
    logic [ 3:0]    time_centiseconds;
    logic           time_centiseconds_en;
    logic           time_centiseconds_ld;
    logic [ 3:0]    time_milliseconds;
    logic           time_milliseconds_en;
    logic           time_milliseconds_ld;
    logic [15:0]    time_clk;
    logic           time_clk_en;
    logic           time_clk_ld;

    logic [23:0]    graphics_color;

    logic [ 7:0]    frame_count;
    logic           vsync_rising_edge;
    logic           VSYNC_PAST;

    // assign abstracted variables
    always_comb begin
        rotate_R_input    = (SW[0] && !KEY[1]);
        rotate_L_input    = (SW[0] && !KEY[3]);
        move_R_input      = (!SW[0] && !KEY[1]);
        move_L_input      = (!SW[0] && !KEY[3]);
        soft_drop_input   = (!KEY[2]);
        hard_drop_input   = (!SW[0] && !KEY[0]);
        hold_input        = (SW[0] && !KEY[0]);
        if (SW[16]) begin
            rotate_R_input    = rotate_R_input    || GPIO[24];
            rotate_L_input    = rotate_L_input    || GPIO[22];
            move_R_input      = move_R_input      || GPIO[35];
            move_L_input      = move_L_input      || GPIO[32];
            soft_drop_input   = soft_drop_input   || GPIO[34];
            hard_drop_input   = hard_drop_input   || GPIO[33];
            hold_input        = hold_input        || GPIO[20] || GPIO[26];
        end
    end

    // DAS modules handle input sync chain and cooldown
    DelayedAutoShiftFSM DAS_rotate_R_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (rotate_R_input),
        .action_valid   (rotate_R_valid && inputs_cool || !status_in_game),
        .action_out     (rotate_R)
    );
    DelayedAutoShiftFSM DAS_rotate_L_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (rotate_L_input),
        .action_valid   (rotate_L_valid || !status_in_game),
        .action_out     (rotate_L)
    );
    DelayedAutoShiftFSM DAS_move_R_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (move_R_input),
        .action_valid   (move_R_valid && inputs_cool || !status_in_game),
        .action_out     (move_R)
    );
    DelayedAutoShiftFSM DAS_move_L_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (move_L_input),
        .action_valid   (move_L_valid && inputs_cool || !status_in_game),
        .action_out     (move_L)
    );
    DelayedAutoShiftFSM DAS_soft_drop_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (soft_drop_input),
        .action_valid   (soft_drop_valid && inputs_cool || !status_in_game),
        .action_out     (soft_drop)
    );
    DelayedAutoShiftFSM DAS_hard_drop_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (hard_drop_input),
        .action_valid   (inputs_cool),
        .action_out     (hard_drop)
    );
    DelayedAutoShiftFSM DAS_hold_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (hold_input),
        .action_valid   (hold_valid && inputs_cool || !status_in_game),
        .action_out     (hold)
    );

    // global cd on inputs to prevent mashing
    counter #(
        .WIDTH  ($bits(global_cd_count))
    ) global_cd_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     ((global_cd_count != '0) || state_update_user),
        .load   (global_cd_count >= GLOBAL_INPUT_CD),
        .up     (1'b1),
        .D      ('0),
        .Q      (global_cd_count)
    );
    assign inputs_cool = global_cd_count == '0;

    assign status_in_game = tetris_screen == SPRINT_MODE ||
                            tetris_screen == MP_MODE;

    // set playfield_data to drive pattern into playfield
    always_comb begin
        // default to locked state rendering into playfield
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                playfield_data[i][j] = tile_type_t'(locked_state[i][j]);
            end
        end
        // then render ghost tiles (should never overlap on locked state)
        for (int i = 0; i < 4; i++) begin
            playfield_data[ghost_rows[i]][ghost_cols[i]] = GHOST;
        end
        // render falling tetromino on top of ghost tiles
        for (int i = 0; i < 4; i++) begin
            playfield_data[ftr_rows[i]][ftr_cols[i]] = falling_type;
        end
    end

    // figure out which update value to use update state
    always_comb begin
        origin_row_update               = origin_row;
        origin_col_update               = origin_col;
        falling_orientation_update      = falling_orientation;
        if (rotate_R) begin
            origin_row_update           = rotate_R_row_nk;
            origin_col_update           = rotate_R_col_nk;
            falling_orientation_update  = rotate_R_orientation_new;
        end else if (rotate_L) begin
            origin_row_update           = rotate_L_row_nk;
            origin_col_update           = rotate_L_col_nk;
            falling_orientation_update  = rotate_L_orientation_new;
        end
        if (move_R) begin
            origin_row_update           = move_R_row_new;
            origin_col_update           = move_R_col_new;
            falling_orientation_update  = move_R_orientation_new;
        end else if (move_L) begin
            origin_row_update           = move_L_row_new;
            origin_col_update           = move_L_col_new;
            falling_orientation_update  = move_L_orientation_new;
        end
        if (soft_drop || auto_drop) begin
            origin_row_update           = soft_drop_row_new;
            origin_col_update           = soft_drop_col_new;
            falling_orientation_update  = soft_drop_orientation_new;
        end
        if (hard_drop) begin
            origin_row_update           = hard_drop_row_new;
            origin_col_update           = hard_drop_col_new;
            falling_orientation_update  = hard_drop_orientation_new;
        end
    end

    assign state_update_user =  rotate_R    ||
                                rotate_L    ||
                                move_R      ||
                                move_L      ||
                                soft_drop   ||
                                hard_drop   ||
                                auto_drop;

    // state registers
    register #(
        .WIDTH      (5),
        .RESET_VAL  (0)
    ) origin_row_reg_inst (
        .clk    (clk),
        .en     (state_update_user),
        .rst_l  (rst_l),
        .clear  (game_start_tetris || falling_piece_lock || hold),
        .D      (origin_row_update),
        .Q      (origin_row)
    );
    register #(
        .WIDTH      (5),
        .RESET_VAL  (4)
    ) origin_col_reg_inst (
        .clk    (clk),
        .en     (state_update_user),
        .rst_l  (rst_l),
        .clear  (game_start_tetris || falling_piece_lock || hold),
        .D      (origin_col_update),
        .Q      (origin_col)
    );
    register #(
        .WIDTH      ($bits(orientation_t)),
        .RESET_VAL  (0)
    ) origin_orientation_reg_inst (
        .clk    (clk),
        .en     (state_update_user),
        .rst_l  (rst_l),
        .clear  (game_start_tetris || falling_piece_lock || hold),
        .D      (falling_orientation_update),
        .Q      (falling_orientation)
    );
    register #(
        .WIDTH      ($bits(tile_type_t))
    ) origin_type_reg_inst (
        .clk    (clk),
        .en     (new_tetromino || hold),
        .rst_l  (rst_l),
        .clear  (1'b0),
        .D      (falling_type_update),
        .Q      (falling_type)
    );

    always_comb begin
        falling_type_update = next_pieces_queue[0];
        if (hold_swap) begin
            falling_type_update = hold_piece_type;
        end
    end

    // locked state
    always_ff @ (posedge clk) begin
        if (game_start_tetris) begin
            for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
                locked_state[i] <= '{PLAYFIELD_COLS{BLANK}};
            end
        end else begin
            for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
                if (lines_full[i]) begin
                    locked_state[i] <= '{PLAYFIELD_COLS{BLANK}};
                end
            end
            if (lines_empty[0]) begin
                locked_state[0] <= '{PLAYFIELD_COLS{BLANK}};
            end
            for (int i = 1; i < PLAYFIELD_ROWS; i++) begin
                if (lines_empty[i]) begin
                    locked_state[i - 1] <= '{PLAYFIELD_COLS{BLANK}};
                end
            end
            for (int i = 1; i < PLAYFIELD_ROWS; i++) begin
                if (lines_empty[i]) begin
                    locked_state[i]     <= locked_state[i - 1];
                end
            end
            if (falling_piece_lock) begin
                for (int i = 0; i < 4; i++) begin
                    locked_state[ftr_rows[i]][ftr_cols[i]] <= falling_type;
                end
            end
            if (load_garbage_pf) begin
                for (int i = 0; i < PLAYFIELD_ROWS - 1; i++) begin
                    locked_state[i] <= locked_state[i + 1];
                end
                locked_state[PLAYFIELD_ROWS - 1] <= garbage_line;
            end
        end
    end

    // find which lines are "full" or "empty"
    always_comb begin
        lines_full  = '{PLAYFIELD_ROWS{1'b1}};
        lines_empty = '{PLAYFIELD_ROWS{1'b1}};
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                if (locked_state[i][j] == BLANK ||
                    locked_state[i][j] == GHOST) begin

                    lines_full[i] = 1'b0;
                end else begin
                    lines_empty[i] = 1'b0;
                end
            end
        end
    end

    // GarbageManager module computes lines to load into PF and attack garbage
    GarbageManager gm_inst (
        .clk                (clk),
        .rst_l              (rst_l),
        .game_start         (game_start_tetris),
        .load_garbage       (load_garbage),
        .network_valid      (network_valid),
        .lines_network_new  (lines_network_new),
        .valid_local        (new_lines_valid),
        .lines_local_new    (lines_to_send),
        .lines_to_pf        (pending_garbage),
        .lines_to_lan       (garbage_attack),
        .lines_send         (network_trigger),
        .lines_load         (load_garbage_pf)
    );
    // generate garbage line
    always_comb begin
        garbage_line = '{10{GARBAGE}};
        garbage_line[random_src%10] = BLANK;
    end

    // LinesManager module manages lines cleared and lines sent
    LinesManager lm_inst (
        .clk                (clk),
        .rst_l              (rst_l),
        .game_start         (game_start_tetris),
        .falling_piece_lock (falling_piece_lock),
        .tspin_detected     (tspin_detected),
        .lines_full         (lines_full),
        .lines_cleared      (lines_cleared),
        .lines_sent         (lines_sent),
        .lines_to_send      (lines_to_send),
        .new_lines_valid    (new_lines_valid),
        .combo_count        ()
    );

    // AutoDrop module handles gravity. Currently fixed
    AutoDropSource ads_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .soft_drop      (soft_drop),
        .soft_drop_valid(soft_drop_valid),
        .tetris_screen  (tetris_screen),
        .lines_cleared  (lines_cleared),
        .auto_drop      (auto_drop)
    );

    // HoldPieceHandler registers the hold piece
    HoldPieceHandler hph_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .hold_input     (hold),
        .game_start     (game_start_tetris),
        .new_tetromino  (new_tetromino),
        .falling_type   (falling_type),
        .hold_valid     (hold_valid),
        .bag_fetch      (hold_bag_fetch),
        .hold_swap      (hold_swap),
        .hold_piece_type(hold_piece_type)
    );

    // GameScreensFSM
    GameScreensFSM game_screen_fsm_inst (
        .clk                (clk),
        .rst_l              (rst_l),
        .falling_row        (origin_row),
        .falling_col        (origin_col),
        .falling_orientation(falling_orientation),
        .falling_type       (falling_type),
        .falling_piece_lock (falling_piece_lock),
        .start_sprint       (soft_drop),
        .lines_cleared      (lines_cleared),
        .battle_ready       (move_L || rotate_L),
        .ready_withdraw     (move_R || rotate_R),
        .opponent_ready     (opponent_ready), // receive network ready
        .opponent_lost      (opponent_lost), // receive network top-out
        .top_out            (top_out), // communicate local user lost to network
        .game_start         (game_start_tetris),
        .game_end           (game_end_tetris),
        .current_screen     (tetris_screen),
        .randomizer_race    (randomizer_race)
    );

    // GameStatesFSM
    GameStatesFSM game_states_fsm_inst (
        .clk                (clk),
        .rst_l              (rst_l),
        .game_start         (game_start_tetris),
        .game_end           (game_end_tetris),
        .user_input         (rotate_R || rotate_L || move_R || move_L),
        .hard_drop          (hard_drop),
        .falling_row        (origin_row),
        .falling_col        (origin_col),
        .ghost_row          (hard_drop_row_new),
        .ghost_col          (hard_drop_col_new),
        .falling_piece_lock (falling_piece_lock),
        .load_garbage       (load_garbage),
        .new_tetromino      (new_tetromino)
    );

    // handle timer logic
    always_comb begin
        time_clk_en             = status_in_game; // SPRINT_MODE or MP_MODE
        time_clk_ld             = time_clk == 16'd50_000;

        time_milliseconds_en    = time_clk_ld;
        time_milliseconds_ld    = (time_milliseconds == 4'd9) &&
                                  time_milliseconds_en;

        time_centiseconds_en    = time_milliseconds_ld;
        time_centiseconds_ld    = (time_centiseconds == 4'd9) &&
                                  time_centiseconds_en;

        time_deciseconds_en     = time_centiseconds_ld;
        time_deciseconds_ld     = (time_deciseconds == 4'd9) &&
                                  time_deciseconds_en;

        time_seconds_en         = time_deciseconds_ld;
        time_seconds_ld         = (time_seconds == 6'd59) &&
                                  time_seconds_en;

        time_minutes_en         = time_seconds_ld;
        time_minutes_ld         = (time_minutes == 6'd59) &&
                                  time_minutes_en;

        time_hours_en           = time_minutes_ld;
        time_hours_ld           = 1'b0; // I really hope it never runs this long

        if (game_start_tetris) begin
            {time_clk_ld,
             time_milliseconds_ld,
             time_centiseconds_ld,
             time_deciseconds_ld,
             time_seconds_ld,
             time_minutes_ld,
             time_hours_ld        } = '1;
        end
    end

    // time tracking counters
    counter #(
        .WIDTH      ($bits(time_hours))
    ) time_hours_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (time_hours_en),
        .load   (time_hours_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (time_hours)
    );
    counter #(
        .WIDTH      ($bits(time_minutes))
    ) time_minutes_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (time_minutes_en),
        .load   (time_minutes_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (time_minutes)
    );
    counter #(
        .WIDTH      ($bits(time_seconds))
    ) time_seconds_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (time_seconds_en),
        .load   (time_seconds_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (time_seconds)
    );
    counter #(
        .WIDTH      ($bits(time_deciseconds))
    ) time_deciseconds_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (time_deciseconds_en),
        .load   (time_deciseconds_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (time_deciseconds)
    );
    counter #(
        .WIDTH      ($bits(time_centiseconds))
    ) time_centiseconds_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (time_centiseconds_en),
        .load   (time_centiseconds_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (time_centiseconds)
    );
    counter #(
        .WIDTH      ($bits(time_milliseconds))
    ) time_milliseconds_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (time_milliseconds_en),
        .load   (time_milliseconds_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (time_milliseconds)
    );
    counter #(
        .WIDTH      ($bits(time_clk))
    ) time_clk_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (time_clk_en),
        .load   (time_clk_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (time_clk)
    );

    // TSD module
    TSpinDetector tsd_inst (
        .clk                (clk),
        .rst_l              (rst_l),
        .origin_row         (origin_row),
        .origin_col         (origin_col),
        .falling_type       (falling_type),
        .falling_orientation(falling_orientation),
        .locked_state       (locked_state),
        .rotate_R           (rotate_R),
        .rotate_L           (rotate_L),
        .move_R             (move_R),
        .move_L             (move_L),
        .move_R_valid       (move_R_valid),
        .move_L_valid       (move_L_valid),
        .falling_piece_lock (falling_piece_lock),
        .tspin_detected     (tspin_detected)
    );
    assign LEDR[17] = tspin_detected;

    // SUV module
    NextStateValid nsv_inst (
        .clk                    (clk),
        .rst_l                  (rst_l),
        .falling_type           (falling_type),
        .rotate_R_row           (rotate_R_row_new),
        .rotate_R_col           (rotate_R_col_new),
        .rotate_R_orientation   (rotate_R_orientation_new),
        .rotate_L_row           (rotate_L_row_new),
        .rotate_L_col           (rotate_L_col_new),
        .rotate_L_orientation   (rotate_L_orientation_new),
        .move_R_row             (move_R_row_new),
        .move_R_col             (move_R_col_new),
        .move_R_orientation     (move_R_orientation_new),
        .move_L_row             (move_L_row_new),
        .move_L_col             (move_L_col_new),
        .move_L_orientation     (move_L_orientation_new),
        .soft_drop_row          (soft_drop_row_new),
        .soft_drop_col          (soft_drop_col_new),
        .soft_drop_orientation  (soft_drop_orientation_new),
        .locked_state           (locked_state),
        .rotate_R_valid         (rotate_R_valid),
        .rotate_R_row_kick      (rotate_R_row_nk),
        .rotate_R_col_kick      (rotate_R_col_nk),
        .rotate_L_valid         (rotate_L_valid),
        .rotate_L_row_kick      (rotate_L_row_nk),
        .rotate_L_col_kick      (rotate_L_col_nk),
        .move_R_valid           (move_R_valid),
        .move_L_valid           (move_L_valid),
        .soft_drop_valid        (soft_drop_valid)
    );

    // ASU module
    ActionStateUpdate asu_inst (
        .clk                    (clk),
        .origin_row             (origin_row),
        .origin_col             (origin_col),
        .falling_type           (falling_type),
        .falling_orientation    (falling_orientation),
        .locked_state           (locked_state),
        .rotate_R_row           (rotate_R_row_new),
        .rotate_R_col           (rotate_R_col_new),
        .rotate_R_orientation   (rotate_R_orientation_new),
        .rotate_L_row           (rotate_L_row_new),
        .rotate_L_col           (rotate_L_col_new),
        .rotate_L_orientation   (rotate_L_orientation_new),
        .move_R_row             (move_R_row_new),
        .move_R_col             (move_R_col_new),
        .move_R_orientation     (move_R_orientation_new),
        .move_L_row             (move_L_row_new),
        .move_L_col             (move_L_col_new),
        .move_L_orientation     (move_L_orientation_new),
        .soft_drop_row          (soft_drop_row_new),
        .soft_drop_col          (soft_drop_col_new),
        .soft_drop_orientation  (soft_drop_orientation_new),
        .hard_drop_row          (hard_drop_row_new),
        .hard_drop_col          (hard_drop_col_new),
        .hard_drop_orientation  (hard_drop_orientation_new),
        .ghost_rows             (ghost_rows),
        .ghost_cols             (ghost_cols)
    );

    // FTR module
    FallingTetrominoRender ftr_active_inst (
        .origin_row             (origin_row),
        .origin_col             (origin_col),
        .falling_type           (falling_type),
        .falling_orientation    (falling_orientation),
        .tile_row               (ftr_rows),
        .tile_col               (ftr_cols)
    );

    // Seven Bag module
    TheSevenBag seven_bag_inst (
        .clk             (clk),
        .rst_l           (rst_l),
        .pieces_remove   (randomizer_race || new_tetromino || hold_bag_fetch),
        .pieces_queue    (next_pieces_queue),
        .the_seven_bag   (LEDR[6:0]),
        .random_src      (random_src)
    );

    // top level module for all graphics drivers
    GraphicsTop graphics_inst (
        .clk                (clk),
        .VGA_row            (VGA_row),
        .VGA_col            (VGA_col),
        .playfield_data     (playfield_data),
        .next_pieces_queue  (next_pieces_queue),
        .lines_cleared      (lines_cleared),
        .lines_sent         (lines_sent),
        .tspin_detected     (tspin_detected),
        .testpattern_active (SW[15]),
        .tetris_screen      (tetris_screen),
        .time_hours         (time_hours),
        .time_minutes       (time_minutes),
        .time_seconds       (time_seconds),
        .time_deciseconds   (time_deciseconds),
        .time_centiseconds  (time_centiseconds),
        .time_milliseconds  (time_milliseconds),
        .hold_piece_type    (hold_piece_type),
        .pending_garbage    (pending_garbage),
        .opponent_playfield (opponent_playfield),
        .opponent_pq        (opponent_pq),
        .opponent_hold      (opponent_hold),
        .frames_en          (SW[14]),
        .frame_count        (frame_count),
        .output_color       (graphics_color)
    );
    // enable simple switching b/w 8-bit and 4-bit color
    always_comb begin
        VGA_R = graphics_color[23:16];
        VGA_G = graphics_color[15: 8];
        VGA_B = graphics_color[ 7: 0];
    end

    // 8-bit frame counter
    counter #(
        .WIDTH      ($bits(frame_count))
    ) frame_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (vsync_rising_edge),
        .load   (1'b0),
        .up     (1'b1),
        .D      ('0),
        .Q      (frame_count)
    );
    always_ff @ (posedge clk) begin
        VSYNC_PAST <= VGA_VS;
    end
    assign vsync_rising_edge = !VSYNC_PAST && VGA_VS;

    // VGA module
    SVGA svga_inst (
        .row    (VGA_row),
        .col    (VGA_col),
        .HS     (VGA_HS),
        .VS     (VGA_VS),
        .blank  (VGA_BLANK),
        .clk    (clk),
        .reset  (!rst_l)
    );
    assign VGA_CLK      = !clk;
    assign VGA_BLANK_N  = !VGA_BLANK;
    assign VGA_SYNC_N   = 1'b0;

    // metrics module
    // handles couters for tracking delays from input to latching onto VGA pins
    MetricsHandler metrics_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .state_update   (state_update_user),
        .VSYNC_REDGE    (vsync_rising_edge),
        .HEX0           (HEX0),
        .HEX1           (HEX1),
        .HEX2           (HEX2),
        .HEX3           (HEX3),
        .HEX4           (HEX4),
        .HEX5           (HEX5)
    );

    // music module
    // integrating with Alton's branch
    music music_inst (
        .clk        (clk),
        .rst_l      (rst_l),
        .GPIO_29    (GPIO[29]),
        .GPIO_27    (GPIO[27]),
        .GPIO_25    (GPIO[25]),
        .GPIO_23    (GPIO[23]),
        .GPIO_21    (GPIO[21]),
        .GPIO_19    (GPIO[19]),
        .GPIO_17    (GPIO[17]),
        .GPIO_15    (GPIO[15])
    );

    // networking
    // integrating with Eric's branch
    // senderFSM controls both sender and receiver on both master/slave
    SenderFSM send_fsm_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .player_ready   (player_ready),
        .player_unready (!player_ready),
        .top_out        (top_out),
        .ACK_received   (ack_received),
        .game_end       (opponent_lost),
        .send_ready     (send_ready),
        .send_game_lost (send_game_lost),
        .game_active    (game_active),
        .ingame         (),
        .gamelost       (),
        .gameready      (),
        .timeout        (win_timeout),
        .lose_timeout   (lose_timeout),
        .lose_timeout_en(lose_timeout_en)
    );

    assign player_ready =   (tetris_screen == MP_READY) ||
                            (tetris_screen == MP_MODE);

    // win timeout counter, handles crosstalk on the lost signal over GPIO
    counter #(
        .WIDTH($bits(win_timeout_cnt))
    ) win_counter (
        .clk    (clk_gpio),
        .rst_l  (rst_l),
        .en     (opponent_lost),
        .load   (opponent_lost_posedge),
        .up     (1'b1),
        .D      ('0),
        .Q      (win_timeout_cnt)
    );
    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            opponent_lost_delay <= 1'b0;
        end else begin
            opponent_lost_delay <= opponent_lost;
        end
    end
    assign opponent_lost_posedge    = opponent_lost && !opponent_lost_delay;
    assign win_timeout              = win_timeout_cnt >= WIN_TIMEOUT_CYCLES;

    // lose timeout counter
    counter #(
        .WIDTH($bits(lose_timeout_cnt))
    ) lose_counter (
        .clk    (clk_gpio),
        .rst_l  (rst_l),
        .en     (lose_timeout_en),
        .load   (!lose_timeout_en),
        .up     (1'b1),
        .D      (32'b0),
        .Q      (lose_timeout_cnt)
    );
    assign lose_timeout             = lose_timeout_cnt >= LOSE_TIMEOUT_CYCLES;

    generate
        if (IS_MASTER) begin
            ClkDivider clk_gen_gpio_inst (
                .clk        (clk),
                .rst_l      (rst_l),
                .clk_100kHz (clk_gpio)
            );

            assign GPIO[0]  = clk_gpio;

            Receiver receiver_inst (
                .clk                    (clk),
                .rst_l                  (rst_l),
                .clk_gpio               (clk_gpio),
                .game_active            (game_active),
                .serial_in_h            (miso_h),
                .serial_in_0            (miso_0),
                .serial_in_1            (miso_1),
                .serial_in_2            (miso_2),
                .serial_in_3            (miso_3),
                .send_ready_ACK         (send_ready_ACK),
                .ack_received           (ack_received),
                .ack_seqNum             (receiver_ack_seqNum),
                .update_opponent_data   (network_valid),
                .opponent_garbage       (lines_network_new),
                .opponent_hold          (network_hold),
                .opponent_piece_queue   (network_pq),
                .opponent_playfield     (network_playfield),
                .opponent_ready         (network_ready),
                .opponent_lost          (network_lost),
                .receive_done           (),
                .packets_received_cnt   (packets_received_cnt),
                .init_seqNum            (1'b0)
            );

            assign miso_h   = GPIO[6];
            assign miso_0   = GPIO[7];
            assign miso_1   = GPIO[8];
            assign miso_2   = GPIO[9];
            assign miso_3   = GPIO[10];

            Sender sender_inst (
                .clk                    (clk),
                .clk_gpio               (clk_gpio),
                .rst_l                  (rst_l),
                .send_game_lost         (send_game_lost),
                .game_active            (game_active),
                .update_data            (network_trigger),
                .garbage                (garbage_attack),
                .hold                   (hold_piece_type),
                .piece_queue            (next_pieces_queue),
                .playfield              (playfield_data),
                .ack_received           (ack_received),
                .ack_seqNum             (1'b1),
                .serial_out_h           (mosi_h),
                .serial_out_0           (mosi_0),
                .serial_out_1           (mosi_1),
                .serial_out_2           (mosi_2),
                .serial_out_3           (mosi_3),
                .send_ready_ACK         (send_ready || send_ready_ACK),
                .send_done              (),
                .send_done_h            (),
                .sender_seqNum          (),
                .init_seqNum            (1'b0)
            );

            assign GPIO[1]  = mosi_h;
            assign GPIO[2]  = mosi_0;
            assign GPIO[3]  = mosi_1;
            assign GPIO[4]  = mosi_2;
            assign GPIO[5]  = mosi_3;

        end else begin
            assign clk_gpio = GPIO[0];

            Receiver receiver_inst (
                .clk                    (clk),
                .rst_l                  (rst_l),
                .clk_gpio               (clk_gpio),
                .game_active            (game_active),
                .serial_in_h            (mosi_h),
                .serial_in_0            (mosi_0),
                .serial_in_1            (mosi_1),
                .serial_in_2            (mosi_2),
                .serial_in_3            (mosi_3),
                .send_ready_ACK         (send_ready_ACK),
                .ack_received           (ack_received),
                .ack_seqNum             (receiver_ack_seqNum),
                .update_opponent_data   (network_valid),
                .opponent_garbage       (lines_network_new),
                .opponent_hold          (network_hold),
                .opponent_piece_queue   (network_pq),
                .opponent_playfield     (network_playfield),
                .opponent_ready         (network_ready),
                .opponent_lost          (network_lost),
                .receive_done           (),
                .packets_received_cnt   (packets_received_cnt),
                .init_seqNum            (1'b0)
            );

            assign mosi_h   = GPIO[1];
            assign mosi_0   = GPIO[2];
            assign mosi_1   = GPIO[3];
            assign mosi_2   = GPIO[4];
            assign mosi_3   = GPIO[5];

            Sender sender_inst (
                .clk                    (clk),
                .clk_gpio               (clk_gpio),
                .rst_l                  (rst_l),
                .send_game_lost         (send_game_lost),
                .game_active            (game_active),
                .update_data            (network_trigger),
                .garbage                (garbage_attack),
                .hold                   (hold_piece_type),
                .piece_queue            (next_pieces_queue),
                .playfield              (playfield_data),
                .ack_received           (ack_received),
                .ack_seqNum             (1'b1),
                .serial_out_h           (miso_h),
                .serial_out_0           (miso_0),
                .serial_out_1           (miso_1),
                .serial_out_2           (miso_2),
                .serial_out_3           (miso_3),
                .send_ready_ACK         (send_ready || send_ready_ACK),
                .send_done              (),
                .send_done_h            (),
                .sender_seqNum          (),
                .init_seqNum            (1'b0)
            );

            assign GPIO[6]  = miso_h;
            assign GPIO[7]  = miso_0;
            assign GPIO[8]  = miso_1;
            assign GPIO[9]  = miso_2;
            assign GPIO[10] = miso_3;
        end
    endgenerate

    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            opponent_ready      <= 1'b0;
            opponent_hold       <= BLANK;
            opponent_pq         <= '{NEXT_PIECES_COUNT{tile_type_t'(BLANK)}};
            opponent_playfield  <= '{20{'{10{tile_type_t'(BLANK)}}}};
            opponent_lost       <= 1'b0;
        end else begin
            opponent_ready              <= network_ready;
            opponent_lost               <= network_lost;
            if (tetris_screen != MP_MODE) begin
                opponent_hold           <= BLANK;
                opponent_pq             <= '{NEXT_PIECES_COUNT{
                                            tile_type_t'(BLANK)}};
                opponent_playfield      <= '{20{'{10{tile_type_t'(BLANK)}}}};
            end
            if (network_valid) begin
                opponent_hold           <= network_hold;
                opponent_pq             <= network_pq;
                opponent_playfield      <= network_playfield;
            end
        end
    end

    // for debugging
    SevenSegmentDigit seqnum_display_inst (
        .bch(packets_received_cnt),
        .segment(HEX7),
        .blank(1'b0)
    );
endmodule // TetrisTop