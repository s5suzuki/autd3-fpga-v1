/*
 * File: sync_time_cnt_gen.sv
 * Project: transducer
 * Created Date: 01/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 04/01/2022
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
           input var CLK_L,
           input var [63:0] SYS_TIME,
           input var [WIDTH-1:0] CYCLE[0:DEPTH-1],
           input var [WIDTH-1:0] UPDATE_CYCLE,
           output var UPDATE,
           output var [WIDTH-1:0] TIME_CNT[0:DEPTH-1]
       );

// bit [63:0] _unused;
// bit [15:0] rem;

bit [WIDTH-1:0] t[0:DEPTH-1] = '{DEPTH{0}};
bit [WIDTH-1:0] update_t = 0;

assign UPDATE = (update_t == 0);

for (genvar i = 0; i < DEPTH; i++) begin
    always_ff @(posedge CLK) begin
        t[i] <= (t[i] == CYCLE[i] - 1) ? 0 : t[i] + 1;
    end

    assign TIME_CNT[i] = t[i];
end

always_ff @(posedge CLK_L) begin
    update_t <= (update_t == UPDATE_CYCLE - 1) ? 0 : update_t + 1;
end

// div_64_13 div_64_13(
//               .s_axis_dividend_tdata(SYS_TIME),
//               .s_axis_dividend_tvalid(1'b1),
//               .s_axis_dividend_tready(),
//               .s_axis_divisor_tdata({3'b000, CYCLE}),
//               .s_axis_divisor_tvalid(1'b1),
//               .s_axis_divisor_tready(),
//               .aclk(CLK),
//               .m_axis_dout_tdata({_unused, rem}),
//               .m_axis_dout_tvalid()
//           );

endmodule
