/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This uses the ActionStateUpdate (ASU) to display a tetromino on the
 * playfield. This tetromino can change position, rotate, and soft drop!
 * USAGE:
 * KEY[3] and KEY[1] are left and right
 *      move when SW[0] is low
 *      rotate when SW[0] is high
 * KEY[2] is softdrop, KEY[0] is hard drop.
 * SW{13:0] selects which tetromino is displayed
 * SW[14] resets the tetromino to a pre-set orientation and position.
 * SW[17] is a hard reset.
 */
`default_nettype none

module ASU_testbench
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

    output logic VGA_CLK,
    output logic VGA_SYNC_N,
    output logic VGA_BLANK_N,
    output logic VGA_HS,
    output logic VGA_VS
);
    // abstract clk signal for uniformity
    logic   clk;
    assign  clk = CLOCK_50;

    // declare local variables
    logic           reset;
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

    logic [31:0]    rotate_R_count;
    logic [31:0]    rotate_L_count;
    logic [31:0]    move_R_count;
    logic [31:0]    move_L_count;
    logic [31:0]    soft_drop_count;
    logic [31:0]    hard_drop_count;

    logic [ 9:0]    VGA_row;
    logic [ 9:0]    VGA_col;
    logic           VGA_BLANK;

    tile_type_t     tile_type           [PLAYFIELD_ROWS][PLAYFIELD_COLS];
    logic [23:0]    ppd_output_color;
    logic           ppd_active;

    logic [ 4:0]    origin_row;
    logic [ 4:0]    origin_row_update;
    logic [ 4:0]    origin_col;
    logic [ 4:0]    origin_col_update;

    tile_type_t     ftr_type_gen;
    logic [ 4:0]    ftr_tile_rows       [4];
    logic [ 4:0]    ftr_tile_cols       [4];

    orientation_t   falling_orientation;
    orientation_t   falling_orientation_update;

    logic [ 3:0]    locked_state        [PLAYFIELD_ROWS][PLAYFIELD_COLS];
    logic [ 4:0]    rotate_R_row_new;
    logic [ 4:0]    rotate_R_col_new;
    orientation_t   rotate_R_orientation_new;
    logic [ 4:0]    rotate_L_row_new;
    logic [ 4:0]    rotate_L_col_new;
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

    // use counters to arm each input
    counter #(
        .WIDTH  (32)
    ) rotate_R_cd_counter (
        .clk    (clk),
        .rst_l  (!reset),
        .en     (rotate_R_count != '0 || rotate_R),
        .load   (rotate_R_count == 32'd8_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (rotate_R_count)
    );
    assign rotate_R_armed = rotate_R_count == '0;
    counter #(
        .WIDTH  (32)
    ) rotate_L_cd_counter (
        .clk    (clk),
        .rst_l  (!reset),
        .en     (rotate_L_count != '0 || rotate_L),
        .load   (rotate_L_count == 32'd8_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (rotate_L_count)
    );
    assign rotate_L_armed = rotate_L_count == '0;
    counter #(
        .WIDTH  (32)
    ) move_R_cd_counter (
        .clk    (clk),
        .rst_l  (!reset),
        .en     (move_R_count != '0 || move_R),
        .load   (move_R_count == 32'd8_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (move_R_count)
    );
    assign move_R_armed = move_R_count == '0;
    counter #(
        .WIDTH  (32)
    ) move_L_cd_counter (
        .clk    (clk),
        .rst_l  (!reset),
        .en     (move_L_count != '0 || move_L),
        .load   (move_L_count == 32'd8_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (move_L_count)
    );
    assign move_L_armed = move_L_count == '0;
    counter #(
        .WIDTH  (32)
    ) soft_drop_cd_counter (
        .clk    (clk),
        .rst_l  (!reset),
        .en     (soft_drop_count != '0 || soft_drop),
        .load   (soft_drop_count == 32'd8_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (soft_drop_count)
    );
    assign soft_drop_armed = soft_drop_count == '0;
    counter #(
        .WIDTH  (32)
    ) hard_drop_cd_counter (
        .clk    (clk),
        .rst_l  (!reset),
        .en     (hard_drop_count != '0 || hard_drop),
        .load   (hard_drop_count == 32'd8_000_000),
        .up     (1'b1),
        .D      ('0),
        .Q      (hard_drop_count)
    );
    assign hard_drop_armed = hard_drop_count == '0;

    // use rising edge triggers to detect unique inputs
    always_ff @ (posedge clk, posedge reset) begin
        if (reset) begin
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

    assign reset = SW[17];

    always_comb begin
        LEDR                    = 18'd0;
        {VGA_R, VGA_G, VGA_B}   = BG_COLOR;
        if (SW[16]) begin
            // prototyping the tetris game screen
            // border color
            if (VGA_row >= BORDER_VSTART && VGA_row < BORDER_VEND &&
                VGA_col >= BORDER_HSTART && VGA_col < BORDER_HEND) begin
                {VGA_R, VGA_G, VGA_B}   = BORDER_COLOR;
            end
            if (VGA_row >= PLAYFIELD_VSTART && VGA_row < PLAYFIELD_VEND &&
                VGA_col >= PLAYFIELD_HSTART && VGA_col < PLAYFIELD_HEND) begin
                {VGA_R, VGA_G, VGA_B}   = TILE_BLANK_COLOR;
            end
            // use the PPD to light up tiles in the playfield
            if (ppd_active) begin
                {VGA_R, VGA_G, VGA_B}   = ppd_output_color;
            end
        end else begin
            // default to generating test pattern
            if (VGA_row < 10'd240) begin
                if ((VGA_col < 10'd160) ||
                    (VGA_col >= 10'd320 && VGA_col < 10'd480)) begin
                    VGA_R = 8'd255;
                end

                if (VGA_col < 10'd320) begin
                    VGA_G = 8'd255;
                end

                if ((VGA_col < 10'd80) ||
                    (VGA_col >= 10'd160 && VGA_col < 10'd240) ||
                    (VGA_col >= 10'd320 && VGA_col < 10'd400) ||
                    (VGA_col >= 10'd480 && VGA_col < 10'd560)) begin
                    VGA_B = 8'd255;
                end
            end
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
        if (SW[15]) begin
            for (int i = 0; i < 4; i++) begin
                tile_type[ghost_rows[i]][ghost_cols[i]]         = GHOST;
            end
            for (int i = 0; i < 4; i++) begin
                tile_type[ftr_tile_rows[i]][ftr_tile_cols[i]]   = ftr_type_gen;
            end
        end else begin
            for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
                for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                    case ((i + j) % 8)
                        0:  tile_type[i][j] = BLANK;
                        1:  tile_type[i][j] = I;
                        2:  tile_type[i][j] = O;
                        3:  tile_type[i][j] = T;
                        4:  tile_type[i][j] = J;
                        5:  tile_type[i][j] = L;
                        6:  tile_type[i][j] = S;
                        7:  tile_type[i][j] = Z;
                    endcase
                end
            end
        end
    end

    // generate locked state
    always_comb begin
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            locked_state[i] = '{PLAYFIELD_COLS{BLANK}};
        end
        locked_state[18][2] = J;
        locked_state[19][2] = J;
        locked_state[19][3] = J;
        locked_state[19][4] = J;

        locked_state[17][7] = S;
        locked_state[17][8] = S;
        locked_state[18][6] = S;
        locked_state[18][7] = S;

        locked_state[18][8] = L;
        locked_state[19][6] = L;
        locked_state[19][7] = L;
        locked_state[19][8] = L;
    end

    // figure out which update value to use update state
    always_comb begin
        origin_row_update           = origin_row;
        origin_col_update           = origin_col;
        falling_orientation_update  = falling_orientation;
        if (rotate_R) begin
            origin_row_update           = rotate_R_row_new;
            origin_col_update           = rotate_R_col_new;
            falling_orientation_update  = rotate_R_orientation_new;
        end else if (rotate_L) begin
            origin_row_update           = rotate_L_row_new;
            origin_col_update           = rotate_L_col_new;
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
        .rst_l  (!reset),
        .clear  (SW[14]),
        .D      (origin_row_update),
        .Q      (origin_row)
    );
    register #(
        .WIDTH      (5),
        .RESET_VAL  (5)
    ) origin_col_reg_inst (
        .clk    (clk),
        .en     (rotate_R || rotate_L || move_R || move_L || soft_drop || hard_drop),
        .rst_l  (!reset),
        .clear  (SW[14]),
        .D      (origin_col_update),
        .Q      (origin_col)
    );
    register #(
        .WIDTH      (2),
        .RESET_VAL  (0)
    ) origin_orientation_reg_inst (
        .clk    (clk),
        .en     (rotate_R || rotate_L || move_R || move_L || soft_drop || hard_drop),
        .rst_l  (!reset),
        .clear  (SW[14]),
        .D      (falling_orientation_update),
        .Q      (falling_orientation)
    );

    // ASU module
    ActionStateUpdate asu_inst (
        .origin_row             (origin_row),
        .origin_col             (origin_col),
        .falling_type_in        (tile_type_t'(SW[13:10])),
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
        .falling_type_in        (tile_type_t'(SW[13:10])),
        .falling_orientation    (falling_orientation),
        .falling_type_out       (ftr_type_gen),
        .tile_row               (ftr_tile_rows),
        .tile_col               (ftr_tile_cols)
    );

    // PPD module
    PlayfieldPixelDriver ppd_inst (
        .VGA_row        (VGA_row),
        .VGA_col        (VGA_col),
        .tile_type      (tile_type),
        .output_color   (ppd_output_color),
        .active         (ppd_active)
    );

    // VGA module
    VGA vga_inst (
        .row    (VGA_row),
        .col    (VGA_col),
        .HS     (VGA_HS),
        .VS     (VGA_VS),
        .blank  (VGA_BLANK),
        .clk    (clk),
        .reset  (reset)
    );
    assign VGA_CLK      = !clk;
    assign VGA_BLANK_N  = !VGA_BLANK;
    assign VGA_SYNC_N   = 1'b0;
endmodule // ASU_testbench