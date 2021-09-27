/*
 * File: normal_operator.sv
 * Project: new
 * Created Date: 26/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 27/09/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`include "./features.vh"
module normal_operator#(
           parameter int TRANS_NUM = 249,
           parameter int DELAY_DEPTH = 8
       )(
           input var CLK,
           input var UPDATE,
           cpu_bus_if.slave_port CPU_BUS,
           output var [7:0] DUTY[0:TRANS_NUM-1],
           output var [7:0] PHASE[0:TRANS_NUM-1],
           output var DUTY_OFFSET[0:TRANS_NUM-1],
`ifdef ENABLE_DELAY
           output var [7:0] DELAY[0:TRANS_NUM-1],
`endif
           output var OUTPUT_EN,
           output var OUTPUT_BALANCE
       );

`include "./param.vh"

logic [8:0] tr_bram_idx;
logic [15:0] tr_bram_dataout;

////////////////////////////////// BRAM //////////////////////////////////
logic tr_ena;
assign tr_ena = (CPU_BUS.BRAM_SELECT == `BRAM_TR_SELECT) & CPU_BUS.EN;

BRAM16x512 tr_bram(
               .clka(CPU_BUS.BUS_CLK),
               .ena(tr_ena),
               .wea(CPU_BUS.WE),
               .addra(CPU_BUS.BRAM_ADDR[8:0]),
               .dina(CPU_BUS.DATA_IN),
               .douta(),
               .clkb(CLK),
               .web(1'b0),
               .addrb(tr_bram_idx),
               .dinb(16'h0000),
               .doutb(tr_bram_dataout)
           );
////////////////////////////////// BRAM //////////////////////////////////

logic [7:0] tr_buf_write_idx;
logic [7:0] duty_buf[0:TRANS_NUM-1];
logic [7:0] phase_buf[0:TRANS_NUM-1];

logic output_en;
logic output_balance;
logic duty_offset[0:TRANS_NUM-1];

assign DUTY = duty_buf;
assign PHASE = phase_buf;
assign DUTY_OFFSET = duty_offset;
assign OUTPUT_EN = output_en;
assign OUTPUT_BALANCE = output_balance;

`ifdef ENABLE_DELAY
logic [DELAY_DEPTH-1:0] delay[0:TRANS_NUM-1];
assign DELAY = delay;
`endif

enum logic [2:0] {
         IDLE,
         DUTY_PHASE_WAIT_0,
         DUTY_PHASE_WAIT_1,
         DUTY_PHASE,
         DELAY_OFFSET_WAIT_0,
         DELAY_OFFSET_WAIT_1,
         DELAY_OFFSET
     } tr_state = IDLE;

always_ff @(posedge CLK) begin
    case(tr_state)
        IDLE: begin
            if (UPDATE) begin
                tr_bram_idx <= 9'd0;
                tr_state <= DUTY_PHASE_WAIT_0;
            end
        end
        DUTY_PHASE_WAIT_0: begin
            tr_bram_idx <= tr_bram_idx + 1;
            tr_state <= DUTY_PHASE_WAIT_1;
        end
        DUTY_PHASE_WAIT_1: begin
            tr_bram_idx <= tr_bram_idx + 1;
            tr_buf_write_idx <= 0;
            tr_state <= DUTY_PHASE;
        end
        DUTY_PHASE: begin
            duty_buf[tr_buf_write_idx] <= tr_bram_dataout[15:8];
            phase_buf[tr_buf_write_idx] <= tr_bram_dataout[7:0];
            if (tr_buf_write_idx == TRANS_NUM - 1) begin
                tr_bram_idx <= 9'h100;
                tr_state <= DELAY_OFFSET_WAIT_0;
            end
            else begin
                tr_bram_idx <= tr_bram_idx + 1;
                tr_buf_write_idx <= tr_buf_write_idx + 1;
            end
        end
        DELAY_OFFSET_WAIT_0: begin
            tr_bram_idx <= tr_bram_idx + 1;
            tr_state <= DELAY_OFFSET_WAIT_1;
        end
        DELAY_OFFSET_WAIT_1: begin
            tr_bram_idx <= tr_bram_idx + 1;
            tr_buf_write_idx <= 0;
            tr_state <= DELAY_OFFSET;
        end
        DELAY_OFFSET: begin
            if (tr_buf_write_idx == TRANS_NUM) begin
                output_en <= tr_bram_dataout[0];
                output_balance <= tr_bram_dataout[1];
                tr_state <= IDLE;
            end
            else begin
                duty_offset[tr_buf_write_idx] <= tr_bram_dataout[DELAY_DEPTH];
`ifdef ENABLE_DELAY

                delay[tr_buf_write_idx] <= tr_bram_dataout[DELAY_DEPTH-1:0];
`endif

                tr_bram_idx <= tr_bram_idx + 1;
                tr_buf_write_idx <= tr_buf_write_idx + 1;
            end
        end
    endcase
end

endmodule
