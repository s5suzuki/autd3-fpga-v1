/*
 * File: sim_config_manager.sv
 * Project: new
 * Created Date: 12/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 12/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module sim_config_manager();

logic MRCC_25P6M;
logic RST;
logic CAT_SYNC0;

logic sys_clk;
logic sync;
logic [2:0] sync0_edge;
assign sync = sync0_edge == 3'b011;

logic ref_clk_init;
logic [7:0] ref_clk_cyc_shift;
logic [7:0] mod_idx_shift;

logic soft_rst;
logic force_fan;

// CPU
parameter TCO = 10; // bus delay 10ns
logic[15:0]bram_addr;
logic [16:0] CPU_ADDR;
assign CPU_ADDR = {bram_addr, 1'b1};
logic [15:0] CPU_DATA;
logic CPU_CKIO;
logic CPU_CS1_N;
logic CPU_WE0_N;
logic MRCC_25P6M;
logic [15:0] CPU_DATA_READ;
logic [15:0] bus_data_reg = 16'bz;
assign CPU_DATA = bus_data_reg;

cpu_bus_if cpu_bus();
assign cpu_bus.BUS_CLK = CPU_CKIO;
assign cpu_bus.EN = ~CPU_CS1_N;
assign cpu_bus.WE = ~CPU_WE0_N;
assign cpu_bus.BRAM_SELECT = CPU_ADDR[16:15];
assign cpu_bus.BRAM_ADDR = CPU_ADDR[14:1];
assign cpu_bus.DATA_IN = CPU_DATA;
assign cpu_data_out = cpu_bus.DATA_OUT;

tr_bus_if tr_bus();
mod_bus_if mod_bus();
config_bus_if config_bus();

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(RST),
                           .clk_out1(sys_clk),
                           .clk_out2()
                       );

mem_manager mem_manager(
                .CLK(sys_clk),
                .CPU_BUS(cpu_bus.slave_port),
                .CONFIG_BUS(config_bus.master_port),
                .MOD_BUS(mod_bus.master_port),
                .TR_BUS(tr_bus.master_port)
            );

config_manager config_manager(
                   .CLK(sys_clk),
                   .RST(RST),
                   .CONFIG_BUS(config_bus.slave_port),
                   .SYNC(sync),
                   .REF_CLK_INIT(ref_clk_init),
                   .REF_CLK_CYCLE_SHIFT(ref_clk_cyc_shift),
                   .MOD_IDX_SHIFT(mod_idx_shift),
                   .SILENT(silent),
                   .FORCE_FAN(force_fan),
                   .THERMO(1'b0)
               );

task bram_write (input [13:0] addr, input [15:0] data_in);
    repeat (20) @(posedge CPU_CKIO);
    bram_addr <= #(TCO) {2'b00, addr};
    CPU_CS1_N <= #(TCO) 0;
    bus_data_reg <= #(TCO) data_in;
    @(posedge CPU_CKIO);
    @(negedge CPU_CKIO);

    CPU_WE0_N <= #(TCO) 0;
    repeat (10) @(posedge CPU_CKIO);

    @(negedge CPU_CKIO);
    CPU_WE0_N <= #(TCO) 1;
endtask


initial begin
    MRCC_25P6M = 1;
    RST = 1;
    CAT_SYNC0 = 0;
    CPU_CKIO = 1;
    CPU_CS1_N = 0;
    CPU_WE0_N = 1;
    CPU_DATA_READ = 0;
    bus_data_reg = 16'bz;
    bram_addr = #(TCO) 16'd0;
    #(1000);
    RST = 0;

    #(1000);
    bram_write(0, 16'h0100);
end

always @(posedge sys_clk) begin
    sync0_edge <= RST ? 0 : {sync0_edge[1:0], CAT_SYNC0};
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

// bus clock 75MHz
always
    #6.65 CPU_CKIO = ~CPU_CKIO;


always begin
    #999200  CAT_SYNC0 = 1; // sync0 1kHz
    #800 CAT_SYNC0 = 0;
end

endmodule
