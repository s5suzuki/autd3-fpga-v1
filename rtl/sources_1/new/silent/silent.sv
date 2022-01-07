/*
 * File: silent.sv
 * Project: silent
 * Created Date: 04/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 05/01/2022
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
           input var ENABLE,
           input var UPDATE,
           input var [WIDTH-1:0] STEP,
           input var [WIDTH-1:0] CYCLE[0:DEPTH-1],
           input var [WIDTH-1:0] DUTY[0:DEPTH-1],
           input var [WIDTH-1:0] PHASE[0:DEPTH-1],
           output var [WIDTH-1:0] DUTY_S[0:DEPTH-1],
           output var [WIDTH-1:0] PHASE_S[0:DEPTH-1],
           output var OUT_VALID
       );

silent_lpf_v2 #(
                  .WIDTH(WIDTH),
                  .DEPTH(DEPTH)
              ) silent_lpf_v2(
                  .*
              );

endmodule
