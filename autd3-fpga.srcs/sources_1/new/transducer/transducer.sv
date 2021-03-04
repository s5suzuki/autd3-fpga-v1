/*
 * File: transducer.sv
 * Project: new
 * Created Date: 03/10/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 04/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module transducer(
           input var CLK,
           input var CLK_LPF,
           input var [9:0] TIME,
           input var [7:0] D,
           input var [7:0] PHASE,
           input var [7:0] DELAY,
           input var SILENT,
           output var PWM_OUT
       );

logic[7:0] d_s, phase_s;

logic[7:0] d, phase;
logic[15:0] delayed;

assign d = SILENT ? d_s : D;
assign phase = SILENT ? phase_s : PHASE;

assign update = (TIME == 10'd639);

silent_lpf silent_lpf(
               .CLK(CLK),
               .CLK_LPF(CLK_LPF),
               .UPDATE(update),
               .D(D),
               .PHASE(PHASE),
               .D_S(d_s),
               .PHASE_S(phase_s)
           );

delayed_fifo#(.WIDTH(8),
              .DEPTH_RADIX(8))
            delayed_fifo_duty(
                .CLK(CLK),
                .UPDATE(update),
                .DELAY(DELAY),
                .DATA_IN({phase, d}),
                .DATA_OUT(delayed)
            );

pwm_generator pwm_generator(
                  .TIME(TIME),
                  .D(delayed[7:0]),
                  .PHASE(delayed[15:8]),
                  .PWM_OUT(PWM_OUT)
              );

endmodule
