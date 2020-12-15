/*
 * File: normal_operator.sv
 * Project: operator
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 15/12/2020
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
           output var [7:0] DUTY[0:`TRANS_NUM-1],
           output var [7:0] PHASE[0:`TRANS_NUM-1]
       );

logic en = (CPU_BUS.BRAM_SELECT == `BRAM_NORMAL_OP_SELECT) & CPU_BUS.EN;

logic [7:0] tr_cnt;
logic [7:0] tr_cnt_bram = (tr_cnt + 8'd2 < `TRANS_NUM) ? tr_cnt + 8'd2 : tr_cnt + 8'd2 - `TRANS_NUM; // BRAM has a 2 clock latency

logic [7:0] duty[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [7:0] phase[0:`TRANS_NUM-1] = '{`TRANS_NUM{8'h00}};
logic [15:0] dout;

assign DUTY = duty;
assign PHASE = phase;

BRAM8x252 normal_op_ram(
              .clka(CPU_BUS.BUS_CLK),
              .ena(en),
              .wea(CPU_BUS.WE),
              .addra(CPU_BUS.BRAM_ADDR[7:0]),
              .dina(CPU_BUS.DATA_IN),
              .douta(),

              .clkb(SYS_CLK),
              .web(1'b0),
              .addrb(tr_cnt_bram),
              .dinb(8'h00),
              .doutb(dout)
          );

initial begin
    tr_cnt = 0;
end

always_ff @(posedge SYS_CLK) begin
    tr_cnt <= (tr_cnt == `TRANS_NUM - 1) ? 0: tr_cnt + 1;
    duty[tr_cnt] <= dout[15:8];
    phase[tr_cnt] <= dout[7:0];
end

endmodule
