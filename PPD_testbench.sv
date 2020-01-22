/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This uses the Playfield Pixel Driver (PPD) to drive the individual tiles in
 * the Tetris playfield. Background and borders are still managed by the
 * testbench.
 */

 `default_nettype none

module PPD_testbench
    import DisplayPkg::*;
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
    logic           reset_syncing;
    logic           reset_sync;

    logic [ 9:0]    VGA_row;
    logic [ 9:0]    VGA_col;
    logic           VGA_BLANK;

    tile_type_t     tile_type           [PLAYFIELD_DIM_Y][PLAYFIELD_DIM_X];
    logic [23:0]    ppd_output_color;
    logic           ppd_active;

    // synchronizer chains
    always_ff @ (posedge clk) begin
        reset_syncing   <= !KEY[0];
        reset_sync      <= reset_syncing;
    end

    always_comb begin
        LEDR                    = 18'd0;
        {VGA_R, VGA_G, VGA_B}   = BG_COLOR;
        if (SW[17]) begin
            // prototyping the tetris game screen
            // border color
            if (VGA_row >= 15 && VGA_row < 425 &&
                VGA_col >= 235 && VGA_col < 405) begin
                {VGA_R, VGA_G, VGA_B}   = {8'd20, 8'd100, 8'd80};
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
        for (int i = 0; i < PLAYFIELD_DIM_Y; i++) begin
            for (int j = 0; j < PLAYFIELD_DIM_X; j++) begin
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
        .reset  (reset_sync)
    );
    assign VGA_CLK      = !clk;
    assign VGA_BLANK_N  = !VGA_BLANK;
    assign VGA_SYNC_N   = 1'b0;
endmodule // PPD_testbench