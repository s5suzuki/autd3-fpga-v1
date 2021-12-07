/*
 * File: normal_operator.sv
 * Project: new
 * Created Date: 26/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/12/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

module normal_operator#(
           parameter int TRANS_NUM = 249,
           parameter string ENABLE_DELAY = "TRUE"
       )(
           input var CLK,
           input var UPDATE,
           cpu_bus_if.slave_port CPU_BUS,
           output var [7:0] DUTY[0:TRANS_NUM-1],
           output var [7:0] PHASE[0:TRANS_NUM-1],
           output var [6:0] DELAY[0:TRANS_NUM-1],
           output var DELAY_RST,
           output var DUTY_OFFSET[0:TRANS_NUM-1]
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
               .web('0),
               .addrb(tr_bram_idx),
               .dinb('0),
               .doutb(tr_bram_dataout)
           );
////////////////////////////////// BRAM //////////////////////////////////

logic [7:0] tr_buf_write_idx;
logic [7:0] duty_buf[0:TRANS_NUM-1];
logic [7:0] phase_buf[0:TRANS_NUM-1];

logic duty_offset[0:TRANS_NUM-1];

assign DUTY = duty_buf;
assign PHASE = phase_buf;
assign DUTY_OFFSET = duty_offset;

enum logic [2:0] {
         IDLE,
         DUTY_PHASE_WAIT_0,
         DUTY_PHASE_WAIT_1,
         DUTY_PHASE,
         DELAY_OFFSET_WAIT_0,
         DELAY_OFFSET_WAIT_1,
         DELAY_OFFSET,
         DELAY_RESET
     } tr_state = IDLE;

always_ff @(posedge CLK) begin
    case(tr_state)
        IDLE: begin
            if (UPDATE) begin
                tr_bram_idx <= '0;
                tr_state <= DUTY_PHASE_WAIT_0;
            end
        end
        DUTY_PHASE_WAIT_0: begin
            tr_bram_idx <= tr_bram_idx + 1'b1;
            tr_state <= DUTY_PHASE_WAIT_1;
        end
        DUTY_PHASE_WAIT_1: begin
            tr_bram_idx <= tr_bram_idx + 1'b1;
            tr_buf_write_idx <= '0;
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
                tr_bram_idx <= tr_bram_idx + 1'b1;
                tr_buf_write_idx <= tr_buf_write_idx + 1'b1;
            end
        end
        DELAY_OFFSET_WAIT_0: begin
            tr_bram_idx <= tr_bram_idx + 1'b1;
            tr_state <= DELAY_OFFSET_WAIT_1;
        end
        DELAY_OFFSET_WAIT_1: begin
            tr_bram_idx <= tr_bram_idx + 1'b1;
            tr_buf_write_idx <= '0;
            tr_state <= DELAY_OFFSET;
        end
        DELAY_OFFSET: begin
            duty_offset[tr_buf_write_idx] <= tr_bram_dataout[8];
            tr_bram_idx <= tr_bram_idx + 1'b1;
            tr_buf_write_idx <= tr_buf_write_idx + 1'b1;
            tr_state <= (tr_buf_write_idx == TRANS_NUM - 1) ? DELAY_RESET : tr_state;
        end
        DELAY_RESET: begin
            tr_state <= IDLE;
        end
    endcase
end

if (ENABLE_DELAY == "TRUE") begin
    logic [6:0] delay[0:TRANS_NUM-1];
    logic delay_rst;
    assign DELAY = delay;
    assign DELAY_RST = delay_rst;

    always_ff @(posedge CLK) begin
        case(tr_state)
            DELAY_OFFSET: begin
                delay[tr_buf_write_idx] <= tr_bram_dataout[6:0];
            end
            DELAY_RESET: begin
                delay_rst <= tr_bram_dataout[0];
            end
        endcase
    end
end

endmodule
