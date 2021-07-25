/*
 * File: silent_lpf_v2.sv
 * Project: new
 * Created Date: 25/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 26/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module silent_lpf_v2#(
           parameter int TRANS_NUM = 249
       )(
           input var CLK,
           input var [7:0] DUTY[0:TRANS_NUM-1],
           input var [7:0] PHASE[0:TRANS_NUM-1],
           output var [7:0] DUTYS[0:TRANS_NUM-1],
           output var [7:0] PHASES[0:TRANS_NUM-1]
       );

logic enin;
logic enin_rst;
logic [7:0] chin = 0;
logic [7:0] chout;

logic [15:0] din;
logic [31:0] dout;
logic [7:0] dout1[0:TRANS_NUM-1];
logic [7:0] dout2[0:TRANS_NUM-1];

assign DUTYS = dout1;
assign PHASES = dout2;

lpf_silent lpf(
               .aclk(CLK),
               .s_axis_data_tvalid(1'd1),
               .s_axis_data_tready(),
               .s_axis_data_tuser(chin),
               .s_axis_data_tdata(din),
               .m_axis_data_tvalid(),
               .m_axis_data_tdata(dout),
               .m_axis_data_tuser(chout),
               .event_s_data_chanid_incorrect()
           );


always_ff @(posedge CLK) begin
    // if (enin & ~enin_rst) begin
    chin <= chin + 1;
    if (chin < TRANS_NUM) begin
        din <= {DUTY[chin], PHASE[chin]};
    end
    else begin
        din <= 0;
    end
    // end
end

always_ff @(negedge CLK) begin
    if (chout < TRANS_NUM) begin
        dout1[chout] <= clamp(dout[31:16]);
        dout2[chout] <= dout[7:0];
    end
end

always_ff @(posedge CLK) begin
    enin_rst <= enin;
end

function automatic [7:0] clamp;
    input signed [15:0] x;
    clamp = (x > 16'sd255) ? 8'd255 : ((x < 16'sd0) ? 0 : x[7:0]);
endfunction

endmodule
