/*
 * File: pwm_generator.sv
 * Project: transducer
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 13/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */


`timescale 1ns / 1ps
module pwm_generator#(
           parameter [9:0] CYCLE = 510
       )(
           input var [8:0] TIME,
           input var [7:0] DUTY,
           input var [7:0] PHASE,
           output var PWM_OUT
       );

assign PWM_OUT = pwm({1'b0, TIME}, {2'b00, DUTY}, {1'b0, PHASE, 1'b0});

function automatic pwm;
    input [9:0] time_t;
    input [9:0] duty;
    input [9:0] phase;
    begin
        if (phase < (duty>>1)) begin
            pwm = (phase + CYCLE <= time_t + (duty>>1)) | (time_t < phase + (duty+1>>1));
        end
        else if (phase + (duty+1>>1) > CYCLE) begin
            pwm = (phase <= time_t + (duty>>1)) | (time_t + CYCLE < phase + (duty+1>>1));
        end
        else begin
            pwm = (phase <= time_t + (duty>>1)) & (time_t < phase + (duty+1>>1));
        end
    end
endfunction

endmodule
