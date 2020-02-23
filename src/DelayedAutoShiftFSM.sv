/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This FSM handles DAS behavior of a held down input. To avoid bouncing from
 * affecting the signal, the input status is checked only at the transition out
 * of each cooldown state. If the input is still asserted, assume the input is
 * being held and use the lower cooldown.
 *
 * Output is a single-cycle pulse whenever an input should be observed by the
 * remainder of the system.
 */
`default_nettype none

module DelayedAutoShiftFSM (
    input  logic clk,
    input  logic rst_l,
    input  logic action_user,
    input  logic action_valid,
    output logic action_out
);
    localparam CD_SHORT = 5_000_000;
    localparam CD_LONG  = 10_000_000;

    logic           action_trigger;
    logic           action_sync;

    logic [31:0]    action_cd;
    logic [31:0]    cd_choice;
    logic           action_cd_en;
    logic           action_cd_ld;

    logic           action_armed;

    enum logic {LONG_WAIT, SHORT_WAIT} state, next_state;

    // synchronizing chain
    always_ff @ (posedge clk) begin
        action_sync     <= action_user;
        action_trigger  <= action_sync;
    end

    // state machine
    always_ff @ (posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            state <= LONG_WAIT;
        end else begin
            state <= next_state;
        end
    end

    // next_state logic
    always_comb begin
        if (action_cd_ld && action_trigger) begin
            next_state = SHORT_WAIT;
        end else begin
            next_state = LONG_WAIT;
        end
    end

    // output logic
    always_comb begin
        cd_choice = CD_LONG;
        if (state == SHORT_WAIT) begin
            cd_choice = CD_SHORT;
        end
    end

    always_comb begin
        action_cd_en = (action_cd != '0) || action_trigger;
        action_cd_ld = action_cd == cd_choice;
    end

    counter #(
        .WIDTH  ($bits(action_cd))
    ) action_cd_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (action_cd_en),
        .load   (action_cd_ld),
        .up     (1'b1),
        .D      (32'd0),
        .Q      (action_cd)
    );

    assign action_armed = action_cd == '0 && action_valid;
    assign action_out   = action_armed && action_trigger;
endmodule // DelayedAutoShiftFSM