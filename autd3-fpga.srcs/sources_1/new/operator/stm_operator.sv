/*
 * File: stm_operator.sv
 * Project: operator
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 02/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module stm_operator#(
           parameter TRANS_NUM = 249
       )(
           stm_op_bus_if.master_port STM_OP_BUS,

           input var [15:0] STM_IDX,
           input var [15:0] STM_CLK_DIV,

           input var SYS_CLK,
           output var [7:0] DUTY[0:TRANS_NUM-1],
           output var [7:0] PHASE[0:TRANS_NUM-1]
       );

`include "../cvt_uid.vh"
localparam TRANS_NUM_X = 18;
localparam TRANS_NUM_Y = 14;

logic fc_trig = 0;
logic signed [23:0] focus_x = 0;
logic signed [23:0] focus_y = 0;
logic signed [23:0] focus_z = 0;
logic signed [23:0] trans_x = 0;
logic signed [23:0] trans_y = 0;
logic [7:0] phase_out;
logic phase_out_valid;

logic [15:0] bram_idx;
logic [15:0] bram_idx_old = 0;
logic [79:0] data_out;
logic idx_change = 0;

logic [7:0] duty = 0;
logic [7:0] duty_buf = 0;
logic [7:0] phase[0:TRANS_NUM-1] = '{TRANS_NUM{8'h00}};
logic [7:0] phase_buf[0:TRANS_NUM-1] = '{TRANS_NUM{8'h00}};
logic [7:0] tr_cnt = 0;
logic [7:0] tr_cnt_uid;
logic [15:0] tr_cnt_x;
logic [15:0] tr_cnt_y;
logic [7:0] tr_cnt_in = 0;

enum logic [3:0] {
         WAIT,
         POS_WAIT_0,
         POS_WAIT_1,
         FC_DATA_IN_STREAM,
         PHASE_CALC_WAIT
     } state_calc = WAIT;

assign DUTY = '{TRANS_NUM{duty}};
assign PHASE = phase;

assign bram_idx = STM_IDX / STM_CLK_DIV;
assign STM_OP_BUS.ADDR = bram_idx;
assign data_out = STM_OP_BUS.DATA;

assign tr_cnt_uid = cvt_uid(tr_cnt);
assign tr_cnt_x = tr_cnt_uid % TRANS_NUM_X;
assign tr_cnt_y = tr_cnt_uid / TRANS_NUM_X;

focus_calculator focus_calculator(
                     .SYS_CLK(SYS_CLK),
                     .DVALID_IN(fc_trig),
                     .FOCUS_X(focus_x),
                     .FOCUS_Y(focus_y),
                     .FOCUS_Z(focus_z),
                     .TRANS_X(trans_x),
                     .TRANS_Y(trans_y),
                     .TRANS_Z(24'sd0),
                     .PHASE(phase_out),
                     .PHASE_CALC_DONE(phase_out_valid)
                 );

always_ff @(posedge SYS_CLK) begin
    if(bram_idx_old != bram_idx) begin
        bram_idx_old <= bram_idx;
        idx_change <= 1;
    end
    else begin
        idx_change <= 0;
    end
end

always_ff @(posedge SYS_CLK) begin
    case(state_calc)
        WAIT: begin
            if(idx_change) begin
                state_calc <= POS_WAIT_0;
            end
        end
        POS_WAIT_0: begin
            state_calc <= POS_WAIT_1;
        end
        POS_WAIT_1: begin
            focus_x <= data_out[23:0];
            focus_y <= data_out[47:24];
            focus_z <= data_out[71:48];
            duty_buf <= data_out[79:72];

            fc_trig <= 1'b1;
            trans_x <= 0;
            trans_y <= 0;
            tr_cnt <= 1;

            state_calc <= FC_DATA_IN_STREAM;
        end
        FC_DATA_IN_STREAM: begin
            // *302.5 ~ (TRANS_SIZE) / (WAVE_LENGTH/256)
            trans_x <= ({1'b0, tr_cnt_x, 8'b00000000} + {4'b0, tr_cnt_x, 5'b00000} + {6'b0, tr_cnt_x, 3'b0000} + {7'b0, tr_cnt_x, 2'b0} + {8'b0, tr_cnt_x, 1'b0}) + (tr_cnt_x >> 1);
            trans_y <= ({1'b0, tr_cnt_y, 8'b00000000} + {4'b0, tr_cnt_y, 5'b00000} + {6'b0, tr_cnt_y, 3'b0000} + {7'b0, tr_cnt_y, 2'b0} + {8'b0, tr_cnt_y, 1'b0}) + (tr_cnt_y >> 1);
            tr_cnt <= tr_cnt + 1;

            state_calc <= (tr_cnt == TRANS_NUM) ? WAIT : FC_DATA_IN_STREAM;
            fc_trig <= (tr_cnt == TRANS_NUM) ? 0 : fc_trig;
        end
    endcase
end

always_ff @(posedge SYS_CLK) begin
    if(idx_change) begin
        phase <= phase_buf;
        duty <= duty_buf;
        tr_cnt_in <= 0;
    end
    else if(phase_out_valid) begin
        phase_buf[tr_cnt_in] <= phase_out;
        tr_cnt_in <= tr_cnt_in + 1;
    end
end

endmodule
