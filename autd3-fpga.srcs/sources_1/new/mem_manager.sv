/*
 * File: mem_manager.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 10/05/2021
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
logic en;
logic we;
logic [1:0] cpu_select;
logic [13:0] cpu_addr;
logic [15:0] cpu_data;
logic [15:0] cpu_data_out;

assign bus_clk = CPU_BUS.BUS_CLK;
assign en = CPU_BUS.EN;
assign we = CPU_BUS.WE;
assign cpu_select = CPU_BUS.BRAM_SELECT;
assign cpu_addr = CPU_BUS.BRAM_ADDR;
assign cpu_data = CPU_BUS.DATA_IN;
assign CPU_BUS.DATA_OUT = cpu_data_out;

///////////////////////////////// Normal Operation ////////////////////////////////////////
logic tr_wea;
assign tr_wea = (cpu_select == BRAM_TR_SELECT) & we;

BRAM16x256 tr_bram(
               .clka(bus_clk),
               .ena(en),
               .wea(tr_wea),
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

//////////////////////////////////// Modulation ///////////////////////////////////////////
logic mod_wea;
assign mod_wea = (cpu_select == BRAM_MOD_SELECT) & we;

BRAM8x32768 mod_bram(
                .clka(bus_clk),
                .ena(en),
                .wea(mod_wea),
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

////////////////////////////////////// Config /////////////////////////////////////////////
logic config_wea;
assign config_wea = (cpu_select == BRAM_CONFIG_SELECT) & we;

BRAM16x512 config_bram(
               .clka(bus_clk),
               .ena(en),
               .wea(config_wea),
               .addra(cpu_addr[8:0]),
               .dina(cpu_data),
               .douta(cpu_data_out),
               .clkb(CLK),
               .web(CONFIG_BUS.WE),
               .addrb(CONFIG_BUS.IDX),
               .dinb(CONFIG_BUS.DATA_IN),
               .doutb(CONFIG_BUS.DATA_OUT)
           );
////////////////////////////////////// Config /////////////////////////////////////////////

endmodule
