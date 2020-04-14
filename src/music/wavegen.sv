`default_nettype none

module wavegen
  (input  logic        clock,
   input  logic        reset,
   input  logic [7:0]  note,
   output logic [7:0]  signal);

  logic [23:0] wave_counter;
  logic [23:0] wavelength_50M;
  note_freq_lookup nf_lookup(.note          (note),
                             .wavelength_50M(wavelength_50M));

  counter #(.WIDTH(24)) _wave_counter(.D('b0),
                                      .clk(clock),
                                      .en('b1),
                                      .rst_l(~reset),
                                      .load(wave_counter >= wavelength_50M - 1),
                                      .up('b1),
                                      .Q(wave_counter));

  always_comb begin
    if (note == 8'd0)
      signal = 8'd0;
    else if (wave_counter < (wavelength_50M >> 1))
      signal = 8'd64;
    else
      signal = 8'd0;
  end

endmodule: wavegen
