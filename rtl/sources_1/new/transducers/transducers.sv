/*
 * File: transducers.sv
 * Project: transducer
 * Created Date: 04/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/01/2022
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
           input var UPDATE,
           input var [WIDTH-1:0] CYCLE[0:TRANS_NUM-1],
           input var [WIDTH-1:0] DUTY[0:TRANS_NUM-1],
           input var [WIDTH-1:0] PHASE[0:TRANS_NUM-1],
           output var PWM_OUT[0:TRANS_NUM-1]
       );

bit OVER[0:TRANS_NUM-1];
bit [WIDTH-1:0] LEFT[0:TRANS_NUM-1];
bit [WIDTH-1:0] RIGHT[0:TRANS_NUM-1];

bit [WIDTH-1:0] TIME_CNT[0:TRANS_NUM-1];

sync_time_cnt_gen#(
                     .WIDTH(WIDTH),
                     .DEPTH(TRANS_NUM)
                 ) sync_time_cnt_gen(
                     .*
                 );

pwm_preconditioner#(
                      .WIDTH(WIDTH),
                      .DEPTH(TRANS_NUM)
                  ) pwm_preconditioner(
                      .CLK(CLK_L),
                      .*
                  );

for (genvar i = 0; i < TRANS_NUM; i++) begin
    pwm_gen#(
               .WIDTH(WIDTH)
           ) pwm_gen(
               .TIME_CNT(TIME_CNT[i]),
               .CYCLE(CYCLE[i]),
               .OVER(OVER[i]),
               .LEFT(LEFT[i]),
               .RIGHT(RIGHT[i]),
               .PWM_OUT(PWM_OUT[i]),
               .*
           );
end

endmodule
