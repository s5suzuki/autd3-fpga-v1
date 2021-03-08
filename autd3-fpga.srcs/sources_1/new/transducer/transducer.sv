/*
 * File: transducer.sv
 * Project: new
 * Created Date: 03/10/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 06/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module transducer(
           input var CLK,
           input var RST,
           input var CLK_LPF,
           input var [9:0] TIME,
           input var [7:0] D,
           input var [7:0] PHASE,
           input var SILENT,
           output var PWM_OUT
       );

logic[7:0] d_s, phase_s;

logic[7:0] d, phase;

assign d = SILENT ? d_s : D;
assign phase = SILENT ? phase_s : PHASE;

assign update = (TIME == 10'd639);

silent_lpf silent_lpf(
               .CLK(CLK),
               .RST(RST),
               .CLK_LPF(CLK_LPF),
               .UPDATE(update),
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
