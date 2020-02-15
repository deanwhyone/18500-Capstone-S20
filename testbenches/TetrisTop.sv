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
 * KEY[2] is softdrop, KEY[0] is hard drop.
 * SW{13:10] selects which tetromino is displayed
 * SW[14] resets the tetromino to a pre-set orientation and position.
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
    logic           key_R_trigger;
    logic           key_L_trigger;
    logic           key_R_trigger_sync;
    logic           key_L_trigger_sync;

    logic           key_soft_trigger;
    logic           key_hard_trigger;
    logic           key_soft_trigger_sync;
    logic           key_hard_trigger_sync;

    logic           rotate_R;
    logic           rotate_L;
    logic           move_R;
    logic           move_L;
    logic           soft_drop;
    logic           hard_drop;

    logic           rotate_R_armed;
    logic           rotate_L_armed;
    logic           move_R_armed;
    logic           move_L_armed;
    logic           soft_drop_armed;
    logic           hard_drop_armed;

    logic           rotate_R_valid;
    logic           rotate_L_valid;
    logic           move_R_valid;
    logic           move_L_valid;
    logic           soft_drop_valid;

    logic [31:0]    rotate_R_cd;
    logic [31:0]    rotate_L_cd;
    logic [31:0]    move_R_cd;
    logic [31:0]    move_L_cd;
    logic [31:0]    soft_drop_cd;
    logic [31:0]    hard_drop_cd;

    logic [ 9:0]    VGA_row;
    logic [ 9:0]    VGA_col;
    logic           VGA_BLANK;

    tile_type_t     tile_type           [PLAYFIELD_ROWS][PLAYFIELD_COLS];

    logic [ 4:0]    origin_row;
    logic [ 4:0]    origin_row_update;
    logic [ 4:0]    origin_col;
    logic [ 4:0]    origin_col_update;

    tile_type_t     falling_type;
    logic [ 4:0]    ftr_rows            [4];
    logic [ 4:0]    ftr_cols            [4];

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

    logic           falling_piece_lock;

    // synchronizer chains
    always_ff @ (posedge clk) begin
        key_R_trigger_sync      <= !KEY[1];
        key_L_trigger_sync      <= !KEY[3];
        key_soft_trigger_sync   <= !KEY[2];
        key_hard_trigger_sync   <= !KEY[0];
        key_R_trigger           <= key_R_trigger_sync;
        key_L_trigger           <= key_L_trigger_sync;
        key_soft_trigger        <= key_soft_trigger_sync;
        key_hard_trigger        <= key_hard_trigger_sync;
    end

    // use counters to set cooldown for each input
    counter #(
        .WIDTH  (32)
    ) rotate_R_cd_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (rotate_R_cd != '0 || rotate_R),
        .load   (rotate_R_cd == 32'd10_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (rotate_R_cd)
    );
    assign rotate_R_armed = rotate_R_cd == '0 && rotate_R_valid;
    counter #(
        .WIDTH  (32)
    ) rotate_L_cd_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (rotate_L_cd != '0 || rotate_L),
        .load   (rotate_L_cd == 32'd10_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (rotate_L_cd)
    );
    assign rotate_L_armed = rotate_L_cd == '0 && rotate_L_valid;
    counter #(
        .WIDTH  (32)
    ) move_R_cd_cder (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (move_R_cd != '0 || move_R),
        .load   (move_R_cd == 32'd10_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (move_R_cd)
    );
    assign move_R_armed = move_R_cd == '0 && move_R_valid;
    counter #(
        .WIDTH  (32)
    ) move_L_cd_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (move_L_cd != '0 || move_L),
        .load   (move_L_cd == 32'd10_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (move_L_cd)
    );
    assign move_L_armed = move_L_cd == '0 && move_L_valid;
    counter #(
        .WIDTH  (32)
    ) soft_drop_cd_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (soft_drop_cd != '0 || soft_drop),
        .load   (soft_drop_cd == 32'd10_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (soft_drop_cd)
    );
    assign soft_drop_armed = soft_drop_cd == '0 && soft_drop_valid;
    counter #(
        .WIDTH  (32)
    ) hard_drop_cd_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (hard_drop_cd != '0 || hard_drop),
        .load   (hard_drop_cd == 32'd10_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (hard_drop_cd)
    );
    assign hard_drop_armed = hard_drop_cd == '0;

    // use rising edge triggers to detect unique inputs
    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            rotate_R        <= 1'b0;
            rotate_L        <= 1'b0;
            move_R          <= 1'b0;
            move_L          <= 1'b0;
            soft_drop       <= 1'b0;
            hard_drop       <= 1'b0;
        end else begin
            if (SW[0]) begin
                rotate_R    <= key_R_trigger && !rotate_R && rotate_R_armed;
                rotate_L    <= key_L_trigger && !rotate_L && rotate_L_armed;
                move_R      <= 1'b0;
                move_L      <= 1'b0;
            end else begin
                move_R      <= key_R_trigger && !move_R && move_R_armed;
                move_L      <= key_L_trigger && !move_L && move_L_armed;
                rotate_R    <= 1'b0;
                rotate_L    <= 1'b0;
            end
            soft_drop   <= key_soft_trigger && !soft_drop && soft_drop_armed;
            hard_drop   <= key_hard_trigger && !hard_drop && hard_drop_armed;
        end
    end

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
        if (soft_drop) begin
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

    // state registers
    register #(
        .WIDTH      (5),
        .RESET_VAL  (5)
    ) origin_row_reg_inst (
        .clk    (clk),
        .en     (rotate_R || rotate_L || move_R || move_L || soft_drop || hard_drop),
        .rst_l  (rst_l),
        .clear  (falling_piece_lock),
        .D      (origin_row_update),
        .Q      (origin_row)
    );
    register #(
        .WIDTH      (5),
        .RESET_VAL  (5)
    ) origin_col_reg_inst (
        .clk    (clk),
        .en     (rotate_R || rotate_L || move_R || move_L || soft_drop || hard_drop),
        .rst_l  (rst_l),
        .clear  (falling_piece_lock),
        .D      (origin_col_update),
        .Q      (origin_col)
    );
    register #(
        .WIDTH      ($bits(orientation_t)),
        .RESET_VAL  (0)
    ) origin_orientation_reg_inst (
        .clk    (clk),
        .en     (rotate_R || rotate_L || move_R || move_L || soft_drop || hard_drop),
        .rst_l  (rst_l),
        .clear  (falling_piece_lock),
        .D      (falling_orientation_update),
        .Q      (falling_orientation)
    );
    register #(
        .WIDTH      ($bits(tile_type_t))
    ) origin_type_reg_inst (
        .clk    (clk),
        .en     (new_tetromino),
        .rst_l  (rst_l),
        .clear  (1'b0),
        .D      (next_pieces_queue[0]),
        .Q      (falling_type)
    );

    // locked state
    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
                locked_state[i] <= '{PLAYFIELD_COLS{BLANK}};
            end
        end else begin
            if (falling_piece_lock) begin
                for (int i = 0; i < 4; i++) begin
                    locked_state[ftr_rows[i]][ftr_cols[i]] <= falling_type;
                end
            end
        end
    end

    // keep register of cleared lines

    // GameScreensFSM
    GameScreensFSM game_screen_fsm_inst (
        .clk                (clk),
        .rst_l              (rst_l),
        .falling_row        (origin_row),
        .falling_col        (origin_col),
        .falling_orientation(falling_orientation),
        .falling_type       (falling_type),
        .start_sprint       (soft_drop),
        .lines_cleared      (), // register local number of lines cleared
        .battle_ready       (rotate_R || move_R),
        .ready_withdraw     (rotate_L || move_L),
        .opponent_ready     (opponent_battle_ready), // receive network ready
        .opponent_lost      (opponent_game_end), // receive network top-out
        .top_out            (), // communicate local user lost to network
        .game_start         (game_start_tetris),
        .game_end           (game_end_tetris),
        .current_screen     (tetris_screen)
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
        .ftr_rows           (ftr_rows),
        .ftr_cols           (ftr_cols),
        .ghost_rows         (ghost_rows),
        .ghost_cols         (ghost_cols),
        .falling_piece_lock (falling_piece_lock),
        .new_tetromino      (new_tetromino)
    );

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
        .pieces_remove   (new_tetromino),
        .pieces_queue    (next_pieces_queue),
        .the_seven_bag   (LEDR[6:0])
    );

    GraphicsTop graphics_inst (
        .VGA_row            (VGA_row),
        .VGA_col            (VGA_col),
        .tile_type          (tile_type),
        .next_pieces_queue  (next_pieces_queue),
        .testpattern_active (SW[16]),
        .tetris_screen      (tetris_screen),
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