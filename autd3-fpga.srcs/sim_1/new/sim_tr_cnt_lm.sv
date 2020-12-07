`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/16/2020 05:20:38 PM
// Design Name:
// Module Name: sim_tr_cnt_lm
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module sim_tr_cnt_lm();

parameter TCO = 10; // bus delay 10ns
parameter BRAM_MOD_SELECT = 8'd250;
parameter BRAM_MOD_OFFSET_SELECT = 8'd251;

reg[1:0]bram_select;
reg[13:0]bram_addr;

wire [15:0] CPU_DATA;
reg CPU_CKIO;
reg CPU_CS1_N;
reg CPU_WE0_N;
reg MRCC_25P6M;

reg [15:0] lm_idx;

reg [15:0] CPU_DATA_READ;

reg [15:0] bus_data_reg = 16'bz;
assign CPU_DATA = bus_data_reg;

transducer_controller transducer_controller(
                          .BUS_CLK(CPU_CKIO),
                          .BRAM_SELECT(bram_select),
                          .EN(~CPU_CS1_N),
                          .WE(~CPU_WE0_N),
                          .ADDR(bram_addr),
                          .DATA_IN(CPU_DATA),

                          .SYS_CLK(MRCC_25P6M),
                          .TIME(),
                          .LM_IDX(lm_idx),
                          .LM_CLK_DIV(16'd1),
                          .MOD_IDX(),
                          .SILENT(),
                          .OP_MODE(1'b0),
                          .XDCR_OUT()
                      );

task bram_write (input [1:0] select, input [13:0] addr, input [15:0] data_in);
    repeat (20) @(posedge CPU_CKIO);
    bram_select <= #(TCO) select;
    bram_addr <= #(TCO) addr;
    CPU_CS1_N <= #(TCO) 0;
    bus_data_reg <= #(TCO) data_in;
    @(posedge CPU_CKIO);
    @(negedge CPU_CKIO);

    CPU_WE0_N <= #(TCO) 0;
    repeat (10) @(posedge CPU_CKIO);

    @(negedge CPU_CKIO);
    CPU_WE0_N <= #(TCO) 1;
endtask

task focus_write(input [15:0] idx, input signed [23:0] x, input signed [23:0] y, input signed [23:0] z, input [7:0] amp);
    bram_write(2'd3, idx * 8, x[15:0]);
    bram_write(2'd3, idx * 8 + 1, {y[7:0], x[23:16]});
    bram_write(2'd3, idx * 8 + 2, y[23:8]);
    bram_write(2'd3, idx * 8 + 3, z[15:0]);
    bram_write(2'd3, idx * 8 + 4, {amp, z[23:16]});
endtask

initial begin
    MRCC_25P6M = 1;
    CPU_CKIO = 1;
    CPU_CS1_N = 0;
    CPU_WE0_N = 1;
    bus_data_reg = 16'bz;
    lm_idx = 0;
    bram_select = 0;
    bram_addr = 0;

    #(10);
    focus_write(0, 24'sd0, 24'sd0, 24'sd0, 8'haa);
    focus_write(1, 24'sd10, 24'sd10, 24'sd0, 8'hbb);
    focus_write(2, 24'sd10, 24'sd10, 24'sd10, 8'hcc);
    focus_write(3, 24'sd100, 24'sd10, 24'sd10, 8'hdd);
    bram_write(0, 14'h00FF, 16'd1);
    focus_write(0, 24'sd0, 24'sd0, 24'sd1, 8'h1a);
    focus_write(1, 24'sd10, 24'sd10, 24'sd1, 8'h1b);
    focus_write(2, 24'sd10, 24'sd10, 24'sd1, 8'h1c);
    focus_write(3, 24'sd100, 24'sd10, 24'sd1, 8'h1d);
    
    #(10);
    lm_idx = 1;
    repeat (640) @(posedge MRCC_25P6M);
    lm_idx = 2;
    repeat (640) @(posedge MRCC_25P6M);
    lm_idx = 3;
    repeat (640) @(posedge MRCC_25P6M);
    lm_idx = 0;
    repeat (640) @(posedge MRCC_25P6M);
    lm_idx = 1;
    repeat (640) @(posedge MRCC_25P6M);
    lm_idx = 2;
    repeat (640) @(posedge MRCC_25P6M);
    lm_idx = 3;
    repeat (640) @(posedge MRCC_25P6M);
    lm_idx = 0;
    repeat (640) @(posedge MRCC_25P6M);
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

always
    #6.65 CPU_CKIO = !CPU_CKIO; // bus clock 75MHz

endmodule
