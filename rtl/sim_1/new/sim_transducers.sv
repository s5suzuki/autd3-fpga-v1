/*
 * File: sim_transducers.sv
 * Project: new
 * Created Date: 24/12/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_transducers();

parameter int CLK_FREQ = 50000000;
parameter int CLK_PWM_FREQ = 200000000;
parameter int UPDATE_FREQ = 40000;
parameter int ULTRASOUND_FREQ = 40000;
parameter int UPDATE_CYCLE = int'(CLK_FREQ/UPDATE_FREQ);
parameter int ULTRASOUND_CYCLE = int'(CLK_PWM_FREQ/ULTRASOUND_FREQ);

parameter int WIDTH = 13;
parameter int DEPTH = 10;

bit CLK;
bit CLK_PWM;
bit LOCKED;
bit [63:0] SYS_TIME;
bit UPDATE;

bit [WIDTH-1:0] CYCLE[0:DEPTH-1];
bit [WIDTH-1:0] DUTY[0:DEPTH-1];
bit [WIDTH-1:0] PHASE[0:DEPTH-1];
bit PWM_OUT[0:DEPTH-1];

sim_helper sim_helper(
               .*
           );

update_timing_gen#(
                     .WIDTH(WIDTH)
                 ) update_timing_gen(
                     .*
                 );

transducers#(
               .WIDTH(WIDTH),
               .TRANS_NUM(DEPTH)
           ) transducers(
               .CLK(CLK_PWM),
               .CLK_L(CLK),
               .*
           );

task automatic set(input int idx, input var [12:0] d, input var [12:0] p);
    DUTY[idx] = d;
    PHASE[idx] = p;
endtask

initial begin
    CYCLE = '{DEPTH{ULTRASOUND_CYCLE}};
    repeat (5) @(posedge UPDATE);
    set(0, 2500, 2500); // DEFAULT
    repeat (5) @(posedge UPDATE);
    set(0, 2500, 1000); // UNDERFLOW
    repeat (5) @(posedge UPDATE);
    set(0, 2500, 4000); // OVERFLOW

    repeat (5) @(posedge UPDATE);
    set(0, 1, 0);
    repeat (5) @(posedge UPDATE);
    set(0, 1, 1);
    repeat (5) @(posedge UPDATE);
    set(0, 2, 1);
    repeat (5) @(posedge UPDATE);
    $finish;
end

endmodule
