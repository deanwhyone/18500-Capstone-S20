`default_nettype none

module music
  (input  logic CLOCK_50,
   input  logic SW[0:17],
   output logic GPIO[0:35]);

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

  wavegen lead_wavegen(.clock        (clock),
                       .reset        (reset),
                       .note         (music_mem[current_note << 1]),
                       .signal       (lead_signal));

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
      GPIO[29] <= lead_signal[0];
      GPIO[27] <= lead_signal[1];
      GPIO[25] <= lead_signal[2];
      GPIO[23] <= lead_signal[3];
      GPIO[21] <= lead_signal[4];
      GPIO[19] <= lead_signal[5];
      GPIO[17] <= lead_signal[6];
      GPIO[15] <= lead_signal[7];
    end
  end

endmodule: music


