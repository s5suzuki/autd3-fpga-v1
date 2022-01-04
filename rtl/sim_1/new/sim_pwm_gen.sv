/*
 * File: sim_pwm_gen.sv
 * Project: new
 * Created Date: 24/12/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 04/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_pwm_gen();

parameter int CLK_PWM_FREQ = 200000000;
parameter int ULTRASOUND_FREQ = 40000;
parameter int ULTRASOUND_CYCLE = int'(CLK_PWM_FREQ/ULTRASOUND_FREQ);

parameter int WIDTH = 13;
parameter int DEPTH = 249;

bit CLK;
bit CLK_PWM;
bit LOCKED;
bit [63:0] SYS_TIME;
bit [12:0] TIME_CNT;
bit START;

bit [WIDTH-1:0] CYCLE[0:DEPTH-1];
bit [WIDTH-1:0] DUTY[0:DEPTH-1];
bit [WIDTH-1:0] PHASE[0:DEPTH-1];
bit OVER[0:DEPTH-1];
bit [WIDTH-1:0] LEFT[0:DEPTH-1];
bit [WIDTH-1:0] RIGHT[0:DEPTH-1];
bit PWM_OUT[0:DEPTH-1];

assign TIME_CNT = SYS_TIME % ULTRASOUND_CYCLE;
assign START = TIME_CNT == 0;

sim_helper sim_helper(
               .*
           );

pwm_preconditioner#(
                      .WIDTH(WIDTH),
                      .DEPTH(DEPTH)
                  ) pwm_preconditioner(
                      .CLK(CLK_PWM),
                      .*
                  );

for (genvar i = 0; i < DEPTH; i++) begin
    pwm_gen pwm_gen(
                .CLK(CLK_PWM),
                .TIME_CNT(TIME_CNT),
                .CYCLE(CYCLE[i]),
                .OVER(OVER[i]),
                .LEFT(LEFT[i]),
                .RIGHT(RIGHT[i]),
                .PWM_OUT(PWM_OUT[i])
            );
end

task automatic set(input int idx, input var [12:0] d, input var [12:0] p);
    DUTY[idx] = d;
    PHASE[idx] = p;
endtask

initial begin
    CYCLE = '{DEPTH{ULTRASOUND_CYCLE}};
    repeat (5) @(posedge START);
    set(0, 2500, 2500); // DEFAULT
    repeat (5) @(posedge START);
    set(0, 2500, 1000); // UNDERFLOW
    repeat (5) @(posedge START);
    set(0, 2500, 4000); // OVERFLOW

    repeat (5) @(posedge START);
    set(0, 1, 0);
    repeat (5) @(posedge START);
    set(0, 1, 1);
    repeat (5) @(posedge START);
    set(0, 2, 1);
end

endmodule
