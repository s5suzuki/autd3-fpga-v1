/*
 * File: silent_lpf_v2.sv
 * Project: new
 * Created Date: 06/12/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 04/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module silent_lpf_v2#(
           parameter int WIDTH = 13,
           parameter int DEPTH = 249
       )(
           input var CLK,
           input var ENABLE,
           input var START,
           input var [WIDTH-1:0] STEP,
           input var [WIDTH-1:0] CYCLE[0:DEPTH-1],
           input var [WIDTH-1:0] DUTY[0:DEPTH-1],
           input var [WIDTH-1:0] PHASE[0:DEPTH-1],
           output var [WIDTH-1:0] DUTY_S[0:DEPTH-1],
           output var [WIDTH-1:0] PHASE_S[0:DEPTH-1]
       );

localparam int ADDSUB_LATENCY = 2;

bit signed [WIDTH:0] step, step_n;
bit signed [WIDTH:0] duty[0:DEPTH-1];
bit signed [WIDTH:0] phase[0:DEPTH-1];
bit signed [WIDTH:0] cycle[0:DEPTH-1], cycle_n[0:DEPTH-1];
bit signed [WIDTH:0] current_duty[0:DEPTH-1] = '{DEPTH{0}};
bit signed [WIDTH:0] current_phase[0:DEPTH-1] = '{DEPTH{0}};
bit signed [WIDTH:0] duty_step, phase_step;
bit signed [WIDTH:0] a_duty_step, b_duty_step;
bit signed [WIDTH:0] a_phase_step, b_phase_step;
bit signed [WIDTH:0] a_duty, b_duty, s_duty;
bit signed [WIDTH:0] a_phase, b_phase, s_phase;
bit add;
bit [$clog2(DEPTH+ADDSUB_LATENCY)-1:0] calc_cnt, calc_step_cnt, set_cnt;

bit [WIDTH-1:0] current_duty_buf[0:DEPTH-1];
bit [WIDTH-1:0] current_phase_buf[0:DEPTH-1];

enum bit [2:0] {
         IDLE,
         PREPARE_CALC_STEP,
         PREPARE_CALC,
         CALC,
         PREPARE_FOLD_PHASE,
         FOLD_PHASE,
         SET_RESULT
     } state = IDLE;

for (genvar i = 0; i < DEPTH; i++) begin
    assign DUTY_S[i] = ENABLE ? current_duty_buf[i] : DUTY[i];
    assign PHASE_S[i] = ENABLE ? current_phase_buf[i] : PHASE[i];
end

c_sub_14_14 c_sub_14_14_duty_step(
                .A(a_duty_step),
                .B(b_duty_step),
                .CLK(CLK),
                .S(duty_step)
            );

c_sub_14_14 c_sub_14_14_phase_step(
                .A(a_phase_step),
                .B(b_phase_step),
                .CLK(CLK),
                .S(phase_step)
            );

c_add_14_14 c_add_14_14_duty(
                .A(a_duty),
                .B(b_duty),
                .CLK(CLK),
                .S(s_duty)
            );

c_addsub_14_14 c_addsub_14_14_phase(
                   .A(a_phase),
                   .B(b_phase),
                   .CLK(CLK),
                   .ADD(add),
                   .S(s_phase)
               );

for (genvar i = 0; i < DEPTH; i++) begin
    always_ff @(posedge CLK) begin
        case(state)
            IDLE: begin
                if (START) begin
                    cycle[i] <= {1'b0, CYCLE[i]};
                    cycle_n[i] <= -{1'b0, CYCLE[i]};
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
            if (START) begin
                step <= {1'b0, STEP};
                step_n <= -{1'b0, STEP};

                calc_step_cnt <= 0;

                state <= PREPARE_CALC_STEP;
            end
        end
        PREPARE_CALC_STEP: begin
            // calculate duty/phase step
            a_duty_step <= duty[calc_step_cnt];
            b_duty_step <= current_duty[calc_step_cnt];
            a_phase_step <= phase[calc_step_cnt];
            b_phase_step <= current_phase[calc_step_cnt];
            calc_step_cnt <= calc_step_cnt + 1;

            if (calc_step_cnt == ADDSUB_LATENCY) begin
                calc_cnt <= 0;
                state <= PREPARE_CALC;
            end
        end
        PREPARE_CALC: begin
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
                add <= (phase_step <= {1'b0, cycle[calc_cnt][WIDTH:1]});
            end
            else begin
                b_phase = (step_n < phase_step) ? phase_step : step_n;
                add <= ({1'b1, cycle_n[calc_cnt][WIDTH:1]} <= phase_step);
            end
            calc_cnt <= calc_cnt + 1;

            if (calc_cnt == ADDSUB_LATENCY) begin
                set_cnt <= 0;
                state <= CALC;
            end
        end
        CALC: begin
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
                add <= (phase_step <= {1'b0, cycle[calc_cnt][WIDTH:1]});
            end
            else begin
                b_phase = (step_n < phase_step) ? phase_step : step_n;
                add <= ({1'b1, cycle_n[calc_cnt][WIDTH:1]} <= phase_step);
            end

            current_duty[set_cnt] <= s_duty;
            current_phase[set_cnt] <= s_phase;
            set_cnt <= set_cnt + 1;

            if (set_cnt == DEPTH - 1) begin
                calc_cnt <= 0;
                state <= PREPARE_FOLD_PHASE;
            end
            else begin
                calc_cnt <= calc_cnt + 1;
            end
        end
        PREPARE_FOLD_PHASE: begin
            a_phase <= current_phase[calc_cnt];
            if (current_phase[calc_cnt] >= cycle[calc_cnt]) begin
                b_phase <= cycle[calc_cnt];
                add <= 1'b0;
            end
            else if (current_phase[calc_cnt][WIDTH] == 1'b1) begin
                b_phase <= cycle[calc_cnt];
                add <= 1'b1;
            end
            else begin
                b_phase <= '0;
                add <= 1'b1;
            end

            calc_cnt <= calc_cnt + 1;

            if (calc_cnt == ADDSUB_LATENCY) begin
                set_cnt <= 0;
                state <= FOLD_PHASE;
            end
        end
        FOLD_PHASE: begin
            a_phase <= current_phase[calc_cnt];
            if (current_phase[calc_cnt] >= cycle[calc_cnt]) begin
                b_phase <= cycle[calc_cnt];
                add <= 1'b0;
            end
            else if (current_phase[calc_cnt][WIDTH] == 1'b1) begin
                b_phase <= cycle[calc_cnt];
                add <= 1'b1;
            end
            else begin
                b_phase <= '0;
                add <= 1'b1;
            end

            current_phase[set_cnt] <= s_phase;

            calc_cnt <= calc_cnt + 1;
            set_cnt <= set_cnt + 1;

            if (set_cnt == DEPTH - 1) begin
                state <= SET_RESULT;
            end
        end
        SET_RESULT: begin
            state <= IDLE;
        end
    endcase
end

for (genvar i = 0; i < DEPTH; i++) begin
    always_ff @(posedge CLK) begin
        case(state)
            SET_RESULT: begin
                current_duty_buf[i] <= current_duty[i][WIDTH-1:0];
                current_phase_buf[i] <= current_phase[i][WIDTH-1:0];
            end
        endcase
    end
end

endmodule
