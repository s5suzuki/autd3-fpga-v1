/*
 * File: silent_lpf_v2.sv
 * Project: new
 * Created Date: 25/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 05/12/2021
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
module silent_lpf_v2#(
           parameter int TRANS_NUM = 249
       )(
           input var CLK,
           input var CLK_MF,
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
logic [7:0] mean_cnt = '0;

logic [7:0] chin = '0;
logic [7:0] chout;

logic [15:0] din;
logic [31:0] dout;
logic [7:0] dutys[0:TRANS_NUM-1];
logic [7:0] phases[0:TRANS_NUM-1];

assign DUTYS = dutys;
assign PHASES = phases;

generate begin:MEAN_ADDR
        genvar ii;
        for(ii = 0; ii < TRANS_NUM; ii++) begin
            logic [8:0] dm, pm;
            addr_88 d_addr_88(
                        .CLK(CLK_MF),
                        .A(duty_mean_l[ii]),
                        .B(duty_mean_r[ii]),
                        .S(dm)
                    );
            addr_88 p_addr_88(
                        .CLK(CLK_MF),
                        .A(phase_mean_l[ii]),
                        .B(phase_mean_r[ii]),
                        .S(pm)
                    );
            assign duty_mean[ii] = dm[8:1];
            assign phase_mean[ii] = pm[8:1];
        end
    end
endgenerate

lpf_silent lpf(
               .aclk(CLK),
               .s_axis_data_tvalid(1'b1),
               .s_axis_data_tready(),
               .s_axis_data_tuser(chin),
               .s_axis_data_tdata(din),
               .m_axis_data_tvalid(),
               .m_axis_data_tdata(dout),
               .m_axis_data_tuser(chout),
               .event_s_data_chanid_incorrect()
           );

always_ff @(posedge CLK_MF) begin
    mean_cnt <= mean_cnt + 1'b1;
    if (mean_cnt == 8'hFF - MEAN_ADD_LATENCY) begin
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
    chin <= chin + 1'b1;
    din <= {duty_mean[chin], phase_mean[chin]};
end

always_ff @(negedge CLK) begin
    dutys[chout] <= clamp(dout[31:16]);
    phases[chout] <= dout[7:0];
end

function automatic [7:0] clamp;
    input signed [15:0] x;
    clamp = (x > 16'sd255) ? 8'd255 : ((x < 16'sd0) ? '0 : x[7:0]);
endfunction

endmodule
