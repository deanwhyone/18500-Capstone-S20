/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * Serial data sender for single data wire
 * On send_start, load data_in into shift register and assert send_en
 * Assert send_done after 216 cycles (length of syncword + encoded data)
 */
 `default_nettype none

module DataSender
	import NetworkPkg::*,
		   DisplayPkg::*;
(
	input  logic 					 clk,
	input  logic 					 rst_l,
	input  logic 					 send_start,
	input  logic [ENC_DATA_BITS-1:0] data_in,
	output logic 					 send_done,
	output logic 					 serial_out
);
	logic 					  send_en;
	logic [ENC_DATA_BITS-1:0] data_reg;
	logic [7:0] 			  sent_count;

	always_ff @(posedge clk, negedge rst_l) begin
		if(!rst_l) begin
			send_en    <= 1'b0;
			serial_out <= 1'b0;
		end
		else if(send_start) begin
			send_en    <= 1'b1;
			serial_out <= 1'b0;
		end
		else begin
			//serial_out is equivalent to MSB of shift register
			serial_out <= data_reg[ENC_DATA_BITS-1];
		end
	end

	//left shift register
	shift_reg #(.WIDTH(ENC_DATA_BITS)) send_reg (
		.clk(clk), 
		.rst_l(rst_l),
		.en(send_en & !send_done),
		.load(send_start),
		.shift_in(1'b0),
		.D(data_in),
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


	//assign send_done = (sent_count == ENC_DATA_BITS + SYNC_BITS);
	assign send_done = (sent_count == 3);
endmodule // DataSender