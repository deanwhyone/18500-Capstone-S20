/**
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * 
 * 							HandshakeSender.sv
 * Serial data sender for handshake wire. Sends data MSB first. On
 * send_start, loads data_in and syncword into a shift register. Sends first 
 * bit on the next cycle. Asserts send_done after 
 * (length of syncword + length of encoded header) cycles.
 *
 * INPUTS:
 *  - clk 			GPIO clock
 *  - rst_l			reset
 *  - send_start	1-cycle pulse on state transition, indicates data can be
 *					loaded in and sending can begin
 *  - game_active   indicates game is in progress, don't send if not asserted
 *  - data_in 		hamming encoded header, consists of pid and sequence number
 *					and their bitwise complement
 * 
 * OUTPUTS:
 *  - send_done		indicates all data has been sent, stays high until 
 *					send_start is asserted again
 *  - serial_out	serial data out, wired to MSB of shift register, or 0 when 
 *					inactive
 **/
 `default_nettype none

module HandshakeSender
	import NetworkPkg::*,
		   DisplayPkg::*;
(
	input  logic 					 clk,
	input  logic 					 rst_l,
	input  logic 					 send_start,
	input  logic 					 game_active,
	input  logic [ENC_HEAD_BITS-1:0] data_in,
	output logic 					 send_done,
	output logic 					 serial_out
);
	logic 					  			   send_en;
	logic [ENC_HEAD_BITS + SYNC_BITS -1:0] data_reg;
	logic [7:0] 			  			   sent_count;

	always_ff @(posedge clk, negedge rst_l) begin
		if(!rst_l) begin
			send_en    <= 1'b0;
			serial_out <= 1'b0;
		end
		else if(!game_active) begin
			send_en    <= 1'b0;
			serial_out <= 1'b0;
		end
		else if(send_start) begin
			send_en    <= 1'b1;
			serial_out <= 1'b0;
		end
		else begin
			//serial_out is equivalent to MSB of shift register
			serial_out <= data_reg[HND_PKT_BITS-1];
		end
	end

	//left shift register
	shift_reg #(.WIDTH(HND_PKT_BITS)) send_reg (
		.clk(clk), 
		.rst_l(rst_l),
		.en(send_en & !send_done),
		.load(send_start),
		.shift_in(1'b0),
		.D({SYNCWORD, data_in}),
		.Q(data_reg)
	);

	//sent bits counter
	counter #(.WIDTH(8)) sent_counter (
		.clk(clk),
		.rst_l(rst_l),
		.en(send_en & !send_done),
		.load(send_start),
		.up(1'b1),
		.D(8'b0),
		.Q(sent_count)
	);


	assign send_done = (sent_count == HND_PKT_BITS);


endmodule // HandshakeSender