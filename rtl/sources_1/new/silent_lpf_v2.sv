/*
 * File: silent_lpf_v2.sv
 * Project: new
 * Created Date: 25/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 06/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module silent_lpf_v2#(
           parameter int TRANS_NUM = 249,
           parameter int WIDTH = 8
       )(
           input var CLK,
           input var ENABLE,
           input var UPDATE,
           input var [WIDTH-1:0] DUTY[0:TRANS_NUM-1],
           input var [WIDTH-1:0] PHASE[0:TRANS_NUM-1],
           output var [WIDTH-1:0] DUTYS[0:TRANS_NUM-1],
           output var [WIDTH-1:0] PHASES[0:TRANS_NUM-1],
           output var OUT_VALID
       );

localparam int ADDSUB_LATENCY = 2;
localparam [WIDTH-1:0] STEP = 3;

bit signed [WIDTH:0] step, step_n;
bit signed [WIDTH:0] duty[0:TRANS_NUM-1];
bit signed [WIDTH:0] phase[0:TRANS_NUM-1];
bit signed [WIDTH:0] current_duty[0:TRANS_NUM-1] = '{TRANS_NUM{0}};
bit signed [WIDTH:0] current_phase[0:TRANS_NUM-1] = '{TRANS_NUM{0}};
bit signed [WIDTH:0] duty_step, phase_step;
bit signed [WIDTH:0] a_duty_step, b_duty_step;
bit signed [WIDTH:0] a_phase_step, b_phase_step;
bit signed [WIDTH:0] a_duty, b_duty, s_duty;
bit signed [WIDTH:0] a_phase, b_phase, s_phase;
bit add;
bit [$clog2(TRANS_NUM+(ADDSUB_LATENCY+1)*3)-1:0] calc_cnt, calc_step_cnt, set_cnt;
bit out_valid = 0;

enum bit {
         IDLE,
         PROCESS
     } state = IDLE;

for (genvar i = 0; i < TRANS_NUM; i++) begin
    assign DUTYS[i] = ENABLE ? current_duty[i][WIDTH-1:0] : DUTY[i];
    assign PHASES[i] = ENABLE ? current_phase[i][WIDTH-1:0] : PHASE[i];
end
assign OUT_VALID = out_valid;

addsub #(
           .WIDTH(WIDTH+1)
       ) sub_duty_step(
           .CLK(CLK),
           .A(a_duty_step),
           .B(b_duty_step),
           .ADD(1'b0),
           .S(duty_step)
       );

addsub #(
           .WIDTH(WIDTH+1)
       ) sub_phase_step(
           .CLK(CLK),
           .A(a_phase_step),
           .B(b_phase_step),
           .ADD(1'b0),
           .S(phase_step)
       );

addsub #(
           .WIDTH(WIDTH+1)
       ) add_duty(
           .CLK(CLK),
           .A(a_duty),
           .B(b_duty),
           .ADD(1'b1),
           .S(s_duty)
       );

addsub #(
           .WIDTH(WIDTH+1)
       ) addsub_phase(
           .CLK(CLK),
           .A(a_phase),
           .B(b_phase),
           .ADD(add),
           .S(s_phase)
       );

for (genvar i = 0; i < TRANS_NUM; i++) begin
    always_ff @(posedge CLK) begin
        case(state)
            IDLE: begin
                if (UPDATE) begin
                    duty[i] <= {1'b0, DUTY[i]};
                    phase[i] <= {1'b0, PHASE[i]};
                end
            end
        endcase
    end
end

always_ff @(posedge CLK) begin
    case(state)
        IDLE: begin
            if (UPDATE) begin
                step <= {1'b0, STEP};
                step_n <= -{1'b0, STEP};

                calc_step_cnt <= 0;
                calc_cnt <= 0;
                set_cnt <= 0;
                out_valid <= 0;

                state <= PROCESS;
            end
        end
        PROCESS: begin
            // calculate duty/phase step
            a_duty_step <= duty[calc_step_cnt];
            b_duty_step <= current_duty[calc_step_cnt];
            a_phase_step <= phase[calc_step_cnt];
            b_phase_step <= current_phase[calc_step_cnt];
            calc_step_cnt <= calc_step_cnt + 1;

            // calculate next duty
            a_duty <= current_duty[calc_cnt];
            if (duty_step[WIDTH] == 1'b0) begin
                b_duty = (duty_step < step) ? duty_step : step;
            end
            else begin
                b_duty = (step_n < duty_step) ? duty_step : step_n;
            end
            // calculate next phase
            a_phase <= current_phase[calc_cnt];
            if (phase_step[WIDTH] == 1'b0) begin
                b_phase = (phase_step < step) ? phase_step : step;
                add <= (phase_step[WIDTH-1] == 1'b0); // phase_step < 128
                // add <= (phase_step <= 128);
            end
            else begin
                b_phase = (step_n < phase_step) ? phase_step : step_n;
                add <= (phase_step[WIDTH-1] == 1'b1); // -128 <= phase_step
                // add <= (-128 <= phase_step);
            end
            if (calc_step_cnt > ADDSUB_LATENCY) begin
                calc_cnt <= calc_cnt + 1;
            end

            if (calc_cnt > ADDSUB_LATENCY) begin
                // set duty/phase
                current_duty[set_cnt] <= s_duty;
                current_phase[set_cnt] <= {1'b0, s_phase[WIDTH-1:0]};
                set_cnt <= set_cnt + 1;

                if (set_cnt == TRANS_NUM - 1) begin
                    out_valid <= 1;
                    state <= IDLE;
                end
            end
        end
    endcase
end

endmodule
