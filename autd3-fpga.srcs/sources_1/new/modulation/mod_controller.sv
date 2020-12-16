/*
 * File: mod_controller.sv
 * Project: new
 * Created Date: 28/08/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 16/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
`include "../consts.vh"

module mod_controller(
           cpu_bus_if.slave_port CPU_BUS,

           input var SYS_CLK,
           input var [`MOD_BUF_IDX_WIDTH-1:0] MOD_IDX,
           output var [7:0] MOD_OUT
       );

logic mod_en = (CPU_BUS.BRAM_SELECT == `BRAM_MOD_SELECT) & CPU_BUS.EN;
logic [13:0] addr = CPU_BUS.BRAM_ADDR[13:0];

BRAM8x32768 mod_ram(
                .clka(CPU_BUS.BUS_CLK),
                .ena(mod_en),
                .wea(CPU_BUS.WE),
                .addra(addr),
                .dina(CPU_BUS.DATA_IN),
                .douta(),

                .clkb(SYS_CLK),
                .web(1'b0),
                .addrb(MOD_IDX),
                .dinb(8'h00),
                .doutb(MOD_OUT)
            );

endmodule
