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

module DelayedAutoShiftFSM #(
    parameter CD_SHORT      = 7_500_000,
    parameter CD_LONG       = 10_000_000,
    parameter BUFFER_LENGTH = 3,
    parameter INPUT_LENGTH  = 63
) (
    input  logic clk,
    input  logic rst_l,
    input  logic action_user,
    input  logic action_valid,
    output logic action_out
);
    logic           action_sync;
    logic           action_recv;
    logic           action_trigger;

    logic [7:0]    crosstalk_count;

    logic [31:0]    action_cd;
    logic [31:0]    cd_choice;
    logic           action_cd_en;
    logic           action_cd_ld;

    logic           action_armed;

    logic [$clog2(BUFFER_LENGTH) - 1:0] buffer_time;

    enum logic [1:0] {LONG_WAIT, BUFFER, SHORT_WAIT} state, next_state;

    // synchronizing chain
    always_ff @ (posedge clk) begin
        action_sync <= action_user;
        action_recv <= action_sync;
    end

    // due to crosstalk in the controller need to see consecutive cycles to
    // register an "input"
    counter #(
        .WIDTH  ($bits(crosstalk_count))
    ) crosstalk_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (action_recv),
        .load   (crosstalk_count >= INPUT_LENGTH || !action_recv),
        .up     (1'b1),
        .D      ('0),
        .Q      (crosstalk_count)
    );

    assign action_trigger = crosstalk_count >= INPUT_LENGTH;

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
        next_state = state;
        case (state)
            LONG_WAIT: begin
                if (action_cd_ld) begin
                    next_state = BUFFER;
                end
            end
            SHORT_WAIT: begin
                if (action_cd_ld) begin
                    next_state = BUFFER;
                end
            end
            BUFFER: begin
                if (action_trigger) begin
                    next_state = SHORT_WAIT;
                end else if (buffer_time >= BUFFER_LENGTH) begin
                    next_state = LONG_WAIT;
                end
            end
        endcase
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
        action_cd_ld = action_cd >= cd_choice;
    end

    counter #(
        .WIDTH  ($bits(action_cd))
    ) action_cd_counter (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (action_cd_en),
        .load   (action_cd_ld),
        .up     (1'b1),
        .D      ('0),
        .Q      (action_cd)
    );

    assign action_armed = action_cd == '0 && action_valid;
    assign action_out   = action_armed && action_trigger;

    counter #(
        .WIDTH  ($bits(buffer_time))
    ) buffer_ctr_inst (
        .clk    (clk),
        .rst_l  (rst_l),
        .en     (state == BUFFER),
        .load   (state != BUFFER),
        .up     (1'b1),
        .D      ('0),
        .Q      (buffer_time)
    );
endmodule // DelayedAutoShiftFSM
