`timescale 1ns / 1ps

module single_cycle_cpu_display(
    //时钟与复位信号
    input clk,
    input resetn,    //后缀"n"代表低电平有效

    //脉冲开关，用于产生脉冲clk，实现单步执行
    input btn_clk,
	
	//控制输出的是什么
	input [1:0]switch,
	
	input [1:0] rf_switch,
	input [3:0] mem_switch,

    output [7:0] figure,
    output [7:0] seg_signal

    );
//-----{调用单周期CPU模块}begin
    reg cpu_clk; //单周期CPU里使用脉冲开关作为时钟，以实现单步执行
    always @(posedge clk)
    begin
        cpu_clk <= btn_clk;
    end
	
    //用于在FPGA板上显示结果
    wire [31:0] cpu_pc;    //CPU的PC
    wire [31:0] cpu_inst;  //该PC取出的指令
    reg [2:0] rf_addr;
    wire [31:0] rf_data;   //寄存器堆从调试端口读出的数据
    wire [31:0] mem_data;  //内存地址对应的数据
    single_cycle_cpu cpu(
        .clk     (cpu_clk ),
        .resetn  (resetn  ),
        .rf_addr ({2'b00,rf_addr}),
        .mem_addr({28'b0000000000000000000000000000,mem_switch}),
        .rf_data (rf_data ),
        .mem_data(mem_data),
        .cpu_pc  (cpu_pc  ),
        .cpu_inst(cpu_inst)
    );
    always @(rf_switch)
    begin
        case(rf_switch)
        2'b00: rf_addr <= 3'b001;
        2'b01: rf_addr <= 3'b010;
        2'b10: rf_addr <= 3'b011;
        2'b11: rf_addr <= 3'b100;
        default: rf_addr <= 3'b000;
        endcase
    end
//-----{调用单周期CPU模块}end
    
	
	reg clkout ;
	reg [31:0]cnt;
	reg [2:0]scan_cnt;
	reg [3:0] display;
    reg [6:0] Y_r;
    reg [7:0] DIG_r ;
	parameter  period= 400000;                                     //!!!!!!!!!!!!!!!!!!!!!500000

	assign figure = {1'b1,(~Y_r[6:0])};
	assign seg_signal =~DIG_r;
	



	always @( posedge clk or negedge resetn)      //分频50Hz
		begin 
		if (!resetn)
			cnt <= 0 ;
		else  begin  
				cnt<= cnt+1;
			if (cnt    == (period >> 1) - 1)               
					clkout <= #1 1'b1;
			else if (cnt == period - 1)                    
				begin 
					clkout <= #1 1'b0;
					 cnt <= #1 'b0;      
				end
			 
			end
		end

	always @(posedge clkout or negedge resetn)          
		begin 
		  if (!resetn)
			scan_cnt <= 0 ;
		else  begin
			scan_cnt <= scan_cnt + 1;    
			if(scan_cnt==3'd7)  scan_cnt <= 0;
			end 
		end
	//片选
	always @( scan_cnt)
		begin 
		case ( scan_cnt )    
			3'b000 : DIG_r <= 8'b10000000;    
			3'b001 : DIG_r <= 8'b01000000;
			3'b010 : DIG_r <= 8'b00100000;    
			3'b011 : DIG_r <= 8'b00010000;    
			3'b100 : DIG_r <= 8'b00001000;    
			3'b101 : DIG_r <= 8'b00000100;    
			3'b110 : DIG_r <= 8'b00000010;     
			3'b111 : DIG_r <= 8'b00000001;    
			default :DIG_r <= 8'b00000000;    
		endcase
		end
	//4选1输出
	always @(switch)
	begin
		if(switch == 2'b00)
		begin
			case (scan_cnt)
			3'b000: display = cpu_pc[3:0]; 
			3'b001: display = cpu_pc[7:4]; 
			3'b010: display = cpu_pc[11:8];
			3'b011: display = cpu_pc[15:12];
			3'b100: display = cpu_pc[19:16];
			3'b101: display = cpu_pc[23:20];
			3'b110: display = cpu_pc[27:24]; 
			3'b111: display = cpu_pc[31:28]; 
			default: display = 4'b0000;
			endcase
		end
		else if(switch == 2'b01)
		begin
			case(scan_cnt)
			3'b000: display = cpu_inst[3:0]; 
			3'b001: display = cpu_inst[7:4]; 
			3'b010: display = cpu_inst[11:8];
			3'b011: display = cpu_inst[15:12];
			3'b100: display = cpu_inst[19:16];
			3'b101: display = cpu_inst[23:20];
			3'b110: display = cpu_inst[27:24]; 
			3'b111: display = cpu_inst[31:28]; 
			default: display = 4'b0000;
			endcase
		end
		else if(switch == 2'b10)
		begin
			case(scan_cnt)
			3'b000: display = rf_data[3:0]; 
			3'b001: display = rf_data[7:4]; 
			3'b010: display = rf_data[11:8];
			3'b011: display = rf_data[15:12];
			3'b100: display = rf_data[19:16];
			3'b101: display = rf_data[23:20];
			3'b110: display = rf_data[27:24]; 
			3'b111: display = rf_data[31:28]; 
			default: display = 4'b0000;
			endcase
		end
		else if(switch == 2'b11)
		begin
			case(scan_cnt)
			3'b000: display = mem_data[3:0]; 
			3'b001: display = mem_data[7:4]; 
			3'b010: display = mem_data[11:8];
			3'b011: display = mem_data[15:12];
			3'b100: display = mem_data[19:16];
			3'b101: display = mem_data[23:20];
			3'b110: display = mem_data[27:24]; 
			3'b111: display = mem_data[31:28]; 
			default: display = 4'b0000;
			endcase
		end
	end
	//显像
	always @(display)
	begin
		case(display)
			4'b0000: Y_r = 7'b0000001; // 0
			4'b0001: Y_r = 7'b1001111; // 1
			4'b0010: Y_r = 7'b0010010; // 2
			4'b0011: Y_r = 7'b0000110; // 3
			4'b0100: Y_r = 7'b1001100; // 4
			4'b0101: Y_r = 7'b0100100; // 5
			4'b0110: Y_r = 7'b0100000; // 6
			4'b0111: Y_r = 7'b0001111; // 7
			4'b1000: Y_r = 7'b0000000; // 8
			4'b1001: Y_r = 7'b0000100; // 9
			4'b1010: Y_r = 7'b0001000; // A
			4'b1011: Y_r = 7'b1100000; // b
			4'b1100: Y_r = 7'b0110001; // c
			4'b1101: Y_r = 7'b1000010; // d
			4'b1110: Y_r = 7'b0110000; // E
			4'b1111: Y_r = 7'b0111000; // F
		endcase
	end
endmodule