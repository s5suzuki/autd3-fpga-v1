/*
 * File: transducers_array.sv
 * Project: transducers_array
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 16/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
`include "../consts.vh"

module transducers_array(
           input var [9:0] TIME,
           input var [7:0] AMP[0:`TRANS_NUM-1],
           input var [7:0] PHASE[0:`TRANS_NUM-1],
           input var [7:0] MOD,
           input var SILENT,
           output var [252:1] XDCR_OUT
       );

`include "../cvt_uid.vh"

generate begin:TRANSDUCERS_GEN
        genvar ii;
        for(ii = 0; ii < `TRANS_NUM; ii++) begin
            logic [7:0] amp_modulated = modulate_amp(AMP[ii], MOD);
            transducer tr(
                           .TIME(TIME),
                           .D(amp_modulated),
                           .PHASE(PHASE[ii]),
                           .SILENT(SILENT),
                           .PWM_OUT(XDCR_OUT[cvt_uid(ii) + 1])
                       );
        end
    end
endgenerate

function automatic [7:0] modulate_amp;
    input [7:0] amp;
    input [7:0] mod;
    modulate_amp = ((amp + 17'd1) * (mod + 17'd1) - 17'd1) >> 8;
endfunction

endmodule
