/*
 * File: sim_lpf.sv
 * Project: new
 * Created Date: 25/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_lpf();

localparam int ULTRASOUND_CNT_CYCLE = 512;
parameter int TRANS_NUM = 249;

logic MRCC_25P6M;
logic RST;

logic sys_clk, lpf_clk;
logic [8:0] time_cnt;

logic update;
assign update = time_cnt == (ULTRASOUND_CNT_CYCLE - 1);

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(RST),
                           .clk_out1(sys_clk),
                           .clk_out2(lpf_clk)
                       );

logic [7:0] duty1[0:TRANS_NUM-1];
logic [7:0] phase1[0:TRANS_NUM-1];
logic [7:0] dutys1[0:TRANS_NUM-1];
logic [7:0] phases1[0:TRANS_NUM-1];

logic [7:0] p0_raw, p0_lpf;
assign p0_raw = phase1[TRANS_NUM-1];
assign p0_lpf = phases1[TRANS_NUM-1];

silent_lpf_v2#(
                 .TRANS_NUM(TRANS_NUM)
             ) silent_lpf_v2(
                 .CLK(sys_clk),
                 .ENABLE(1'b1),
                 .UPDATE(update),
                 .DUTY(duty1),
                 .PHASE(phase1),
                 .DUTYS(dutys1),
                 .PHASES(phases1),
                 .OUT_VALID()
             );

initial begin
    MRCC_25P6M = 0;
    RST = 1;
    duty1 = '{TRANS_NUM{8'h00}};
    phase1 = '{TRANS_NUM{8'h00}};
    #1000;
    RST = 0;
    #(1.0*1000*1000);
    for(int i =0; i < TRANS_NUM; i++) begin
        duty1[i] = $urandom;
        phase1[i] = $urandom;
    end
    #(11.5*1000*1000);
    for(int i =0; i < TRANS_NUM; i++) begin
        if (dutys1[i] !== duty1[i]) begin
            $display("ASSERTION FAILED in duty[%d]", i);
            $finish;
        end
        if (phases1[i] !== phase1[i]) begin
            $display("ASSERTION FAILED in phase[%d]", i);
            $finish;
        end
    end
    $display("Ok!");
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
