/*
 * File: sim_delayed_fifo.sv
 * Project: new
 * Created Date: 20/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 12/10/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_delayed_fifo();

localparam int ULTRASOUND_CNT_CYCLE = 512;

logic MRCC_25P6M;
logic RST;

logic sys_clk;
logic [8:0] time_cnt;

logic [7:0] delay_1, delay_2;

logic [7:0] duty;
logic [7:0] phase;

logic update;
assign update = time_cnt == (ULTRASOUND_CNT_CYCLE - 1);

logic [7:0] duty_out_1, duty_out_2;
logic [7:0] phase_out_1, phase_out_2;

delayed_fifo delayed_fifo_1(
                 .CLK(sys_clk),
                 .UPDATE(update),
                 .DELAY(delay_1),
                 .DATA_IN({duty, phase}),
                 .DATA_OUT({duty_out_1, phase_out_1})
             );

delayed_fifo delayed_fifo_2(
                 .CLK(sys_clk),
                 .UPDATE(update),
                 .DELAY(delay_2),
                 .DATA_IN({duty, phase}),
                 .DATA_OUT({duty_out_2, phase_out_2})
             );

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(RST),
                           .clk_out1(sys_clk),
                           .clk_out2()
                       );

initial begin
    MRCC_25P6M = 0;
    RST = 1;
    duty = 8'h00;
    phase = 8'd0;
    delay_1 = 8'd1;
    delay_2 = 8'd2;
    #10000;
    RST = 0;

    repeat (5) @(posedge update);
    repeat (500) @(posedge sys_clk);
    phase = 8'd100;
    duty = 8'hFF;

    repeat (5120) @(posedge sys_clk);
    delay_1 = 8'h80 | 8'd7;
    delay_2 = 8'h80 | 8'd3;

    repeat (5120) @(posedge sys_clk);
    delay_1 = 8'h00;
    delay_2 = 8'h00;
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

always @(posedge sys_clk)
    time_cnt <= (RST | (time_cnt == (ULTRASOUND_CNT_CYCLE-1))) ? 0 : time_cnt + 1;

endmodule
