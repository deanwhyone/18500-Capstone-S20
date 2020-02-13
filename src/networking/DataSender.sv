/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * Serial data sender for single data wire
 */
 `default_nettype none

module DataSender
	import NetworkPkg::*,
		   DisplayPkg::*;
(
	input  logic 					 clk,
	input  logic 					 rst_l,
	input  logic 					 send_en,
	input  logic [ENC_DATA_BITS-1:0] data_in,
	output logic 					 send_done,
	output logic 					 serial_out
);

endmodule // DataSender