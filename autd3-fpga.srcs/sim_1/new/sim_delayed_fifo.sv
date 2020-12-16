/*
 * File: sim_delayed_fifo.sv
 * Project: new
 * Created Date: 16/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 16/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module sim_delayed_fifo();

logic MRCC_25P6M, rst;

logic [9:0] time_t = 0;

logic [7:0] duty = 8'hFF;
logic [8:0] delay;
logic pwm_out_1, pwm_out_2;

assign update = time_t == 10'd639;

transducer transducer_1(
               .TIME(time_t),
               .D(duty),
               .DELAY(0),
               .PHASE(0),
               .SILENT(1'b0),
               .PWM_OUT(pwm_out_1)
           );
transducer transducer_2(
               .TIME(time_t),
               .D(duty),
               .DELAY(delay),
               .PHASE(0),
               .SILENT(1'b0),
               .PWM_OUT(pwm_out_2)
           );

initial begin
    MRCC_25P6M = 0;
    rst = 1;
    duty = 0;
    delay = 0;
    #100;
    rst = 0;
    #100000;
    @(posedge update);
    delay = 10;
    repeat (40) @(posedge update);
    delay = 2;
    repeat (40) @(posedge update);
    delay = 4;
    repeat (40) @(posedge update);
    delay = 1;
    repeat (40) @(posedge update);
    delay = 0;
    repeat (40) @(posedge update);
    delay = 5;
end

always_ff @(posedge MRCC_25P6M) begin
    time_t = ((time_t == 10'd639) | rst) ? 0 : time_t + 1;
end

always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

always begin
    repeat (10) @(posedge update);
    duty = 0;
    repeat (10) @(posedge update);
    duty = 8'hFF;
end

endmodule
