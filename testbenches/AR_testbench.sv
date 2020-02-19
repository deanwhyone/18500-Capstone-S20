/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This testbench is for prototyping the alphanumeral drivers to display text
 * on-screen via the VGA module.
 */
`default_nettype none

module AR_testbench (
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
    localparam STRING_LENGTH = 37;
    localparam SCALE = 4;

    // abstract clk signal for uniformity
    logic   clk;
    assign  clk = CLOCK_50;

    // declare local variables
    logic  rst_l;
    assign rst_l = !SW[17];

    logic [ 9:0]    VGA_row;
    logic [ 9:0]    VGA_col;
    logic           VGA_BLANK;

    logic [ 7:0]                chars           [STRING_LENGTH];
    logic [ 0:5]                bitmap          [STRING_LENGTH][6];
    logic [STRING_LENGTH:0]     actives;
    logic                       general_active;

    always_comb begin
        for (int i = 0; i < STRING_LENGTH; i++) begin
            if (i < 11) begin
                chars[i] = 8'(i + 48);
            end else begin
                chars[i] = 8'(i + 54);
            end
        end
    end

    genvar g;
    generate
        for (g = 0; g < 10; g++) begin : BITMAP_NUM_G
            AlphanumeralRender #(
                .SCALE      (SCALE),
                .ORIGIN_ROW (0),
                .ORIGIN_COL (8 * SCALE * (g))
            ) AR_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (chars[g]),
                .active     (actives[g])
            );
        end
        for (g = 10; g < 24; g++) begin : BITMAP_ALPHA_0_G
            AlphanumeralRender #(
                .SCALE      (SCALE),
                .ORIGIN_ROW (150),
                .ORIGIN_COL (8 * SCALE * (g - 10))
            ) AR_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (chars[g]),
                .active     (actives[g])
            );
        end
        for (g = 24; g < STRING_LENGTH; g++) begin : BITMAP_ALPHA_1_G
            AlphanumeralRender #(
                .SCALE      (SCALE),
                .ORIGIN_ROW (200),
                .ORIGIN_COL (8 * SCALE * (g - 24))
            ) AR_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (chars[g]),
                .active     (actives[g])
            );
        end
        AlphanumeralRender #(
                .SCALE      (SCALE),
                .ORIGIN_ROW (250),
                .ORIGIN_COL (0)
            ) AR_inst (
                .VGA_row    (VGA_row),
                .VGA_col    (VGA_col),
                .character  (":"),
                .active     (actives[STRING_LENGTH])
            );
    endgenerate

    assign general_active = |actives;

    always_comb begin
        {VGA_R, VGA_G, VGA_B} = 24'h40_4040;
        if (general_active) begin
            {VGA_R, VGA_G, VGA_B} = 24'hff_ffff;
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
        .reset  (!rst_l)
    );
    assign VGA_CLK      = !clk;
    assign VGA_BLANK_N  = !VGA_BLANK;
    assign VGA_SYNC_N   = 1'b0;

endmodule // AR_testbench