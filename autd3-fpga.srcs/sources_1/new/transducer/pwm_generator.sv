/*
 * File: pwm_generator.sv
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
module pwm_generator#(
           parameter [9:0] CYCLE = 510
       )(
           input var [8:0] TIME,
           input var [7:0] DUTY,
           input var [7:0] PHASE,
           output var PWM_OUT
       );

assign PWM_OUT = pwm({1'b0, TIME}, {2'b00, DUTY}, {1'b0, PHASE, 1'b0});

function automatic pwm;
    input [9:0] time_t;
    input [9:0] duty;
    input [9:0] phase;
    logic [9:0] dl = {1'b0, duty[9:1]};
    logic [9:0] dr = {1'b0, duty[9:1]} + duty[0];
    logic pwm1 = phase <= time_t + dl;
    logic pwm1o = phase + CYCLE <= time_t + dl;
    logic pwm2 = time_t < phase + dr;
    logic pwm2o = time_t + CYCLE < dr + phase;
    pwm = ((phase < dl) & (pwm1o | pwm2)) | ((phase + dr > CYCLE) & (pwm1 | pwm2o)) | (pwm1 & pwm2);
endfunction

endmodule
