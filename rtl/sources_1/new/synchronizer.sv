/*
 * File: synchronizer.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 26/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module synchronizer#(
           parameter int TRANS_NUM = 249,
           parameter int SYS_CLK_FREQ = 20480000,
           parameter int ULTRASOUND_FREQ = 40000,
           parameter int SYNC0_FREQ = 2000,
           localparam int ULTRASOUND_CNT_CYCLE = SYS_CLK_FREQ/ULTRASOUND_FREQ,
           localparam int ULTRASOUND_CNT_CYCLE_WIDTH = $clog2(ULTRASOUND_CNT_CYCLE)
       )
       (
           input var CLK,
           input var SYNC,
           output var [ULTRASOUND_CNT_CYCLE_WIDTH-1:0] TIME,
           output var REF_CLK_TICK,
           output var UPDATE
       );

logic [ULTRASOUND_CNT_CYCLE_WIDTH-1:0] time_cnt_for_ultrasound;

assign TIME = time_cnt_for_ultrasound;
assign UPDATE = SYNC | (time_cnt_for_ultrasound == ULTRASOUND_CNT_CYCLE - 1);

always_ff @(posedge CLK)
    time_cnt_for_ultrasound <= SYNC ? 0 : time_cnt_for_ultrasound + 1;

///////////////////////////////// Reference Clock /////////////////////////////////////////
localparam int REF_CLK_FREQ = ULTRASOUND_FREQ;
localparam int REF_CLK_CYCLE = REF_CLK_FREQ / SYNC0_FREQ;
localparam int REF_CLK_DIVIDER_CYCLE = SYS_CLK_FREQ / REF_CLK_FREQ;
localparam [31:0] REF_CLK_CYCLE_NS = 1000000000 / REF_CLK_FREQ;

localparam int REF_CLK_CYCLE_CNT_WIDTH = $clog2(REF_CLK_CYCLE);
localparam int REF_CLK_DIVIDER_CNT_WIDTH = $clog2(REF_CLK_DIVIDER_CYCLE);

logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt;
logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt_sync;
logic [REF_CLK_DIVIDER_CNT_WIDTH-1:0] ref_clk_divider;
logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt_watch;

assign REF_CLK_TICK = (ref_clk_cnt != ref_clk_cnt_watch);

always_ff @(posedge CLK) begin
    if(SYNC) begin
        ref_clk_cnt <= 0;
        ref_clk_divider <= 0;
    end
    else begin
        if(ref_clk_divider == REF_CLK_DIVIDER_CYCLE - 1) begin
            ref_clk_divider <= 0;
            ref_clk_cnt <= (ref_clk_cnt == REF_CLK_CYCLE - 1) ? 0 : ref_clk_cnt + 1;
        end
        else begin
            ref_clk_divider <= ref_clk_divider + 1;
        end
    end
end

always_ff @(posedge CLK)
    ref_clk_cnt_watch <= ref_clk_cnt;
///////////////////////////////// Reference Clock /////////////////////////////////////////

endmodule
