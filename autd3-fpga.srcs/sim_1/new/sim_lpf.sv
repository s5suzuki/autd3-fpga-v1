/*
 * File: sim_lpf.sv
 * Project: new
 * Created Date: 25/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 27/09/2021
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

silent_lpf_v2#(
                 .TRANS_NUM(TRANS_NUM)
             ) silent_lpf_v2(
                 .CLK(lpf_clk),
                 .DUTY(duty1),
                 .PHASE(phase1),
                 .DUTYS(dutys1),
                 .PHASES(phases1)
             );

logic [7:0] p,d;
logic [7:0] fd_async;
logic [7:0] fs_async;
logic [7:0] fd_async_buf;
logic [7:0] fs_async_buf;
logic [7:0] datain;
logic chin;
logic signed [15:0] dataout;
logic chout, enout, enin;
logic enout_rst, enin_rst;

lpf_40k_500 lpf_old(
                .aclk(time_cnt[0]),
                .s_axis_data_tvalid(1'd1),
                .s_axis_data_tready(enin),
                .s_axis_data_tuser(chin),
                .s_axis_data_tdata(datain),
                .m_axis_data_tvalid(enout),
                .m_axis_data_tdata(dataout),
                .m_axis_data_tuser(chout),
                .event_s_data_chanid_incorrect()
            );

initial begin
    MRCC_25P6M = 0;
    RST = 1;
    duty1 = '{TRANS_NUM{8'h00}};
    phase1 = '{TRANS_NUM{8'h00}};
    #1000;
    RST = 0;
    #100000;
    duty1[0] = 8'hFF;
    phase1[0] = 8'hFF;
    duty1[1] = 8'haa;
    phase1[1] = 8'hbb;
    duty1[TRANS_NUM-1] = 8'h88;
    phase1[TRANS_NUM-1] = 8'h99;
    p = 8'hFF;
    d = 8'haa;
end

always @(posedge sys_clk)
    time_cnt <= (RST | (time_cnt == (ULTRASOUND_CNT_CYCLE-1))) ? 0 : time_cnt + 1;

always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

// OLD
always_ff @(posedge sys_clk) begin
    if (RST) begin
        chin <= 1;
        datain <= 0;
    end
    else if (enin & ~enin_rst) begin
        chin <= ~chin;
        datain <= (chin == 1'b0) ? p : d;
    end
end

always_ff @(posedge sys_clk) begin
    if (RST) begin
        enin_rst <= 1'b0;
    end
    else if (enin) begin
        enin_rst <= 1'b1;
    end
    else begin
        enin_rst <= 1'b0;
    end
end
always_ff @(posedge sys_clk) begin
    if (RST) begin
        enout_rst <= 1'b0;
    end
    else if (enout) begin
        enout_rst <= 1'b1;
    end
    else begin
        enout_rst <= 1'b0;
    end
end

always_ff @(negedge sys_clk) begin
    if (RST) begin
        fs_async_buf <= 0;
        fd_async_buf <= 0;
    end
    else if (enout & ~enout_rst) begin
        if (chout == 1'd0) begin
            fd_async_buf <= clamp(dataout);
        end
        else begin
            fs_async_buf <= dataout[7:0];
        end
    end
end

always_ff @(posedge sys_clk) begin
    if (RST) begin
        fd_async <= 0;
        fs_async <= 0;
    end
    else if(update) begin
        fd_async <= fd_async_buf;
        fs_async <= fs_async_buf;
    end
end

function automatic [7:0] clamp;
    input signed [15:0] x;
    clamp = (x > 16'sd255) ? 8'd255 : ((x < 16'sd0) ? 0 : x[7:0]);
endfunction


endmodule
