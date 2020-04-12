/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * Generic library file taken from 18447
 */
`default_nettype none

/**
 * Latches and stores values of WIDTH bits and initializes to RESET_VAL.
 *
 * This register uses an asynchronous active-low reset and a synchronous
 * active-high clear. Upon clear or reset, the value of the register becomes
 * RESET_VAL.
 *
 * Parameters:
 *  - WIDTH         The number of bits that the register holds.
 *  - RESET_VAL     The value that the register holds after a reset.
 *
 * Inputs:
 *  - clk           The clock to use for the register.
 *  - rst_l         An active-low asynchronous reset.
 *  - clear         An active-high synchronous reset.
 *  - en            Indicates whether or not to load the register.
 *  - D             The input to the register.
 *
 * Outputs:
 *  - Q             The latched output from the register.
 **/
module register
   #(parameter                      WIDTH=0,
     parameter logic [WIDTH-1:0]    RESET_VAL='b0)
    (input  logic               clk, en, rst_l, clear,
     input  logic [WIDTH-1:0]   D,
     output logic [WIDTH-1:0]   Q);

     always_ff @(posedge clk, negedge rst_l) begin
         if (!rst_l)
             Q <= RESET_VAL;
         else if (clear)
             Q <= RESET_VAL;
         else if (en)
             Q <= D;
     end

endmodule // register

/**
 * Counts by INC per enabled clock edge.
 *
 * This counter can be loaded, and increments in INC if enabled. Counter always
 * resets to 0, can be "reset" to other values via D input.
 *
 * Parameters:
 *  - WIDTH         The number of bits that the counter holds.
 *  - INC           The value that the counter increments by, default 1.
 *
 * Inputs:
 *  - clk           The clock to use for the counter.
 *  - rst_l         An active-low asynchronous reset.
 *  - en            Indicates whether or not to load the counter.
 *  - D             The input to the counter.
 *  - load          Indicates whether value should come from D input
 *  - up            Indicates if counter should count up (1) or down (0)
 *
 * Outputs:
 *  - Q             The latched output from the counter.
 **/
module counter
    # (parameter WIDTH = 8, INC = 1)
    (input logic [WIDTH - 1:0] D,
     input logic clk, en, rst_l, load, up,
     output logic [WIDTH - 1:0] Q);

    always_ff @ (posedge clk, negedge rst_l) begin
        if (~rst_l)
            Q <= {WIDTH{1'b0}};
        else if (load)
            Q <= D;
        else if (en)
            if (up)
                Q <= Q + INC;
            else
                Q <= Q - INC;
        else
            Q <= Q;
    end
endmodule // counter

/**
 * Converts (supported) ASCII value to 6x6 bitmap data.
 * Supported ASCII values are alphanumerals
 * character is ASCII value for which the bitmap is being searched for (address)
 * Bitmapping from https://previews.123rf.com/images/iunewind/iunewind1607/iunewind160700049/60848823-8-bit-monospace-font-6x6-pixels-on-glyph-vector-set-of-alphabet-numbers-and-symbols.jpg
 */
module AlphanumeralBitMap (
    input  logic [ 7:0] character,
    output logic [ 0:5] bitmap [6]);

    always_comb begin
        case (character)
            // .
            8'h2e: bitmap = '{6'h00, 6'h00, 6'h00, 6'h00, 6'h0c, 6'h0c};
            // 0
            8'h30: bitmap = '{6'h1e, 6'h23, 6'h25, 6'h29, 6'h31, 6'h1e};
            // 1
            8'h31: bitmap = '{6'h04, 6'h0c, 6'h14, 6'h04, 6'h04, 6'h1f};
            // 2
            8'h32: bitmap = '{6'h1e, 6'h21, 6'h01, 6'h1e, 6'h20, 6'h3f};
            // 3
            8'h33: bitmap = '{6'h1e, 6'h21, 6'h06, 6'h01, 6'h21, 6'h1e};
            // 4
            8'h34: bitmap = '{6'h02, 6'h06, 6'h0a, 6'h12, 6'h3f, 6'h02};
            // 5
            8'h35: bitmap = '{6'h3f, 6'h20, 6'h3e, 6'h01, 6'h21, 6'h1e};
            // 6
            8'h36: bitmap = '{6'h1e, 6'h20, 6'h3e, 6'h21, 6'h21, 6'h1e};
            // 7
            8'h37: bitmap = '{6'h3f, 6'h01, 6'h02, 6'h04, 6'h08, 6'h08};
            // 8
            8'h38: bitmap = '{6'h1e, 6'h21, 6'h1e, 6'h21, 6'h21, 6'h1e};
            // 9
            8'h39: bitmap = '{6'h1e, 6'h21, 6'h21, 6'h1f, 6'h01, 6'h1e};
            // :
            8'h3A: bitmap = '{6'h00, 6'h08, 6'h00, 6'h00, 6'h08, 6'h00};
            // A
            8'h41: bitmap = '{6'h1e, 6'h21, 6'h21, 6'h3f, 6'h21, 6'h21};
            // B
            8'h42: bitmap = '{6'h3e, 6'h21, 6'h3e, 6'h21, 6'h21, 6'h3e};
            // C
            8'h43: bitmap = '{6'h1e, 6'h21, 6'h20, 6'h20, 6'h21, 6'h1e};
            // D
            8'h44: bitmap = '{6'h3c, 6'h22, 6'h21, 6'h21, 6'h22, 6'h3c};
            // E
            8'h45: bitmap = '{6'h3f, 6'h20, 6'h3c, 6'h20, 6'h20, 6'h3f};
            // F
            8'h46: bitmap = '{6'h3f, 6'h20, 6'h3e, 6'h20, 6'h20, 6'h20};
            // G
            8'h47: bitmap = '{6'h1e, 6'h21, 6'h20, 6'h27, 6'h21, 6'h1e};
            // H
            8'h48: bitmap = '{6'h21, 6'h21, 6'h3f, 6'h21, 6'h21, 6'h21};
            // I
            8'h49: bitmap = '{6'h0e, 6'h04, 6'h04, 6'h04, 6'h04, 6'h0e};
            // J
            8'h4a: bitmap = '{6'h07, 6'h02, 6'h02, 6'h22, 6'h22, 6'h1c};
            // K
            8'h4b: bitmap = '{6'h22, 6'h24, 6'h38, 6'h24, 6'h22, 6'h21};
            // L
            8'h4c: bitmap = '{6'h20, 6'h20, 6'h20, 6'h20, 6'h20, 6'h3f};
            // M
            8'h4d: bitmap = '{6'h21, 6'h33, 6'h2d, 6'h21, 6'h21, 6'h21};
            // N
            8'h4e: bitmap = '{6'h21, 6'h31, 6'h29, 6'h25, 6'h23, 6'h21};
            // O
            8'h4f: bitmap = '{6'h1e, 6'h21, 6'h21, 6'h21, 6'h21, 6'h1e};
            // P
            8'h50: bitmap = '{6'h3e, 6'h21, 6'h21, 6'h3e, 6'h20, 6'h20};
            // Q
            8'h51: bitmap = '{6'h1e, 6'h21, 6'h21, 6'h25, 6'h23, 6'h1e};
            // R
            8'h52: bitmap = '{6'h3e, 6'h21, 6'h21, 6'h3e, 6'h22, 6'h21};
            // S
            8'h53: bitmap = '{6'h1f, 6'h20, 6'h1e, 6'h01, 6'h01, 6'h3e};
            // T
            8'h54: bitmap = '{6'h3e, 6'h08, 6'h08, 6'h08, 6'h08, 6'h08};
            // U
            8'h55: bitmap = '{6'h21, 6'h21, 6'h21, 6'h21, 6'h21, 6'h1e};
            // V
            8'h56: bitmap = '{6'h21, 6'h21, 6'h21, 6'h21, 6'h12, 6'h0c};
            // W
            8'h57: bitmap = '{6'h21, 6'h21, 6'h21, 6'h21, 6'h2d, 6'h12};
            // X
            8'h58: bitmap = '{6'h21, 6'h12, 6'h0c, 6'h0c, 6'h12, 6'h21};
            // Y
            8'h59: bitmap = '{6'h22, 6'h14, 6'h08, 6'h08, 6'h08, 6'h08};
            // Z
            8'h5A: bitmap = '{6'h3f, 6'h02, 6'h04, 6'h08, 6'h10, 6'h3f};
            // else
            default: bitmap = '{6{6'd0}};
        endcase
    end
endmodule // AlphanumeralBitMap

module HEXtoSevenSegment
    (input  logic [3:0] bch,
     output logic [6:0] segment);

    always_comb begin
        case (bch)
            4'd0:       segment = 7'b100_0000;
            4'd1:       segment = 7'b111_1001;
            4'd2:       segment = 7'b010_0100;
            4'd3:       segment = 7'b011_0000;
            4'd4:       segment = 7'b001_1001;
            4'd5:       segment = 7'b001_0010;
            4'd6:       segment = 7'b000_0010;
            4'd7:       segment = 7'b111_1000;
            4'd8:       segment = 7'b000_0000;
            4'd9:       segment = 7'b001_0000;
            4'd10:      segment = 7'b001_0000;
            4'd11:      segment = 7'b000_0011;
            4'd12:      segment = 7'b100_0110;
            4'd13:      segment = 7'b010_0001;
            4'd14:      segment = 7'b000_0110;
            4'd15:      segment = 7'b000_1110;
            default:    segment = 7'b111_1111;
        endcase
    end
endmodule // HEXtoSevenSegment

module SevenSegmentDigit
    (input  logic [3:0] bch,
     output logic [6:0] segment,
     input  logic       blank);

    logic [6:0] decoded;

    HEXtoSevenSegment b2ss (
        .bch    (bch),
        .segment(decoded)
    );

    always_comb begin
        if (blank == 1'b1)
            segment = 7'b111_1111;
        else
            segment = decoded;
    end
endmodule // SevenSegmentDigit