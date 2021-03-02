/*
 * File: sim_op_sel copy.sv
 * Project: new
 * Created Date: 02/03/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 02/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module sim_fc();

logic MRCC_25P6M;

logic [7:0] phase;
logic phase_calc_done;

logic [23:0] focus_x;
logic [23:0] focus_y;
logic [23:0] focus_z;
logic [23:0] trans_x;
logic [23:0] trans_y;
logic tvalid_in;

focus_calculator focus_calculator(
                     .SYS_CLK(MRCC_25P6M),
                     .DVALID_IN(tvalid_in),
                     .FOCUS_X(focus_x),
                     .FOCUS_Y(focus_y),
                     .FOCUS_Z(focus_z),
                     .TRANS_X(trans_x),
                     .TRANS_Y(trans_y),
                     .TRANS_Z(0),
                     .PHASE(phase),
                     .PHASE_CALC_DONE(phase_calc_done)
                 );

initial begin
    MRCC_25P6M = 1;

    focus_x = 0;
    focus_y = 0;
    focus_z = 0;
    trans_x = 0;
    trans_y = 0;
    tvalid_in = 0;
    #(1000);
    focus_z = 24'd10;
    tvalid_in = 1;
    #(100);
    tvalid_in = 0;
    #(10000);
    focus_z = 24'd256;
    tvalid_in = 1;
    #(100);
    tvalid_in = 0;
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

endmodule
