/*
 * File: tr_cntroller.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 27/09/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
`include "features.vh"
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
           cpu_bus_if.slave_port CPU_BUS,
`ifdef ENABLE_MODULATION
           mod_sync_if.slave_port MOD_SYNC,
`endif
`ifdef ENABLE_SEQUENCE
           seq_sync_if.slave_port SEQ_SYNC,
`endif
`ifdef ENABLE_SILENT
           input var SILENT,
`endif
`ifdef ENABLE_SYNC_DBG
           output var [15:0] MOD_CLK_CYCLE,
           output var [15:0] MOD_IDX,
           output var [15:0] SEQ_CLK_CYCLE,
           output var [15:0] SEQ_IDX,
`endif
           output var [252:1] XDCR_OUT
       );

logic update;
BUFG bufg(.O(update), .I(UPDATE));

logic [7:0] normal_duty[0:TRANS_NUM-1];
logic [7:0] normal_phase[0:TRANS_NUM-1];
logic duty_offset[0:TRANS_NUM-1];
`ifdef ENABLE_DELAY
logic [7:0] delay[0:TRANS_NUM-1];
`endif
logic output_en;
logic output_balance;

normal_operator#(
                   .TRANS_NUM(TRANS_NUM)
               ) normal_operator(
                   .CLK(CLK),
                   .UPDATE(update),
                   .CPU_BUS(CPU_BUS),
                   .DUTY(normal_duty),
                   .PHASE(normal_phase),
                   .DUTY_OFFSET(duty_offset),
`ifdef ENABLE_DELAY
                   .DELAY(delay),
`endif
                   .OUTPUT_EN(output_en),
                   .OUTPUT_BALANCE(output_balance)
               );

///////////////////////// Sequence Modulation //////////////////////////
logic [7:0] duty_raw[0:TRANS_NUM-1];
logic [7:0] phase_raw[0:TRANS_NUM-1];

`ifdef ENABLE_SEQUENCE
logic [7:0] seq_duty[0:TRANS_NUM-1];
logic [7:0] seq_phase[0:TRANS_NUM-1];
seq_operator#(
                .TRANS_NUM(TRANS_NUM)
            ) seq_operator(
                .CLK(CLK),
                .CPU_BUS(CPU_BUS),
                .SEQ_SYNC(SEQ_SYNC),
`ifdef ENABLE_SYNC_DBG
                .SEQ_CLK_CYCLE(SEQ_CLK_CYCLE),
                .SEQ_IDX(SEQ_IDX),
`endif
                .DUTY(seq_duty),
                .PHASE(seq_phase)
            );
assign duty_raw = SEQ_SYNC.SEQ_MODE ? seq_duty : normal_duty;
assign phase_raw = SEQ_SYNC.SEQ_MODE ? seq_phase : normal_phase;
`else
assign duty_raw = normal_duty;
assign phase_raw = normal_phase;
`endif
///////////////////////// Sequence Modulation //////////////////////////

///////////////////////// Amplitude Modulation /////////////////////////
logic [7:0] duty_modulated[0:TRANS_NUM-1];

`ifdef ENABLE_MODULATION
modulator#(
             .TRANS_NUM(TRANS_NUM)
         ) modulator(
             .CLK(CLK),
             .CPU_BUS(CPU_BUS),
             .MOD_SYNC(MOD_SYNC),
`ifdef ENABLE_SYNC_DBG
             .MOD_CLK_CYCLE(MOD_CLK_CYCLE),
             .MOD_IDX(MOD_IDX),
`endif
             .DUTY(duty_raw),
             .DUTY_MODULATED(duty_modulated)
         );
`else
assign duty_modulated = duty_raw;
`endif
///////////////////////// Amplitude Modulation /////////////////////////

///////////////////////////// Silent Mode //////////////////////////////
logic [7:0] duty_silent[0:TRANS_NUM-1];
logic [7:0] phase_silent[0:TRANS_NUM-1];

`ifdef ENABLE_SILENT
logic [7:0] ds[0:TRANS_NUM-1];
logic [7:0] ps[0:TRANS_NUM-1];
silent_lpf_v2#(
                 .TRANS_NUM(TRANS_NUM)
             ) silent_lpf_v2(
                 .CLK(CLK_LPF),
                 .DUTY(duty_modulated),
                 .PHASE(phase_raw),
                 .DUTYS(ds),
                 .PHASES(ps)
             );
assign duty_silent = SILENT ? ds : duty_modulated;
assign phase_silent = SILENT ? ps : phase_raw;
`else
assign duty_silent = duty_modulated;
assign phase_silent = phase_raw;
`endif
///////////////////////////// Silent Mode //////////////////////////////

///////////////////////////// Delay output /////////////////////////////
logic [7:0] duty_delayed[0:TRANS_NUM-1];
logic [7:0] phase_delayed[0:TRANS_NUM-1];

`ifdef ENABLE_DELAY
generate begin:TRANSDUCERS_DELAY
        genvar ii;
        for(ii = 0; ii < TRANS_NUM; ii++) begin
            delayed_fifo #(
                             .DEPTH(DELAY_DEPTH)
                         ) delayed_fifo(
                             .CLK(CLK),
                             .UPDATE(update),
                             .DELAY(delay[ii]),
                             .DATA_IN(duty_silent[ii]),
                             .DATA_OUT(duty_delayed[ii])
                         );
        end
    end
endgenerate
`else
always_ff @(posedge CLK) begin
    duty_delayed <= update ? duty_silent : duty_delayed;
end
`endif

always_ff @(posedge CLK) begin
    phase_delayed <= update ? phase_silent : phase_delayed;
end
///////////////////////////// Delay output /////////////////////////////

logic balance = 0;
logic [4:0] balance_cnt = 0;
always_ff @(posedge CLK) begin
    if (output_balance) begin
        if (balance_cnt == 5'd19) begin
            balance <= ~balance;
            balance_cnt <= 0;
        end
        else begin
            balance_cnt <= balance_cnt + 1;
        end
    end
    else begin
        balance <= 0;
    end
end

`include "cvt_uid.vh"
generate begin:TRANSDUCERS_GEN
        genvar ii;
        for(ii = 0; ii < TRANS_NUM; ii++) begin
            logic pwm_out;
            logic tr_out;
            assign XDCR_OUT[cvt_uid(ii) + 1] = tr_out;
            pwm_generator pwm_generator(
                              .TIME(TIME),
                              .DUTY(duty_delayed[ii]),
                              .PHASE(phase_delayed[ii]),
                              .DUTY_OFFSET(duty_offset[ii]),
                              .PWM_OUT(pwm_out)
                          );
            always_ff @(posedge CLK) begin
                tr_out <= output_en ? pwm_out : balance;
            end
        end
    end
endgenerate

endmodule
