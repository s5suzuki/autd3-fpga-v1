/*
 * File: sync.sv
 * Project: sync
 * Created Date: 05/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 05/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

module sync#(
           parameter int WIDTH = 13
       )(
           input var CLK,
           input var [63:0] SYS_TIME,
           input var [WIDTH-1:0] UPDATE_CYCLE,
           output var UPDATE
       );

update_timing_gen#(
                     .WIDTH(WIDTH)
                 ) update_timing_gen(
                     .*
                 );

endmodule
