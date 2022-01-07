/*
 * File: top.sv
 * Project: new
 * Created Date: 27/03/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 06/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module top(
           input var [16:1] CPU_ADDR,
           inout tri [15:0] CPU_DATA,
           input var CPU_CKIO,
           input var CPU_CS1_N,
           input var RESET_N,
           input var CPU_WE0_N,
           input var CPU_RD_N,
           input var CPU_RDWR,
           input var MRCC_25P6M,
           input var CAT_SYNC0,
           output var FORCE_FAN,
           input var THERMO,
           output var [252:1] XDCR_OUT,
           //    input var [3:0] GPIO_IN,
           output var [3:0] GPIO_OUT
       );

localparam string PHASE_INVERTED = "TRUE";
localparam string ENABLE_MODULATION = "TRUE";
localparam string ENABLE_SILENT = "TRUE";
localparam string ENABLE_SEQUENCE = "TRUE";
localparam string ENABLE_DELAY = "TRUE";
localparam string ENABLE_SYNC_DBG = "TRUE";

localparam int TRANS_NUM = 249;
localparam int SYS_CLK_FREQ = 20480000;
localparam int ULTRASOUND_FREQ = 40000;
localparam int SYNC0_FREQ = 2000;
localparam int ULTRASOUND_CNT_CYCLE = SYS_CLK_FREQ/ULTRASOUND_FREQ;

logic sys_clk;
logic reset;

logic [2:0] sync0;
logic sync0_edge;

logic [15:0] cpu_data_out;

logic [8:0] time_cnt;
logic ref_clk_tick;

logic [15:0] mod_clk_cycle;
logic [15:0] mod_idx;
logic [15:0] seq_clk_cycle;
logic [15:0] seq_idx;

assign reset = ~RESET_N;
assign CPU_DATA  = (~CPU_CS1_N && ~CPU_RD_N && CPU_RDWR) ? cpu_data_out : 16'bz;
assign sync0_edge = (sync0 == 3'b011);

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(reset),
                           .clk_out1(sys_clk),
                           .clk_out2()
                       );

cpu_bus_if cpu_bus();
assign cpu_bus.BUS_CLK = CPU_CKIO;
assign cpu_bus.EN = ~CPU_CS1_N;
assign cpu_bus.WE = ~CPU_WE0_N;
assign cpu_bus.BRAM_SELECT = CPU_ADDR[16:15];
assign cpu_bus.BRAM_ADDR = CPU_ADDR[14:1];
assign cpu_bus.DATA_IN = CPU_DATA;

mod_sync_if mod_sync();
assign mod_sync.REF_CLK_TICK = ref_clk_tick;
assign mod_sync.SYNC = sync0_edge;

seq_sync_if seq_sync();
assign seq_sync.REF_CLK_TICK = ref_clk_tick;
assign seq_sync.SYNC = sync0_edge;

config_manager #(
                   .ENABLE_SILENT(ENABLE_SILENT),
                   .ENABLE_MODULATION(ENABLE_MODULATION),
                   .ENABLE_SEQUENCE(ENABLE_SEQUENCE)
               ) config_manager(
                   .CLK(sys_clk),
                   .CPU_BUS(cpu_bus.slave_port),
                   .DATA_OUT(cpu_data_out),
                   .MOD_SYNC(mod_sync.master_port),
                   .SEQ_SYNC(seq_sync.master_port),
                   .SILENT(silent),
                   .FORCE_FAN(FORCE_FAN),
                   .THERMO(THERMO),
                   .OUTPUT_EN(output_en),
                   .OUTPUT_BALANCE(output_balance)
               );

synchronizer#(
                .TRANS_NUM(TRANS_NUM),
                .SYS_CLK_FREQ(SYS_CLK_FREQ),
                .ULTRASOUND_FREQ(ULTRASOUND_FREQ),
                .SYNC0_FREQ(SYNC0_FREQ)
            ) synchronizer(
                .CLK(sys_clk),
                .SYNC(sync0_edge),
                .TIME(time_cnt),
                .REF_CLK_TICK(ref_clk_tick),
                .UPDATE(update)
            );

tr_cntroller#(
                .TRANS_NUM(TRANS_NUM),
                .ULTRASOUND_CNT_CYCLE(ULTRASOUND_CNT_CYCLE),
                .PHASE_INVERTED(PHASE_INVERTED),
                .ENABLE_MODULATION(ENABLE_MODULATION),
                .ENABLE_SEQUENCE(ENABLE_SEQUENCE),
                .ENABLE_SILENT(ENABLE_SILENT),
                .ENABLE_DELAY(ENABLE_DELAY),
                .ENABLE_SYNC_DBG(ENABLE_SYNC_DBG)
            ) tr_cntroller(
                .CLK(sys_clk),
                .TIME(time_cnt),
                .UPDATE(update),
                .CPU_BUS(cpu_bus.slave_port),
                .MOD_SYNC(mod_sync.slave_port),
                .SEQ_SYNC(seq_sync.slave_port),
                .SILENT(silent),
                .MOD_CLK_CYCLE(mod_clk_cycle),
                .MOD_IDX(mod_idx),
                .SEQ_CLK_CYCLE(seq_clk_cycle),
                .SEQ_IDX(seq_idx),
                .OUTPUT_EN(output_en),
                .OUTPUT_BALANCE(output_balance),
                .XDCR_OUT(XDCR_OUT)
            );

always_ff @(posedge sys_clk)
    sync0 <= {sync0[1:0], CAT_SYNC0};

if (ENABLE_SYNC_DBG == "TRUE") begin
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
            dbg_0 <= mod_idx == mod_clk_cycle;
            dbg_1 <= seq_idx == seq_clk_cycle;
            dbg_2 <= sync0_edge;
            dbg_3 <= time_cnt == (ULTRASOUND_CNT_CYCLE >> 1);
            dbg_0_rst <= dbg_0;
            dbg_1_rst <= dbg_1;
            dbg_2_rst <= dbg_2;
            dbg_3_rst <= dbg_3;
            gpo_0 <= (dbg_0 & ~dbg_0_rst) ? ~gpo_0 : gpo_0;
            gpo_1 <= (dbg_1 & ~dbg_1_rst) ? ~gpo_1 : gpo_1;
            gpo_2 <= (dbg_2 & ~dbg_2_rst) ? ~gpo_2 : gpo_2;
            gpo_3 <= (dbg_3 & ~dbg_3_rst) ? ~gpo_3 : gpo_3;
        end
    end
end

endmodule
