/*
 * File: silent_timing_gen.sv
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

`timescale 1ns / 1ps
module silent_timing_gen#(
           parameter int WIDTH = 13
       )(
           input var CLK,
           input var [63:0] SYS_TIME,
           input var [WIDTH-1:0] UPDATE_CYCLE,
           output var UPDATE
       );

bit [WIDTH-1:0] update_t = 0;

assign UPDATE = (update_t == 0);

always_ff @(posedge CLK) begin
    update_t <= (update_t == UPDATE_CYCLE - 1) ? 0 : update_t + 1;
end

endmodule
