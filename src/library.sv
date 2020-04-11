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


/* Left shift register with load 
 */
module shift_reg
   #(parameter                      WIDTH=0,
     parameter logic [WIDTH-1:0]    RESET_VAL='b0)
    (input  logic               clk, en, rst_l, load,
     input  logic               shift_in,
     input  logic [WIDTH-1:0]   D,
     output logic [WIDTH-1:0]   Q);

    always_ff @(posedge clk, negedge rst_l) begin
        if (!rst_l)
            Q <= RESET_VAL;
        else if (load)
            Q <= D;
        else if (en) begin
            Q <= Q << 1;
            Q[0] <= shift_in;
        end
    end
endmodule // shift_reg

module BCDtoSevenSegment(input logic [3:0] bcd, output logic [6:0] seg);
    always_comb begin
        case(bcd)
            0 : seg = 7'b1000000; 
            1 : seg = 7'b1111001; 
            2 : seg = 7'b0100100; 
            3 : seg = 7'b0110000; 
            4 : seg = 7'b0011001; 
            5 : seg = 7'b0010010; 
            6 : seg = 7'b0000010; 
            7 : seg = 7'b1111000; 
            8 : seg = 7'b0000000; 
            9 : seg = 7'b0010000; 
            default : seg = 7'b1111111;
        endcase
    end
endmodule: BCDtoSevenSegment