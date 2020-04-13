/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module instantiates the necessary counters for recording input delay and
 * drives the HEX displays to monitor this value.
 *
 * Input delay is measured by counting clock cycles between a user input that
 * updates the game state, implying the input is valid, and the vertical sync
 * pulse from the (S)VGA module. This is parameterized by processing delay to
 * ensure that a valid vertical sync pulse is used, that which includes the data
 * from the tracked user input.
 */
`default_nettype none

module MetricsHandler #(
    parameter COMPUTE_DELAY = 4
) (
    input  logic        clk,
    input  logic        rst_l,
    input  logic        state_update,
    input  logic        V_SYNC,
    output logic [ 6:0] HEX0,
    output logic [ 6:0] HEX1,
    output logic [ 6:0] HEX2,
    output logic [ 6:0] HEX3,
    output logic [ 6:0] HEX4,
    output logic [ 6:0] HEX5
);
    localparam HEX_COUNT = 6;

    logic [ 6:0]    HEX_DISPLAYS    [HEX_COUNT];
    logic [ 3:0]    HEX_VALUE       [HEX_COUNT];

    enum logic {COUNT, STOP} state, nstate;

    logic [23:0]    latency_count;
    logic           latency_en;
    logic           latency_ld;

    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            state <= STOP;
        end else begin
            state <= nstate;
        end
    end

    always_comb begin
        if (state_update) begin
            nstate = COUNT;
        end else if (latency_count >= COMPUTE_DELAY && V_SYNC) begin
            nstate = STOP;
        end else begin
            nstate = state;
        end
    end

    counter #(
        .WIDTH      ($bits(latency_count))
    ) latency_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (latency_en),
        .load   (latency_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (latency_count)
    );
    assign latency_ld = state_update;   // reset latency counter on new input
    assign latency_en = state == COUNT;

    genvar g;
    generate
        for (g = 0; g < HEX_COUNT; g++) begin : SSD_G
            assign HEX_VALUE[g] = latency_count[4 * g + 3:4 * g];

            SevenSegmentDigit ssd_inst (
                .bch    (HEX_VALUE[g]),
                .segment(HEX_DISPLAYS[g]),
                .blank  (1'b0)
            );
        end
    endgenerate

    assign HEX0 = HEX_DISPLAYS[0];
    assign HEX1 = HEX_DISPLAYS[1];
    assign HEX2 = HEX_DISPLAYS[2];
    assign HEX3 = HEX_DISPLAYS[3];
    assign HEX4 = HEX_DISPLAYS[4];
    assign HEX5 = HEX_DISPLAYS[5];
endmodule // MetricsHandler