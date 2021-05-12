/*
 * File: mem_manager.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 12/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module mem_manager(
           input var CLK,
           cpu_bus_if.slave_port CPU_BUS,
           tr_bus_if.master_port TR_BUS,
           mod_bus_if.master_port MOD_BUS,
           config_bus_if.master_port CONFIG_BUS
       );

localparam [1:0] BRAM_CONFIG_SELECT = 2'h0;
localparam [1:0] BRAM_MOD_SELECT = 2'h1;
localparam [1:0] BRAM_TR_SELECT = 2'h2;

logic bus_clk;
(*mark_debug="true"*) logic en;
(*mark_debug="true"*) logic we;
(*mark_debug="true"*) logic [1:0] cpu_select;
(*mark_debug="true"*) logic [13:0] cpu_addr;
(*mark_debug="true"*) logic [15:0] cpu_data;
(*mark_debug="true"*) logic [15:0] cpu_data_out;

assign bus_clk = CPU_BUS.BUS_CLK;
assign en = CPU_BUS.EN;
assign we = CPU_BUS.WE;
assign cpu_select = CPU_BUS.BRAM_SELECT;
assign cpu_addr = CPU_BUS.BRAM_ADDR;
assign cpu_data = CPU_BUS.DATA_IN;
assign CPU_BUS.DATA_OUT = cpu_data_out;

////////////////////////////////////// Config /////////////////////////////////////////////
(*mark_debug="true"*) logic config_ena;
assign config_ena = (cpu_select == BRAM_CONFIG_SELECT) & en;

BRAM16x256 config_bram(
               .clka(bus_clk),
               .ena(config_ena),
               .wea(we),
               .addra(cpu_addr[7:0]),
               .dina(cpu_data),
               .douta(cpu_data_out),
               .clkb(CLK),
               .web(CONFIG_BUS.WE),
               .addrb(CONFIG_BUS.IDX),
               .dinb(CONFIG_BUS.DATA_IN),
               .doutb(CONFIG_BUS.DATA_OUT)
           );
////////////////////////////////////// Config /////////////////////////////////////////////

//////////////////////////////////// Modulation ///////////////////////////////////////////
(*mark_debug="true"*) logic mod_ena;
assign mod_ena = (cpu_select == BRAM_MOD_SELECT) & en;

BRAM8x32768 mod_bram(
                .clka(bus_clk),
                .ena(mod_ena),
                .wea(we),
                .addra(cpu_addr),
                .dina(cpu_data),
                .douta(),
                .clkb(CLK),
                .web(1'b0),
                .addrb(MOD_BUS.IDX),
                .dinb(8'h00),
                .doutb(MOD_BUS.DATA_OUT)
            );
//////////////////////////////////// Modulation ///////////////////////////////////////////

///////////////////////////////// Normal Operation ////////////////////////////////////////
(*mark_debug="true"*) logic tr_ena;
assign tr_ena = (cpu_select == BRAM_TR_SELECT) & en;

BRAM16x256 tr_bram(
               .clka(bus_clk),
               .ena(tr_ena),
               .wea(we),
               .addra(cpu_addr[7:0]),
               .dina(cpu_data),
               .douta(),
               .clkb(CLK),
               .web(1'b0),
               .addrb(TR_BUS.IDX),
               .dinb(16'h0000),
               .doutb(TR_BUS.DATA_OUT)
           );
///////////////////////////////// Normal Operation ////////////////////////////////////////

endmodule
