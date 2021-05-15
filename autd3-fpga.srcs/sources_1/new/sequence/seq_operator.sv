/*
 * File: seq_operator.sv
 * Project: sequence
 * Created Date: 13/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 13/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

// The unit of focus calculation is WAVELENGTH/255.
module seq_operator#(
           parameter TRANS_NUM = 249
       )(
           input var CLK,
           input var RST,
           seq_bus_if.slave_port SEQ_BUS,
           input var [15:0] SEQ_IDX,
           input var [15:0] WAVELENGTH_UM,
           output var [7:0] DUTY[0:TRANS_NUM-1],
           output var [7:0] PHASE[0:TRANS_NUM-1]
       );

`include "../cvt_uid.vh"
localparam TRANS_NUM_X = 18;
localparam TRANS_NUM_Y = 14;

localparam [21:0] TRANS_SPACING_UNIT = 22'd2590800; // TRNAS_SPACING*255 = 10.16*255

logic fc_trig;
logic signed [23:0] focus_x, focus_y, focus_z;
logic signed [47:0] trans_x, trans_y;
logic [7:0] phase_out;
logic phase_out_valid;

logic [15:0] seq_idx;
logic [15:0] seq_idx_old;
logic [79:0] data_out;
logic idx_change;

logic [7:0] duty;
logic [7:0] phase[0:TRANS_NUM-1];
logic [7:0] tr_cnt;
logic [7:0] tr_cnt_uid;
logic [23:0] tr_cnt_x, tr_cnt_y;
logic [7:0] tr_cnt_in;

logic [23:0] trans_spacing;
logic [15:0] _unused;
logic dout_tvalid;

enum logic [3:0] {
         WAIT,
         POS_WAIT_0,
         POS_WAIT_1,
         POS_WAIT_2,
         POS_WAIT_3,
         FC_DATA_IN_STREAM,
         PHASE_CALC_WAIT
     } state_calc;

assign idx_change = (seq_idx != seq_idx_old);

assign DUTY = '{TRANS_NUM{duty}};
assign PHASE = phase;

assign SEQ_BUS.IDX = SEQ_IDX;
assign data_out = SEQ_BUS.DATA_OUT;

assign tr_cnt_uid = cvt_uid(tr_cnt);
assign tr_cnt_x = tr_cnt_uid % TRANS_NUM_X;
assign tr_cnt_y = tr_cnt_uid / TRANS_NUM_X;

div_22_by_16 div_22_by_16(
                 .s_axis_dividend_tdata(TRANS_SPACING_UNIT),
                 .s_axis_dividend_tvalid(1'b1),
                 .s_axis_divisor_tdata(WAVELENGTH_UM),
                 .s_axis_divisor_tvalid(1'b1),
                 .aclk(CLK),
                 .m_axis_dout_tdata({trans_spacing, _unused}),
                 .m_axis_dout_tvalid()
             );
mult_24 mult_24_tr_x(
            .CLK(CLK),
            .A(tr_cnt_x),
            .B(trans_spacing),
            .P(trans_x)
        );
mult_24 mult_24_tr_y(
            .CLK(CLK),
            .A(tr_cnt_y),
            .B(trans_spacing),
            .P(trans_y)
        );

focus_calculator focus_calculator(
                     .CLK(CLK),
                     .RST(RST),
                     .DVALID_IN(fc_trig),
                     .FOCUS_X(focus_x),
                     .FOCUS_Y(focus_y),
                     .FOCUS_Z(focus_z),
                     .TRANS_X(trans_x[23:0]),
                     .TRANS_Y(trans_y[23:0]),
                     .TRANS_Z(24'sd0),
                     .PHASE(phase_out),
                     .PHASE_CALC_DONE(phase_out_valid)
                 );

always_ff @(posedge CLK)
    seq_idx_old <= RST ? 0 : seq_idx;

always_ff @(posedge CLK) begin
    if (RST) begin
        focus_x <= 0;
        focus_y <= 0;
        focus_z <= 0;
        duty <= 0;
        fc_trig <= 0;
        tr_cnt <= 0;
        state_calc <= WAIT;
    end
    else begin
        case(state_calc)
            WAIT: begin
                if(idx_change) begin
                    tr_cnt <= tr_cnt + 1;
                    state_calc <= POS_WAIT_0;
                end
            end
            POS_WAIT_0: begin
                tr_cnt <= tr_cnt + 1;
                state_calc <= POS_WAIT_1;
            end
            POS_WAIT_1: begin
                tr_cnt <= tr_cnt + 1;
                state_calc <= POS_WAIT_2;
            end
            POS_WAIT_2: begin
                tr_cnt <= tr_cnt + 1;
                state_calc <= POS_WAIT_3;
            end
            POS_WAIT_3: begin
                focus_x <= data_out[23:0];
                focus_y <= data_out[47:24];
                focus_z <= data_out[71:48];
                duty <= data_out[79:72];
                fc_trig <= 1'b1;
                tr_cnt <= tr_cnt + 1;
                state_calc <= FC_DATA_IN_STREAM;
            end
            FC_DATA_IN_STREAM: begin
                tr_cnt <= (tr_cnt == TRANS_NUM + 4) ? 0 : tr_cnt + 1;
                state_calc <= (tr_cnt == TRANS_NUM + 4) ? WAIT : FC_DATA_IN_STREAM;
                fc_trig <= (tr_cnt == TRANS_NUM + 4) ? 0 : fc_trig;
            end
        endcase
    end
end

always_ff @(posedge CLK) begin
    if (RST) begin
        phase <= '{TRANS_NUM{8'h00}};
        tr_cnt_in <= 0;
    end
    else if(phase_out_valid) begin
        phase[tr_cnt_in] <= phase_out;
        tr_cnt_in <= tr_cnt_in + 1;
    end
end

endmodule
