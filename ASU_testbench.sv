/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This uses the ActionStateUpdate (ASU) to display a tetromino on the
 * playfield. This tetromino can change position using KEY[3] and KEY[1] as left
 * move and right move when SW[0] is low and left rorate and right rotate when
 * SW[0] is high. KEY[2] is softdrop, KEY[0] is hard drop. You must reset the
 * board (SW[17]) to restart.
 */
`default_nettype none

/**
 * Latches and stores values of WIDTH bits and initializes to RESET_VAL.
 *
 * This register uses an asynchronous active-low reset and a synchronous
 * active-high clear. Upon clear or reset, the value of the register becomes
 * RESET_VAL.
 *
 * Parameters:
 *  - WIDTH         The number of bits that the register holds.
 *  - RESET_VAL     The value that the register holds after a reset.
 *
 * Inputs:
 *  - clk           The clock to use for the register.
 *  - rst_l         An active-low asynchronous reset.
 *  - clear         An active-high synchronous reset.
 *  - en            Indicates whether or not to load the register.
 *  - D             The input to the register.
 *
 * Outputs:
 *  - Q             The latched output from the register.
 **/
module register
   #(parameter                      WIDTH=0,
     parameter logic [WIDTH-1:0]    RESET_VAL='b0)
    (input  logic               clk, en, rst_l, clear,
     input  logic [WIDTH-1:0]   D,
     output logic [WIDTH-1:0]   Q);

     always_ff @(posedge clk, negedge rst_l) begin
         if (!rst_l)
             Q <= RESET_VAL;
         else if (clear)
             Q <= RESET_VAL;
         else if (en)
             Q <= D;
     end

endmodule:register

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
    logic           rotate_R;
    logic           rotate_L;
    logic           move_R;
    logic           move_L;

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

    logic [PLAYFIELD_COLS-1:0][ 3:0] locked_state    [PLAYFIELD_ROWS];
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


    // synchronizer chains
    always_ff @ (posedge clk) begin
        key_R_trigger_sync  <= !KEY[3];
        key_L_trigger_sync  <= !KEY[1];
        key_R_trigger       <= key_R_trigger_sync;
        key_L_trigger       <= key_L_trigger_sync;
    end

    // use rising edge triggers to detect unique inputs
    always_ff @ (posedge clk, posedge reset) begin
        if (reset) begin
            rotate_R        <= 1'b0;
            rotate_L        <= 1'b0;
            move_R          <= 1'b0;
            move_L          <= 1'b0;
        end else begin
            if (SW[0]) begin
                rotate_R    <= key_R_trigger && !rotate_R;
                rotate_L    <= key_L_trigger && !rotate_L;
            end else begin
                move_R      <= key_R_trigger && !move_R;
                move_L      <= key_L_trigger && !move_L;
            end
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
        // default to empty playfield
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            for (int j = 0; j < PLAYFIELD_COLS; j++) begin
                tile_type[i][j] = BLANK;
            end
        end
        if (SW[15]) begin
            for (int i = 0; i < 4; i++) begin
                tile_type[ftr_tile_rows[i]][ftr_tile_cols[i]] = ftr_type_gen;
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

    // generate empty locked state
    always_comb begin
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            locked_state[i] = '{PLAYFIELD_COLS{tile_type_t'(BLANK)}};
        end
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
        end else if (rotate_L) begin
            origin_row_update           = move_L_row_new;
            origin_col_update           = move_L_col_new;
            falling_orientation_update  = move_L_orientation_new;
        end
    end

    // state registers
    register #(
        .WIDTH      (5),
        .RESET_VAL  (10)
    ) origin_row_reg_inst (
        .clk    (clk),
        .en     (rotate_R || rotate_L || move_R || move_L),
        .rst_l  (!reset),
        .clear  (1'b0),
        .D      (origin_row_update),
        .Q      (origin_row)
    );
    register #(
        .WIDTH      (5),
        .RESET_VAL  (5)
    ) origin_col_reg_inst (
        .clk    (clk),
        .en     (rotate_R || rotate_L || move_R || move_L),
        .rst_l  (!reset),
        .clear  (1'b0),
        .D      (origin_col_update),
        .Q      (origin_col)
    );
    register #(
        .WIDTH      (2),
        .RESET_VAL  (0)
    ) origin_orientation_reg_inst (
        .clk    (clk),
        .en     (rotate_R || rotate_L || move_R || move_L),
        .rst_l  (!reset),
        .clear  (1'b0),
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
        .ghost_rows             (),
        .ghost_cols             ()
    );

    // FTR module
    FallingTetrominoRender ftr_inst (
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