/*
 * File: normal_operator.sv
 * Project: new
 * Created Date: 26/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 26/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`include "param.vh"
module normal_operator#(
           parameter int TRANS_NUM = 249,
           parameter int DELAY_DEPTH = 8
       )(
           input var CLK,
           input var UPDATE,
           tr_bus_if.slave_port TR_BUS,
           output var [7:0] DUTY[0:TRANS_NUM-1],
           output var [7:0] PHASE[0:TRANS_NUM-1],
           output var DUTY_OFFSET[0:TRANS_NUM-1],
`ifdef ENABLE_DELAY
           output var [7:0] DELAY[0:TRANS_NUM-1],
`endif
           output var OUTPUT_EN
       );

logic [7:0] tr_buf_write_idx;
logic [8:0] tr_bram_idx;
logic [15:0] tr_bram_dataout;
logic [7:0] duty_buf[0:TRANS_NUM-1];
logic [7:0] phase_buf[0:TRANS_NUM-1];

logic output_en;
logic duty_offset[0:TRANS_NUM-1];

assign TR_BUS.IDX = tr_bram_idx;
assign tr_bram_dataout = TR_BUS.DATA_OUT;

assign DUTY = duty_buf;
assign PHASE = phase_buf;
assign DUTY_OFFSET = duty_offset;
assign OUTPUT_EN = output_en;

`ifdef ENABLE_DELAY
logic [DELAY_DEPTH-1:0] delay[0:TRANS_NUM-1];
assign DELAY = delay;
`endif

enum logic [2:0] {
         IDLE,
         DUTY_PHASE_WAIT_0,
         DUTY_PHASE_WAIT_1,
         DUTY_PHASE,
         DELAY_OFFSET_WAIT_0,
         DELAY_OFFSET_WAIT_1,
         DELAY_OFFSET
     } tr_state = IDLE;

always_ff @(posedge CLK) begin
    case(tr_state)
        IDLE: begin
            if (UPDATE) begin
                tr_bram_idx <= 9'd0;
                tr_state <= DUTY_PHASE_WAIT_0;
            end
        end
        DUTY_PHASE_WAIT_0: begin
            tr_bram_idx <= tr_bram_idx + 1;
            tr_state <= DUTY_PHASE_WAIT_1;
        end
        DUTY_PHASE_WAIT_1: begin
            tr_bram_idx <= tr_bram_idx + 1;
            tr_buf_write_idx <= 0;
            tr_state <= DUTY_PHASE;
        end
        DUTY_PHASE: begin
            duty_buf[tr_buf_write_idx] <= tr_bram_dataout[15:8];
            phase_buf[tr_buf_write_idx] <= tr_bram_dataout[7:0];
            if (tr_buf_write_idx == TRANS_NUM - 1) begin
                tr_bram_idx <= 9'h100;
                tr_state <= DELAY_OFFSET_WAIT_0;
            end
            else begin
                tr_bram_idx <= tr_bram_idx + 1;
                tr_buf_write_idx <= tr_buf_write_idx + 1;
            end
        end
        DELAY_OFFSET_WAIT_0: begin
            tr_bram_idx <= tr_bram_idx + 1;
            tr_state <= DELAY_OFFSET_WAIT_1;
        end
        DELAY_OFFSET_WAIT_1: begin
            tr_bram_idx <= tr_bram_idx + 1;
            tr_buf_write_idx <= 0;
            tr_state <= DELAY_OFFSET;
        end
        DELAY_OFFSET: begin
            if (tr_buf_write_idx == TRANS_NUM) begin
                output_en <= tr_bram_dataout[DELAY_DEPTH];
                tr_state <= IDLE;
            end
            else begin
                duty_offset[tr_buf_write_idx] <= tr_bram_dataout[DELAY_DEPTH];
`ifdef ENABLE_DELAY

                delay[tr_buf_write_idx] <= tr_bram_dataout[DELAY_DEPTH-1:0];
`endif

                tr_bram_idx <= tr_bram_idx + 1;
                tr_buf_write_idx <= tr_buf_write_idx + 1;
            end
        end
    endcase
end

endmodule
