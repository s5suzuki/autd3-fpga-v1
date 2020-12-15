/*
 * File: transducer.sv
 * Project: new
 * Created Date: 03/10/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 15/12/2020
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
           input var SILENT,
           output var PWM_OUT
       );

logic[7:0] d_s, phase_s;

logic[7:0] d = SILENT ? d_s : D;
logic[7:0] phase = SILENT ? phase_s : PHASE;

silent_lpf silent_lpf(
               .CLK(TIME[0]),
               .D(D),
               .PHASE(PHASE),
               .D_S(d_s),
               .PHASE_S(phase_s)
           );

pwm_generator pwm_generator(
                  .TIME(TIME),
                  .D(d),
                  .PHASE(phase),
                  .PWM_OUT(PWM_OUT)
              );

endmodule
