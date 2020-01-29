`default_nettype none

module readmemh_tb;
  logic [7:0] memory [0:255];

  initial begin
    $readmemh("korobeiniki_hex.mem", memory);
  end

  initial begin
    for (int i = 0; i < 256; i++) begin
      $display("mem[%d] = %x", i, memory[i]);
    end
  end

endmodule: readmemh_tb
