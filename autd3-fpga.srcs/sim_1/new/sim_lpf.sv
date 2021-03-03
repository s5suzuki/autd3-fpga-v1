/*
 * File: sim_lpf.sv
 * Project: new
 * Created Date: 03/03/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 03/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */


`timescale 1ns / 1ps

module sim_lpf();

logic MRCC_25P6M;
logic [9:0] time_cnt;

logic [7:0] duty;
logic [7:0] phase;
logic [7:0] duty_lpf;
logic [7:0] phase_lpf;

logic update;

assign update = (time_cnt == 10'd639);

silent_lpf silent_lpf(
               .CLK(MRCC_25P6M),
               .UPDATE(update),
               .D(duty),
               .PHASE(phase),
               .D_S(duty_lpf),
               .PHASE_S(phase_lpf)
           );

initial begin
    MRCC_25P6M = 1;
    time_cnt = 0;
    duty = 0;
    phase = 0;

    #(100000);
    duty = 8'hff;
    phase = 8'hf0;
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

always @(posedge MRCC_25P6M) begin
    time_cnt = (time_cnt == 10'd639) ? 0 : time_cnt + 1;
end

endmodule
