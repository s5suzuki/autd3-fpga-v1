/*
 * File: mod_synchronizer.sv
 * Project: new
 * Created Date: 15/10/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module mod_synchronizer#(
           parameter REF_CLK_FREQ  = 40000,
           parameter REF_CLK_CYCLE_MAX  = 32,
           parameter MOD_BUF_SIZE = 32000,
           localparam REF_CLK_CYCLE_CNT_MAX  = REF_CLK_CYCLE_MAX * REF_CLK_FREQ,
           localparam REF_CLK_CYCLE_CNT_WIDTH  = $clog2(REF_CLK_CYCLE_CNT_MAX),
           localparam MOD_BUF_IDX_WIDTH = $clog2(MOD_BUF_SIZE)
       )(
           input var [REF_CLK_CYCLE_CNT_WIDTH-1:0] REF_CLK_CNT,
           input var [7:0] MOD_IDX_SHIFT,
           output var [MOD_BUF_IDX_WIDTH-1:0] MOD_IDX_OUT
       );

localparam MOD_UPDATE_FREQ_BASE = 8 * 1000;
localparam int MOD_UPDATE_CYCLE_CNT = REF_CLK_FREQ / MOD_UPDATE_FREQ_BASE;

assign MOD_IDX_OUT = (REF_CLK_CNT / MOD_UPDATE_CYCLE_CNT) >> MOD_IDX_SHIFT;

endmodule
