/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * Serial data sender for handshake wire
 */
 `default_nettype none

module HandshakeSender
	import NetworkPkg::*,
		   DisplayPkg::*;
(
	input  logic 					 clk,
	input  logic 					 rst_l,
	input  logic 					 send_start,
	input  logic [ENC_HEAD_BITS-1:0] data_in,
	output logic 					 send_done,
	output logic 					 serial_out
);

endmodule // HandshakeSender