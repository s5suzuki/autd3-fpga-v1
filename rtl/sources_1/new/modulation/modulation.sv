/*
 * File: modulation.sv
 * Project: modulation
 * Created Date: 07/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 08/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module modulation#(
           parameter int WIDTH = 13,
           parameter int DEPTH = 249,
           parameter [1:0] BRAM_CONFIG_SELECT = 2'h0,
           parameter [1:0] BRAM_MOD_SELECT = 2'h0,
           parameter [13:0] MOD_BRAM_ADDR_OFFSET_ADDR = 14'h0006
       )(
           input var CLK,
           cpu_bus_if.slave_port CPU_BUS,
           input var [63:0] SYS_TIME,
           input var [15:0] MOD_CYCLE,
           input var [31:0] UPDATE_CYCLE,
           input var [WIDTH-1:0] DUTY[0:DEPTH-1],
           output var [WIDTH-1:0] DUTY_M[0:DEPTH-1],
           output var OUT_VALID
       );

bit [7:0] MOD;
bit [15:0] ADDR;
bit UPDATE;

modulation_buffer#(
                     .BRAM_CONFIG_SELECT(BRAM_CONFIG_SELECT),
                     .BRAM_MOD_SELECT(BRAM_MOD_SELECT),
                     .MOD_BRAM_ADDR_OFFSET_ADDR(MOD_BRAM_ADDR_OFFSET_ADDR)
                 ) modulation_buffer(
                     .*
                 );

modulation_sampler modulation_sampler(
                       .*
                   );

modulator#(
             .WIDTH(WIDTH),
             .DEPTH(DEPTH)
         ) modulator(
             .*
         );

endmodule
