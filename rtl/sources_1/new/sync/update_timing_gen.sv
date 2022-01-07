/*
 * File: update_timing_gen.sv
 * Project: sync
 * Created Date: 05/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module update_timing_gen#(
           parameter int WIDTH = 13
       )(
           input var CLK,
           input var [63:0] SYS_TIME,
           input var [WIDTH-1:0] UPDATE_CYCLE,
           output var UPDATE
       );

bit [63:0] divined;
bit [63:0] _unused;
bit rem_tvalid;
if (WIDTH <= 16) begin
    bit [15:0] divisor;
    bit [15:0] rem;
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
end
else if (WIDTH <= 32) begin
    bit [31:0] divisor;
    bit [31:0] rem;
    div_64_32 div_64_32(
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
end
else begin
    $error("not supported");
end

bit signed [WIDTH:0] a_sub_diff, b_sub_diff, s_sub_diff;
bit signed [WIDTH:0] a_sub_fold_diff, b_sub_fold_diff, s_sub_fold_diff;
bit sync_done = 1;
bit signed [WIDTH:0] sync_diff = 0;
bit [WIDTH-1:0] update_t = 0;
bit update;

enum bit [2:0] {
         IDLE,
         WAIT_CALC_DIFF_1,
         WAIT_CALC_DIFF_2,
         FOLD_SYNC_DIFF,
         WAIT_FOLD_SYNC_DIFF_1,
         WIAT_FOLD_SYNC_DIFF_2,
         SYNC
     } state = IDLE;

assign UPDATE = update;

addsub#(
          .WIDTH(WIDTH+1)
      ) sub_diff(
          .CLK(CLK),
          .A(a_sub_diff),
          .B(b_sub_diff),
          .ADD(1'b0),
          .S(s_sub_diff)
      );

addsub#(
          .WIDTH(WIDTH+1)
      ) sub_fold_diff(
          .CLK(CLK),
          .A(a_sub_fold_diff),
          .B(b_sub_fold_diff),
          .ADD(1'b0),
          .S(s_sub_fold_diff)
      );

always_ff @(posedge CLK) begin
    divined <= {2'b00, SYS_TIME[63:2]};
    divisor <= UPDATE_CYCLE;
end

always_ff @(posedge CLK) begin
    if (state == SYNC) begin
        sync_diff <= s_sub_fold_diff;
        sync_done <= 0;
        if (update_t == UPDATE_CYCLE - 1) begin
            update_t <= '0;
            update <= 1'b1;
        end
        else begin
            update_t <= update_t + 1;
            update <= 1'b0;
        end
    end
    else begin
        if (sync_diff > 0) begin
            if (update_t == UPDATE_CYCLE - 2) begin
                update_t <= '0;
                update <= 1'b1;
            end
            else if (update_t == UPDATE_CYCLE - 1) begin
                update_t <= 1;
                update <= 1'b1;
            end
            else begin
                update_t <= update_t + 2;
                update <= 1'b0;
            end
            sync_diff <= sync_diff - 1;
        end
        else if (sync_diff[WIDTH] == 1'b1) begin
            if (update) begin
                update <= 0;
            end
            sync_diff <= sync_diff + 1;
        end
        else begin
            if (update_t == UPDATE_CYCLE - 1) begin
                update_t <= '0;
                update <= 1'b1;
            end
            else begin
                update_t <= update_t + 1;
                update <= 1'b0;
            end
            sync_done <= 1;
        end
    end
end

always_ff @(posedge CLK) begin
    case(state)
        IDLE: begin
            if (sync_done & rem_tvalid) begin
                a_sub_diff <= {1'b0, rem[WIDTH-1:0]};
                b_sub_diff <= {1'b0, update_t};

                state <= WAIT_CALC_DIFF_1;
            end
        end
        WAIT_CALC_DIFF_1: begin
            state <= WAIT_CALC_DIFF_2;
        end
        WAIT_CALC_DIFF_2: begin
            state <= FOLD_SYNC_DIFF;
        end
        FOLD_SYNC_DIFF: begin
            a_sub_fold_diff <= s_sub_diff;
            b_sub_fold_diff <= (s_sub_diff >= UPDATE_CYCLE) ? UPDATE_CYCLE : 0;
            state <= WAIT_FOLD_SYNC_DIFF_1;
        end
        WAIT_FOLD_SYNC_DIFF_1: begin
            state <= WIAT_FOLD_SYNC_DIFF_2;
        end
        WIAT_FOLD_SYNC_DIFF_2: begin
            state <= SYNC;
        end
        SYNC: begin
            state <= IDLE;
        end
    endcase
end

endmodule
