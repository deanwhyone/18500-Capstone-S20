`default_nettype none

// simple readmem testbench

module readmemh_tb;
  logic [7:0] memory [0:255];

  logic clock, reset;
  logic [7:0] music_signal;

  initial begin
    $readmemh("korobeiniki_hex.mem", memory);
    //$monitor($time,,"music_signal = %d", music_signal, m.lead_signal, memory[m.current_note << 1]);
    $monitor($time,,m.current_note,memory[m.current_note << 1]);
    clock = 0;
    reset = 1;
    #5
    clock = 1;
    #5
    clock = 0;
    reset = 0;
    #5
    forever #5 clock = ~clock;
  end

  music m(clock, reset, memory, music_signal);

  initial begin
    #500000000 $finish;
  end

endmodule: readmemh_tb

module note_freq_lookup
  (input  logic [7:0] note,
   output logic [21:0] wavelength_50M);

  always_comb begin
    case (note)
      8'd1: wavelength_50M = 22'd3058104;
      8'd2: wavelength_50M = 22'd2886836;
      8'd3: wavelength_50M = 22'd2724796;
      8'd4: wavelength_50M = 22'd2570694;
      8'd5: wavelength_50M = 22'd2427184;
      8'd6: wavelength_50M = 22'd2290426;
      8'd7: wavelength_50M = 22'd2162630;
      8'd8: wavelength_50M = 22'd2040816;
      8'd9: wavelength_50M = 22'd1926040;
      8'd10: wavelength_50M = 22'd1818182;
      8'd11: wavelength_50M = 22'd1715854;
      8'd12: wavelength_50M = 22'd1619695;
      8'd13: wavelength_50M = 22'd1529052;
      8'd14: wavelength_50M = 22'd1443001;
      8'd15: wavelength_50M = 22'd1362027;
      8'd16: wavelength_50M = 22'd1285678;
      8'd17: wavelength_50M = 22'd1213592;
      8'd18: wavelength_50M = 22'd1145475;
      8'd19: wavelength_50M = 22'd1081081;
      8'd20: wavelength_50M = 22'd1020408;
      8'd21: wavelength_50M = 22'd963206;
      8'd22: wavelength_50M = 22'd909091;
      8'd23: wavelength_50M = 22'd858074;
      8'd24: wavelength_50M = 22'd809848;
      8'd25: wavelength_50M = 22'd764409;
      8'd26: wavelength_50M = 22'd721501;
      8'd27: wavelength_50M = 22'd681013;
      8'd28: wavelength_50M = 22'd642839;
      8'd29: wavelength_50M = 22'd606722;
      8'd30: wavelength_50M = 22'd572672;
      8'd31: wavelength_50M = 22'd540541;
      8'd32: wavelength_50M = 22'd510204;
      8'd33: wavelength_50M = 22'd481556;
      8'd34: wavelength_50M = 22'd454545;
      8'd35: wavelength_50M = 22'd429037;
      8'd36: wavelength_50M = 22'd404957;
      8'd37: wavelength_50M = 22'd382234;
      8'd38: wavelength_50M = 22'd360776;
      8'd39: wavelength_50M = 22'd340530;
      8'd40: wavelength_50M = 22'd321419;
      8'd41: wavelength_50M = 22'd303380;
      8'd42: wavelength_50M = 22'd286352;
      8'd43: wavelength_50M = 22'd270270;
      8'd44: wavelength_50M = 22'd255102;
      8'd45: wavelength_50M = 22'd240790;
      8'd46: wavelength_50M = 22'd227273;
      8'd47: wavelength_50M = 22'd214519;
      8'd48: wavelength_50M = 22'd202478;
      8'd49: wavelength_50M = 22'd191110;
      8'd50: wavelength_50M = 22'd180388;
      8'd51: wavelength_50M = 22'd170265;
      8'd52: wavelength_50M = 22'd160705;
      8'd53: wavelength_50M = 22'd151685;
      8'd54: wavelength_50M = 22'd143172;
      8'd55: wavelength_50M = 22'd135139;
      8'd56: wavelength_50M = 22'd127551;
      8'd57: wavelength_50M = 22'd120395;
      8'd58: wavelength_50M = 22'd113636;
      8'd59: wavelength_50M = 22'd107259;
      8'd60: wavelength_50M = 22'd101239;
      8'd61: wavelength_50M = 22'd95557;
      8'd62: wavelength_50M = 22'd90192;
      8'd63: wavelength_50M = 22'd85131;
      8'd64: wavelength_50M = 22'd80354;
      8'd65: wavelength_50M = 22'd75844;
      8'd66: wavelength_50M = 22'd71586;
      8'd67: wavelength_50M = 22'd67568;
      8'd68: wavelength_50M = 22'd63776;
      8'd69: wavelength_50M = 22'd60197;
      8'd70: wavelength_50M = 22'd56818;
      8'd71: wavelength_50M = 22'd53629;
      8'd72: wavelength_50M = 22'd50619;
      8'd73: wavelength_50M = 22'd47778;
      8'd74: wavelength_50M = 22'd45097;
      8'd75: wavelength_50M = 22'd42566;
      8'd76: wavelength_50M = 22'd40176;
      8'd77: wavelength_50M = 22'd37922;
      8'd78: wavelength_50M = 22'd35793;
      8'd79: wavelength_50M = 22'd33784;
      8'd80: wavelength_50M = 22'd31888;
      8'd81: wavelength_50M = 22'd30098;
      8'd82: wavelength_50M = 22'd28409;
      8'd83: wavelength_50M = 22'd26815;
      8'd84: wavelength_50M = 22'd25310;
      8'd85: wavelength_50M = 22'd23889;
      8'd86: wavelength_50M = 22'd22548;
      8'd87: wavelength_50M = 22'd21283;
      8'd88: wavelength_50M = 22'd20088;
      8'd89: wavelength_50M = 22'd18961;
      8'd90: wavelength_50M = 22'd17897;
      8'd91: wavelength_50M = 22'd16892;
      8'd92: wavelength_50M = 22'd15944;
      8'd93: wavelength_50M = 22'd15049;
      8'd94: wavelength_50M = 22'd14205;
      8'd95: wavelength_50M = 22'd13407;
      8'd96: wavelength_50M = 22'd12655;
      8'd97: wavelength_50M = 22'd11945;
      8'd98: wavelength_50M = 22'd11274;
      8'd99: wavelength_50M = 22'd10641;
      8'd100: wavelength_50M = 22'd10044;
      8'd101: wavelength_50M = 22'd9480;
      8'd102: wavelength_50M = 22'd8948;
      8'd103: wavelength_50M = 22'd8446;
      8'd104: wavelength_50M = 22'd7972;
      8'd105: wavelength_50M = 22'd7525;
      8'd106: wavelength_50M = 22'd7102;
      8'd107: wavelength_50M = 22'd6704;
      8'd108: wavelength_50M = 22'd6327;
    endcase
  end

endmodule: note_freq_lookup

module wavegen
  (input  logic [31:0] clock_counter,
   input  logic [7:0] note,
   output logic [7:0] signal);

  logic [21:0] wavelength_50M;
  note_freq_lookup nf_lookup(note, wavelength_50M);

  always_comb begin
    if (note == 8'd0)
      signal = 8'd0;
    else if ((clock_counter % wavelength_50M) < (wavelength_50M >> 1))
      signal = 8'd64;
    else
      signal = 8'd0;
  end

endmodule: wavegen

module music
  (input  logic clock,
   input  logic reset,
   input  logic [7:0] music_mem [0:255],
   output logic [7:0] music_signal);

  localparam CLOCK_FREQ = 50000000;
  localparam AUDIO_FREQ = 50000;
  localparam NOTE_FREQ = 4;

  logic [31:0] clock_counter;
  logic [9:0]  audio_sample_counter;
  logic [24:0] note_tick_counter;
  logic [6:0] current_note;
  logic [7:0] lead_signal;

  wavegen lead_wavegen(clock_counter,
                       music_mem[current_note << 1],
                       lead_signal);

  always_ff @(posedge clock) begin
    if (reset) begin
      clock_counter <= 'b0;
      audio_sample_counter <= 'b0;
      note_tick_counter <= 'b0;
      current_note <= 'b0;
    end
    else begin
      clock_counter <= clock_counter + 1'b1;
      audio_sample_counter <= audio_sample_counter + 1'b1;
      note_tick_counter <= note_tick_counter + 1'b1;
      if (audio_sample_counter >= CLOCK_FREQ / AUDIO_FREQ - 1) begin
        audio_sample_counter <= 'b0;
        music_signal <= lead_signal;
      end
      if (note_tick_counter >= CLOCK_FREQ / NOTE_FREQ - 1) begin
        note_tick_counter <= 'b0;
        current_note <= current_note + 1'b1;
      end
    end
  end

endmodule: music


