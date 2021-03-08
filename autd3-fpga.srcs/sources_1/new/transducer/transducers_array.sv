/*
 * File: transducers_array.sv
 * Project: transducers_array
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 06/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module transducers_array#(
           parameter TRANS_NUM = 249
       )(
           input var CLK,
           input var RST,
           input var CLK_LPF,
           input var [9:0] TIME,
           input var [7:0] DUTY[0:TRANS_NUM-1],
           input var [7:0] PHASE[0:TRANS_NUM-1],
           input var [7:0] MOD,
           input var SILENT,
           output var [252:1] XDCR_OUT
       );

`include "../cvt_uid.vh"

generate begin:TRANSDUCERS_GEN
        genvar ii;
        for(ii = 0; ii < TRANS_NUM; ii++) begin
            logic [7:0] duty_modulated;
            assign duty_modulated = modulate_duty(DUTY[ii], MOD);
            transducer tr(
                           .CLK(CLK),
                           .RST(RST),
                           .CLK_LPF(CLK_LPF),
                           .TIME(TIME),
                           .D(duty_modulated),
                           .PHASE(PHASE[ii]),
                           .SILENT(SILENT),
                           .PWM_OUT(XDCR_OUT[cvt_uid(ii) + 1])
                       );
        end
    end
endgenerate

function automatic [7:0] modulate_duty;
    input [7:0] duty;
    input [7:0] mod;
    modulate_duty = ((duty + 17'd1) * (mod + 17'd1) - 17'd1) >> 8;
endfunction

endmodule
