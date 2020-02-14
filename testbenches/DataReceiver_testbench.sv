/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * Simulation testbench for data receiver module
 */
 `default_nettype none

module DataReceiver_testbench
	import NetworkPkg::*,
		   DisplayPkg::*;
();
	logic clk, rst_l, receive_start, receive_done, serial_in;
	logic [ENC_DATA_BITS-1:0] data_out;

	logic send_start, send_done, serial_out;
	logic [ENC_DATA_BITS-1:0] data_in;

	default clocking cb_main @(posedge clk); endclocking

	DataReceiver dut(.*);
	DataSender sender(.*);

	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk;
	end

	task doReset;
		rst_l = 1'b1;
		rst_l <= 1'b0;
		#1 rst_l <= 1'b1;
	endtask : doReset

	function displayState;
		$display("receive_start: %b, sync_en: %b, sync_reg: %b, sync_done: %b, serial_in: %b, receive_count: %0d, receive_done: %b, data_out %h, send_done %b",
				 receive_start, dut.sync_en, dut.sync_reg, dut.sync_done, serial_in, dut.receive_count, receive_done, data_out, send_done);
	endfunction : displayState

	assign serial_in = serial_out;

	initial begin
		send_start = 1;
		receive_start = 1;
		data_in = {108{2'b10}};
		doReset;
		##1;
		send_start <= 0;
		receive_start <= 0;
		displayState();
		for(int i = 0; i < 12; i++) begin
			##1;
			displayState();
		end
		##209;
		displayState();
		##1;
		displayState();
		##1;
		displayState();
		##1;
		displayState();
		##1;
		displayState();
		assert(data_out == data_in);
		$finish();
	end


endmodule : DataReceiver_testbench