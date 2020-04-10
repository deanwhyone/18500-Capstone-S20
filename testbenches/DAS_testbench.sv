/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This uses the Delayed Auto Shift FSM to drive LEDs to test if the polling.
 * rate is correct as defined for the DAS mechanism. This is to test different
 * mechanisms for handling keyswitch jitter on a lightweight testbench to
 * reduce synthesis, place, and route time.
 */
`default_nettype none

module DAS_testbench (
    input  logic        CLOCK_50,

    input  logic [17:0] SW,
    input  logic [ 3:0] KEY,

    output logic [17:0] LEDR
);
    localparam KEY_COUNT            = 4;
    localparam int CD_SHORT [KEY_COUNT] = '{6_500_000,
                                            7_000_000,
                                            7_500_000,
                                            8_000_000};
    localparam int CD_LONG [KEY_COUNT]  = '{10_000_000,
                                            10_000_000,
                                            10_000_000,
                                            10_000_000};

    // abstract clk signal for uniformity
    logic   clk;
    assign  clk     = CLOCK_50;
    logic   rst_l;
    assign  rst_l   = !SW[17];

    // declare local variables
    logic           trigger     [KEY_COUNT];
    logic   [31:0]  led_driver  [KEY_COUNT];

    genvar g;
    generate
        for (g = 0; g < KEY_COUNT; g++) begin : DAS_MODULES_G
            DelayedAutoShiftFSM #(
                .CD_SHORT       (CD_SHORT[g]),
                .CD_LONG        (CD_LONG[g])
            ) das_inst (
                .clk            (clk),
                .rst_l          (rst_l),
                .action_user    (!KEY[g]),
                .action_valid   (1'b1),
                .action_out     (trigger[g])
            );
            // drive LEDs with counters. single cycle pulses are not visible
            counter #(
                .WIDTH  (32)
            ) driver_counter_inst (
                .clk    (clk),
                .rst_l  (rst_l),
                .en     (led_driver[g] != '0 || trigger[g]),
                .load   (led_driver[g] == 32'd100_000),
                .up     (1'b1),
                .D      ('0),
                .Q      (led_driver[g])
            );
        end
    endgenerate

    always_comb begin
        for (int i = 0; i < KEY_COUNT; i++) begin
            LEDR[i] = (led_driver[i] != '0);
        end
    end
endmodule // DAS_testbench