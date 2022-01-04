/*
 * File: top_v2.sv
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

localparam int WIDTH = 13;
localparam int TRANS_NUM = 249;

bit clk;
bit reset;

bit [63:0] sys_time = 0;

bit [12:0] cycle[0:TRANS_NUM-1];
bit [12:0] duty[0:TRANS_NUM-1];
bit [12:0] phase[0:TRANS_NUM-1];
bit [12:0] duty_s[0:TRANS_NUM-1];
bit [12:0] phase_s[0:TRANS_NUM-1];
bit [12:0] step;

assign reset = ~RESET_N;

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(reset),
                           .clk_out1(clk),
                           .clk_out2(clk_l),
                           .locked()
                       );

silent #(
           .WIDTH(WIDTH),
           .DEPTH(TRANS_NUM)
       ) silent(
           .CLK(clk_l),
           .SYS_TIME(sys_time),
           .ENABLE(1'b1),
           .UPDATE_CYCLE(13'd1250),
           .STEP(step),
           .CYCLE(cycle),
           .DUTY(duty),
           .PHASE(phase),
           .DUTY_S(duty_s),
           .PHASE_S(phase_s)
       );

transducers#(
               .WIDTH(WIDTH),
               .TRANS_NUM(TRANS_NUM)
           ) transducers(
               .CLK(clk),
               .CLK_L(clk_l),
               .SYS_TIME(sys_time),
               .UPDATE_CYCLE(13'd1250),
               .CYCLE(cycle),
               .DUTY(duty_s),
               .PHASE(phase_s),
               .XDCR_OUT(XDCR_OUT)
           );

always_ff @(posedge clk) begin
    step <= 13'd100;
    cycle <= '{TRANS_NUM{13'd5000}};
    duty <= '{TRANS_NUM{13'd2500}};
    phase <= '{TRANS_NUM{13'd2500}};
    sys_time <= sys_time + 1;
end

bit force_fan;
bit [3:0] gpio_out;

assign FORCE_FAN = force_fan;
assign GPIO_OUT = gpio_out;

always_ff @(posedge clk) begin
    force_fan <= 1'b0;
    gpio_out <= 4'b0000;
end

endmodule
