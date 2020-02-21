/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module specifies a 31 bit LFSR for pseudo-random number generation
 * This is intended to be used for generating next pieces in the game.
 * 31 bit maximal LFSR: x^31 + x^28 + 1
 * Found from https://web.archive.org/web/20161007061934/http://courses.cse.tamu.edu/csce680/walker/lfsr_table.pdf
 * Implemented as described from
 * This is implemented as a 31-stage Galois implementation to reduce critical
 * path. Unlikely to cause issues, but better suited nonetheless
 */
`default_nettype none

module LFSR31 #(
    SEED = 31'h1
) (
    input  logic clk,
    input  logic rst_l,
    output logic output_bit
);
    localparam WIDTH = 31;
    logic registers [31];

    always_ff @(posedge clk, negedge rst_l) begin
        if (!rst_l) begin
            // this is valid syntax according to VCS
            // but Quartus doesn't support streaming operators?
            // {>>{registers}} <= SEED;
            for (int i = 0; i < WIDTH; i++) begin
                registers[i] <= SEED[i];
            end
        end else begin
            registers[WIDTH - 1] <= registers[0];
            for (int i = 0; i < WIDTH - 1; i++) begin
                if (i == 27) begin
                    registers[i] <= registers[i + 1] ^ registers[0];
                end else begin
                    registers[i] <= registers[i + 1];
                end
            end
        end
    end

    assign output_bit = registers[0];
endmodule // LFSR31
