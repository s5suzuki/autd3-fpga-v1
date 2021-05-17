/*
 * File: transducer.sv
 * Project: transducer
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module transducer#(
           parameter int ULTRASOUND_CNT_CYCLE = 510
       )(
           input var CLK,
           input var RST,
           input var CLK_LPF,
           input var [8:0] TIME,
           input var [7:0] DUTY,
           input var [7:0] PHASE,
           input var SILENT,
           output var PWM_OUT
       );

logic[7:0] duty_s, phase_s;
logic[7:0] duty, phase;

always_ff @(posedge CLK) begin
    if (TIME == (ULTRASOUND_CNT_CYCLE - 1)) begin
        duty <= SILENT ? duty_s : DUTY;
        phase <= SILENT ? phase_s : PHASE;
    end
end

silent_lpf silent_lpf(
               .CLK(CLK),
               .RST(RST),
               .CLK_LPF(CLK_LPF),
               .DUTY(DUTY),
               .PHASE(PHASE),
               .DUTY_S(duty_s),
               .PHASE_S(phase_s)
           );

pwm_generator pwm_generator(
                  .TIME(TIME),
                  .DUTY(duty),
                  .PHASE(phase),
                  .PWM_OUT(PWM_OUT)
              );

endmodule
