/*
 * File: sim_pwm_generator.sv
 * Project: new
 * Created Date: 13/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 28/09/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_pwm_generator();

localparam int ULTRASOUND_CNT_CYCLE = 512;

logic MRCC_25P6M;
logic RST;

logic sys_clk;
logic [8:0] time_cnt;
logic [7:0] duty;
logic [7:0] phase;
logic pwm_out;

logic update;
assign update = time_cnt == (ULTRASOUND_CNT_CYCLE - 1);

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(RST),
                           .clk_out1(sys_clk),
                           .clk_out2()
                       );

pwm_generator pwm_generator(
                  .TIME(time_cnt),
                  .DUTY(duty),
                  .PHASE(phase),
                  .DUTY_OFFSET(1),
                  .PWM_OUT(pwm_out)
              );

task automatic set(input var [7:0] d, input var [7:0] p);
    @(posedge update);
    duty = d;
    phase = p;
    #50000;
endtask

initial begin
    MRCC_25P6M = 0;
    RST = 1;
    time_cnt = 0;
    duty = 0;
    phase = 0;
    #1000;
    RST = 0;
    #1000;

    // duty is odd
    set(255, 50);
    set(255, 200);
    set(255, 0);
    set(255, 255);

    // duty is even
    set(250, 50);
    set(240, 60);
    set(250, 200);
    set(240, 195);
    set(250, 150);
    set(0, 0);
    set(0, 255);

    $finish;
end

always @(posedge sys_clk)
    time_cnt <= (RST | (time_cnt == (ULTRASOUND_CNT_CYCLE-1))) ? 0 : time_cnt + 1;

always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

endmodule
