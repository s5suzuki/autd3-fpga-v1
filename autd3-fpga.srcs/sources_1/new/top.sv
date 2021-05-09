/*
 * File: top.sv
 * Project: new
 * Created Date: 27/03/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 09/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module top(
           input var [16:0] CPU_ADDR,
           inout tri [15:0] CPU_DATA,
           input var CPU_CKIO,
           input var CPU_CS1_N,
           input var RESET_N,
           input var CPU_WE0_N,
           input var CPU_WE1_N,
           input var CPU_RD_N,
           input var CPU_RDWR,
           input var MRCC_25P6M,
           input var CAT_SYNC0,
           output var FORCE_FAN,
           input var THERMO,
           output var [252:1] XDCR_OUT,
           input var [3:0]GPIO_IN,
           output var [3:0]GPIO_OUT
       );

localparam int TRANS_NUM = 249;
localparam int SYS_CLK_FREQ = 20400000;
localparam int ULTRASOUND_FREQ = 40000;
localparam int ULTRASOUND_CNT_CYCLE = SYS_CLK_FREQ/ULTRASOUND_FREQ;

logic sys_clk;
logic reset;

assign reset = ~RESET_N;
assign CPU_DATA  = (~CPU_CS1_N && ~CPU_RD_N && CPU_RDWR) ? cpu_data_out : 16'bz;

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(reset),
                           .clk_out1(sys_clk),
                           .clk_out2(lpf_clk)
                       );

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

mem_manager mem_manager(
                .CPU_BUS(cpu_bus.slave_port),
                .TR_BUS(tr_bus.master_port),
                .MOD_BUS(mod_bus.master_port),
                .CONFIG_BUS(config_bus.master_port)
            );

config_manager config_manager(
                   .CLK(sys_clk),
                   .RST(reset),
                   .CONFIG_BUS(config_bus.slave_port),
                   .CLK_SYNC(clk_sync),
                   .FORCE_FAN(FORCE_FAN),
                   .THERMO(THERMO)
               );

logic [8:0] time_cnt;

synchronizer#(
                .SYS_CLK_FREQ(SYS_CLK_FREQ),
                .ULTRASOUND_FREQ(ULTRASOUND_FREQ)
            ) synchronizer(
                .CLK(sys_clk),
                .RST(reset),
                .CAT_SYNC0(CAT_SYNC0),
                .CLK_SYNC(clk_sync),
                .TIME(time_cnt),
                .MOD_BUS(mod_bus.slave_port)
            );

tr_cntroller#(
                .TRANS_NUM(TRANS_NUM),
                .ULTRASOUND_CNT_CYCLE(ULTRASOUND_CNT_CYCLE)
            ) tr_cntroller(
                .CLK(sys_clk),
                .RST(reset),
                .CLK_LPF(lpf_clk),
                .TIME(time_cnt),
                .MOD_BUS(mod_bus.slave_port),
                .TR_BUS(tr_bus.slave_port),
                .XDCR_OUT(XDCR_OUT)
            );
endmodule
