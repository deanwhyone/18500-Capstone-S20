/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * Simulation testbench for data sender module
 */
 `default_nettype none

module DataSender_testbench
	import NetworkPkg::*,
		   DisplayPkg::*;
();
	logic clk, rst_l, send_start, send_done, serial_out;
	logic [ENC_DATA_BITS-1:0] data_in;

	default clocking cb_main @(posedge clk); endclocking

	DataSender dut(.*);

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
		$display("send_start: %b, send_en: %b, data_reg: %h, serial_out: %b, sent_count: %0d, send_done: %b",
				 send_start, dut.send_en, dut.data_reg, serial_out, dut.sent_count, send_done);
	endfunction : displayState

	initial begin
		send_start = 1;
		data_in = {108{2'b10}};
		doReset;
		##1;
		send_start <= 0;
		displayState();
		for(int i = 0; i < 12; i++) begin
			##1;
			displayState();
		end
		##216;
		displayState();
		$finish();
	end


endmodule // DataSender_testbench