/*
 * File: focus_calculator.sv
 * Project: new
 * Created Date: 05/07/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 03/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module focus_calculator(
           input var SYS_CLK,
           input var DVALID_IN,
           input var [23:0] FOCUS_X,
           input var [23:0] FOCUS_Y,
           input var [23:0] FOCUS_Z,
           input var [23:0] TRANS_X,
           input var [23:0] TRANS_Y,
           input var [23:0] TRANS_Z,
           output var [7:0] PHASE,
           output var PHASE_CALC_DONE
       );

localparam SQRT_LATENCY = 25 + 1 + 4;
localparam SQRT_LATENCY_WIDTH = $clog2(SQRT_LATENCY);

logic signed [23:0] dx = 0;
logic signed [23:0] dy = 0;
logic signed [23:0] dz = 0;
logic [47:0] d2 = 0;
logic [47:0] dx2, dy2, dz2;
logic tvalid_in = 0;
logic tvalid_out;
logic [31:0] dout;
logic [8:0] phase = 0;
logic phase_calc_done = 0;

logic [2:0] calc_mode_edge = 0;
logic [2:0] calc_mode = 0;
logic [SQRT_LATENCY_WIDTH-1:0] wait_cnt = 0;
logic [7:0] input_num = 0;
logic [7:0] output_num = 0;
logic run = 0;

sqrt_48 sqrt_48(
            .aclk(SYS_CLK),
            .s_axis_cartesian_tvalid(tvalid_in),
            .s_axis_cartesian_tdata(d2),
            .m_axis_dout_tvalid(tvalid_out),
            .m_axis_dout_tdata(dout));

mult_24 mult_24x(
            .CLK(SYS_CLK),
            .A(dx),
            .B(dx),
            .P(dx2)
        );
mult_24 mult_24y(
            .CLK(SYS_CLK),
            .A(dy),
            .B(dy),
            .P(dy2)
        );
mult_24 mult_24z(
            .CLK(SYS_CLK),
            .A(dz),
            .B(dz),
            .P(dz2)
        );

assign PHASE = phase[7:0];
assign PHASE_CALC_DONE = phase_calc_done;

always_ff @(posedge SYS_CLK) begin
    calc_mode_edge <= {calc_mode_edge[1:0], DVALID_IN};
    case(calc_mode_edge)
        3'b001: begin
            tvalid_in <= 1'b1;
            wait_cnt <= 0;
        end
        3'b110: begin
            tvalid_in <= 1'b0;
            wait_cnt <= ~run ? 0 : (wait_cnt == SQRT_LATENCY - 1) ? SQRT_LATENCY - 1 : wait_cnt+1;
        end
        default: begin
            wait_cnt <= ~run ? 0 : (wait_cnt == SQRT_LATENCY - 1) ? SQRT_LATENCY - 1 : wait_cnt+1;
        end
    endcase
end

always_ff @(posedge SYS_CLK) begin
    if(run) begin
        if(DVALID_IN) begin
            // STAGE_0
            dx <= {1'b0, TRANS_X} - {1'b0, FOCUS_X};
            dy <= {1'b0, TRANS_Y} - {1'b0, FOCUS_Y};
            dz <= {1'b0, TRANS_Z} - {1'b0, FOCUS_Z};
            input_num <= input_num + 1;
        end
        else if(output_num == input_num) begin
            input_num <= 0;
        end

        // STAGE_1
        d2 <= dx2 + dy2 + dz2;

        // STAGE_2
        phase <= 9'h100 - dout[8:0];
        if(wait_cnt == SQRT_LATENCY - 1) begin
            if(output_num == input_num) begin
                phase_calc_done <= 0;
                output_num <= 0;
                run <= 0;
            end
            else begin
                phase_calc_done <= 1;
                output_num <= output_num+1;
            end
        end
    end
    else begin
        if(DVALID_IN) begin
            // STAGE_0
            dx <= {1'b0, TRANS_X} - {1'b0, FOCUS_X};
            dy <= {1'b0, TRANS_Y} - {1'b0, FOCUS_Y};
            dz <= {1'b0, TRANS_Z} - {1'b0, FOCUS_Z};
            input_num <= 1;
            run <= 1;
        end
    end
end

endmodule
