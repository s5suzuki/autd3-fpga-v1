/*
 * File: sim_pwm_gen.sv
 * Project: new
 * Created Date: 24/12/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 27/12/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_pwm_gen();

parameter int CLK_FREQ = 200000000;

bit CLK;
bit [63:0] SYS_TIME;
bit SET;
bit [12:0] CYCLE;
bit [12:0] DUTY;
bit [12:0] PHASE;
bit PWM_OUT;

sim_helper sim_helper(
               .*
           );


pwm_gen #(
            .PHASE_INVERTED("TRUE")
        ) pwm_gen (
            .*
        );

task automatic set_cycle(input var [12:0] cycle);
    @(posedge CLK);
    CYCLE = cycle;
    SET = 1;
    @(posedge CLK);
    CYCLE = 0;
    SET = 0;
endtask

task automatic set(input var [12:0] d, input var [12:0] p);
    DUTY = d;
    PHASE = p;
    #100000;
endtask

initial begin
    set_cycle(5000);
    set(2500, 0);
end

endmodule
