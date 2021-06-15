/*
 * File: mem_manager.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 15/06/2021
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
           seq_bus_if.master_port SEQ_BUS,
           config_bus_if.master_port CONFIG_BUS,
           input var [14:0] MOD_IDX,
           output var [7:0] MOD
       );

localparam [1:0] BRAM_CONFIG_SELECT = 2'h0;
localparam [1:0] BRAM_MOD_SELECT = 2'h1;
localparam [1:0] BRAM_TR_SELECT = 2'h2;
localparam [1:0] BRAM_SEQ_SELECT = 2'h3;

localparam [13:0] SEQ_BRAM_ADDR_OFFSET_ADDR = 14'h0007;

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

////////////////////////////////////// Config /////////////////////////////////////////////
logic config_ena;
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
logic mod_ena;
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
                .addrb(MOD_IDX),
                .dinb(8'h00),
                .doutb(MOD)
            );
//////////////////////////////////// Modulation ///////////////////////////////////////////

///////////////////////////////// Normal Operation ////////////////////////////////////////
logic tr_ena;
assign tr_ena = (cpu_select == BRAM_TR_SELECT) & en;

BRAM16x512 tr_bram(
               .clka(bus_clk),
               .ena(tr_ena),
               .wea(we),
               .addra(cpu_addr[8:0]),
               .dina(cpu_data),
               .douta(),
               .clkb(CLK),
               .web(1'b0),
               .addrb(TR_BUS.IDX),
               .dinb(16'h0000),
               .doutb(TR_BUS.DATA_OUT)
           );
///////////////////////////////// Normal Operation ////////////////////////////////////////

//////////////////////////////// Sequence Operation ///////////////////////////////////////
logic seq_ena;
logic [18:0] seq_addr;
logic [4:0] seq_addr_offset;
logic [2:0] seq_we_edge;
logic [47:0] _unused;

assign seq_ena = (cpu_select == BRAM_SEQ_SELECT) & en;
assign seq_addr = {seq_addr_offset, cpu_addr};

BRAM256x14000 stm_ram(
                  .clka(bus_clk),
                  .ena(seq_ena),
                  .wea(we),
                  .addra(seq_addr),
                  .dina(cpu_data),
                  .douta(),
                  .clkb(CLK),
                  .web(1'b0),
                  .addrb(SEQ_BUS.IDX),
                  .dinb(128'd0),
                  .doutb({_unused, SEQ_BUS.DATA_OUT})
              );

always_ff @(posedge bus_clk) begin
    seq_we_edge <= {seq_we_edge[1:0], (we & config_ena)};
    if(seq_we_edge == 3'b011) begin
        case(cpu_addr)
            SEQ_BRAM_ADDR_OFFSET_ADDR:
                seq_addr_offset <= cpu_data[4:0];
        endcase
    end
end
//////////////////////////////// Sequence Operation ///////////////////////////////////////

endmodule
