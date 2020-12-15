/*
 * File: transducer_controller.sv
 * Project: new
 * Created Date: 06/11/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 15/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
`include "consts.vh"

module transducer_controller(
           input var BUS_CLK,
           input var [1:0] BRAM_SELECT,
           input var EN,
           input var WE,
           input var [13:0] ADDR,
           input var [15:0] DATA_IN,

           input var SYS_CLK,
           input var [9:0] TIME,
           input var [15:0] LM_IDX,
           input var [15:0] LM_CLK_DIV,
           input var [`MOD_BUF_IDX_WIDTH-1:0] MOD_IDX,
           input var SILENT,
           input var OP_MODE,
           output var [252:1] XDCR_OUT
       );

`define LM_BRAM_ADDR_OFFSET_ADDR 14'h0005

logic [7:0] normal_phase[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [7:0] phase_modulated[0:`TRANS_NUM-1];

logic lm_op_en = (BRAM_SELECT == `BRAM_LM_SELECT) & EN;
logic [4:0] lm_addr_in_offset;
logic [2:0] we_edge;
logic lm_addr_in_offset_en = (BRAM_SELECT == `BRAM_PROP_SELECT) & EN;
logic [18:0] lm_addr_in = {lm_addr_in_offset, ADDR};
logic [15:0] bram_lm_idx = LM_IDX / LM_CLK_DIV;
logic [15:0] bram_lm_idx_old;
logic lm_idx_change;
logic signed [23:0] focus_x, focus_y, focus_z;
logic signed [23:0] trans_x, trans_y;
logic fc_trig;
logic [7:0] lm_amp, lm_amp_buf;
logic [7:0] lm_phase[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [7:0] lm_phase_buf[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [127:0] lm_data_out;
logic [7:0] lm_tr_cnt;
logic [7:0] lm_tr_cnt_uid = cvt_uid(lm_tr_cnt);
logic [15:0] lm_tr_cnt_x = lm_tr_cnt_uid % `TRANS_NUM_X;
logic [15:0] lm_tr_cnt_y = lm_tr_cnt_uid / `TRANS_NUM_X;
logic [7:0] lm_tr_cnt_in;
logic [7:0] lm_phase_out;
logic lm_phase_out_valid;

logic [7:0] mod;

enum logic [3:0] {
         WAIT,
         POS_WAIT_0,
         POS_WAIT_1,
         FC_DATA_IN_STREAM,
         PHASE_CALC_WAIT
     } state_calc;

mod_controller mod_cnt(
                   .BUS_CLK(BUS_CLK),
                   .BRAM_SELECT(BRAM_SELECT),
                   .EN(EN),
                   .WE(WE),
                   .ADDR(ADDR),
                   .DATA_IN(DATA_IN),

                   .SYS_CLK(SYS_CLK),
                   .MOD_IDX(MOD_IDX),
                   .MOD_OUT(mod)
               );


BRAM256x14000 lm_ram(
                  .clka(BUS_CLK),
                  .ena(lm_op_en),
                  .wea(WE),
                  .addra(lm_addr_in),
                  .dina(DATA_IN),
                  .douta(),

                  .clkb(SYS_CLK),
                  .web(1'b0),
                  .addrb(bram_lm_idx),
                  .dinb(256'd0),
                  .doutb(lm_data_out)
              );


focus_calculator focus_calculator(
                     .SYS_CLK(SYS_CLK),
                     .DVALID_IN(fc_trig),
                     .FOCUS_X(focus_x),
                     .FOCUS_Y(focus_y),
                     .FOCUS_Z(focus_z),
                     .TRANS_X(trans_x),
                     .TRANS_Y(trans_y),
                     .TRANS_Z(24'sd0),
                     .PHASE(lm_phase_out),
                     .PHASE_CALC_DONE(lm_phase_out_valid)
                 );

initial begin
    lm_addr_in_offset = 0;
    bram_lm_idx_old = 0;
    fc_trig = 0;
    state_calc = WAIT;
    lm_amp = 8'h00;
    we_edge = 0;
    lm_tr_cnt = 0;
    lm_tr_cnt_in = 0;
    lm_amp = 0;
    lm_amp_buf = 0;

    focus_x = 0;
    focus_y = 0;
    focus_z = 0;
    trans_x = 0;
    trans_y = 0;
end

always_ff @(posedge SYS_CLK) begin
    if(bram_lm_idx_old != bram_lm_idx) begin
        bram_lm_idx_old <= bram_lm_idx;
        lm_idx_change <= 1;
    end
    else begin
        lm_idx_change <= 0;
    end
end

always_ff @(posedge SYS_CLK) begin
    case(state_calc)
        WAIT: begin
            if(lm_idx_change) begin
                state_calc <= POS_WAIT_0;
            end
        end
        POS_WAIT_0: begin
            state_calc <= POS_WAIT_1;
        end
        POS_WAIT_1: begin
            focus_x <= lm_data_out[23:0];
            focus_y <= lm_data_out[47:24];
            focus_z <= lm_data_out[71:48];
            lm_amp_buf <= lm_data_out[79:72];

            fc_trig <= 1'b1;
            trans_x <= 0;
            trans_y <= 0;
            lm_tr_cnt <= 1;

            state_calc <= FC_DATA_IN_STREAM;
        end
        FC_DATA_IN_STREAM: begin
            // *306.59375 ~ (TRANS_SIZE) / (WAVE_LENGTH/256)
            trans_x <= ({1'b0, lm_tr_cnt_x, 8'b00000000} + {4'b0, lm_tr_cnt_x, 5'b00000} + {5'b0, lm_tr_cnt_x, 4'b0000} + {8'b0, lm_tr_cnt_x, 1'b0}) + (({1'b0, lm_tr_cnt_x, 4'b0000}+{4'b000, lm_tr_cnt_x, 1'b0}+{5'b0000, lm_tr_cnt_x}) >> 5);
            trans_y <= ({1'b0, lm_tr_cnt_y, 8'b00000000} + {4'b0, lm_tr_cnt_y, 5'b00000} + {5'b0, lm_tr_cnt_y, 4'b0000} + {8'b0, lm_tr_cnt_y, 1'b0}) + (({1'b0, lm_tr_cnt_y, 4'b0000}+{4'b000, lm_tr_cnt_y, 1'b0}+{5'b0000, lm_tr_cnt_y}) >> 5);
            lm_tr_cnt <= lm_tr_cnt + 1;

            state_calc <= (lm_tr_cnt == `TRANS_NUM) ? WAIT : FC_DATA_IN_STREAM;
            fc_trig <= (lm_tr_cnt == `TRANS_NUM) ? 0 : fc_trig;
        end
    endcase
end

always_ff @(posedge SYS_CLK) begin
    if(lm_idx_change) begin
        lm_phase <= lm_phase_buf;
        lm_amp <= lm_amp_buf;
        lm_tr_cnt_in <= 0;
    end
    else if(lm_phase_out_valid) begin
        lm_phase_buf[lm_tr_cnt_in] <= lm_phase_out;
        lm_tr_cnt_in <= lm_tr_cnt_in + 1;
    end
end

always_ff @(posedge BUS_CLK) begin
    we_edge <= {we_edge[1:0], (WE & lm_addr_in_offset_en)};
    if(we_edge == 3'b011) begin
        case(ADDR)
            `LM_BRAM_ADDR_OFFSET_ADDR:
                lm_addr_in_offset <= DATA_IN[4:0];
        endcase
    end
end


endmodule
