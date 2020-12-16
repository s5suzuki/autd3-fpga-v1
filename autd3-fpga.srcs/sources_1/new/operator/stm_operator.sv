/*
 * File: stm_operator.sv
 * Project: operator
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 16/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
`include "../consts.vh"

module stm_operator(
           cpu_bus_if.slave_port CPU_BUS,

           input var [15:0] STM_IDX,
           input var [15:0] STM_CLK_DIV,

           input var SYS_CLK,
           output var [7:0] DUTY[0:`TRANS_NUM-1],
           output var [7:0] PHASE[0:`TRANS_NUM-1]
       );

`include "../cvt_uid.vh"
`define STM_BRAM_ADDR_OFFSET_ADDR 14'h0005

reg fc_trig;
logic signed [23:0] focus_x, focus_y, focus_z;
logic signed [23:0] trans_x, trans_y;
logic [7:0] phase_out;
logic phase_out_valid;

logic [15:0] bram_idx = STM_IDX / STM_CLK_DIV;
logic [15:0] bram_idx_old;
logic idx_change;

logic op_en = (CPU_BUS.BRAM_SELECT == `BRAM_STM_SELECT) & CPU_BUS.EN;
logic [4:0] addr_in_offset;
logic [2:0] we_edge;
logic addr_in_offset_en = (CPU_BUS.BRAM_SELECT == `BRAM_PROP_SELECT) & CPU_BUS.EN;
logic [18:0] addr_in = {addr_in_offset, CPU_BUS.BRAM_ADDR};

logic [7:0] duty, duty_buf;
logic [7:0] phase[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [7:0] phase_buf[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [127:0] data_out;
logic [7:0] tr_cnt;
logic [7:0] tr_cnt_uid = cvt_uid(tr_cnt);
logic [15:0] tr_cnt_x = tr_cnt_uid % `TRANS_NUM_X;
logic [15:0] tr_cnt_y = tr_cnt_uid / `TRANS_NUM_X;
logic [7:0] tr_cnt_in;

enum logic [3:0] {
         WAIT,
         POS_WAIT_0,
         POS_WAIT_1,
         FC_DATA_IN_STREAM,
         PHASE_CALC_WAIT
     } state_calc;

assign DUTY = '{`TRANS_NUM{duty}};
assign PHASE = phase;

focus_calculator focus_calculator(
                     .SYS_CLK(SYS_CLK),
                     .DVALID_IN(fc_trig),
                     .FOCUS_X(focus_x),
                     .FOCUS_Y(focus_y),
                     .FOCUS_Z(focus_z),
                     .TRANS_X(trans_x),
                     .TRANS_Y(trans_y),
                     .TRANS_Z(24'sd0),
                     .PHASE(phase_out),
                     .PHASE_CALC_DONE(phase_out_valid)
                 );

BRAM256x14000 stm_ram(
                  .clka(CPU_BUS.BUS_CLK),
                  .ena(op_en),
                  .wea(CPU_BUS.WE),
                  .addra(addr_in),
                  .dina(CPU_BUS.DATA_IN),
                  .douta(),

                  .clkb(SYS_CLK),
                  .web(1'b0),
                  .addrb(bram_idx),
                  .dinb(256'd0),
                  .doutb(data_out)
              );

initial begin
    addr_in_offset = 0;
    bram_idx_old = 0;
    fc_trig = 0;
    state_calc = WAIT;
    duty = 8'h00;
    we_edge = 0;
    tr_cnt = 0;
    tr_cnt_in = 0;
    duty = 0;
    duty_buf = 0;

    focus_x = 0;
    focus_y = 0;
    focus_z = 0;
    trans_x = 0;
    trans_y = 0;
end

always_ff @(posedge SYS_CLK) begin
    if(bram_idx_old != bram_idx) begin
        bram_idx_old <= bram_idx;
        idx_change <= 1;
    end
    else begin
        idx_change <= 0;
    end
end

always_ff @(posedge SYS_CLK) begin
    case(state_calc)
        WAIT: begin
            if(idx_change) begin
                state_calc <= POS_WAIT_0;
            end
        end
        POS_WAIT_0: begin
            state_calc <= POS_WAIT_1;
        end
        POS_WAIT_1: begin
            focus_x <= data_out[23:0];
            focus_y <= data_out[47:24];
            focus_z <= data_out[71:48];
            duty_buf <= data_out[79:72];

            fc_trig <= 1'b1;
            trans_x <= 0;
            trans_y <= 0;
            tr_cnt <= 1;

            state_calc <= FC_DATA_IN_STREAM;
        end
        FC_DATA_IN_STREAM: begin
            // *306.59375 ~ (TRANS_SIZE) / (WAVE_LENGTH/256)
            trans_x <= ({1'b0, tr_cnt_x, 8'b00000000} + {4'b0, tr_cnt_x, 5'b00000} + {5'b0, tr_cnt_x, 4'b0000} + {8'b0, tr_cnt_x, 1'b0}) + (({1'b0, tr_cnt_x, 4'b0000}+{4'b000, tr_cnt_x, 1'b0}+{5'b0000, tr_cnt_x}) >> 5);
            trans_y <= ({1'b0, tr_cnt_y, 8'b00000000} + {4'b0, tr_cnt_y, 5'b00000} + {5'b0, tr_cnt_y, 4'b0000} + {8'b0, tr_cnt_y, 1'b0}) + (({1'b0, tr_cnt_y, 4'b0000}+{4'b000, tr_cnt_y, 1'b0}+{5'b0000, tr_cnt_y}) >> 5);
            tr_cnt <= tr_cnt + 1;

            state_calc <= (tr_cnt == `TRANS_NUM) ? WAIT : FC_DATA_IN_STREAM;
            fc_trig <= (tr_cnt == `TRANS_NUM) ? 0 : fc_trig;
        end
    endcase
end

always_ff @(posedge SYS_CLK) begin
    if(idx_change) begin
        phase <= phase_buf;
        duty <= duty_buf;
        tr_cnt_in <= 0;
    end
    else if(phase_out_valid) begin
        phase_buf[tr_cnt_in] <= phase_out;
        tr_cnt_in <= tr_cnt_in + 1;
    end
end

always_ff @(posedge CPU_BUS.BUS_CLK) begin
    we_edge <= {we_edge[1:0], (CPU_BUS.WE & addr_in_offset_en)};
    if(we_edge == 3'b011) begin
        case(CPU_BUS.BRAM_ADDR)
            `STM_BRAM_ADDR_OFFSET_ADDR:
                addr_in_offset <= CPU_BUS.DATA_IN[4:0];
        endcase
    end
end

endmodule
