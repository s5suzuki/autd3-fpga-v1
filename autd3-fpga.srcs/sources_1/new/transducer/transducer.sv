/*
 * File: transducer.sv
 * Project: transducer
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 15/06/2021
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
           input var [7:0] MOD,
           input var SILENT,
           output var PWM_OUT
       );

logic [16:0] duty_modulated;
logic [7:0] mod_d;
logic [7:0] duty_s, phase_s;
logic [7:0] duty, phase;

assign duty = SILENT ? duty_s : duty_modulated[15:8];
assign phase = SILENT ? phase_s : PHASE;

mult8x8 mod_mult(
            .CLK(CLK),
            .A(DUTY),
            .B(mod_d),
            .P(duty_modulated)
        );

delayed_fifo #(
                 .DEPTH(DELAY_DEPTH)
             ) delayed_fifo(
                 .CLK(CLK),
                 .UPDATE(UPDATE),
                 .DELAY(DELAY),
                 .DATA_IN(MOD),
                 .DATA_OUT(mod_d)
             );

silent_lpf silent_lpf(
               .CLK(CLK),
               .CLK_LPF(CLK_LPF),
               .DUTY(duty_modulated[15:8]),
               .PHASE(PHASE),
               .DUTY_S(duty_s),
               .PHASE_S(phase_s)
           );

pwm_generator pwm_generator(
                  .TIME(TIME),
                  .DUTY(duty),
                  .PHASE(phase),
                  .PWM_OUT(PWM_OUT)
              );

endmodule
