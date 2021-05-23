/*
 * File: silent_lpf.sv
 * Project: transducer
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 18/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module silent_lpf(
           input var CLK,
           input var CLK_LPF,
           input var RST,
           input var [7:0] DUTY,
           input var [7:0] PHASE,
           output var [7:0] DUTY_S,
           output var [7:0] PHASE_S
       );

logic [7:0] fd_async;
logic [7:0] fs_async;

logic [7:0] datain;
logic chin;
logic signed [15:0] dataout;
logic chout, enout, enin;
logic enout_rst, enin_rst;

assign DUTY_S = fd_async;
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

always_ff @(posedge CLK) begin
    if (RST) begin
        chin <= 1;
    end
    else if (enin & ~enin_rst) begin
        chin <= ~chin;
        datain <= (chin == 1'b0) ? PHASE : DUTY;
    end
end

always_ff @(posedge CLK) begin
    enout_rst <= enout;
    enin_rst <= enin;
end

always_ff @(negedge CLK) begin
    if (enout & ~enout_rst) begin
        if (chout == 1'd0) begin
            fd_async <= clamp(dataout);
        end
        else begin
            fs_async <= dataout[7:0];
        end
    end
end

function automatic [7:0] clamp;
    input signed [15:0] x;
    clamp = (x > 16'sd255) ? 8'd255 : ((x < 16'sd0) ? 0 : x[7:0]);
endfunction

endmodule
