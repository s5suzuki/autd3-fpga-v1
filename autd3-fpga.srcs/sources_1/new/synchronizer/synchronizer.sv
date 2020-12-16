/*
 * File: synchronizer.sv
 * Project: new
 * Created Date: 18/06/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 16/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

`include "consts.vh"

module synchronizer(
           input var SYS_CLK,
           input var RST,
           input var SYNC,

           input var [7:0] REF_CLK_CYCLE_SHIFT,

           input var REF_CLK_INIT,
           output var REF_CLK_INIT_DONE_OUT,

           input var STM_CLK_INIT,
           input var [15:0] STM_CLK_CYCLE,
           output var [10:0] LAP_OUT,
           input var STM_CLK_CALIB,
           input var [15:0] STM_CLK_CALIB_SHIFT,
           output var STM_CLK_CALIB_DONE_OUT,

           input var [7:0] MOD_IDX_SHIFT,

           output var [`TIME_CNT_CYCLE_WIDTH-1:0] TIME_CNT_OUT,
           output var [`MOD_BUF_IDX_WIDTH-1:0] MOD_IDX_OUT,
           output var [15:0] STM_IDX_OUT
       );

logic [`TIME_CNT_CYCLE_WIDTH-1: 0] time_cnt = 0;

logic [`REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt;
logic [`STM_LAP_CYCLE_CNT_WIDTH-1:0] lap;
logic [`STM_LAP_CYCLE_CNT_WIDTH:0] stm_clk_init_lap;

logic [`REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt_watch = 0;
logic ref_clk_tick = (ref_clk_cnt != ref_clk_cnt_watch);

assign TIME_CNT_OUT = time_cnt;
assign LAP_OUT = stm_clk_init_lap;

initial begin
    time_cnt = 0;
    ref_clk_cnt_watch = 0;
end

ref_clk_synchronizer ref_clk_synchronizer(
                         .SYS_CLK(SYS_CLK),
                         .RST(RST),
                         .SYNC(SYNC),
                         .REF_CLK_INIT(REF_CLK_INIT),
                         .REF_CLK_CYCLE_SHIFT(REF_CLK_CYCLE_SHIFT),
                         .REF_CLK_INIT_DONE_OUT(REF_CLK_INIT_DONE_OUT),
                         .REF_CLK_CNT_OUT(ref_clk_cnt),
                         .LAP_CNT_OUT(lap)
                     );

mod_synchronizer mod_synchronizer(
                     .REF_CLK_CNT(ref_clk_cnt),
                     .MOD_IDX_SHIFT(MOD_IDX_SHIFT),
                     .MOD_IDX_OUT(MOD_IDX_OUT)
                 );

stm_synchronizer stm_synchronizer(
                     .SYS_CLK(SYS_CLK),
                     .RST(RST),
                     .SYNC(SYNC),

                     .REF_CLK_TICK(ref_clk_tick),

                     .STM_CLK_INIT(STM_CLK_INIT),
                     .STM_CLK_CYCLE(STM_CLK_CYCLE),
                     .LAP(lap),
                     .STM_INIT_LAP_OUT(stm_clk_init_lap),
                     .STM_CLK_CALIB(STM_CLK_CALIB),
                     .STM_CLK_CALIB_SHIFT(STM_CLK_CALIB_SHIFT),
                     .STM_CLK_CALIB_DONE_OUT(STM_CLK_CALIB_DONE_OUT),

                     .STM_CLK_OUT(STM_IDX_OUT)
                 );

always_ff @(posedge SYS_CLK) begin
    if ((time_cnt == `TIME_CNT_CYCLE - 10'd1) || SYNC || RST) begin
        time_cnt <= 10'd0;
    end
    else begin
        time_cnt <= time_cnt + 1;
    end
end

always_ff @(posedge SYS_CLK) begin
    if (ref_clk_cnt != ref_clk_cnt_watch) begin
        ref_clk_cnt_watch <= ref_clk_cnt;
    end
end

endmodule
