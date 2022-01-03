/*
 * File: top_v2.sv
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
module top_v2(
           input var [16:1] CPU_ADDR,
           inout tri [15:0] CPU_DATA,
           input var CPU_CKIO,
           input var CPU_CS1_N,
           input var RESET_N,
           input var CPU_WE0_N,
           input var CPU_RD_N,
           input var CPU_RDWR,
           input var MRCC_25P6M,
           input var CAT_SYNC0,
           output var FORCE_FAN,
           input var THERMO,
           output var [252:1] XDCR_OUT,
           //    input var [3:0] GPIO_IN,
           output var [3:0] GPIO_OUT
       );

localparam string PHASE_INVERTED = "TRUE";

localparam int TRANS_NUM = 249;
localparam int CLK_FREQ = 200000000;

bit clk;
bit reset;

bit [63:0] sys_time = 0;

bit [12:0] cycle[0:TRANS_NUM-1];
bit [12:0] duty[0:TRANS_NUM-1];
bit [12:0] phase[0:TRANS_NUM-1];
bit [12:0] duty_s[0:TRANS_NUM-1];
bit [12:0] phase_s[0:TRANS_NUM-1];
bit [12:0] step;
bit start;
bit [12:0] t;

assign reset = ~RESET_N;
assign start = t === 0;

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(reset),
                           .clk_out1(clk),
                           .clk_out2(clk_l),
                           .locked()
                       );

sync_time_cnt_gen sync_time_cnt_gen(
                      .CLK(clk),
                      .SYS_TIME(sys_time),
                      .CYCLE(cycle[0]),
                      .TIME_CNT(t)
                  );

silent_lpf_v2 #(
                  .WIDTH(13),
                  .DEPTH(TRANS_NUM)
              ) silent_lpf_v2(
                  .CLK(clk_l),
                  .ENABLE(1'b1),
                  .START(start),
                  .STEP(step),
                  .CYCLE(cycle),
                  .DUTY(duty),
                  .PHASE(phase),
                  .DUTY_S(duty_s),
                  .PHASE_S(phase_s)
              );

`include "cvt_uid.vh"
for (genvar ii = 0; ii < TRANS_NUM; ii++) begin
    bit pwm_out;
    bit tr_out;
    assign XDCR_OUT[cvt_uid(ii) + 1] = tr_out;
    pwm_gen #(
                .PHASE_INVERTED(PHASE_INVERTED)
            ) pwm_gen(
                .CLK(clk),
                .TIME_CNT(t),
                .CYCLE(cycle[ii]),
                .DUTY(duty_s[ii]),
                .PHASE(phase_s[ii]),
                .PWM_OUT(tr_out)
            );
end

always_ff @(posedge clk) begin
    step <= 13'd100;
    cycle <= '{TRANS_NUM{13'd5000}};
    duty <= '{TRANS_NUM{13'd2500}};
    phase <= '{TRANS_NUM{13'd2500}};
    sys_time <= sys_time + 1;
end

endmodule
