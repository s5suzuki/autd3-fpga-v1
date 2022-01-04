/*
 * File: transducers.sv
 * Project: transducer
 * Created Date: 04/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 04/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

module transducers#(
           parameter int WIDTH = 13,
           parameter int TRANS_NUM = 249
       )(
           input var CLK,
           input var CLK_L,
           input var [63:0] SYS_TIME,
           input var [WIDTH-1:0] UPDATE_CYCLE,
           input var [WIDTH-1:0] CYCLE[0:TRANS_NUM-1],
           input var [WIDTH-1:0] DUTY[0:TRANS_NUM-1],
           input var [WIDTH-1:0] PHASE[0:TRANS_NUM-1],
           output var [252:1] XDCR_OUT
       );

bit OVER[0:TRANS_NUM-1];
bit [WIDTH-1:0] LEFT[0:TRANS_NUM-1];
bit [WIDTH-1:0] RIGHT[0:TRANS_NUM-1];

bit UPDATE;
bit [WIDTH-1:0] TIME_CNT[0:TRANS_NUM-1];

sync_time_cnt_gen sync_time_cnt_gen(
                      .*
                  );

pwm_preconditioner#(
                      .WIDTH(WIDTH),
                      .DEPTH(TRANS_NUM)
                  ) pwm_preconditioner(
                      .CLK(CLK_L),
                      .*
                  );

`include "cvt_uid.vh"
for (genvar ii = 0; ii < TRANS_NUM; ii++) begin
    bit PWM_OUT;
    assign XDCR_OUT[cvt_uid(ii) + 1] = PWM_OUT;
    pwm_gen#(
               .WIDTH(WIDTH)
           ) pwm_gen(
               .TIME_CNT(TIME_CNT[ii]),
               .CYCLE(CYCLE[ii]),
               .OVER(OVER[ii]),
               .LEFT(LEFT[ii]),
               .RIGHT(RIGHT[ii]),
               .*
           );
end

endmodule
