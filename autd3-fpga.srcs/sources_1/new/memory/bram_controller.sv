/*
 * File: bram_controller.sv
 * Project: new
 * Created Date: 17/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module bram_controller(
           cpu_bus_if.slave_port CPU_BUS,

           input var SYS_CLK,
           config_bus_if.slave_port CONFIG_BUS,
           mod_bus_if.slave_port MOD_BUS,
           normal_op_bus_if.slave_port NORMAL_OP_BUS,
           stm_op_bus_if.slave_port STM_OP_BUS
       );

localparam [1:0] BRAM_CONFIG_SELECT = 2'h0;
localparam [1:0] BRAM_MOD_SELECT = 2'h1;
localparam [1:0] BRAM_NORMAL_OP_SELECT = 2'h2;
localparam [1:0] BRAM_STM_SELECT = 2'h3;

localparam [13:0] STM_BRAM_ADDR_OFFSET_ADDR = 14'h0005;

logic config_en, mod_en, normal_op_en, stm_op_en;

logic [4:0] stm_addr_in_offset = 0;
logic [2:0] stm_we_edge = 0;
logic stm_addr_in_offset_en;
logic [18:0] stm_addr_in;

assign config_en = (CPU_BUS.BRAM_SELECT == BRAM_CONFIG_SELECT) & CPU_BUS.EN;
assign mod_en = (CPU_BUS.BRAM_SELECT == BRAM_MOD_SELECT) & CPU_BUS.EN;
assign normal_op_en = (CPU_BUS.BRAM_SELECT == BRAM_NORMAL_OP_SELECT) & CPU_BUS.EN;
assign stm_op_en = (CPU_BUS.BRAM_SELECT == BRAM_NORMAL_OP_SELECT) & CPU_BUS.EN;

assign stm_addr_in_offset_en = (CPU_BUS.BRAM_SELECT == BRAM_CONFIG_SELECT) & CPU_BUS.EN;
assign stm_addr_in = {stm_addr_in_offset, CPU_BUS.BRAM_ADDR};

BRAM16x256 ram_props(
               .clka(CPU_BUS.BUS_CLK),
               .ena(config_en),
               .wea(CPU_BUS.WE),
               .addra(CPU_BUS.BRAM_ADDR[7:0]),
               .dina(CPU_BUS.DATA_IN),
               .douta(CPU_BUS.DATA_OUT),

               .clkb(SYS_CLK),
               .web(CONFIG_BUS.WE),
               .addrb(CONFIG_BUS.ADDR),
               .dinb(CONFIG_BUS.DATA_IN),
               .doutb(CONFIG_BUS.DATA_OUT)
           );

BRAM8x32768 mod_ram(
                .clka(CPU_BUS.BUS_CLK),
                .ena(mod_en),
                .wea(CPU_BUS.WE),
                .addra(CPU_BUS.BRAM_ADDR[13:0]),
                .dina(CPU_BUS.DATA_IN),
                .douta(),

                .clkb(SYS_CLK),
                .web(1'b0),
                .addrb(MOD_BUS.MOD_IDX),
                .dinb(8'h00),
                .doutb(MOD_BUS.MOD)
            );

BRAM16x512 normal_op_ram(
               .clka(CPU_BUS.BUS_CLK),
               .ena(normal_op_en),
               .wea(CPU_BUS.WE),
               .addra(CPU_BUS.BRAM_ADDR[8:0]),
               .dina(CPU_BUS.DATA_IN),
               .douta(),

               .clkb(SYS_CLK),
               .web(1'b0),
               .addrb(NORMAL_OP_BUS.ADDR),
               .dinb(8'h00),
               .doutb(NORMAL_OP_BUS.DATA)
           );

logic [47:0] _unused;
BRAM256x14000 stm_ram(
                  .clka(CPU_BUS.BUS_CLK),
                  .ena(stm_op_en),
                  .wea(CPU_BUS.WE),
                  .addra(stm_addr_in),
                  .dina(CPU_BUS.DATA_IN),
                  .douta(),

                  .clkb(SYS_CLK),
                  .web(1'b0),
                  .addrb(STM_OP_BUS.ADDR),
                  .dinb(256'd0),
                  .doutb({_unused, STM_OP_BUS.DATA})
              );

always_ff @(posedge CPU_BUS.BUS_CLK) begin
    stm_we_edge <= {stm_we_edge[1:0], (CPU_BUS.WE & stm_addr_in_offset_en)};
    if(stm_we_edge == 3'b011) begin
        case(CPU_BUS.BRAM_ADDR)
            STM_BRAM_ADDR_OFFSET_ADDR:
                stm_addr_in_offset <= CPU_BUS.DATA_IN[4:0];
        endcase
    end
end

endmodule
