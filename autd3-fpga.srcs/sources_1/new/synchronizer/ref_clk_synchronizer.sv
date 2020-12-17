/*
 * File: ref_clk_synchronizer.sv
 * Project: new
 * Created Date: 26/06/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module ref_clk_synchronizer#(
           parameter SYS_CLK_FREQ = 25600000,
           parameter SYNC_FREQ = 1000,
           parameter REF_CLK_FREQ = 40000,
           parameter REF_CLK_CYCLE_BASE = 1,
           parameter REF_CLK_CYCLE_MAX = 32,
           parameter SYNC_CYCLE_CNT = 40,

           localparam STM_LAP_CYCLE_CNT = 1 * SYNC_FREQ,
           localparam REF_CLK_CYCLE_CNT_MAX = REF_CLK_CYCLE_MAX * REF_CLK_FREQ,
           localparam REF_CLK_CYCLE_CNT_BASE = REF_CLK_CYCLE_BASE * REF_CLK_FREQ,
           localparam REF_CLK_CYCLE_CNT_WIDTH = $clog2(REF_CLK_CYCLE_CNT_MAX),
           localparam STM_LAP_CYCLE_CNT_WIDTH = $clog2(STM_LAP_CYCLE_CNT)
       )(
           input var SYS_CLK,
           input var RST,
           input var SYNC,
           input var REF_CLK_INIT,
           input var [7:0] REF_CLK_CYCLE_SHIFT,
           output var REF_CLK_INIT_DONE_OUT,
           output var [REF_CLK_CYCLE_CNT_WIDTH-1:0] REF_CLK_CNT_OUT,
           output var [STM_LAP_CYCLE_CNT_WIDTH-1:0] LAP_CNT_OUT
       );

localparam int REF_CLK_DIVIDER_CNT = (SYS_CLK_FREQ / REF_CLK_FREQ);
localparam int REF_CLK_DIVIDER_CNT_WIDTH = $clog2(REF_CLK_DIVIDER_CNT);

logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt = 0;
logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt_sync = 0;
logic [REF_CLK_DIVIDER_CNT_WIDTH-1:0] ref_clk_divider = 0;

logic [STM_LAP_CYCLE_CNT_WIDTH-1:0] lap = 0;
logic ref_clk_init_flag = 0;
logic ref_clk_init_done = 0;

logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cycle;

assign REF_CLK_INIT_DONE_OUT = ref_clk_init_done;
assign REF_CLK_CNT_OUT = ref_clk_cnt;
assign LAP_CNT_OUT = lap;

assign ref_clk_cycle = (REF_CLK_CYCLE_CNT_BASE) << REF_CLK_CYCLE_SHIFT;

always_ff @(posedge SYS_CLK) begin
    if(RST) begin
        ref_clk_init_flag <= 0;
        ref_clk_init_done <= 0;
    end
    else begin
        if(REF_CLK_INIT) begin
            ref_clk_init_flag <= 1;
            ref_clk_init_done <= 0;
        end
        else begin
            if (SYNC) begin
                if (ref_clk_init_flag) begin
                    ref_clk_cnt <= 0;
                    ref_clk_cnt_sync <= 0;
                    lap <= 0;
                    ref_clk_init_flag <= 0;
                    ref_clk_init_done <= 1;
                end
                else begin
                    ref_clk_cnt <= ref_clk_cnt_sync + SYNC_CYCLE_CNT < ref_clk_cycle ? (ref_clk_cnt_sync + SYNC_CYCLE_CNT) : 0;
                    ref_clk_cnt_sync <= ref_clk_cnt_sync + SYNC_CYCLE_CNT < ref_clk_cycle ? (ref_clk_cnt_sync + SYNC_CYCLE_CNT) : 0;
                    lap <= (lap == STM_LAP_CYCLE_CNT - 1) ? 0 : lap + 1;
                end
                ref_clk_divider <= 0;
            end
            else begin
                if(ref_clk_divider == REF_CLK_DIVIDER_CNT - 1) begin
                    ref_clk_divider <= 0;
                    ref_clk_cnt <= (ref_clk_cnt == ref_clk_cycle - 1) ? 0 : ref_clk_cnt + 1;
                end
                else begin
                    ref_clk_divider <= ref_clk_divider + 1;
                end
                ref_clk_init_done <= 0;
            end
        end
    end
end

endmodule
