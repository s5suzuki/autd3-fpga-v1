/*
 * File: normal_operator.sv
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

module normal_operator(
           cpu_bus_if.slave_port CPU_BUS,

           input var SYS_CLK,
           input var [9:0] TIME,
           output var [7:0] DUTY[0:`TRANS_NUM-1],
           output var [7:0] PHASE[0:`TRANS_NUM-1],
           output var [7:0] DELAY_OUT[0:`TRANS_NUM-1]
       );

logic en;

logic [7:0] tr_cnt_write = 0;
logic [8:0] bram_addr = 0;
logic [15:0] dout;

logic [7:0] duty[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [7:0] duty_buf[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [7:0] phase[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [7:0] phase_buf[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [7:0] delay[0:`TRANS_NUM-1] = '{`TRANS_NUM{9'h00}};
logic [7:0] delay_buf[0:`TRANS_NUM-1] = '{`TRANS_NUM{9'h00}};

enum logic [2:0] {
         IDLE,
         AMP_PHASE_WAIT_0,
         AMP_PHASE_WAIT_1,
         AMP_PHASE,
         DELAY_WAIT_0,
         DELAY_WAIT_1,
         DELAY
     } state = IDLE;

assign DUTY = duty;
assign PHASE = phase;
assign DELAY_OUT = delay;
assign en = (CPU_BUS.BRAM_SELECT == `BRAM_NORMAL_OP_SELECT) & CPU_BUS.EN;

BRAM16x512 normal_op_ram(
               .clka(CPU_BUS.BUS_CLK),
               .ena(en),
               .wea(CPU_BUS.WE),
               .addra(CPU_BUS.BRAM_ADDR[8:0]),
               .dina(CPU_BUS.DATA_IN),
               .douta(),

               .clkb(SYS_CLK),
               .web(1'b0),
               .addrb(bram_addr),
               .dinb(8'h00),
               .doutb(dout)
           );

always_ff @(posedge SYS_CLK) begin
    case(state)
        IDLE: begin
            if (TIME == 10'd0) begin
                bram_addr <= 8'd0;
                state <= AMP_PHASE_WAIT_0;
            end
        end
        AMP_PHASE_WAIT_0: begin
            bram_addr <= bram_addr + 1;
            state <= AMP_PHASE_WAIT_1;
        end
        AMP_PHASE_WAIT_1: begin
            bram_addr <= bram_addr + 1;
            tr_cnt_write <= 0;
            state <= AMP_PHASE;
        end
        AMP_PHASE: begin
            duty_buf[tr_cnt_write] <= dout[15:8];
            phase_buf[tr_cnt_write] <= dout[7:0];
            if (tr_cnt_write == `TRANS_NUM - 1) begin
                bram_addr <= 9'h100;
                state <= DELAY_WAIT_0;
            end
            else begin
                bram_addr <= bram_addr + 1;
                tr_cnt_write <= tr_cnt_write + 1;
                state <= AMP_PHASE;
            end
        end
        DELAY_WAIT_0: begin
            bram_addr <= bram_addr + 1;
            state <= DELAY_WAIT_1;
        end
        DELAY_WAIT_1: begin
            bram_addr <= bram_addr + 1;
            tr_cnt_write <= 0;
            state <= DELAY;
        end
        DELAY: begin
            delay_buf[tr_cnt_write] <= dout[8:0];
            if (tr_cnt_write == `TRANS_NUM - 1) begin
                state <= IDLE;
            end
            else begin
                bram_addr <= bram_addr + 1;
                tr_cnt_write <= tr_cnt_write + 1;
                state <= DELAY;
            end
        end
    endcase
end

always_ff @(posedge SYS_CLK) begin
    if (TIME == 10'd639) begin
        duty <= duty_buf;
        phase <= phase_buf;
        delay <= delay_buf;
    end
end

endmodule
