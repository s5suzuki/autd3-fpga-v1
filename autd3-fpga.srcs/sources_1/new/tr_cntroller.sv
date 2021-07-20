/*
 * File: tr_cntroller.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 20/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module tr_cntroller#(
           parameter int TRANS_NUM = 249,
           parameter int ULTRASOUND_CNT_CYCLE = 512,
           parameter int DELAY_DEPTH = 8
       )
       (
           input var CLK,
           input var CLK_LPF,
           input var [8:0] TIME,
           input var UPDATE,
           tr_bus_if.slave_port TR_BUS,
           input var [7:0] MOD,
           input var SILENT,
           seq_bus_if.slave_port SEQ_BUS,
           input var SEQ_MODE,
           input var [15:0] SEQ_IDX,
           input var [15:0] WAVELENGTH_UM,
           input var SEQ_DATA_MODE,
           output var [252:1] XDCR_OUT,
           input var [255:0] OUTPUT_EN
       );

logic [7:0] seq_duty[0:TRANS_NUM-1];
logic [7:0] seq_phase[0:TRANS_NUM-1];

logic output_en;
logic duty_offset[0:TRANS_NUM-1];
logic [DELAY_DEPTH-1:0] delay[0:TRANS_NUM-1];

logic [7:0] tr_buf_write_idx;
logic [8:0] tr_bram_idx;
logic [15:0] tr_bram_dataout;
logic [7:0] duty_buf[0:TRANS_NUM-1];
logic [7:0] phase_buf[0:TRANS_NUM-1];

assign TR_BUS.IDX = tr_bram_idx;
assign tr_bram_dataout = TR_BUS.DATA_OUT;

enum logic [2:0] {
         IDLE,
         DUTY_PHASE_WAIT_0,
         DUTY_PHASE_WAIT_1,
         DUTY_PHASE,
         DELAY_EN_WAIT_0,
         DELAY_EN_WAIT_1,
         DELAY_EN
     } tr_state = IDLE;

logic update;
BUFG bufg(.O(update), .I(UPDATE));

seq_operator#(
                .TRANS_NUM(TRANS_NUM)
            ) seq_operator(
                .CLK(CLK),
                .SEQ_BUS(SEQ_BUS),
                .SEQ_IDX(SEQ_IDX),
                .WAVELENGTH_UM(WAVELENGTH_UM),
                .SEQ_DATA_MODE(SEQ_DATA_MODE),
                .DUTY(seq_duty),
                .PHASE(seq_phase)
            );

always_ff @(posedge CLK) begin
    case(tr_state)
        IDLE: begin
            if (update) begin
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
                tr_state <= DELAY_EN_WAIT_0;
            end
            else begin
                tr_bram_idx <= tr_bram_idx + 1;
                tr_buf_write_idx <= tr_buf_write_idx + 1;
            end
        end
        DELAY_EN_WAIT_0: begin
            tr_bram_idx <= tr_bram_idx + 1;
            tr_state <= DELAY_EN_WAIT_1;
        end
        DELAY_EN_WAIT_1: begin
            tr_bram_idx <= tr_bram_idx + 1;
            tr_buf_write_idx <= 0;
            tr_state <= DELAY_EN;
        end
        DELAY_EN: begin
            if (tr_buf_write_idx == TRANS_NUM) begin
                output_en <= tr_bram_dataout[DELAY_DEPTH];
                tr_state <= IDLE;
            end
            else begin
                duty_offset[tr_buf_write_idx] <= tr_bram_dataout[DELAY_DEPTH];
                delay[tr_buf_write_idx] <= tr_bram_dataout[DELAY_DEPTH-1:0];
                tr_bram_idx <= tr_bram_idx + 1;
                tr_buf_write_idx <= tr_buf_write_idx + 1;
            end
        end
    endcase
end

logic [8:0] mod;
assign mod = {1'b0, MOD} + 9'd1;

`include "cvt_uid.vh"
generate begin:TRANSDUCERS_GEN
        genvar ii;
        for(ii = 0; ii < TRANS_NUM; ii++) begin
            logic [7:0] duty, phase;
            logic pwm_out;
            logic [16:0] duty_modulated;
            assign duty = SEQ_MODE ? seq_duty[ii] : duty_buf[ii];
            assign phase = SEQ_MODE ? seq_phase[ii] : phase_buf[ii];
            assign XDCR_OUT[cvt_uid(ii) + 1] = pwm_out & output_en;
            mult8x8 mod_mult(
                        .CLK(CLK),
                        .A(duty),
                        .B(mod),
                        .P(duty_modulated)
                    );
            transducer#(
                          .ULTRASOUND_CNT_CYCLE(ULTRASOUND_CNT_CYCLE),
                          .DELAY_DEPTH(DELAY_DEPTH)
                      ) tr(
                          .CLK(CLK),
                          .CLK_LPF(CLK_LPF),
                          .TIME(TIME),
                          .UPDATE(update),
                          .DUTY(duty_modulated[15:8]),
                          .DUTY_OFFSET(duty_offset[ii]),
                          .PHASE(phase),
                          .DELAY(delay[ii]),
                          .SILENT(SILENT),
                          .PWM_OUT(pwm_out)
                      );
        end
    end
endgenerate

endmodule
