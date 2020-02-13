/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 * [255 247] Hamming encoder to output encoded version of input data
 */
 `default_nettype none

module HammingEncoder
	import NetworkPkg::*,
		   DisplayPkg::*; 
(
	input logic  [246:0] data_in,
	output logic [254:0] ham_out
);

endmodule // HammingEncoder