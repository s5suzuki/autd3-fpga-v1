/*
 * File: transducer.sv
 * Project: transducer
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 18/06/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module transducer#(
           parameter int ULTRASOUND_CNT_CYCLE = 510,
           parameter int DELAY_DEPTH = 8
       )(
           input var CLK,
           input var CLK_LPF,
           input var [8:0] TIME,
           input var UPDATE,
           input var [7:0] DUTY,
           input var [7:0] PHASE,
           input var [DELAY_DEPTH-1:0] DELAY,
           input var SILENT,
           output var PWM_OUT
       );

logic [7:0] duty_s, phase_s;
logic [7:0] duty, dutyd;
logic [7:0] phase;

assign duty = SILENT ? duty_s : DUTY;

silent_lpf silent_lpf(
               .CLK(CLK),
               .CLK_LPF(CLK_LPF),
               .DUTY(DUTY),
               .PHASE(PHASE),
               .DUTY_S(duty_s),
               .PHASE_S(phase_s)
           );

delayed_fifo #(
                 .DEPTH(DELAY_DEPTH)
             ) delayed_fifo(
                 .CLK(CLK),
                 .UPDATE(UPDATE),
                 .DELAY(DELAY),
                 .DATA_IN(duty),
                 .DATA_OUT(dutyd)
             );

pwm_generator pwm_generator(
                  .TIME(TIME),
                  .DUTY(dutyd),
                  .PHASE(phase),
                  .PWM_OUT(PWM_OUT)
              );

always_ff @(posedge CLK)
    phase <= UPDATE ? (SILENT ? phase_s : PHASE) : phase;

endmodule
