/*
 * File: sim_silent.sv
 * Project: new
 * Created Date: 25/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_silent();

parameter int CLK_FREQ = 50000000;
parameter int CLK_PWM_FREQ = 200000000;
parameter int ULTRASOUND_FREQ = 40000;
parameter int WIDTH = 13;
parameter int DEPTH = 1;

localparam int ULTRASOUND_CYCLE = int'(CLK_PWM_FREQ/ULTRASOUND_FREQ);

bit CLK, CLK_PWM;
bit LOCKED;
bit [63:0] SYS_TIME;

sim_helper sim_helper(
               .*
           );

bit ENABLE = 1'b1;
bit [WIDTH-1:0] STEP;
bit [WIDTH-1:0] UPDATE_CYCLE;
bit [WIDTH-1:0] CYCLE[0:DEPTH-1];
bit [WIDTH-1:0] DUTY[0:DEPTH-1];
bit [WIDTH-1:0] PHASE[0:DEPTH-1];
bit [WIDTH-1:0] DUTY_S[0:DEPTH-1];
bit [WIDTH-1:0] PHASE_S[0:DEPTH-1];
bit OUT_VALID;

silent #(
           .WIDTH(WIDTH),
           .DEPTH(DEPTH)
       ) silent(
           .*
       );

int n_repeat;
initial begin
    CYCLE = '{DEPTH{ULTRASOUND_CYCLE}};
    UPDATE_CYCLE = ULTRASOUND_CYCLE/4;
    STEP = 100;
    n_repeat = int'(ULTRASOUND_CYCLE/STEP) + 5;

    // from 0 to random
    for(int i =0; i < DEPTH; i++) begin
        DUTY[i] = $urandom_range(CYCLE[i]);
        PHASE[i] = $urandom_range(CYCLE[i]);
    end
    repeat (n_repeat) @(posedge OUT_VALID);
    for(int i =0; i < DEPTH; i++) begin
        if (DUTY_S[i] !== DUTY[i]) begin
            $display("ASSERTION FAILED in DUTY[%d]", i);
            $finish;
        end
        if (PHASE_S[i] !== PHASE[i]) begin
            $display("ASSERTION FAILED in PHASE[%d]", i);
            $finish;
        end
    end

    // from random to random
    for(int i =0; i < DEPTH; i++) begin
        DUTY[i] = $urandom_range(CYCLE[i]);
        PHASE[i] = $urandom_range(CYCLE[i]);
    end
    repeat (n_repeat) @(posedge OUT_VALID);
    for(int i =0; i < DEPTH; i++) begin
        if (DUTY_S[i] !== DUTY[i]) begin
            $display("ASSERTION FAILED in DUTY[%d]", i);
            $finish;
        end
        if (PHASE_S[i] !== PHASE[i]) begin
            $display("ASSERTION FAILED in PHASE[%d]", i);
            $finish;
        end
    end

    $display("Ok!");
    $finish;
end

endmodule
