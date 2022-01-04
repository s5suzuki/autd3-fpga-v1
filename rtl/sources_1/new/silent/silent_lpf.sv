/*
 * File: silent_lpf.sv
 * Project: new
 * Created Date: 25/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 29/12/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
/*
To maintain compatibility with older versions, the sampling frequency of the LPF remains to be 20 kHz.
Since there are not enough resources to increase the sampling frequency of the LPF to 40kHz without changing the filter characteristics, the mean of two values sampled at 40kHz is used as the input of the LPF.
*/
module silent_lpf#(
           parameter int TRANS_NUM = 249
       )(
           input var CLK,
           input var [7:0] DUTY[0:TRANS_NUM-1],
           input var [7:0] PHASE[0:TRANS_NUM-1],
           output var [7:0] DUTYS[0:TRANS_NUM-1],
           output var [7:0] PHASES[0:TRANS_NUM-1]
       );

localparam int MEAN_ADD_LATENCY = 2;

logic [7:0] duty_mean_l[0:TRANS_NUM-1] = '{TRANS_NUM{'0}};
logic [7:0] duty_mean_r[0:TRANS_NUM-1] = '{TRANS_NUM{'0}};
logic [7:0] phase_mean_l[0:TRANS_NUM-1] = '{TRANS_NUM{'0}};
logic [7:0] phase_mean_r[0:TRANS_NUM-1] = '{TRANS_NUM{'0}};
logic [7:0] duty_mean[0:TRANS_NUM-1], phase_mean[0:TRANS_NUM-1];
logic ptr = '0;
logic [6:0] mean_cnt = '0;

logic aclk;
logic [7:0] s_axis_data_tuser = '0;
logic [15:0] s_axis_data_tdata = '0;
logic [7:0] m_axis_data_tuser;
logic [31:0] m_axis_data_tdata;

logic [7:0] dutys[0:TRANS_NUM-1];
logic [7:0] phases[0:TRANS_NUM-1];

assign aclk = CLK;
assign DUTYS = dutys;
assign PHASES = phases;

for (genvar ii = 0; ii < TRANS_NUM; ii++) begin
    logic [8:0] dm, pm;
    addr_88 d_addr_88(
                .*,
                .A(duty_mean_l[ii]),
                .B(duty_mean_r[ii]),
                .S(dm)
            );
    addr_88 p_addr_88(
                .*,
                .A(phase_mean_l[ii]),
                .B(phase_mean_r[ii]),
                .S(pm)
            );
    assign duty_mean[ii] = dm[8:1];
    assign phase_mean[ii] = pm[8:1];
end

lpf_silent lpf(
               .*,
               .s_axis_data_tvalid(1'b1),
               .s_axis_data_tready(),
               .m_axis_data_tvalid(),
               .event_s_data_chanid_incorrect()
           );

always_ff @(posedge CLK) begin
    mean_cnt <= mean_cnt + 1'b1;
    if (mean_cnt == 8'h7F - MEAN_ADD_LATENCY) begin
        ptr <= ~ptr;
        if (ptr) begin
            duty_mean_l <= DUTY;
            phase_mean_l <= PHASE;
        end
        else begin
            duty_mean_r <= DUTY;
            phase_mean_r <= PHASE;
        end
    end
end

always_ff @(posedge CLK) begin
    s_axis_data_tuser <= s_axis_data_tuser + 1'b1;
    s_axis_data_tdata <= {duty_mean[s_axis_data_tuser], phase_mean[s_axis_data_tuser]};
end

always_ff @(negedge CLK) begin
    dutys[m_axis_data_tuser + 1'b1] <= clamp(m_axis_data_tdata[31:16]);
    phases[m_axis_data_tuser + 1'b1] <= m_axis_data_tdata[7:0];
end

function automatic [7:0] clamp;
    input signed [15:0] x;
    clamp = (x > 16'sd255) ? 8'd255 : ((x < 16'sd0) ? '0 : x[7:0]);
endfunction

endmodule
