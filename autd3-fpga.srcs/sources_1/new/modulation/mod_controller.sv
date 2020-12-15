/*
 * File: mod_controller.sv
 * Project: new
 * Created Date: 28/08/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 15/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
`include "../consts.vh"

module mod_controller(
           input var BUS_CLK,
           input var EN,
           input var WE,
           input var [1:0] BRAM_SELECT,
           input var [13:0] ADDR,
           input var [15:0] DATA_IN,

           input var SYS_CLK,
           input var [`MOD_BUF_IDX_WIDTH-1:0] MOD_IDX,
           output var [7:0] MOD_OUT
       );

logic mod_en = (BRAM_SELECT == `BRAM_MOD_SELECT) & EN;
logic [13:0] addr = ADDR[13:0];

BRAM8x32768 mod_ram(
                .clka(BUS_CLK),
                .ena(mod_en),
                .wea(WE),
                .addra(addr),
                .dina(DATA_IN),
                .douta(),

                .clkb(SYS_CLK),
                .web(1'b0),
                .addrb(MOD_IDX),
                .dinb(8'h00),
                .doutb(MOD_OUT)
            );

endmodule
