`timescale 1ns / 1ps
module testbench();

	//Input
	reg clk;
	reg resetn;
	reg btn_clk;
	reg [1:0] switch;
	reg [1:0] rf_switch;
	reg [3:0] mem_switch;
	
	//Output
	wire [7:0] figure;
	wire [7:0] seg_signal;
	
	
	single_cycle_cpu_display uut
	(
		.clk(clk),
		.resetn(resetn),
		.btn_clk(btn_clk),
		.switch(switch),
		.rf_switch(rf_switch),
		.mem_switch(mem_switch),
		.figure(figure),
		.seg_signal(seg_signal)
	);
	
	initial
	begin
		clk = 0;
		resetn = 0;
		btn_clk = 0;
		switch = 0;
		rf_switch = 1;
		mem_switch = 0;
	end
	
	
	always #10
	begin
		clk = ~clk;		
	end
	always #100
	   resetn = 1;
	always #40
		btn_clk = ~btn_clk;
	always #50
	begin
		rf_switch = rf_switch + 1;
		mem_switch = mem_switch + 1;
		switch = switch +1;
	end
endmodule