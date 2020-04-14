`default_nettype none

module note_freq_lookup
  (input  logic [7:0]  note,
   output logic [23:0] wavelength_50M);

  logic [23:0] frequency_mem [0:127];

  initial begin
    $readmemh("../../assets/frequency_hex.mem", frequency_mem);
  end

  assign wavelength_50M = frequency_mem[(note + 1) % 128];

endmodule: note_freq_lookup
