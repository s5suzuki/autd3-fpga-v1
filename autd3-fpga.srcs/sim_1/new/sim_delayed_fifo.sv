/*
 * File: sim_delayed_fifo.sv
 * Project: new
 * Created Date: 20/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 20/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_delayed_fifo();

localparam int ULTRASOUND_CNT_CYCLE = 510;

logic MRCC_25P6M;
logic RST;

logic sys_clk;
logic [8:0] time_cnt;

logic silent = 1'b0;

logic [7:0] duty;
logic [7:0] phase;
logic [7:0] delay;

logic update;
assign update = time_cnt == (ULTRASOUND_CNT_CYCLE - 1);

transducer transducer(
               .CLK(sys_clk),
               .RST(RST),
               .CLK_LPF(lpf_clk),
               .TIME(time_cnt),
               .UPDATE(update),
               .DUTY(duty),
               .PHASE(phase),
               .DELAY(8'h0),
               .SILENT(silent),
               .PWM_OUT()
           );

// transducer transducer_delay(
//                .CLK(sys_clk),
//                .RST(RST),
//                .CLK_LPF(lpf_clk),
//                .TIME(time_cnt),
//                .UPDATE(update),
//                .DUTY(duty),
//                .PHASE(phase),
//                .DELAY(8'd255),
//                .SILENT(silent),
//                .PWM_OUT()
//            );

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(RST),
                           .clk_out1(sys_clk),
                           .clk_out2(lpf_clk)
                       );

initial begin
    MRCC_25P6M = 0;
    RST = 1;
    duty = 8'h00;
    phase = 8'd0;
    #10000;
    RST = 0;

    repeat (5) @(posedge update);
    repeat (500) @(posedge sys_clk);
    phase = 8'd100;
    duty = 8'hFF;
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
