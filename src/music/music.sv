`default_nettype none

module music (
    input  logic clk,
    input  logic rst_l,
    output logic GPIO_29,
    output logic GPIO_27,
    output logic GPIO_25,
    output logic GPIO_23,
    output logic GPIO_21,
    output logic GPIO_19,
    output logic GPIO_17,
    output logic GPIO_15
);
    localparam CLOCK_FREQ   = 50_000_000;
    localparam AUDIO_FREQ   = 50_000;
    localparam NOTE_FREQ    = 4;

    logic [7:0] music_mem [0:255];

    initial begin
        $readmemh("../../assets/korobeiniki_hex.mem", music_mem);
    end

    logic [9:0]  audio_sample_counter;
    logic [24:0] note_tick_counter;
    logic [6:0] current_note;
    logic [7:0] lead_signal;
    logic [7:0] bass_signal;
    logic [7:0] dac_out;

    wavegen lead_wavegen (
        .clock        (clk),
        .reset        (!rst_l),
        .note         (music_mem[current_note * 2]),
        .signal       (lead_signal)
    );

    wavegen bass_wavegen (
        .clock        (clk),
        .reset        (!rst_l),
        .note         (music_mem[current_note * 2 + 1]),
        .signal       (bass_signal)
    );

    assign dac_out = lead_signal + bass_signal;

    counter #(
        .WIDTH(10)
    ) _audio_sample_counter (
        .D      ('b0),
        .clk    (clk),
        .en     ('b1),
        .rst_l  (rst_l),
        .load   (audio_sample_counter >= CLOCK_FREQ / AUDIO_FREQ - 1),
        .up     ('b1),
        .Q      (audio_sample_counter)
    );

    counter #(
        .WIDTH(25)
    ) _note_tick_counter (
        .D      ('b0),
        .clk    (clk),
        .en     ('b1),
        .rst_l  (rst_l),
        .load   (note_tick_counter >= CLOCK_FREQ / NOTE_FREQ - 1),
        .up     ('b1),
        .Q      (note_tick_counter)
    );

    counter #(
        .WIDTH(7)
    ) _current_note_counter (
        .D      ('b0),
        .clk    (clk),
        .en     (note_tick_counter == CLOCK_FREQ / NOTE_FREQ - 1),
        .rst_l  (rst_l),
        .load   ('b0),
        .up     ('b1),
        .Q      (current_note)
    );

    always_ff @ (posedge clk) begin
        if (audio_sample_counter == 0) begin
            GPIO_29 <= dac_out[0];
            GPIO_27 <= dac_out[1];
            GPIO_25 <= dac_out[2];
            GPIO_23 <= dac_out[3];
            GPIO_21 <= dac_out[4];
            GPIO_19 <= dac_out[5];
            GPIO_17 <= dac_out[6];
            GPIO_15 <= dac_out[7];
        end
    end
endmodule // music