/*
 * File: modulation.sv
 * Project: modulation
 * Created Date: 07/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module modulation#(
           parameter int WIDTH = 13,
           parameter int DEPTH = 249
       )(
           input var CLK,
           input var [63:0] SYS_TIME,
           input var [15:0] MOD_CYCLE,
           input var [31:0] UPDATE_CYCLE,
           input var [WIDTH-1:0] DUTY[0:DEPTH-1],
           output var [WIDTH-1:0] DUTY_M[0:DEPTH-1],
           output var OUT_VALID
       );

bit [7:0] MOD;
bit [15:0] ADDR;

modulation_buffer modulation_buffer(
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
