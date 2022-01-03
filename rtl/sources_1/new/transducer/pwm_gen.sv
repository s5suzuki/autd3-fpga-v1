/*
 * File: pwm_gen.sv
 * Project: transducer
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 03/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */


`timescale 1ns / 1ps
module pwm_gen#(
           parameter string PHASE_INVERTED = "TRUE"
       )(
           input var CLK,
           input var [12:0] TIME_CNT,
           input var [12:0] CYCLE,
           input var [12:0] DUTY,
           input var [12:0] PHASE,
           output var PWM_OUT
       );

bit [12:0] t;

bit [14:0] P;
bit [14:0] DL;
bit [14:0] DR;
bit [14:0] pc, tc;
bit [14:0] left, right;
bit pwm1, pwm2, pwm1o, pwm2o;
bit cond_1, cond_2;

assign PWM_OUT = (pwm1 & pwm2) | ((pwm2 | pwm1o) & cond_1) | ((pwm2o | pwm1) & cond_2);
assign t = TIME_CNT;

always_ff @(posedge CLK) begin
    if (t == CYCLE - 1) begin
        if (PHASE_INVERTED == "TRUE") begin
            P <= {2'b00, CYCLE - PHASE};
        end
        else begin
            P <= {2'b00, PHASE};
        end
        DL <= {3'b000, DUTY[12:1]};
        DR <= {3'b000, DUTY[12:1]} + {14'h0000, DUTY[0]};
    end
end

always_ff @(posedge CLK) begin
    left <= {2'b00, t} + DL;
    right <= P + DR;
    pc <= {2'b00, CYCLE} + {1'b0, P};
    tc <= {2'b00, CYCLE} + {2'b00, t};

    pwm1 <= P <= left;
    pwm2 <= {2'b00, t} < right;
    pwm1o <= pc <= left;
    pwm2o <= tc < right;
    cond_1 <= P < DL;
    cond_2 <= {2'b00, CYCLE} < right;
end

endmodule
