`default_nettype none

module music
  (input  logic CLOCK_50,
   input  logic SW[0:17],
   output logic GPIO_0[29:15]); // only uses odd numbered pins (29, 27, 25 ... 15)

  logic clock, reset;
  assign clock = CLOCK_50;
  assign reset = SW[0];

  logic [7:0] music_mem [0:255];

  initial begin
    $readmemh("../../assets/korobeiniki_hex.mem", music_mem);
  end

  localparam CLOCK_FREQ = 50000000;
  localparam AUDIO_FREQ = 50000;
  localparam NOTE_FREQ = 4;

  logic [9:0]  audio_sample_counter;
  logic [24:0] note_tick_counter;
  logic [6:0] current_note;
  logic [7:0] lead_signal;
  logic [7:0] bass_signal;
  logic [7:0] dac_out;

  wavegen lead_wavegen(.clock        (clock),
                       .reset        (reset),
                       .note         (music_mem[current_note * 2]),
                       .signal       (lead_signal));

  wavegen bass_wavegen(.clock        (clock),
                       .reset        (reset),
                       .note         (music_mem[current_note * 2 + 1]),
                       .signal       (bass_signal));

  assign dac_out = lead_signal + bass_signal;

  counter #(.WIDTH(10)) _audio_sample_counter(.D('b0),
                                              .clk(clock),
                                              .en('b1),
                                              .rst_l(~reset),
                                              .load(audio_sample_counter >= CLOCK_FREQ / AUDIO_FREQ - 1),
                                              .up('b1),
                                              .Q(audio_sample_counter));

  counter #(.WIDTH(25)) _note_tick_counter(.D('b0),
                                           .clk(clock),
                                           .en('b1),
                                           .rst_l(~reset),
                                           .load(note_tick_counter >= CLOCK_FREQ / NOTE_FREQ - 1),
                                           .up('b1),
                                           .Q(note_tick_counter));

  counter #(.WIDTH(7)) _current_note_counter(.D('b0),
                                             .clk(clock),
                                             .en(note_tick_counter == CLOCK_FREQ / NOTE_FREQ - 1),
                                             .rst_l(~reset),
                                             .load('b0),
                                             .up('b1),
                                             .Q(current_note));

  always_ff @(posedge clock) begin
    if (audio_sample_counter == 0) begin
      GPIO_0[29] <= dac_out[0];
      GPIO_0[27] <= dac_out[1];
      GPIO_0[25] <= dac_out[2];
      GPIO_0[23] <= dac_out[3];
      GPIO_0[21] <= dac_out[4];
      GPIO_0[19] <= dac_out[5];
      GPIO_0[17] <= dac_out[6];
      GPIO_0[15] <= dac_out[7];
    end
  end

endmodule: music


