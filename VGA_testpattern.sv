/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This generates a static test pattern for VGA.
 */
 `default_nettype none

module VGA_testpattern (
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
    logic       reset_syncing;
    logic       reset_sync;

    logic [9:0] VGA_row;
    logic [9:0] VGA_col;
    logic       VGA_BLANK;

    // synchronizer chains
    always_ff @ (posedge clk) begin
        reset_syncing   <= !KEY[0];
        reset_sync      <= reset_syncing;
    end

    // generate the test pattern + other static patterns here
    always_comb begin
        LEDR                    = 18'd0;
        {VGA_R, VGA_G, VGA_B}   = {8'd32, 8'd32, 8'd32};
        if (SW[17]) begin
            // prototyping the tetris game screen
            // border color
            if (VGA_row > 55 && VGA_row < 465 &&
                VGA_col > 235 && VGA_col < 405) begin
                {VGA_R, VGA_G, VGA_B}   = {8'd20, 8'd100, 8'd80};
            end
            // grid
            if (VGA_row > 60 && VGA_row < 460 &&
                VGA_col > 240 && VGA_col < 400) begin
                {VGA_R, VGA_G, VGA_B}   = 24'h0;
                if (VGA_col[3:0] == 4'd0) begin
                    {VGA_R, VGA_G, VGA_B}   = {8'd32, 8'd32, 8'd32};
                end
                if ((VGA_row % 20) == 32'd0) begin
                    {VGA_R, VGA_G, VGA_B}   = {8'd32, 8'd32, 8'd32};
                end
            end
            // light up individual tiles
            // there are 200 tiles (10 wide, 20 tall)
            // 7 colors - SW[16:14]
            // color coordinate - x = SW[13:10], y = SW[9:5]
            if (VGA_row > (60 + 20*SW[9:5]) && VGA_row < (80 + 20*SW[9:5]) &&
                VGA_col > (240 + 16*SW[13:10]) &&
                VGA_col < (256 + 16*SW[13:10])) begin
                case (SW[16:14])
                    3'd0: begin
                        {VGA_R, VGA_G, VGA_B}   = 24'h00fdff;
                    end
                    3'd1: begin
                        {VGA_R, VGA_G, VGA_B}   = 24'hffff00;
                    end
                    3'd2: begin
                        {VGA_R, VGA_G, VGA_B}   = 24'hff00ff;
                    end
                    3'd3: begin
                        {VGA_R, VGA_G, VGA_B}   = 24'h0000ff;
                    end
                    3'd4: begin
                        {VGA_R, VGA_G, VGA_B}   = 24'hff8000;
                    end
                    3'd5: begin
                        {VGA_R, VGA_G, VGA_B}   = 24'h00ff00;
                    end
                    3'd6: begin
                        {VGA_R, VGA_G, VGA_B}   = 24'hff0000;
                    end
                    default: {VGA_R, VGA_G, VGA_B}   = 24'h0;
                endcase
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
endmodule // VGA_testpattern