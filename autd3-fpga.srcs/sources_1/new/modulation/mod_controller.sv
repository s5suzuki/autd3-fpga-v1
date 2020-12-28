/*
 * File: mod_controller.sv
 * Project: new
 * Created Date: 28/08/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module mod_controller#(
           parameter MOD_BUF_SIZE = 32000,
           localparam MOD_BUF_IDX_WIDTH = $clog2(MOD_BUF_SIZE)
       )(
           mod_bus_if.master_port MOD_BUS,

           input var [MOD_BUF_IDX_WIDTH-1:0] MOD_IDX,
           output var [7:0] MOD_OUT
       );

assign MOD_BUS.MOD_IDX = MOD_IDX;
assign MOD_OUT = MOD_BUS.MOD;

endmodule
