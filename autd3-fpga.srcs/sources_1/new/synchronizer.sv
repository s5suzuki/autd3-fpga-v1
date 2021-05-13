/*
 * File: synchronizer.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 13/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module synchronizer#(
           parameter int SYS_CLK_FREQ = 20400000,
           parameter int ULTRASOUND_FREQ = 40000,
           parameter int SYNC0_FREQ = 1000,
           parameter int REF_CLK_CYCLE_BASE = 1,
           parameter int REF_CLK_CYCLE_MAX = 32,
           localparam int ULTRASOUND_CNT_CYCLE = SYS_CLK_FREQ/ULTRASOUND_FREQ,
           localparam int ULTRASOUND_CNT_CYCLE_WIDTH = $clog2(ULTRASOUND_CNT_CYCLE)
       )
       (
           input var CLK,
           input var RST,
           input var SYNC,
           input var REF_CLK_INIT,
           input var [7:0] REF_CLK_CYCLE_SHIFT,
           input var [7:0] MOD_IDX_SHIFT,
           input var SEQ_CLK_INIT,
           input var [15:0] SEQ_CLK_CYCLE,
           input var [15:0] SEQ_CLK_DIV,
           output var [ULTRASOUND_CNT_CYCLE_WIDTH-1:0] TIME,
           output var [14:0] MOD_IDX,
           output var [15:0] SEQ_IDX
       );


logic [ULTRASOUND_CNT_CYCLE_WIDTH-1:0] time_cnt_for_ultrasound;

assign TIME = time_cnt_for_ultrasound;

always_ff @(posedge CLK)
    time_cnt_for_ultrasound <= (RST | SYNC | (time_cnt_for_ultrasound == ULTRASOUND_CNT_CYCLE - 1)) ? 0 : time_cnt_for_ultrasound + 1;

///////////////////////////////// Reference Clock /////////////////////////////////////////
localparam int REF_CLK_FREQ = ULTRASOUND_FREQ;
localparam int SYNC_CYCLE_CNT = REF_CLK_FREQ/SYNC0_FREQ;
localparam int REF_CLK_CYCLE_CNT_BASE = REF_CLK_CYCLE_BASE * REF_CLK_FREQ;
localparam int REF_CLK_CYCLE_CNT_MAX = REF_CLK_CYCLE_MAX * REF_CLK_FREQ;
localparam int REF_CLK_DIVIDER_CNT = SYS_CLK_FREQ / REF_CLK_FREQ;

localparam int REF_CLK_CYCLE_CNT_WIDTH = $clog2(REF_CLK_CYCLE_CNT_MAX);
localparam int REF_CLK_DIVIDER_CNT_WIDTH = $clog2(REF_CLK_DIVIDER_CNT);

logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt;
logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt_sync;
logic [REF_CLK_DIVIDER_CNT_WIDTH-1:0] ref_clk_divider;

logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cycle;

assign ref_clk_cycle = REF_CLK_CYCLE_CNT_BASE << REF_CLK_CYCLE_SHIFT;

always_ff @(posedge CLK) begin
    if(RST | (SYNC & REF_CLK_INIT)) begin
        ref_clk_cnt <= 0;
        ref_clk_cnt_sync <= 0;
        ref_clk_divider <= 0;
    end
    else begin
        if (SYNC) begin
            ref_clk_cnt <= ref_clk_cnt_sync + SYNC_CYCLE_CNT < ref_clk_cycle ? (ref_clk_cnt_sync + SYNC_CYCLE_CNT) : 0;
            ref_clk_cnt_sync <= ref_clk_cnt_sync + SYNC_CYCLE_CNT < ref_clk_cycle ? (ref_clk_cnt_sync + SYNC_CYCLE_CNT) : 0;
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
        end
    end
end
///////////////////////////////// Reference Clock /////////////////////////////////////////

//////////////////////////////////// Modulation ///////////////////////////////////////////
localparam int MOD_UPDATE_FREQ_BASE = 8 * 1000;
localparam int MOD_UPDATE_CYCLE_CNT = REF_CLK_FREQ / MOD_UPDATE_FREQ_BASE;

assign MOD_IDX = (ref_clk_cnt / MOD_UPDATE_CYCLE_CNT) >> MOD_IDX_SHIFT;
//////////////////////////////////// Modulation ///////////////////////////////////////////

////////////////////////////////// Sequence Clock /////////////////////////////////////////
logic [15:0] seq_cnt;
logic [15:0] seq_cnt_div;
logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt_watch;
logic ref_clk_tick;

assign SEQ_IDX = seq_cnt;
assign ref_clk_tick = (ref_clk_cnt != ref_clk_cnt_watch);

always_ff @(posedge SYS_CLK)
    ref_clk_cnt_watch <= RST ? 0 : ref_clk_cnt;

always_ff @(posedge SYS_CLK) begin
    if(RST | (SYNC & SEQ_CLK_INIT)) begin
        seq_cnt <= 0;
        seq_cnt_div <= 0;
    end
    else if(ref_clk_tick) begin
        if(seq_cnt_div == SEQ_CLK_DIV - 1) begin
            seq_cnt_div <= 0;
            seq_cnt <= (seq_cnt == SEQ_CLK_CYCLE - 1) ? 0 : seq_cnt + 1;
        end
        else begin
            seq_cnt_div <= seq_cnt_div + 1;
        end
    end
end
////////////////////////////////// Sequence Clock /////////////////////////////////////////

endmodule
