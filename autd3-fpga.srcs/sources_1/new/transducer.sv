/*
 * File: transducer.sv
 * Project: new
 * Created Date: 03/10/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module transducer(
           input var [9:0] TIME,
           input var [7:0] D,
           input var [7:0] S,
           input var SILENT,
           output var PWM_OUT
       );

logic[7:0] fd_async, fs_async;

logic[7:0] d = SILENT ? fd_async : D;
logic[7:0] s = keep_phase(SILENT ? fs_async : S, d);

logic[9:0] d_pwm;
logic[9:0] s_pwm;

always_comb begin
    d_pwm = ({d, 7'b0} + {2'b0, d, 5'b0} + {8'b0, d}) >> 7; // normalized to 0-319
    s_pwm = ({s, 8'b0} + {2'b0, s, 6'b0} + {9'b0, s}) >> 7; // normalized to 0-639
end

assign PWM_OUT = pwm(TIME, d_pwm, s_pwm);

function automatic pwm;
    input [9:0] timet;
    input [9:0] d;
    input [9:0] s;
    begin
        if (d + s < 10'd640) begin
            pwm = (s <= timet && timet < d + s);
        end
        else begin
            pwm = (timet < d + s - 10'd640 || s <= timet);
        end
    end
endfunction

function automatic [7:0] keep_phase;
    input [7:0] s;
    input [7:0] d;
    keep_phase = {1'b0, s} + (9'h07F - {2'b00, d[7:1]});
endfunction

// Silent mode
logic[7:0] datain;
logic chin;
logic signed [15:0] dataout;
logic chout, enout, enin;

lpf_40k_500 LPF(
                .aclk(TIME[0]),
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
    d_pwm = 10'b0;
    s_pwm = 10'b0;
    datain = 8'd0;
    chin = 1;
    fd_async = 8'd0;
    fs_async = 8'd0;
end

always_ff @(posedge enin) begin
    chin <= ~chin;
    datain <= (chin == 1'b0) ? S : D;
end

always_ff @(negedge enout) begin
    if (chout == 1'd0) begin
        fd_async <= clamp(dataout);
    end
    else begin
        fs_async <= dataout[7:0];
    end
end

function automatic [7:0] clamp;
    input signed [15:0] x;
    clamp = (x > 16'sd255) ? 8'd255 : ((x < 16'sd0) ? 0 : x[7:0]);
endfunction

endmodule
