/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This FSM handles the in-game states of Tetris. It handles piece locks and
 * removes a piece from the queue after a piece lock. The coordinates provided
 * are used to determine if the falling tetromino is touching the "ground".
 *
 * Default lockout is either 10 or 15, depending on the implementation of the
 * game. Various TTC games match either one or the other. We'll use 15.
 */
`default_nettype none

module GameStatesFSM
    import GamePkg::*;
(
    input  logic        clk,
    input  logic        rst_l,
    input  logic        game_start,
    input  logic        game_end,
    input  logic        user_input,
    input  logic        hard_drop,
    input  logic [ 4:0] falling_row,
    input  logic [ 4:0] falling_col,
    input  logic [ 4:0] ghost_row,
    input  logic [ 4:0] ghost_col,
    output logic        falling_piece_lock,
    output logic        load_garbage,
    output logic        new_tetromino
);
    game_states_t   state;
    game_states_t   next_state;

    logic [31:0]    piece_lock_countdown;
    logic           lock_counter_en;
    logic           lock_counter_ld;

    logic [ 3:0]    match_mask;
    logic [ 3:0]    lock_reset_count;

    logic           stable_piece;

    logic [ 4:0]    garbage_tick;
    logic           garbage_tick_ld;

    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // next_state logic
    always_comb begin
        next_state = state;
        unique case (state)
            IDLE: begin
                if (game_start) begin
                    next_state = NEW_PIECE;
                end
            end
            NEW_PIECE: begin
                next_state = PIECE_FALLING;
            end
            PIECE_FALLING: begin
                if (stable_piece || hard_drop) begin
                    next_state = PIECE_LOCK;
                end
            end
            PIECE_LOCK: begin
                next_state = LOAD_GARBAGE;
            end
            LOAD_GARBAGE: begin
                next_state = LOAD_GARBAGE;
                if (garbage_tick == 5'd16) begin
                    next_state = NEW_PIECE;
                end
            end
        endcase
        if (game_end) next_state = IDLE;
    end

    // output logic
    always_comb begin
        if (state == PIECE_LOCK)    falling_piece_lock = 1'b1;
        else                        falling_piece_lock = 1'b0;

        if (state == NEW_PIECE) new_tetromino = 1'b1;
        else                    new_tetromino = 1'b0;

        if (state == LOAD_GARBAGE) begin
            load_garbage    = 1'b1;
            garbage_tick_ld = 1'b0;
        end else begin
            load_garbage    = 1'b0;
            garbage_tick_ld = 1'b1;
        end
    end

    // lock_counter should be enabled when falling tile is on the ground
    always_comb begin
        lock_counter_en =   (state == PIECE_FALLING) &&
                            (falling_row == ghost_row) &&
                            (falling_col == ghost_col);
    end

    // lock_counter should load when in NEW_PIECE state (1 cycle) and
    //                          when interrupted by user input
    always_comb begin
        lock_counter_ld = (state == NEW_PIECE) ||
                          (lock_counter_en && user_input &&
                           lock_reset_count < 15);
    end

    // if lock_counter hits zero, piece is stable
    assign stable_piece = piece_lock_countdown == '0;

    counter #(
        .WIDTH  ($bits(piece_lock_countdown))
    ) lock_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (lock_counter_en),
        .load   (lock_counter_ld),
        .up     (1'b0),
        .D      (LOCK_DELAY),
        .Q      (piece_lock_countdown)
    );
    counter #(
        .WIDTH  ($bits(lock_reset_count))
    ) lock_reset_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (lock_counter_ld),
        .load   (state == NEW_PIECE),
        .up     (1'b1),
        .D      ('0),
        .Q      (lock_reset_count)
    );

    counter #(
        .WIDTH  ($bits(garbage_tick))
    ) garbage_tick_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (state == LOAD_GARBAGE),
        .load   (garbage_tick_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (garbage_tick)
    );
endmodule // GameStatesFSM