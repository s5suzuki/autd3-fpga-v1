/*
 * File: seq_operator.sv
 * Project: sequence
 * Created Date: 13/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 20/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

// The unit of focus calculation is WAVELENGTH/256
module seq_operator#(
           parameter TRANS_NUM = 249
       )(
           input var CLK,
           seq_bus_if.slave_port SEQ_BUS,
           input var [15:0] SEQ_IDX,
           input var [15:0] WAVELENGTH_UM,
           input var SEQ_DATA_MODE,
           output var [7:0] DUTY[0:TRANS_NUM-1],
           output var [7:0] PHASE[0:TRANS_NUM-1]
       );

`include "../cvt_uid.vh"
`include "../param.vh"

localparam TRANS_NUM_X = 18;
localparam TRANS_NUM_Y = 14;

localparam [23:0] TRANS_SPACING_UNIT = 24'd2600960; // TRNAS_SPACING*255 = 10.16e3 um * 256
localparam int MULT_DIVIDER_LATENCY = 4 + 28;

logic [$clog2(MULT_DIVIDER_LATENCY)-1:0] wait_cnt;

logic fc_trig;
logic signed [17:0] focus_x, focus_y, focus_z;
logic [31:0] trans_x, trans_y;
logic [7:0] phase_out;
logic phase_out_valid;

logic [15:0] seq_idx = 16'd0;
logic [15:0] seq_idx_old = 16'd0;
logic [63:0] data_out;
logic idx_change;

logic [7:0] duty[0:TRANS_NUM-1];
logic [7:0] phase[0:TRANS_NUM-1];
logic [8:0] tr_cnt;
logic [7:0] tr_cnt_uid;
logic [23:0] tr_cnt_x, tr_cnt_y;
logic [47:0] tr_x_u, tr_y_u;
logic [7:0] tr_cnt_in;

logic [15:0] _unused_x, _unused_y;

enum logic [1:0] {
         WAIT,
         DIV_WAIT,
         FC_DATA_IN_STREAM,
         LOAD_DUTY_PHASE
     } state_calc = WAIT;

assign idx_change = (seq_idx != seq_idx_old);

assign DUTY = duty;
assign PHASE = phase;

assign SEQ_BUS.IDX = SEQ_IDX;
assign data_out = SEQ_BUS.DATA_OUT;

assign tr_cnt_uid = cvt_uid(tr_cnt[7:0]);
assign tr_cnt_x = tr_cnt_uid % TRANS_NUM_X;
assign tr_cnt_y = tr_cnt_uid / TRANS_NUM_X;

mult_24 mult_24_tr_x(
            .CLK(CLK),
            .A(tr_cnt_x),
            .B(TRANS_SPACING_UNIT),
            .P(tr_x_u)
        );
mult_24 mult_24_tr_y(
            .CLK(CLK),
            .A(tr_cnt_y),
            .B(TRANS_SPACING_UNIT),
            .P(tr_y_u)
        );
divider div_x(
            .s_axis_dividend_tdata(tr_x_u[31:0]),
            .s_axis_dividend_tvalid(1'b1),
            .s_axis_divisor_tdata(WAVELENGTH_UM),
            .s_axis_divisor_tvalid(1'b1),
            .aclk(CLK),
            .m_axis_dout_tdata({trans_x, _unused_x}),
            .m_axis_dout_tvalid()
        );
divider div_y(
            .s_axis_dividend_tdata(tr_y_u[31:0]),
            .s_axis_dividend_tvalid(1'b1),
            .s_axis_divisor_tdata(WAVELENGTH_UM),
            .s_axis_divisor_tvalid(1'b1),
            .aclk(CLK),
            .m_axis_dout_tdata({trans_y, _unused_y}),
            .m_axis_dout_tvalid()
        );

focus_calculator focus_calculator(
                     .CLK(CLK),
                     .DVALID_IN(fc_trig),
                     .FOCUS_X(focus_x),
                     .FOCUS_Y(focus_y),
                     .FOCUS_Z(focus_z),
                     .TRANS_X(trans_x[17:0]),
                     .TRANS_Y(trans_y[17:0]),
                     .TRANS_Z(18'sd0),
                     .PHASE(phase_out),
                     .PHASE_CALC_DONE(phase_out_valid)
                 );

always_ff @(posedge CLK) begin
    seq_idx <= SEQ_IDX;
    seq_idx_old <= seq_idx;
end

always_ff @(posedge CLK) begin
    case(SEQ_DATA_MODE)
        SEQ_DATA_MODE_FOCI: begin
            if(phase_out_valid) begin
                phase[tr_cnt_in] <= phase_out;
                tr_cnt_in <= tr_cnt_in + 1;
            end
            else begin
                tr_cnt_in <= 0;
            end

            case(state_calc)
                WAIT: begin
                    if (idx_change) begin
                        fc_trig <= 0;
                        tr_cnt <= 0;
                        wait_cnt <= 0;
                        state_calc <= DIV_WAIT;
                    end
                end
                DIV_WAIT: begin
                    tr_cnt <= tr_cnt + 1;
                    wait_cnt <= wait_cnt + 1;
                    if (wait_cnt == MULT_DIVIDER_LATENCY - 1) begin
                        focus_x <= data_out[17:0];
                        focus_y <= data_out[35:18];
                        focus_z <= data_out[53:36];
                        duty <= '{TRANS_NUM{data_out[61:54]}};
                        fc_trig <= 1'b1;
                        state_calc <= FC_DATA_IN_STREAM;
                    end
                end
                FC_DATA_IN_STREAM: begin
                    tr_cnt <= tr_cnt + 1;
                    if (tr_cnt == TRANS_NUM + MULT_DIVIDER_LATENCY - 1) begin
                        state_calc <= WAIT;
                        fc_trig <= 0;
                    end
                end
            endcase
        end
        SEQ_DATA_MODE_RAW_DUTY_PHASE: begin
            case(state_calc)
                WAIT: begin
                    if (idx_change) begin
                        tr_cnt <= 0;
                        state_calc <= LOAD_DUTY_PHASE;
                    end
                end
                LOAD_DUTY_PHASE: begin
                    if (tr_cnt < ((TRANS_NUM >> 2) << 2)) begin
                        {duty[tr_cnt], phase[tr_cnt]} <= data_out[15:0];
                        {duty[tr_cnt + 1], phase[tr_cnt + 1]} <= data_out[31:16];
                        {duty[tr_cnt + 2], phase[tr_cnt + 2]} <= data_out[47:32];
                        {duty[tr_cnt + 3], phase[tr_cnt + 3]} <= data_out[63:48];
                        tr_cnt <= tr_cnt + 4;
                    end
                    else begin
                        {duty[tr_cnt], phase[tr_cnt]} <= data_out[15:0];
                        state_calc <= WAIT;
                    end
                end
                default:
                    state_calc <= WAIT;
            endcase
        end
    endcase
end

endmodule
