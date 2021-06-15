/*
 * File: top.sv
 * Project: new
 * Created Date: 27/03/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 15/06/2021
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

localparam int TRANS_NUM = 1;
localparam int SYS_CLK_FREQ = 20400000;
localparam int ULTRASOUND_FREQ = 40000;
localparam int SYNC0_FREQ = 2000;
localparam int ULTRASOUND_CNT_CYCLE = SYS_CLK_FREQ/ULTRASOUND_FREQ;

logic sys_clk;
logic reset;

logic [2:0] sync0;
logic sync0_edge;

logic [15:0] cpu_data_out;

logic [8:0] time_cnt;

logic [15:0] mod_clk_cycle;
logic [15:0] mod_clk_div;
logic [63:0] mod_clk_sync_time;
logic [14:0] mod_idx;
logic [7:0] mod;

logic [15:0] seq_clk_cycle;
logic [15:0] seq_clk_div;
logic [15:0] seq_idx;
logic [15:0] wavelength;
logic [63:0] seq_clk_sync_time;

assign reset = ~RESET_N;
assign CPU_DATA  = (~CPU_CS1_N && ~CPU_RD_N && CPU_RDWR) ? cpu_data_out : 16'bz;
assign sync0_edge = (sync0 == 3'b011);

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
config_bus_if config_bus();
seq_bus_if seq_bus();

mem_manager mem_manager(
                .CLK(sys_clk),
                .CPU_BUS(cpu_bus.slave_port),
                .TR_BUS(tr_bus.master_port),
                .CONFIG_BUS(config_bus.master_port),
                .SEQ_BUS(seq_bus.master_port),
                .MOD_IDX(mod_idx),
                .MOD(mod)
            );

config_manager config_manager(
                   .CLK(sys_clk),
                   .CONFIG_BUS(config_bus.slave_port),
                   .SYNC(sync0_edge),
                   .MOD_CLK_INIT(mod_clk_init),
                   .MOD_CLK_CYCLE(mod_clk_cycle),
                   .MOD_CLK_DIV(mod_clk_div),
                   .MOD_CLK_SYNC_TIME_NS(mod_clk_sync_time),
                   .SEQ_CLK_INIT(seq_clk_init),
                   .SEQ_CLK_CYCLE(seq_clk_cycle),
                   .SEQ_CLK_DIV(seq_clk_div),
                   .SEQ_CLK_SYNC_TIME_NS(seq_clk_sync_time),
                   .WAVELENGTH_UM(wavelength),
                   .SEQ_MODE(seq_mode),
                   .SILENT(silent),
                   .FORCE_FAN(FORCE_FAN),
                   .THERMO(THERMO)
               );

synchronizer#(
                .SYS_CLK_FREQ(SYS_CLK_FREQ),
                .ULTRASOUND_FREQ(ULTRASOUND_FREQ),
                .SYNC0_FREQ(SYNC0_FREQ)
            ) synchronizer(
                .CLK(sys_clk),
                .SYNC(sync0_edge),
                .MOD_CLK_INIT(mod_clk_init),
                .MOD_CLK_CYCLE(mod_clk_cycle),
                .MOD_CLK_DIV(mod_clk_div),
                .MOD_CLK_SYNC_TIME_NS(mod_clk_sync_time),
                .SEQ_CLK_INIT(seq_clk_init),
                .SEQ_CLK_CYCLE(seq_clk_cycle),
                .SEQ_CLK_DIV(seq_clk_div),
                .SEQ_CLK_SYNC_TIME_NS(seq_clk_sync_time),
                .TIME(time_cnt),
                .MOD_IDX(mod_idx),
                .SEQ_IDX(seq_idx)
            );

tr_cntroller#(
                .TRANS_NUM(TRANS_NUM),
                .ULTRASOUND_CNT_CYCLE(ULTRASOUND_CNT_CYCLE)
            ) tr_cntroller(
                .CLK(sys_clk),
                .CLK_LPF(lpf_clk),
                .TIME(time_cnt),
                .TR_BUS(tr_bus.slave_port),
                .MOD(mod),
                .SILENT(silent),
                .SEQ_BUS(seq_bus.slave_port),
                .SEQ_MODE(seq_mode),
                .SEQ_IDX(seq_idx),
                .WAVELENGTH_UM(wavelength),
                .XDCR_OUT(XDCR_OUT)
            );

always_ff @(posedge sys_clk)
    sync0 <= {sync0[1:0], CAT_SYNC0};

// SYNC DBG OUT
logic dbg_0, dbg_0_rst;
logic dbg_1, dbg_1_rst;
logic dbg_2, dbg_2_rst;
logic dbg_3, dbg_3_rst;
logic gpo_0;
logic gpo_1;
logic gpo_2;
logic gpo_3;

assign GPIO_OUT = {gpo_3, gpo_2, gpo_1, gpo_0};

always_ff @(posedge sys_clk) begin
    if(reset) begin
        gpo_0 <= 0;
        gpo_1 <= 0;
        gpo_2 <= 0;
        gpo_3 <= 0;
    end
    else begin
        dbg_0 <= mod_idx == mod_clk_cycle - 1;
        dbg_1 <= seq_idx == seq_clk_cycle - 1;
        dbg_2 <= sync0_edge;
        dbg_3 <= time_cnt == (ULTRASOUND_CNT_CYCLE >> 1);
        dbg_0_rst <= dbg_0 ? 1 : 0;
        dbg_1_rst <= dbg_1 ? 1 : 0;
        dbg_2_rst <= dbg_2 ? 1 : 0;
        dbg_3_rst <= dbg_3 ? 1 : 0;
        gpo_0 <= (dbg_0 & ~dbg_0_rst) ? ~gpo_0 : gpo_0;
        gpo_1 <= (dbg_1 & ~dbg_1_rst) ? ~gpo_1 : gpo_1;
        gpo_2 <= (dbg_2 & ~dbg_2_rst) ? ~gpo_2 : gpo_2;
        gpo_3 <= (dbg_3 & ~dbg_3_rst) ? ~gpo_3 : gpo_3;
    end
end

endmodule
