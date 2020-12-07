/*
 * File: mod_synchronizer.sv
 * Project: new
 * Created Date: 15/10/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

`include "consts.vh"

module mod_synchronizer(
           input var [`REF_CLK_CYCLE_CNT_WIDTH-1:0] REF_CLK_CNT,
           input var [7:0] MOD_IDX_SHIFT,
           output var [`MOD_BUF_IDX_WIDTH-1:0] MOD_IDX_OUT
       );

localparam MOD_UPDATE_FREQ_BASE = 8 * 1000;
localparam int MOD_UPDATE_CYCLE_CNT = `REF_CLK_FREQ / MOD_UPDATE_FREQ_BASE;

logic [`MOD_BUF_IDX_WIDTH-1:0] mod_idx = (REF_CLK_CNT / MOD_UPDATE_CYCLE_CNT) >> MOD_IDX_SHIFT;

assign MOD_IDX_OUT = mod_idx;

endmodule
