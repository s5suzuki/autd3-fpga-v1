/*
 * File: pwm_gen.sv
 * Project: transducer
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 04/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */


`timescale 1ns / 1ps
module pwm_gen#(
           parameter int WIDTH = 13
       )(
           input var CLK,
           input var [WIDTH-1:0] TIME_CNT,
           input var [WIDTH-1:0] CYCLE,
           input var OVER,
           input var [WIDTH-1:0] LEFT,
           input var [WIDTH-1:0] RIGHT,
           output var PWM_OUT
       );

bit [WIDTH-1:0] t;
bit [WIDTH-1:0] left, right;
bit over;
bit pwm;

assign PWM_OUT = pwm;
assign t = TIME_CNT;

always_ff @(posedge CLK) begin
    if (t == CYCLE - 1) begin
        left <= LEFT;
        right <= RIGHT;
        over <= OVER;
    end
end

always_ff @(posedge CLK) begin
    if (over) begin
        pwm <= (t < right) | (left <= t);
    end
    else begin
        pwm <= (left <= t) & (t < right);
    end
end

endmodule
