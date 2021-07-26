/*
 * File: tr_cntroller.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 26/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
`include "param.vh"
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

normal_operator#(
                   .TRANS_NUM(TRANS_NUM)
               ) normal_operator(
                   .CLK(CLK),
                   .UPDATE(update),
                   .TR_BUS(TR_BUS),
                   .DUTY(normal_duty),
                   .PHASE(normal_phase),
                   .DUTY_OFFSET(duty_offset),
`ifdef ENABLE_DELAY
                   .DELAY(delay),
`endif
                   .OUTPUT_EN(output_en)
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
                .SEQ_BUS(SEQ_BUS),
                .SEQ_IDX(SEQ_IDX),
                .WAVELENGTH_UM(WAVELENGTH_UM),
                .SEQ_DATA_MODE(SEQ_DATA_MODE),
                .DUTY(seq_duty),
                .PHASE(seq_phase)
            );
assign duty_raw = SEQ_MODE ? seq_duty : normal_duty;
assign phase_raw = SEQ_MODE ? seq_phase : normal_phase;
`else
assign duty_raw = normal_duty;
assign phase_raw = normal_phase;
`endif
///////////////////////// Sequence Modulation //////////////////////////

///////////////////////// Amplitude Modulation /////////////////////////
logic [8:0] mod;
assign mod = {1'b0, MOD} + 9'd1;
logic [7:0] duty_modulated[0:TRANS_NUM-1];

generate begin:TRANSDUCERS_MOD
        genvar ii;
        for(ii = 0; ii < TRANS_NUM; ii++) begin
            logic [16:0] dm;
            mult8x8 mod_mult(
                        .CLK(CLK),
                        .A(duty_raw[ii]),
                        .B(mod),
                        .P(dm)
                    );
            assign duty_modulated[ii] = dm[15:8];
        end
    end
endgenerate
///////////////////////// Amplitude Modulation /////////////////////////

///////////////////////////// Silent Mode //////////////////////////////
logic [7:0] duty_silent[0:TRANS_NUM-1];
logic [7:0] phase_silent[0:TRANS_NUM-1];

`ifdef ENABLE_SILENT
silent_lpf_v2#(
                 .TRANS_NUM(TRANS_NUM)
             ) silent_lpf_v2(
                 .CLK(CLK_LPF),
                 .DUTY(duty_modulated),
                 .PHASE(phase_raw),
                 .DUTYS(duty_silent),
                 .PHASES(phase_silent)
             );
`else
assign duty_silent = duty_modulated;
assign phase_silent = phase_raw;
`endif
///////////////////////////// Silent Mode //////////////////////////////

///////////////////////////// Delay output /////////////////////////////
logic [7:0] duty_delayed[0:TRANS_NUM-1];

`ifdef ENABLE_DELAY
generate begin:TRANSDUCERS_DELAY
        genvar ii;
        for(ii = 0; ii < TRANS_NUM; ii++) begin
            logic [7:0] ddi;
            logic [7:0] ddo;
            assign ddi = SILENT ? duty_silent[ii] : duty_modulated[ii];
            delayed_fifo #(
                             .DEPTH(DELAY_DEPTH)
                         ) delayed_fifo(
                             .CLK(CLK),
                             .UPDATE(update),
                             .DELAY(delay[ii]),
                             .DATA_IN(ddi),
                             .DATA_OUT(ddo)
                         );
            assign duty_delayed[ii] = ddo;
        end
    end
endgenerate
`else
assign duty_delayed = SILENT ? duty_silent : duty_modulated;
`endif
///////////////////////////// Delay output /////////////////////////////

`include "cvt_uid.vh"
generate begin:TRANSDUCERS_GEN
        genvar ii;
        for(ii = 0; ii < TRANS_NUM; ii++) begin
            logic [7:0] duty;
            logic [7:0] phase;
            logic pwm_out;
            assign XDCR_OUT[cvt_uid(ii) + 1] = pwm_out & output_en;
            pwm_generator pwm_generator(
                              .TIME(TIME),
                              .DUTY(duty),
                              .PHASE(phase),
                              .DUTY_OFFSET(duty_offset[ii]),
                              .PWM_OUT(pwm_out)
                          );
            always_ff @(posedge CLK) begin
                duty <= update ? duty_delayed[ii] : duty;
                phase <= update ? (SILENT ? phase_silent[ii] : phase_raw[ii]) : phase;
            end
        end
    end
endgenerate

endmodule
