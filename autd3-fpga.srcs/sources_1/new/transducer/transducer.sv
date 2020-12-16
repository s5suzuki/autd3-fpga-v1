/*
 * File: transducer.sv
 * Project: new
 * Created Date: 03/10/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 16/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module transducer(
           input var [9:0] TIME,
           input var [7:0] D,
           input var [7:0] PHASE,
           input var [7:0] DELAY,
           input var SILENT,
           output var PWM_OUT
       );

logic[7:0] d_s, phase_s;

logic[7:0] d, dd;
logic[7:0] phase, phased;

assign d = SILENT ? d_s : D;
assign phase = SILENT ? phase_s : PHASE;

assign update = TIME == 10'd639;

silent_lpf silent_lpf(
               .CLK(TIME[0]),
               .D(D),
               .PHASE(PHASE),
               .D_S(d_s),
               .PHASE_S(phase_s)
           );

delayed_fifo#(.WIDTH(8),
              .DEPTH_RADIX(8))
            delayed_fifo_duty(
                .CLK(update),
                .DELAY(DELAY),
                .DATA_IN(d),
                .DATA_OUT(dd)
            );

delayed_fifo#(.WIDTH(8),
              .DEPTH_RADIX(8))
            delayed_fifo_phase(
                .CLK(update),
                .DELAY(DELAY),
                .DATA_IN(phase),
                .DATA_OUT(phased)
            );

pwm_generator pwm_generator(
                  .TIME(TIME),
                  .D(dd),
                  .PHASE(phased),
                  .PWM_OUT(PWM_OUT)
              );

endmodule
