/*
 * File: tr_cntroller.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 09/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module tr_cntroller#(
           parameter int TRANS_NUM = 249,
           parameter int ULTRASOUND_CNT_CYCLE = 510
       )
       (
           input var CLK,
           input var RST,
           input var CLK_LPF,
           input var [8:0] TIME,
           mod_bus_if.slave_port MOD_BUS,
           tr_bus_if.slave_port TR_BUS,
           output var [252:1] XDCR_OUT
       );

logic [7:0] duty[0:TRANS_NUM-1];
logic [7:0] phase[0:TRANS_NUM-1];

logic [7:0] tr_buf_write_idx;
logic [7:0] tr_bram_idx;
logic [15:0] tr_bram_dataout;
logic [7:0] duty_buf[0:TRANS_NUM-1];
logic [7:0] phase_buf[0:TRANS_NUM-1];

assign TR_BUS.IDX = tr_bram_idx;
assign tr_bram_dataout = TR_BUS.DATA_OUT;

enum logic [2:0] {
         IDLE,
         DUTY_PHASE_WAIT_0,
         DUTY_PHASE_WAIT_1,
         DUTY_PHASE
     } tr_state;

always_ff @(posedge CLK) begin
    if (RST) begin
        tr_bram_idx <= 0;
        tr_state <= IDLE;
        tr_buf_write_idx <= 0;
        duty_buf <= '{TRANS_NUM{8'h00}};
        phase_buf <= '{TRANS_NUM{8'h00}};
    end
    else begin
        case(tr_state)
            IDLE: begin
                if (TIME == 10'd0) begin
                    tr_bram_idx <= 8'd0;
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
                    tr_bram_idx <= 8'd0;
                    tr_state <= IDLE;
                end
                else begin
                    tr_bram_idx <= tr_bram_idx + 1;
                    tr_buf_write_idx <= tr_buf_write_idx + 1;
                    tr_state <= DUTY_PHASE;
                end
            end
        endcase
    end
end

always_ff @(posedge CLK) begin
    if (RST) begin
        duty <= '{TRANS_NUM{8'h00}};
        phase <= '{TRANS_NUM{8'h00}};
    end
    else if (TIME == (ULTRASOUND_CNT_CYCLE - 1)) begin
        duty <= duty_buf;
        phase <= phase_buf;
    end
end

`include "cvt_uid.vh"
generate begin:TRANSDUCERS_GEN
        genvar ii;
        for(ii = 0; ii < TRANS_NUM; ii++) begin
            logic [7:0] duty_modulated;
            assign duty_modulated = modulate_duty(duty[ii], MOD_BUS.DATA_OUT);
            transducer#(
                          .ULTRASOUND_CNT_CYCLE(ULTRASOUND_CNT_CYCLE)
                      ) tr(
                          .CLK(CLK),
                          .RST(RST),
                          .CLK_LPF(CLK_LPF),
                          .TIME(TIME),
                          .DUTY(duty_modulated),
                          .PHASE(phase[ii]),
                          .SILENT(1'b0),
                          .PWM_OUT(XDCR_OUT[cvt_uid(ii) + 1])
                      );
        end
    end
endgenerate

function automatic [7:0] modulate_duty;
    input [7:0] duty;
    input [7:0] mod;
    modulate_duty = (({9'd0, duty} + 17'd1) * ({9'd0, mod} + 17'd1) - 17'd1) >> 8;
endfunction

endmodule
