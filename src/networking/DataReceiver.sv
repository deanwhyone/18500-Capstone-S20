/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 * 								DataReceiver.sv
 * Serial data receiver for single data wire. Upon receive_start listens for 
 * syncword, once detected shifts in data until a full packet is assembled.
 * Asserts receive_done after (length of encoded data) cycles to signal that 
 * a full packet is held on data_out.
 * 
 * INPUTS:
 *  - clk 			 GPIO clock
 *  - rst_l			 reset
 *  - receive_start  1-cycle pulse on state transition, indicates data_out can
 *					 be cleared and to begin listening for a new packet
 *  - serial_in 	 serial data in, shifts into LSB of shift register
 * 
 * OUTPUTS:
 *  - receive_done	 indicates a full packet has been received and is on 
 *					 data_out, held until receive_start is asserted again
 *  - data_out		 reconstructed encoded data, held with receive_done
 **/

module DataReceiver
 	import NetworkPkg::*,
		   DisplayPkg::*;
(
	input  logic 					 clk,
	input  logic 					 rst_l,
	input  logic 					 receive_start,
	input  logic 					 game_active,
	input  logic					 serial_in,
	output logic [ENC_DATA_BITS-1:0] data_out,
	output logic 					 receive_done
);
	logic 				  	  sync_en;
	logic				  	  sync_done;
	logic [SYNC_BITS-1:0]	  sync_reg;
	logic [7:0]	  			  receive_count;

	//set sync_en
	always_ff @(posedge clk, negedge rst_l) begin
		if(!rst_l) begin
			sync_en <= 1'b0;
		end
		else if(!game_active) begin
			sync_en <= 1'b0;
		end
		else if(receive_start) begin
			sync_en <= 1'b1;
		end
	end

	//shift register for syncword detection
	shift_reg #(.WIDTH(SYNC_BITS)) sync_detection (
		.clk(clk), 
		.rst_l(rst_l),
		.en(sync_en & !sync_done),
		.load(receive_start),
		.shift_in(serial_in),
		.D('0),
		.Q(sync_reg)
	);

	assign sync_done = (sync_reg == SYNCWORD);

	//shift register for data
	shift_reg #(.WIDTH(ENC_DATA_BITS)) data_reg (
		.clk(clk), 
		.rst_l(rst_l),
		.en(sync_done & !receive_done),
		.load(receive_start),
		.shift_in(serial_in),
		.D('0),
		.Q(data_out)
	);

	//received bits counter
	counter #(.WIDTH(8)) rec_counter (
		.clk(clk),
		.rst_l(rst_l),
		.en(sync_done & !receive_done),
		.load(receive_start),
		.up(1'b1),
		.D(8'b0),
		.Q(receive_count)
	);

	assign receive_done = (receive_count == ENC_DATA_BITS);

endmodule : DataReceiver