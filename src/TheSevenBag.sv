/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module implements the Seven Bag, the randomness scheme used to generate
 * next pieces in Tetris, as specified in the Tetris Guideline. Our PRNG
 * is based on a set of 31-bit LFSR to generate next state bits. Invalid
 * outputs are ignored.
 *
 * pieces_queue is organized as a shift queue with 0 index being the front of
 * the queue.
 */
`default_nettype none

module TheSevenBag
    import DisplayPkg::*,
           GamePkg::*;
(
    input  logic        clk,
    input  logic        rst_l,
    input  logic        pieces_remove,
    output tile_type_t  pieces_queue    [NEXT_PIECES_COUNT],
    output logic [ 6:0] the_seven_bag
);
    logic [$bits(tile_type_t) - 1:0]    pieces_intf     [NEXT_PIECES_COUNT];
    logic [$bits(tile_type_t) - 1:0]    piece_generate;
    logic                               piece_generate_valid;
    logic                               pieces_reg_en   [NEXT_PIECES_COUNT - 1];
    logic                               pieces_enq;
    // logic [ 6:0]                        the_seven_bag;
    logic [ 6:0]                        the_seven_bag_next;

    // the seven bag is constructed of a packed 7-bit register
    // 1 indicates that a piece is still in the bag
    // 0 indicates that a piece has been removed from the bag
    always @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            the_seven_bag <= '1;
        end else begin
            the_seven_bag <= the_seven_bag_next;
        end
    end

    always_comb begin
        the_seven_bag_next = the_seven_bag;
        if (pieces_enq && piece_generate_valid) begin
            unique case (tile_type_t'(piece_generate))
                I:          the_seven_bag_next[0]   = 1'b0;
                O:          the_seven_bag_next[1]   = 1'b0;
                T:          the_seven_bag_next[2]   = 1'b0;
                J:          the_seven_bag_next[3]   = 1'b0;
                L:          the_seven_bag_next[4]   = 1'b0;
                S:          the_seven_bag_next[5]   = 1'b0;
                Z:          the_seven_bag_next[6]   = 1'b0;
            endcase
        end
        // empty bag should never occur, bag refills instantly when empty
        if (the_seven_bag_next == 7'd0) begin
            the_seven_bag_next = '1;
        end
    end

    // construct a queue of next pieces that are filled by the seven bag
    genvar g;
    generate
        for (g = 0; g < NEXT_PIECES_COUNT - 1; g++) begin : SHIFT_QUEUE_G
            register #(
                .WIDTH      ($bits(tile_type_t)),
                .RESET_VAL  (BLANK)
            ) pieces_queue_reg (
                .clk        (clk),
                .rst_l      (rst_l),
                .en         (pieces_reg_en[g]),
                .clear      (1'b0),
                .D          (pieces_queue[g + 1]),
                .Q          (pieces_intf[g])
            );
        end
    endgenerate

    // last index of the shift queue is separately instantiated to take
    // generated input. Also enabled to when directed to enq from LFSRs
    register #(
        .WIDTH      ($bits(tile_type_t)),
        .RESET_VAL  (BLANK)
    ) pieces_queue_reg_new (
        .clk        (clk),
        .rst_l      (rst_l),
        .en         (pieces_enq),
        .clear      (1'b0),
        .D          ((piece_generate_valid) ? piece_generate : BLANK),
        .Q          (pieces_intf[NEXT_PIECES_COUNT - 1])
    );

    // enable lines need to be connected. If index 0 is enabled, all ensuing
    // registers need also be enabled
    always_comb begin
        pieces_reg_en[0] = pieces_remove || (pieces_queue[0] == BLANK);
        for (int i = 1; i < NEXT_PIECES_COUNT - 1; i++) begin
            pieces_reg_en[i] = (pieces_queue[i] == BLANK) ||
                               pieces_reg_en[i - 1];
        end
        // enq when last register in the shift queue is BLANK or need to pass
        // along whatever its current contents are
        pieces_enq = (pieces_queue[NEXT_PIECES_COUNT - 1] == BLANK) ||
                     pieces_reg_en[NEXT_PIECES_COUNT - 2];
    end

    // translation logic. Cannot connect tile_type_t nets to logic ports so we
    // drive the nets with logic types driven by the register outputs
    always_comb begin
        for (int i = 0; i < NEXT_PIECES_COUNT; i++) begin
            pieces_queue[i] = tile_type_t'(pieces_intf[i]);
        end
    end

    // valid pieces are tetrominos and that tetromino is in the seven bag
    always_comb begin
        piece_generate_valid = 1'b0;
        if (((tile_type_t'(piece_generate) == I) && the_seven_bag[0]) ||
            ((tile_type_t'(piece_generate) == O) && the_seven_bag[1]) ||
            ((tile_type_t'(piece_generate) == T) && the_seven_bag[2]) ||
            ((tile_type_t'(piece_generate) == J) && the_seven_bag[3]) ||
            ((tile_type_t'(piece_generate) == L) && the_seven_bag[4]) ||
            ((tile_type_t'(piece_generate) == S) && the_seven_bag[5]) ||
            ((tile_type_t'(piece_generate) == Z) && the_seven_bag[6])) begin

            piece_generate_valid = 1'b1;
        end
    end

    // generate 4 LFSRs to drive each bit of the generated tile_type_t net
    generate
        for (g = 0; g < $bits(tile_type_t); g++) begin : LFSR_G
            LFSR31 #(
                .SEED       (SEEDS[g])
            ) tetromino_random_generator (
                .clk        (clk),
                .rst_l      (rst_l),
                .output_bit (piece_generate[g])
            );
        end
    endgenerate
endmodule // TheSevenBag