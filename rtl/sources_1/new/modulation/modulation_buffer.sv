/*
 * File: modulation_buffer.sv
 * Project: modulation
 * Created Date: 07/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module modulation_buffer#(
           parameter [1:0] BRAM_CONFIG_SELECT = 2'h0,
           parameter [1:0] BRAM_MOD_SELECT = 2'h0,
           parameter [13:0] MOD_BRAM_ADDR_OFFSET_ADDR = 14'h0006
       )(
           input var CLK,
           cpu_bus_if.slave_port CPU_BUS,
           input var [15:0] ADDR,
           output var [7:0] MOD
       );

bit config_ena, mod_ena;

bit [14:0] mod_addr;
bit mod_addr_offset;

assign config_ena = (CPU_BUS.BRAM_SELECT == BRAM_CONFIG_SELECT) & CPU_BUS.EN;
assign mod_ena = (CPU_BUS.BRAM_SELECT == BRAM_MOD_SELECT) & CPU_BUS.EN;
assign mod_addr = {mod_addr_offset, CPU_BUS.BRAM_ADDR};

BRAM_MOD mod_bram(
             .clka(CPU_BUS.BUS_CLK),
             .ena(mod_ena),
             .wea(CPU_BUS.WE),
             .addra(mod_addr),
             .dina(CPU_BUS.DATA_IN),
             .douta(),
             .clkb(CLK),
             .web('0),
             .addrb(ADDR),
             .dinb('0),
             .doutb(MOD)
         );

bit [2:0] config_we_edge = 3'b000;
always_ff @(posedge CPU_BUS.BUS_CLK) begin
    config_we_edge <= {config_we_edge[1:0], (CPU_BUS.WE & config_ena)};
    if(config_we_edge == 3'b011) begin
        case(CPU_BUS.BRAM_ADDR)
            MOD_BRAM_ADDR_OFFSET_ADDR:
                mod_addr_offset <= CPU_BUS.DATA_IN[0];
        endcase
    end
end

endmodule
