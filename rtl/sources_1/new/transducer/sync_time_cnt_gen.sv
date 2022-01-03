/*
 * File: sync_time_cnt_gen.sv
 * Project: transducer
 * Created Date: 01/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 01/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sync_time_cnt_gen(
           input var CLK,
           input var [63:0] SYS_TIME,
           input var [12:0] CYCLE,
           output var [12:0] TIME_CNT
       );

bit [63:0] _unused;
bit [15:0] rem;

bit [12:0] t;

assign TIME_CNT = t;

div_64_13 div_64_13(
              .s_axis_dividend_tdata(SYS_TIME),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata({3'b000, CYCLE}),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata({_unused, rem}),
              .m_axis_dout_tvalid()
          );

always_ff @(posedge CLK) begin
    t <= rem[12:0];
end

endmodule
