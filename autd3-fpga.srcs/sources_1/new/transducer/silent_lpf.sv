/*
 * File: silent_lpf.sv
 * Project: transducer
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 03/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module silent_lpf(
           input var CLK,
           input var CLK_LPF,
           input var UPDATE,
           input var [7:0] D,
           input var [7:0] PHASE,
           output var [7:0] D_S,
           output var [7:0] PHASE_S
       );

logic[7:0] fd_async = 0;
logic[7:0] fs_async = 0;
logic[7:0] fd_async_buf = 0;
logic[7:0] fs_async_buf = 0;

logic[7:0] datain = 0;
logic chin = 1;
logic signed [15:0] dataout;
logic chout, enout, enin;

assign D_S = fd_async;
assign PHASE_S = fs_async;

lpf_40k_500 LPF(
                .aclk(CLK_LPF),
                .s_axis_data_tvalid(1'd1),
                .s_axis_data_tready(enin),
                .s_axis_data_tuser(chin),
                .s_axis_data_tdata(datain),
                .m_axis_data_tvalid(enout),
                .m_axis_data_tdata(dataout),
                .m_axis_data_tuser(chout),
                .event_s_data_chanid_incorrect()
            );

always_ff @(posedge enin) begin
    chin <= ~chin;
    datain <= (chin == 1'b0) ? PHASE : D;
end

always_ff @(negedge enout) begin
    if (chout == 1'd0) begin
        fd_async_buf <= clamp(dataout);
    end
    else begin
        fs_async_buf <= dataout[7:0];
    end
end

always_ff @(posedge CLK) begin
    if(UPDATE) begin
        fd_async <= fd_async_buf;
        fs_async <= fs_async_buf;
    end
end

function automatic [7:0] clamp;
    input signed [15:0] x;
    clamp = (x > 16'sd255) ? 8'd255 : ((x < 16'sd0) ? 0 : x[7:0]);
endfunction

endmodule
