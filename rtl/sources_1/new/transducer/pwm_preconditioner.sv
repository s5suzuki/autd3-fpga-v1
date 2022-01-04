/*
 * File: pwm_preconditioner.sv
 * Project: transducer
 * Created Date: 04/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 04/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */


`timescale 1ns / 1ps
module pwm_preconditioner#(
           parameter int WIDTH = 13,
           parameter int DEPTH = 249
       )(
           input var CLK,
           input var START,
           input var [WIDTH-1:0] CYCLE[0:DEPTH-1],
           input var [WIDTH-1:0] DUTY[0:DEPTH-1],
           input var [WIDTH-1:0] PHASE[0:DEPTH-1],
           output var OVER[0:DEPTH-1],
           output var [WIDTH-1:0] LEFT[0:DEPTH-1],
           output var [WIDTH-1:0] RIGHT[0:DEPTH-1]
       );

localparam int ADDSUB_LATENCY = 2;

bit signed [WIDTH+1:0] cycle[0:DEPTH-1];
bit signed [WIDTH+1:0] duty[0:DEPTH-1];
bit signed [WIDTH+1:0] phase[0:DEPTH-1];
bit [WIDTH-1:0] left_buf[0:DEPTH-1], right_buf[0:DEPTH-1];
bit over_buf[0:DEPTH-1];

bit signed [WIDTH+1:0] a_phase, b_phase, s_phase;
bit signed [WIDTH+1:0] a_duty_r, b_duty_r, s_duty_r;
bit signed [WIDTH+1:0] a_left, b_left, s_left;
bit signed [WIDTH+1:0] a_right, b_right, s_right;
bit signed [WIDTH+1:0] a_fold_left, b_fold_left, s_fold_left;
bit signed [WIDTH+1:0] a_fold_right, b_fold_right, s_fold_right;

bit [$clog2(DEPTH+ADDSUB_LATENCY*3)-1:0] cnt, lr_cnt, fold_cnt, set_cnt;

enum bit {
         IDLE,
         PROCESS
     } state = IDLE;

for (genvar i = 0; i < DEPTH; i++) begin
    assign OVER[i] = over_buf[i];
    assign LEFT[i] = left_buf[i];
    assign RIGHT[i] = right_buf[i];
end

addsub #(
           .WIDTH(15)
       ) sub_phase(
           .CLK(CLK),
           .A(a_phase),
           .B(b_phase),
           .ADD(1'b0),
           .S(s_phase)
       );
addsub #(
           .WIDTH(15)
       ) add_duty_r(
           .CLK(CLK),
           .A(a_duty_r),
           .B(b_duty_r),
           .ADD(1'b1),
           .S(s_duty_r)
       );

addsub #(
           .WIDTH(15)
       ) sub_left(
           .CLK(CLK),
           .A(a_left),
           .B(b_left),
           .ADD(1'b0),
           .S(s_left)
       );
addsub #(
           .WIDTH(15)
       ) add_right(
           .CLK(CLK),
           .A(a_right),
           .B(b_right),
           .ADD(1'b1),
           .S(s_right)
       );

addsub #(
           .WIDTH(15)
       ) add_fold_left(
           .CLK(CLK),
           .A(a_fold_left),
           .B(b_fold_left),
           .ADD(1'b1),
           .S(s_fold_left)
       );
addsub #(
           .WIDTH(15)
       ) sub_fold_right(
           .CLK(CLK),
           .A(a_fold_right),
           .B(b_fold_right),
           .ADD(1'b0),
           .S(s_fold_right)
       );

for (genvar i = 0; i < DEPTH; i++) begin
    always_ff @(posedge CLK) begin
        case(state)
            IDLE: begin
                if (START) begin
                    cycle[i] <= {2'b00, CYCLE[i]};
                    duty[i] <= {2'b00, DUTY[i]};
                    phase[i] <= {2'b00, PHASE[i]};
                end
            end
        endcase
    end
end

always_ff @(posedge CLK) begin
    case(state)
        IDLE: begin
            if (START) begin
                cnt <= 0;
                lr_cnt <= 0;
                fold_cnt <= 0;
                set_cnt <= 0;
                state <= PROCESS;
            end
        end
        PROCESS: begin
            // invert phase, calc duty_r
            a_phase <= cycle[cnt];
            b_phase <= phase[cnt];
            a_duty_r <= {1'b0, duty[cnt][WIDTH+1:1]};
            b_duty_r <= duty[cnt][0];
            cnt <= cnt + 1;

            // calc left/right
            a_left <= s_phase;
            b_left <= {1'b0, duty[lr_cnt][WIDTH+1:1]};
            a_right <= s_phase;
            b_right <= s_duty_r;
            if (cnt > ADDSUB_LATENCY) begin
                lr_cnt <= lr_cnt + 1;
            end

            // make left/right be in [0, cycle-1]
            a_fold_left <= s_left;
            a_fold_right <= s_right;
            if (s_left[WIDTH] == 1'b1) begin
                b_fold_left <= cycle[fold_cnt];
                b_fold_right <= 0;
            end
            else if (cycle[fold_cnt] <= s_right) begin
                b_fold_left <= 0;
                b_fold_right <= cycle[fold_cnt];
            end
            else begin
                b_fold_left <= 0;
                b_fold_right <= 0;
            end
            if (lr_cnt > ADDSUB_LATENCY) begin
                fold_cnt <= fold_cnt + 1;
                if (fold_cnt <= DEPTH - 1) begin
                    over_buf[fold_cnt] <= (s_left[WIDTH] == 1'b1) | (cycle[fold_cnt] <= s_right);
                end
            end

            if (fold_cnt > ADDSUB_LATENCY) begin
                left_buf[set_cnt] <= s_fold_left[WIDTH-1:0];
                right_buf[set_cnt] <= s_fold_right[WIDTH-1:0];
                if (set_cnt == DEPTH - 1) begin
                    state <= IDLE;
                end
                else begin
                    set_cnt <= set_cnt + 1;
                end
            end
        end
    endcase
end

endmodule
