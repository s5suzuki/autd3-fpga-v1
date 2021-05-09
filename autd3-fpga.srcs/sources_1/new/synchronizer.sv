/*
 * File: synchronizer.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 09/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module synchronizer#(
           parameter int SYS_CLK_FREQ = 20400000,
           parameter int ULTRASOUND_FREQ = 40000
       )
       (
           input var CLK,
           input var RST,
           input var CAT_SYNC0,
           input var CLK_SYNC,
           output var [8:0] TIME,
           mod_bus_if.slave_port MOD_BUS
       );

localparam int REF_CLK_CNT_CYCLE = 20400000;
localparam int ULTRASOUND_CNT_CYCLE = SYS_CLK_FREQ/ULTRASOUND_FREQ;

localparam int SYNC0_FREQ = 1000;
localparam int REF_CLK_SYNC_STEP = SYS_CLK_FREQ/SYNC0_FREQ;

localparam int MOD_FREQ = 4000;
localparam int MOD_BUF_SIZE = 4000;
localparam int MOD_CNT_CYCLE = SYS_CLK_FREQ/MOD_FREQ;

logic [2:0] sync0;
logic sync0_edge;
logic clk_sync;
logic clk_sync_rst;

logic [$clog2(REF_CLK_CNT_CYCLE)-1:0] ref_clk_cnt;
logic [$clog2(REF_CLK_CNT_CYCLE)-1:0] ref_clk_cnt_sync;

logic [8:0] time_cnt_for_ultrasound;

assign sync0_edge = (sync0 == 3'b011);
assign MOD_BUS.IDX = ref_clk_cnt/MOD_CNT_CYCLE;
assign clk_sync = CLK_SYNC;
assign TIME = time_cnt_for_ultrasound;

always_ff @(posedge CLK) begin
    if (RST) begin
        sync0 <= 0;
    end
    else begin
        sync0 <= {sync0[1:0], CAT_SYNC0};
    end
end

always_ff @(posedge CLK) begin
    if (RST | sync0_edge) begin
        time_cnt_for_ultrasound <= 0;
    end
    else begin
        time_cnt_for_ultrasound <= (time_cnt_for_ultrasound == (ULTRASOUND_CNT_CYCLE - 1)) ? 0 : time_cnt_for_ultrasound + 1;
    end
end

always_ff @(posedge CLK) begin
    if (RST) begin
        clk_sync_rst <= 0;
    end
    else if (sync0_edge) begin
        if (clk_sync) begin
            clk_sync_rst <= 1;
        end
        else begin
            clk_sync_rst <= 0;
        end
    end
end

always_ff @(posedge CLK) begin
    if (RST | (sync0_edge & clk_sync & ~clk_sync_rst)) begin
        ref_clk_cnt <= 0;
        ref_clk_cnt_sync <= 0;
    end
    else if (sync0_edge) begin
        if (ref_clk_cnt_sync + REF_CLK_SYNC_STEP == REF_CLK_CNT_CYCLE) begin
            ref_clk_cnt <= 0;
            ref_clk_cnt_sync <= 0;
        end
        else begin
            ref_clk_cnt <= ref_clk_cnt_sync + REF_CLK_SYNC_STEP;
            ref_clk_cnt_sync <= ref_clk_cnt_sync + REF_CLK_SYNC_STEP;
        end
    end
    else begin
        ref_clk_cnt <= (ref_clk_cnt == (REF_CLK_CNT_CYCLE - 1)) ? 0 : ref_clk_cnt + 1;
    end
end

endmodule
