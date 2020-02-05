/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module tests a LFSR. Here particularly it is to be tested against the
 * 31-bit maximal LFSR, developed for our Tetris implementation.
 */
`default_nettype none

module LFSR_testbench;
    logic           clk;
    logic           rst_l;
    logic [2:0]     tetromino_select;
    logic           random_output_valid;

    int             tetromino_counter[7];
    logic           counter_enable;

    localparam logic [30:0] SEED [3] = '{31'h5eed_cafe,
                                         31'h0b57_ac1e,
                                         31'h0dec_0de5};

    // clk generator
    initial begin
        clk     = 1'b0;
        rst_l   = 1'b0;
        rst_l   <= 1'b1;
        forever #5 clk = !clk;
    end

    initial begin
        counter_enable = 1'b0;
        repeat (18500) @ (posedge clk);
        counter_enable <= 1'b1;
        repeat (1000000) @ (posedge clk);
        $display({"RNG Distribution\n",
                  "\t1: %0d,\n",
                  "\t2: %0d,\n",
                  "\t3: %0d,\n",
                  "\t4: %0d,\n",
                  "\t5: %0d,\n",
                  "\t6: %0d,\n",
                  "\t7: %0d,\n"},
                  tetromino_counter[0],
                  tetromino_counter[1],
                  tetromino_counter[2],
                  tetromino_counter[3],
                  tetromino_counter[4],
                  tetromino_counter[5],
                  tetromino_counter[6]);
        #1 $finish();
    end

    assign random_output_valid = |tetromino_select;

    genvar g;
    generate
        for (g = 0; g < 3; g++) begin : LFSR_G
            LFSR31 #(
                .SEED       (SEED[g])
            ) tetromino_random_generator (
                .clk        (clk),
                .rst_l      (rst_l),
                .output_bit (tetromino_select[g])
            );
        end
        for (g = 0; g < 7; g++) begin : CHOICE_COUNTERS_G
            counter #(
                .WIDTH  (32)
            ) tetromino_counters (
                .clk    (clk),
                .rst_l  (rst_l),
                .en     (counter_enable && (tetromino_select == g)),
                .load   (1'b0),
                .up     (1'b1),
                .D      ('0),
                .Q      (tetromino_counter[g])
            );
        end
    endgenerate


endmodule // LFSR_testbench