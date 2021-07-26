/*
 * File: pwm_generator.sv
 * Project: transducer
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 26/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */


`timescale 1ns / 1ps
module pwm_generator(
           input var [8:0] TIME,
           input var [7:0] DUTY,
           input var [7:0] PHASE,
           input var DUTY_OFFSET,
           output var PWM_OUT
       );

`include "../param.vh"

`ifdef PHASE_INVERTED
assign PWM_OUT = pwm(TIME, {1'b0, DUTY} + DUTY_OFFSET, {8'hFF-PHASE, 1'b0});
`else
assign PWM_OUT = pwm(TIME, {1'b0, DUTY} + DUTY_OFFSET, {PHASE, 1'b0});
`endif

function automatic pwm;
    input [8:0] time_t;
    input [8:0] duty;
    input [8:0] phase;
    logic [8:0] dl = {1'b0, duty[8:1]};
    logic [8:0] dr = {1'b0, duty[8:1]} + duty[0];
    logic pwm1 = {1'b0, phase} <= {1'b0, time_t} + {1'b0, dl};
    logic pwm1o = {1'b1, phase[8:0]} <= {1'b0, time_t} + {1'b0, dl};
    logic pwm2 = {1'b0, time_t} < {1'b0, phase} + {1'b0, dr};
    logic pwm2o = {1'b1, time_t[8:0]} < {1'b0, phase} + {1'b0, dr};
    pwm = ((phase < dl) & (pwm1o | pwm2)) | (({1'b0, phase} + {1'b0, dr} > 10'h200) & (pwm1 | pwm2o)) | (pwm1 & pwm2);
endfunction

endmodule
