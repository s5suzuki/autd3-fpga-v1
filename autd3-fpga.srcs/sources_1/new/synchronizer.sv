/*
 * File: synchronizer.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module synchronizer#(
           parameter int SYS_CLK_FREQ = 20400000,
           parameter int ULTRASOUND_FREQ = 40000,
           parameter int SYNC0_FREQ = 1000,
           localparam int ULTRASOUND_CNT_CYCLE = SYS_CLK_FREQ/ULTRASOUND_FREQ,
           localparam int ULTRASOUND_CNT_CYCLE_WIDTH = $clog2(ULTRASOUND_CNT_CYCLE)
       )
       (
           input var CLK,
           input var RST,
           input var SYNC,
           input var SEQ_CLK_INIT,
           input var MOD_CLK_INIT,
           input var [15:0] SEQ_CLK_CYCLE,
           input var [15:0] SEQ_CLK_DIV,
           input var [15:0] MOD_CLK_CYCLE,
           input var [15:0] MOD_CLK_DIV,
           input var [63:0] SEQ_CLK_SYNC_TIME_NS,
           input var [63:0] MOD_CLK_SYNC_TIME_NS,
           output var [ULTRASOUND_CNT_CYCLE_WIDTH-1:0] TIME,
           output var [14:0] MOD_IDX,
           output var [15:0] SEQ_IDX
       );

logic [ULTRASOUND_CNT_CYCLE_WIDTH-1:0] time_cnt_for_ultrasound;

assign TIME = time_cnt_for_ultrasound;

always_ff @(posedge CLK)
    time_cnt_for_ultrasound <= (SYNC | (time_cnt_for_ultrasound == ULTRASOUND_CNT_CYCLE - 1)) ? 0 : time_cnt_for_ultrasound + 1;

///////////////////////////////// Reference Clock /////////////////////////////////////////
localparam int REF_CLK_FREQ = ULTRASOUND_FREQ;
localparam int REF_CLK_CYCLE = REF_CLK_FREQ / SYNC0_FREQ;
localparam int REF_CLK_DIVIDER_CYCLE = SYS_CLK_FREQ / REF_CLK_FREQ;
localparam [31:0] REF_CLK_CYCLE_NS = 1000000000 / REF_CLK_FREQ;

localparam int REF_CLK_CYCLE_CNT_WIDTH = $clog2(REF_CLK_CYCLE);
localparam int REF_CLK_DIVIDER_CNT_WIDTH = $clog2(REF_CLK_DIVIDER_CYCLE);

logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt;
logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt_sync;
logic [REF_CLK_DIVIDER_CNT_WIDTH-1:0] ref_clk_divider;
logic [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk_cnt_watch;
logic ref_clk_tick;

assign ref_clk_tick = (ref_clk_cnt != ref_clk_cnt_watch);

always_ff @(posedge CLK) begin
    if(SYNC) begin
        ref_clk_cnt <= 0;
        ref_clk_divider <= 0;
    end
    else begin
        if(ref_clk_divider == REF_CLK_DIVIDER_CYCLE - 1) begin
            ref_clk_divider <= 0;
            ref_clk_cnt <= (ref_clk_cnt == REF_CLK_CYCLE - 1) ? 0 : ref_clk_cnt + 1;
        end
        else begin
            ref_clk_divider <= ref_clk_divider + 1;
        end
    end
end

always_ff @(posedge CLK)
    ref_clk_cnt_watch <= ref_clk_cnt;
///////////////////////////////// Reference Clock /////////////////////////////////////////

//////////////////////////////////// Modulation ///////////////////////////////////////////
logic [15:0] mod_cnt;
logic [15:0] mod_cnt_div;

logic [95:0] mod_clk_sync_time_ref_unit;
logic [47:0] mod_tcycle;
logic [95:0] mod_shift;
logic [63:0] mod_cnt_shift;
logic [31:0] mod_div_shift;

assign MOD_IDX = mod_cnt;

divider64 div_ref_unit_mod(
              .s_axis_dividend_tdata(MOD_CLK_SYNC_TIME_NS),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata(REF_CLK_CYCLE_NS),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata(mod_clk_sync_time_ref_unit),
              .m_axis_dout_tvalid()
          );
mult_24 mult_tcycle_mod(
            .CLK(CLK),
            .A({8'd0, MOD_CLK_CYCLE}),
            .B({8'd0, MOD_CLK_DIV}),
            .P(mod_tcycle)
        );
divider64 sync_shift_rem_mod(
              .s_axis_dividend_tdata(mod_clk_sync_time_ref_unit[95:32]),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata(mod_tcycle[31:0]),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata(mod_shift),
              .m_axis_dout_tvalid()
          );
divider64 sync_shift_div_rem_mod(
              .s_axis_dividend_tdata({32'd0, mod_shift[31:0]}),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata({16'd0, MOD_CLK_DIV}),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata({mod_cnt_shift, mod_div_shift}),
              .m_axis_dout_tvalid()
          );

always_ff @(posedge CLK) begin
    if (SYNC & MOD_CLK_INIT) begin
        mod_cnt <= mod_cnt_shift[15:0];
        mod_cnt_div <= mod_div_shift[15:0];
    end
    else if(ref_clk_tick) begin
        if(mod_cnt_div == MOD_CLK_DIV - 1) begin
            mod_cnt_div <= 0;
            mod_cnt <= (mod_cnt == MOD_CLK_CYCLE - 1) ? 0 : mod_cnt + 1;
        end
        else begin
            mod_cnt_div <= mod_cnt_div + 1;
        end
    end
end
//////////////////////////////////// Modulation ///////////////////////////////////////////

////////////////////////////////// Sequence Clock /////////////////////////////////////////
logic [15:0] seq_cnt;
logic [15:0] seq_cnt_div;

assign SEQ_IDX = seq_cnt;

logic [95:0] seq_clk_sync_time_ref_unit;
logic [47:0] seq_tcycle;
logic [95:0] seq_shift;
logic [63:0] seq_cnt_shift;
logic [31:0] seq_div_shift;

divider64 div_ref_unit_seq(
              .s_axis_dividend_tdata(SEQ_CLK_SYNC_TIME_NS),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata(REF_CLK_CYCLE_NS),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata(seq_clk_sync_time_ref_unit),
              .m_axis_dout_tvalid()
          );
mult_24 mult_tcycle(
            .CLK(CLK),
            .A({8'd0, SEQ_CLK_CYCLE}),
            .B({8'd0, SEQ_CLK_DIV}),
            .P(seq_tcycle)
        );
divider64 sync_shift_rem(
              .s_axis_dividend_tdata(seq_clk_sync_time_ref_unit[95:32]),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata(seq_tcycle[31:0]),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata(seq_shift),
              .m_axis_dout_tvalid()
          );
divider64 sync_shift_div_rem(
              .s_axis_dividend_tdata({32'd0, seq_shift[31:0]}),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata({16'd0, SEQ_CLK_DIV}),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata({seq_cnt_shift, seq_div_shift}),
              .m_axis_dout_tvalid()
          );

always_ff @(posedge CLK) begin
    if (SYNC & SEQ_CLK_INIT) begin
        seq_cnt <= seq_cnt_shift[15:0];
        seq_cnt_div <= seq_div_shift[15:0];
    end
    else if(ref_clk_tick) begin
        if(seq_cnt_div == SEQ_CLK_DIV - 1) begin
            seq_cnt_div <= 0;
            seq_cnt <= (seq_cnt == SEQ_CLK_CYCLE - 1) ? 0 : seq_cnt + 1;
        end
        else begin
            seq_cnt_div <= seq_cnt_div + 1;
        end
    end
end
////////////////////////////////// Sequence Clock /////////////////////////////////////////

endmodule
