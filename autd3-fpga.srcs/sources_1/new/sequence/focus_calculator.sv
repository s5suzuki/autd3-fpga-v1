/*
 * File: focus_calculator.sv
 * Project: sequence
 * Created Date: 13/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 20/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module focus_calculator(
           input var CLK,
           input var RST,
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
localparam REMINDER_LATENCY = 34;

logic signed [23:0] dx, dy, dz;
logic [47:0] d2;
logic [47:0] dx2, dy2, dz2;
logic tvalid_in;
logic tvalid_out;
logic [31:0] dout;
logic [7:0] phase;
logic phase_calc_done;

logic [1:0] calc_mode_edge;
logic [$clog2(SQRT_LATENCY + REMINDER_LATENCY)-1:0] wait_cnt;
logic [7:0] input_num;
logic [7:0] output_num;
logic run;

logic [31:0] _unused;
logic [7:0] reminder;

sqrt_48 sqrt_48(
            .aclk(CLK),
            .s_axis_cartesian_tvalid(tvalid_in),
            .s_axis_cartesian_tdata(d2),
            .m_axis_dout_tvalid(tvalid_out),
            .m_axis_dout_tdata(dout));

divider32 rem255(
              .s_axis_dividend_tdata(dout),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata(8'hFF),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata({_unused, reminder}),
              .m_axis_dout_tvalid()
          );

mult_24 mult_24x(
            .CLK(CLK),
            .A(dx),
            .B(dx),
            .P(dx2)
        );
mult_24 mult_24y(
            .CLK(CLK),
            .A(dy),
            .B(dy),
            .P(dy2)
        );
mult_24 mult_24z(
            .CLK(CLK),
            .A(dz),
            .B(dz),
            .P(dz2)
        );

assign PHASE = phase;
assign PHASE_CALC_DONE = phase_calc_done;

always_ff @(posedge CLK) begin
    calc_mode_edge <= {calc_mode_edge[0], DVALID_IN};
    case(calc_mode_edge)
        2'b01: begin
            tvalid_in <= 1'b1;
            wait_cnt <= 0;
        end
        2'b10: begin
            tvalid_in <= 1'b0;
            wait_cnt <= ~run ? 0 : (wait_cnt == SQRT_LATENCY + REMINDER_LATENCY - 1) ? SQRT_LATENCY + REMINDER_LATENCY - 1 : wait_cnt + 1;
        end
        default: begin
            wait_cnt <= ~run ? 0 : (wait_cnt == SQRT_LATENCY + REMINDER_LATENCY - 1) ? SQRT_LATENCY + REMINDER_LATENCY - 1 : wait_cnt + 1;
        end
    endcase
end

always_ff @(posedge CLK) begin
    if (RST) begin
        phase_calc_done <= 0;
        input_num <= 0;
        output_num <= 0;
        run <= 0;
    end
    else if(run) begin
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
        phase <= 8'hFF - reminder;
        if(wait_cnt == SQRT_LATENCY + REMINDER_LATENCY - 1) begin
            if(output_num == input_num) begin
                phase_calc_done <= 0;
                output_num <= 0;
                run <= 0;
            end
            else begin
                phase_calc_done <= 1;
                output_num <= output_num + 1;
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
