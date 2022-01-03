/*
 * File: sim_helper.sv
 * Project: new
 * Created Date: 24/12/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 03/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_helper(
           output var CLK,
           output var CLK_PWM,
           output var LOCKED,
           output var [63:0] TIME_CNT
       );

bit MRCC_25P6M;

bit clk_1, clk_2;
bit reset;
bit locked;
bit [63:0] time_cnt;

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(reset),
                           .clk_out1(clk_1),
                           .clk_out2(clk_2),
                           .locked(locked)
                       );

assign CLK = clk_2;
assign CLK_PWM = clk_1;
assign LOCKED = locked;
assign TIME_CNT = time_cnt;

initial begin
    MRCC_25P6M = 0;
    reset = 1;
    #1000;
    reset = 0;
    time_cnt = 0;
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

always @(posedge CLK_PWM) begin
    time_cnt = time_cnt + 1;
end

endmodule