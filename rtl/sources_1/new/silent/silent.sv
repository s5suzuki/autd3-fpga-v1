/*
 * File: silent.sv
 * Project: silent
 * Created Date: 04/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 04/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

module silent#(
           parameter int WIDTH = 13,
           parameter int DEPTH = 249
       )(
           input var CLK,
           input var [63:0] SYS_TIME,
           input var ENABLE,
           input var [WIDTH-1:0] UPDATE_CYCLE,
           input var [WIDTH-1:0] STEP,
           input var [WIDTH-1:0] CYCLE[0:DEPTH-1],
           input var [WIDTH-1:0] DUTY[0:DEPTH-1],
           input var [WIDTH-1:0] PHASE[0:DEPTH-1],
           output var [WIDTH-1:0] DUTY_S[0:DEPTH-1],
           output var [WIDTH-1:0] PHASE_S[0:DEPTH-1]
       );

bit UPDATE;

silent_timing_gen#(
                     .WIDTH(WIDTH)
                 ) silent_timing_gen(
                     .*
                 );

silent_lpf_v2 #(
                  .WIDTH(WIDTH),
                  .DEPTH(DEPTH)
              ) silent_lpf_v2(
                  .*
              );

endmodule
