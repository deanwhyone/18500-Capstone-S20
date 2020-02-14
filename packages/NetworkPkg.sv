/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * Package defining fields, constants, sizes, structures
 * of TSPIN network protocol
 */
`default_nettype none

`ifndef NETWORK_PKG_READ
`define NETWORK_PKG_READ

package NetworkPkg;
	//number of data wires
	parameter NUM_DATA_LINES = 4;

	//# PID bits after hamming encoding
	parameter ENC_HEAD_BITS  = 7;

	//# bits for garbage lines sent
	parameter GBG_BITS  	 = 4;

	//# bits for hold register
	parameter HLD_BITS  	 = 4;

	//# bits for piece queue
	parameter PQ_BITS   	 = 24;

	//# bits for playfield
	parameter PFD_BITS 		 = 800;

	//# bits for syncword
	parameter SYNC_BITS 	 = 8;

	//# total data bits
	parameter DATA_BITS 	 = GBG_BITS + HLD_BITS + PQ_BITS + PFD_BITS;

	//# data bits per wire
	parameter PAR_DATA_BITS  = DATA_BITS / NUM_DATA_LINES;

	//# data bits per wire after hamming encoding, hardcoded to 8 parity bits
	parameter ENC_DATA_BITS  = PAR_DATA_BITS + 8;

	//# cycles before timeout & data resend
	parameter TIMEOUT_CYCLES = 100;

	//syncword
	parameter SYNCWORD 		 = 8'hff;

	// Packet ID's for handshaking
	typedef enum logic {
		PID_ACK = 1'b1, PID_GE = 1'b0, PID_X = 1'bx
	} pid_t;

	// Handshake header, pid and sequence number and their bitwise complement
	typedef struct packed {
		pid_t pid;
		logic seqNum;
		logic pid_n;
		logic seqNum_n;
	} hnd_head_t;

	// Handshake packet
	typedef struct packed {
		logic [SYNC_BITS-1:0]     sync;
		logic [ENC_HEAD_BITS-1:0] data;
	} hnd_pkt_t;

	//single data wire packet
	typedef struct packed {
		logic [SYNC_BITS-1:0] 	  sync;
		logic [ENC_DATA_BITS-1:0] data;
	} par_data_pkt_t;

	//overall decoded data packet
	typedef struct packed {
		logic [GBG_BITS-1:0] 	  garbage;
		logic [HLD_BITS-1:0] 	  hold;
		logic [PQ_BITS-1:0]  	  piece_queue;
		logic [PFD_BITS-1:0] 	  playfield;
	} data_pkt_t;

endpackage // NetworkPkg

`endif