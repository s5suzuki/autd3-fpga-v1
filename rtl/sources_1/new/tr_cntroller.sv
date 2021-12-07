/*
 * File: tr_cntroller.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/12/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module tr_cntroller#(
           parameter int TRANS_NUM = 249,
           parameter int ULTRASOUND_CNT_CYCLE = 512,
           parameter string PHASE_INVERTED = "TRUE",
           parameter string ENABLE_MODULATION = "TRUE",
           parameter string ENABLE_SEQUENCE = "TRUE",
           parameter string ENABLE_SILENT = "TRUE",
           parameter string ENABLE_DELAY = "TRUE",
           parameter string ENABLE_SYNC_DBG = "TRUE"
       ) (
           input var CLK,
           input var CLK_LPF,
           input var CLK_MF,
           input var [8:0] TIME,
           input var UPDATE,
           cpu_bus_if.slave_port CPU_BUS,
           mod_sync_if.slave_port MOD_SYNC,
           seq_sync_if.slave_port SEQ_SYNC,
           input var SILENT,
           output var [15:0] MOD_CLK_CYCLE,
           output var [15:0] MOD_IDX,
           output var [15:0] SEQ_CLK_CYCLE,
           output var [15:0] SEQ_IDX,
           input var OUTPUT_EN,
           input var OUTPUT_BALANCE,
           output var [252:1] XDCR_OUT
       );

logic update;
BUFG bufg(.O(update), .I(UPDATE));

logic [7:0] normal_duty[0:TRANS_NUM-1];
logic [7:0] normal_phase[0:TRANS_NUM-1];
logic duty_offset[0:TRANS_NUM-1];
logic [6:0] delay[0:TRANS_NUM-1];

normal_operator#(
                   .TRANS_NUM(TRANS_NUM),
                   .ENABLE_DELAY(ENABLE_DELAY)
               ) normal_operator(
                   .*,
                   .UPDATE(update),
                   .DUTY(normal_duty),
                   .PHASE(normal_phase),
                   .DELAY(delay),
                   .DELAY_RST(delay_rst),
                   .DUTY_OFFSET(duty_offset)
               );

///////////////////////// Sequence Modulation //////////////////////////
logic [7:0] duty_raw[0:TRANS_NUM-1];
logic [7:0] phase_raw[0:TRANS_NUM-1];

if (ENABLE_SEQUENCE == "TRUE") begin
    logic [7:0] seq_duty[0:TRANS_NUM-1];
    logic [7:0] seq_phase[0:TRANS_NUM-1];
    seq_operator#(
                    .TRANS_NUM(TRANS_NUM)
                ) seq_operator(
                    .*,
                    .DUTY(seq_duty),
                    .PHASE(seq_phase)
                );
    assign duty_raw = SEQ_SYNC.OP_MODE ? seq_duty : normal_duty;
    assign phase_raw = SEQ_SYNC.OP_MODE ? seq_phase : normal_phase;
end
else begin
    assign duty_raw = normal_duty;
    assign phase_raw = normal_phase;
end
///////////////////////// Sequence Modulation //////////////////////////

///////////////////////// Amplitude Modulation /////////////////////////
logic [7:0] duty_modulated[0:TRANS_NUM-1];

if (ENABLE_MODULATION == "TRUE") begin
    modulator#(
                 .TRANS_NUM(TRANS_NUM),
                 .ENABLE_SYNC_DBG(ENABLE_SYNC_DBG)
             )
             modulator(
                 .*,
                 .DUTY(duty_raw),
                 .DUTY_MODULATED(duty_modulated)
             );
end
else begin
    assign duty_modulated = duty_raw;
end
///////////////////////// Amplitude Modulation /////////////////////////

///////////////////////////// Silent Mode //////////////////////////////
logic [7:0] duty_silent[0:TRANS_NUM-1];
logic [7:0] phase_silent[0:TRANS_NUM-1];

if (ENABLE_SILENT == "TRUE") begin
    logic [7:0] ds[0:TRANS_NUM-1];
    logic [7:0] ps[0:TRANS_NUM-1];
    silent_lpf_v2#(
                     .TRANS_NUM(TRANS_NUM)
                 ) silent_lpf_v2(
                     .*,
                     .CLK(CLK_LPF),
                     .DUTY(duty_modulated),
                     .PHASE(phase_raw),
                     .DUTYS(ds),
                     .PHASES(ps)
                 );
    assign duty_silent = SILENT ? ds : duty_modulated;
    assign phase_silent = SILENT ? ps : phase_raw;
end
else begin
    assign duty_silent = duty_modulated;
    assign phase_silent = phase_raw;
end
///////////////////////////// Silent Mode //////////////////////////////

///////////////////////////// Delay output /////////////////////////////
logic [7:0] duty_delayed[0:TRANS_NUM-1];
logic [7:0] phase_delayed[0:TRANS_NUM-1];

if (ENABLE_DELAY == "TRUE") begin
    for (genvar ii = 0; ii < TRANS_NUM; ii++) begin
        delayed_fifo delayed_fifo(
                         .*,
                         .RST(delay_rst),
                         .UPDATE(update),
                         .DELAY(delay[ii]),
                         .DATA_IN({duty_silent[ii], phase_silent[ii]}),
                         .DATA_OUT({duty_delayed[ii], phase_delayed[ii]})
                     );
    end
end
else begin
    always_ff @(posedge CLK) begin
        duty_delayed <= update ? duty_silent : duty_delayed;
        phase_delayed <= update ? phase_silent : phase_delayed;
    end
end
///////////////////////////// Delay output /////////////////////////////

logic balance = 0;
always_ff @(posedge CLK)
    balance <= OUTPUT_BALANCE ? ~balance : 0;

`include "cvt_uid.vh"
for (genvar ii = 0; ii < TRANS_NUM; ii++) begin
    logic pwm_out;
    logic tr_out;
    assign XDCR_OUT[cvt_uid(ii) + 1] = tr_out;
    pwm_generator #(
                      .PHASE_INVERTED(PHASE_INVERTED)
                  ) pwm_generator(
                      .*,
                      .DUTY(duty_delayed[ii]),
                      .PHASE(phase_delayed[ii]),
                      .DUTY_OFFSET(duty_offset[ii]),
                      .PWM_OUT(pwm_out)
                  );
    always_ff @(posedge CLK)
        tr_out <= OUTPUT_EN ? pwm_out : balance;
end

endmodule
