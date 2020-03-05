/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module is a simulation testbench of the LinesManager module
 */
`default_nettype none

module LinesManager_testbench
import DisplayPkg::*;
();
    logic        clk;
    logic        rst_l;
    logic        game_start;
    logic        falling_piece_lock;
    logic        tspin_detected;
    logic        lines_full          [PLAYFIELD_ROWS];
    logic [ 9:0] lines_cleared;
    logic [ 9:0] lines_sent;
    logic [ 4:0] combo_count;

    // clock maker
    initial begin
        clk     = 1'b0;
        rst_l   = 1'b0;
        rst_l   <= 1'b1;
        forever #5 clk = !clk;
    end

    task initializeSignals();
        game_start          = 1'b0;
        falling_piece_lock  = 1'b0;
        tspin_detected      = 1'b0;
        for (int i = 0; i < PLAYFIELD_ROWS; i++) begin
            lines_full[i] = 1'b0;
        end
    endtask

    initial begin
        initializeSignals();
        repeat (10) @ (posedge clk);
        // simulate game start pulse
        game_start <= 1'b1;
        @ (posedge clk);
        game_start <= 1'b0;
        // first piece falls
        repeat (5) @ (posedge clk);
        // first piece locks, generates FPL pulze
        falling_piece_lock <= 1'b1;
        @ (posedge clk);
        falling_piece_lock <= 1'b0;
        // clears a line, lines full is pulse by clearing mechanism
        lines_full[18] <= 1'b1;
        @ (posedge clk);
        lines_full[18] <= 1'b0;

        // another piece falls
        repeat (10) @ (posedge clk);
        // piece lands and locks
        falling_piece_lock <= 1'b1;
        @ (posedge clk);
        falling_piece_lock <= 1'b0;
        // clears the next line
        lines_full[19] <= 1'b1;
        @ (posedge clk);
        lines_full[19] <= 1'b0;

        // another piece falls
        repeat (10) @ (posedge clk);
        // piece lands and locks
        falling_piece_lock <= 1'b1;
        @ (posedge clk);
        falling_piece_lock <= 1'b0;
        // clears the next line
        lines_full[19] <= 1'b1;
        @ (posedge clk);
        lines_full[19] <= 1'b0;

        // another piece falls
        repeat (10) @ (posedge clk);
        // piece lands and locks
        falling_piece_lock <= 1'b1;
        @ (posedge clk);
        falling_piece_lock <= 1'b0;
        // clears the next line
        lines_full[19] <= 1'b1;
        @ (posedge clk);
        lines_full[19] <= 1'b0;

        repeat (20) @ (posedge clk);
        #1 $finish();
    end

    LinesManager dut_inst (.*);
endmodule // LinesManager_testbench