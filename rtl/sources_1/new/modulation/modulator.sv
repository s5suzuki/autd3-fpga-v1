/*
 * File: modulator.sv
 * Project: modulation
 * Created Date: 07/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module modulator#(
           parameter int WIDTH = 13,
           parameter int DEPTH = 249
       )(
           input var CLK,
           input var UPDATE,
           input var [7:0] MOD,
           input var [WIDTH-1:0] DUTY[0:DEPTH-1],
           output var [WIDTH-1:0] DUTY_M[0:DEPTH-1],
           output var OUT_VALID
       );

localparam int MULT_LATENCY = 3;

bit [WIDTH-1:0] duty[0:DEPTH-1];
bit [WIDTH-1:0] duty_m[0:DEPTH-1];

bit [WIDTH-1:0] a;
bit [8:0] b;
bit [WIDTH+8:0] p;

bit [$clog2(DEPTH+(MULT_LATENCY+1))-1:0] calc_cnt, set_cnt;
bit out_valid = 0;

assign OUT_VALID = out_valid;
for (genvar i = 0; i < DEPTH; i++) begin
    assign DUTY_M[i] = duty_m[i];
end

mult#(
        .WIDTH_A(WIDTH),
        .WIDTH_B(9)
    ) mult(
        .CLK(CLK),
        .A(a),
        .B(b),
        .P(p)
    );

enum bit {
         IDLE,
         PROCESS
     } state = IDLE;

for (genvar i = 0; i < DEPTH; i++) begin
    always_ff @(posedge CLK) begin
        case(state)
            IDLE: begin
                if (UPDATE) begin
                    duty[i] <= DUTY[i];
                end
            end
        endcase
    end
end

always_ff @(posedge CLK) begin
    case(state)
        IDLE: begin
            if (UPDATE) begin
                out_valid <= 0;
                b <= MOD + 1;
                state <= PROCESS;
            end
        end
        PROCESS: begin
            a <= duty[calc_cnt];
            calc_cnt <= calc_cnt + 1;

            if (calc_cnt > MULT_LATENCY) begin
                duty_m[set_cnt] <= p[WIDTH+7:WIDTH];

                set_cnt <= set_cnt + 1;
                if (set_cnt == DEPTH - 1) begin
                    out_valid <= 1;
                    state <= IDLE;
                end
            end
        end
    endcase
end

endmodule
