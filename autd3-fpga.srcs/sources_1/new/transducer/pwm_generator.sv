/*
 * File: pwm_generator.sv
 * Project: transducer
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 23/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

// TIME is a counter that counts from 0 to 639 at 25.6MHz.
// D is a duty ratio (8bit)
// PHASE is a phase (8bit)
module pwm_generator(
           input var [9:0] TIME,
           input var [7:0] D,
           input var [7:0] PHASE,
           output var PWM_OUT
       );

logic[9:0] time_t;
logic[7:0] d;
logic[7:0] s;

logic[9:0] d_pwm;
logic[9:0] s_pwm;

assign time_t = TIME;
assign d = D;
assign s = keep_phase(PHASE, d); // s is a shift duration of PWM signal.
assign PWM_OUT = pwm(time_t, d_pwm, s_pwm);

always_comb begin
    d_pwm = ({d, 7'b0} + {2'b0, d, 5'b0} + {8'b0, d}) >> 7; // normalized to 0-319 (= 0 to 50%)
    s_pwm = ({s, 8'b0} + {2'b0, s, 6'b0} + {9'b0, s}) >> 7; // normalized to 0-639 (= 0 to 2pi)
end

function automatic pwm;
    input [9:0] timet;
    input [9:0] d;
    input [9:0] s;
    begin
        if (d + s < 10'd640) begin
            pwm = (s <= timet) & (timet < d + s);
        end
        else begin
            pwm = (timet < (d + s - 10'd640)) | (s <= timet);
        end
    end
endfunction

// Shift duration S does not equal the phase of ultrasound emitted and has some a bias term related to duty ratio D.
// (c.f. Eq. 16 in "Suzuki, Shun, et al. "Reducing Amplitude Fluctuation by Gradual Phase Shift in Midair Ultrasound Haptics." IEEE Transactions on Haptics 13.1 (2020): 87-93.")
// Therefore, even if the phase is constant, S will change as the duty ratio changes.
function automatic [7:0] keep_phase;
    input [7:0] phase;
    input [7:0] d;
    keep_phase = {1'b0, phase} + (9'h07F - {2'b00, d[7:1]});
endfunction

endmodule
