/*
 * File: sim_modulation.sv
 * Project: new
 * Created Date: 08/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 08/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_modulation();

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

bit [WIDTH-1:0] DUTY[0:DEPTH-1];
bit [WIDTH-1:0] DUTY_M[0:DEPTH-1];
bit OUT_VALID;

sim_helper sim_helper(
               .*
           );

sim_cpu_bus sim_cpu_bus();

modulation#(
              .WIDTH(WIDTH),
              .DEPTH(DEPTH)
          ) modulation(
              .CPU_BUS(sim_cpu_bus.cpu_bus.slave_port),
              .MOD_CYCLE(16'd10),
              .UPDATE_CYCLE(UPDATE_CYCLE),
              .*
          );

initial begin
    DUTY = '{DEPTH{ULTRASOUND_CYCLE/2}};
    sim_cpu_bus.bram_write(0, 0, 0);
    $finish;
end

endmodule
