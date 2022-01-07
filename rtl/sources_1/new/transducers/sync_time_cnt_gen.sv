/*
 * File: sync_time_cnt_gen.sv
 * Project: transducer
 * Created Date: 01/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sync_time_cnt_gen#(
           parameter int WIDTH = 13,
           parameter int DEPTH = 249
       )(
           input var CLK,
           input var [63:0] SYS_TIME,
           input var [WIDTH-1:0] CYCLE[0:DEPTH-1],
           output var [WIDTH-1:0] TIME_CNT[0:DEPTH-1]
       );

bit [63:0] divined;
bit [15:0] divisor;
bit [63:0] _unused;
bit [15:0] rem;
bit rem_tvalid;

bit [WIDTH-1:0] t[0:DEPTH-1] = '{DEPTH{0}};

bit [$clog2(DEPTH)-1:0] sync_cnt = 0;

div_64_16 div_64_16(
              .s_axis_dividend_tdata(divined),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_dividend_tready(),
              .s_axis_divisor_tdata(divisor),
              .s_axis_divisor_tvalid(1'b1),
              .s_axis_divisor_tready(),
              .aclk(CLK),
              .m_axis_dout_tdata({_unused, rem}),
              .m_axis_dout_tvalid(rem_tvalid)
          );

for (genvar i = 0; i < DEPTH; i++) begin
    always_ff @(posedge CLK) begin
        if (rem_tvalid & (sync_cnt == i)) begin
            t[i] <= rem[WIDTH-1:0];
        end
        else begin
            t[i] <= (t[i] == CYCLE[i] - 1) ? 0 : t[i] + 1;
        end
    end

    assign TIME_CNT[i] = t[i];
end

always_ff @(posedge CLK) begin
    divined <= SYS_TIME[63:0];
    divisor <= CYCLE[sync_cnt];

    if (rem_tvalid) begin
        sync_cnt <= (sync_cnt == DEPTH - 1) ? 0 : sync_cnt + 1;
    end
end

endmodule
