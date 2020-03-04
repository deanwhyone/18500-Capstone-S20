/*
 * 18500 Capstone S20
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
 * SW{13:10] selects which tetromino is put in the hold area
 * SW[16] loads in the VGA testpattern when low, otherwise should run Tetris
 * SW[17] is a hard reset.
 *
 * LEDR[6:0] illuminate the state of the seven bag, each light represents a
 * different tetromino remainin the in the bag.
 */
`default_nettype none

module TetrisTop
    import  DisplayPkg::*,
            GamePkg::*;
(
    input  logic        CLOCK_50,

    input  logic [17:0] SW,
    input  logic [ 3:0] KEY,

    output logic [17:0] LEDR,
    output logic [ 7:0] VGA_R,
    output logic [ 7:0] VGA_G,
    output logic [ 7:0] VGA_B,

    output logic        VGA_CLK,
    output logic        VGA_SYNC_N,
    output logic        VGA_BLANK_N,
    output logic        VGA_HS,
    output logic        VGA_VS
);
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
    logic           auto_drop;
    logic           hold;
    logic           state_update_user;

    logic           rotate_R_valid;
    logic           rotate_L_valid;
    logic           move_R_valid;
    logic           move_L_valid;
    logic           soft_drop_valid;
    logic           hold_valid;

    logic [ 9:0]    VGA_row;
    logic [ 9:0]    VGA_col;
    logic           VGA_BLANK;

    tile_type_t     tile_type           [PLAYFIELD_ROWS][PLAYFIELD_COLS];

    logic [ 4:0]    origin_row;
    logic [ 4:0]    origin_row_update;
    logic [ 4:0]    origin_col;
    logic [ 4:0]    origin_col_update;

    logic [ 4:0]    ftr_rows            [4];
    logic [ 4:0]    ftr_cols            [4];

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

    logic [ 4:0]    ghost_rows          [4];
    logic [ 4:0]    ghost_cols          [4];

    logic [ 3:0]    locked_state        [PLAYFIELD_ROWS][PLAYFIELD_COLS];

    logic           game_start_tetris;
    logic           game_end_tetris;
    logic           opponent_game_end;
    logic           opponent_battle_ready;
    game_screens_t  tetris_screen;

    tile_type_t     next_pieces_queue   [NEXT_PIECES_COUNT];
    logic           new_tetromino;
    logic           randomizer_race;

    tile_type_t     hold_piece_type;
    logic           hold_bag_fetch;
    logic           hold_swap;

    logic           falling_piece_lock;
    logic           tspin_detected;

    logic [ 9:0]    lines_cleared;
    logic           lines_full          [PLAYFIELD_ROWS];
    logic           lines_empty         [PLAYFIELD_ROWS];

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

    // DAS modules handle input sync chain and cooldown
    DelayedAutoShiftFSM DAS_move_R_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (!SW[0] && !KEY[1]),
        .action_valid   (move_R_valid),
        .action_out     (move_R)
    );
    DelayedAutoShiftFSM DAS_move_L_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (!SW[0] && !KEY[3]),
        .action_valid   (move_L_valid),
        .action_out     (move_L)
    );
    DelayedAutoShiftFSM DAS_rotate_R_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (SW[0] && !KEY[1]),
        .action_valid   (rotate_R_valid),
        .action_out     (rotate_R)
    );
    DelayedAutoShiftFSM DAS_rotate_L_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (SW[0] && !KEY[3]),
        .action_valid   (rotate_L_valid),
        .action_out     (rotate_L)
    );
    DelayedAutoShiftFSM DAS_soft_drop_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (!KEY[2]),
        .action_valid   (soft_drop_valid),
        .action_out     (soft_drop)
    );
    DelayedAutoShiftFSM DAS_hard_drop_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (!SW[0] && !KEY[0]),
        .action_valid   (1'b1),
        .action_out     (hard_drop)
    );
    DelayedAutoShiftFSM DAS_hold_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .action_user    (SW[0] && !KEY[0]),
        .action_valid   (hold_valid),
        .action_out     (hold)
    );

    // set tile_type to drive pattern into playfield
    always_comb begin
        // default to locked state rendering into playfield
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                tile_type[i][j] = tile_type_t'(locked_state[i][j]);
            end
        end
        // then render ghost tiles (should never overlap on locked state)
        for (int i = 0; i < 4; i++) begin
            tile_type[ghost_rows[i]][ghost_cols[i]] = GHOST;
        end
        // render falling tetromino on top of ghost tiles
        for (int i = 0; i < 4; i++) begin
            tile_type[ftr_rows[i]][ftr_cols[i]]     = falling_type;
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
        .clear  (falling_piece_lock || hold),
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
        .clear  (falling_piece_lock || hold),
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
        .clear  (falling_piece_lock || hold),
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

    // LinesManager module manages lines cleared and lines sent
    LinesManager lm_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .game_start     (game_start_tetris),
        .lines_full     (lines_full),
        .lines_cleared  (lines_cleared)
    );

    // AutoDrop module handles gravity. Currently fixed
    AutoDropSource ads_inst (
        .clk            (clk),
        .rst_l          (rst_l),
        .soft_drop      (soft_drop),
        .soft_drop_valid(soft_drop_valid),
        .tetris_screen  (tetris_screen),
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
        .start_sprint       (!KEY[2]),
        .lines_cleared      (lines_cleared),
        .battle_ready       (!KEY[3]),
        .ready_withdraw     (!KEY[0]),
        .opponent_ready     (opponent_battle_ready), // receive network ready
        .opponent_lost      (opponent_game_end), // receive network top-out
        .top_out            (), // communicate local user lost to network
        .game_start         (game_start_tetris),
        .game_end           (game_end_tetris),
        .current_screen     (tetris_screen),
        .randomizer_race    (randomizer_race)
    );
    assign opponent_battle_ready    = 1'b0; // no network, opponent never ready
    assign opponent_game_end        = 1'b0; // no network, opponent never ends

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
        .new_tetromino      (new_tetromino)
    );

    // handle timer logic
    always_comb begin
        time_clk_en             = (tetris_screen == SPRINT_MODE) ||
                                  (tetris_screen == MP_MODE);
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
        .the_seven_bag   (LEDR[6:0])
    );

    // top level module for all graphics drivers
    GraphicsTop graphics_inst (
        .VGA_row            (VGA_row),
        .VGA_col            (VGA_col),
        .tile_type          (tile_type),
        .next_pieces_queue  (next_pieces_queue),
        .lines_cleared      (lines_cleared),
        .tspin_detected     (tspin_detected),
        .testpattern_active (SW[16]),
        .tetris_screen      (tetris_screen),
        .time_hours         (time_hours),
        .time_minutes       (time_minutes),
        .time_seconds       (time_seconds),
        .time_deciseconds   (time_deciseconds),
        .time_centiseconds  (time_centiseconds),
        .time_milliseconds  (time_milliseconds),
        .hold_piece_type    (hold_piece_type),
        .output_color       ({VGA_R, VGA_G, VGA_B})
    );

    // VGA module
    VGA vga_inst (
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
endmodule // TetrisTop