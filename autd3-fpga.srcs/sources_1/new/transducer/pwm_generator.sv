/*
 * File: pwm_generator.sv
 * Project: transducer
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 26/09/2021
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

`include "../features.vh"

`ifdef PHASE_INVERTED
assign PWM_OUT = pwm(TIME, {1'b0, DUTY} + DUTY_OFFSET, {8'hFF-PHASE, 1'b0});
`else
assign PWM_OUT = pwm(TIME, {1'b0, DUTY} + DUTY_OFFSET, {PHASE, 1'b0});
`endif

function automatic pwm;
    input [8:0] t;
    input [8:0] D;
    input [8:0] P;
    logic [8:0] DL = {1'b0, D[8:1]};
    logic [8:0] DR = {1'b0, D[8:1]} + D[0];
    logic pwm1 = {1'b0, P} <= {1'b0, t} + {1'b0, DL};
    logic pwm2 = {1'b0, t} < {1'b0, P} + {1'b0, DR};
    logic pwm1o = {1'b1, P} <= {1'b0, t} + {1'b0, DL};
    logic pwm2o = {1'b1, t} < {1'b0, P} + {1'b0, DR};
    pwm = (pwm1 & pwm2) | ((pwm2 | pwm1o) & (P < DL)) | ((pwm2o | pwm1) & (10'h200 < {1'b0, P} + {1'b0, DR}));
endfunction

endmodule
