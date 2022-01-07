/*
 * File: modulation_sampler.sv
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
module modulation_sampler(
           input var CLK,
           input var [63:0] SYS_TIME,
           input var [15:0] MOD_CYCLE,
           input var [31:0] UPDATE_CYCLE,
           output var [15:0] ADDR
       );

bit UPDATE;

update_timing_gen#(
                     .WIDTH(32)
                 ) update_timing_gen(
                     .*
                 );

endmodule
