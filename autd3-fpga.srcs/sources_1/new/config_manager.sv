/*
 * File: config_manager.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 26/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
`include "./features.vh"
module config_manager(
           input var CLK,
           input var SYNC,
           cpu_bus_if.slave_port CPU_BUS,
`ifdef ENABLE_MODULATION
           mod_sync_if.master_port MOD_SYNC,
`endif
`ifdef ENABLE_SEQUENCE
           seq_sync_if.master_port SEQ_SYNC,
`endif
`ifdef ENABLE_SILENT
           output var SILENT,
`endif
           output var FORCE_FAN,
           input var THERMO
       );

`include "./param.vh"

logic [5:0] config_bram_addr;
logic [15:0] config_bram_din;
logic [15:0] config_bram_dout;
logic config_web;

////////////////////////////////// BRAM //////////////////////////////////
logic config_ena;
assign config_ena = (CPU_BUS.BRAM_SELECT == `BRAM_CONFIG_SELECT) & CPU_BUS.EN;

logic [15:0] cpu_data_out;
assign CPU_BUS.DATA_OUT = cpu_data_out;

BRAM_CONFIG config_bram(
                .clka(CPU_BUS.BUS_CLK),
                .ena(config_ena),
                .wea(CPU_BUS.WE),
                .addra(CPU_BUS.BRAM_ADDR[5:0]),
                .dina(CPU_BUS.DATA_IN),
                .douta(cpu_data_out),
                .clkb(CLK),
                .web(config_web),
                .addrb(config_bram_addr),
                .dinb(config_bram_din),
                .doutb(config_bram_dout)
            );
////////////////////////////////// BRAM //////////////////////////////////

localparam [5:0] BRAM_CFP                 = 6'h00; // CFP: Control Flag and Properties
localparam [5:0] BRAM_FPGA_INFO           = 6'h01;
localparam [5:0] BRAM_SEQ_CYCLE           = 6'h02;
localparam [5:0] BRAM_SEQ_DIV             = 6'h03;
localparam [5:0] BRAM_WAVELENGTH          = 6'h08;
localparam [5:0] BRAM_SEQ_SYNC_TIME_0     = 6'h09;
localparam [5:0] BRAM_SEQ_SYNC_TIME_1     = 6'h0A;
localparam [5:0] BRAM_SEQ_SYNC_TIME_2     = 6'h0B;
localparam [5:0] BRAM_SEQ_SYNC_TIME_3     = 6'h0C;
localparam [5:0] BRAM_MOD_CYCLE           = 6'h0D;
localparam [5:0] BRAM_MOD_DIV             = 6'h0E;
localparam [5:0] BRAM_MOD_SYNC_TIME_0     = 6'h0F;
localparam [5:0] BRAM_MOD_SYNC_TIME_1     = 6'h10;
localparam [5:0] BRAM_MOD_SYNC_TIME_2     = 6'h11;
localparam [5:0] BRAM_MOD_SYNC_TIME_3     = 6'h12;

localparam CF_SILENT    = 3;
localparam CF_FORCE_FAN = 4;
localparam CF_SEQ_MODE  = 5;

localparam P_SEQ_DATA_MODE_IDX = 8;
localparam P_MOD_INIT_IDX      = 14;
localparam P_SEQ_INIT_IDX      = 15;

logic [15:0] cfp;
logic [7:0] ctrl_flags;
logic [7:0] fpga_info;

logic [15:0] mod_clk_cycle;
logic [15:0] mod_clk_div;
logic [63:0] mod_clk_sync_time;
logic [15:0] seq_clk_cycle;
logic [15:0] seq_clk_div;
logic [63:0] seq_clk_sync_time;
logic [15:0] wavelength;

enum logic [4:0] {
         READ_CFP,
         WRITE_FPGA_INFO,

         REQ_CFP_CLEAR,
         REQ_CFP_CLEAR_WAIT0,
         REQ_CFP_CLEAR_WAIT1,
         CFP_CLEAR,

         REQ_READ_MOD_CLK_DIV,
         REQ_READ_MOD_CLK_SYNC_TIME_0,
         REQ_READ_MOD_CLK_SYNC_TIME_1,
         REQ_READ_MOD_CLK_SYNC_TIME_2,
         REQ_READ_MOD_CLK_SYNC_TIME_3,
         READ_MOD_CLK_SYNC_TIME_1,
         READ_MOD_CLK_SYNC_TIME_2,
         READ_MOD_CLK_SYNC_TIME_3,

         REQ_READ_SEQ_CLK_DIV,
         REQ_READ_WAVELENGTH,
         REQ_READ_SEQ_CLK_SYNC_TIME_0,
         REQ_READ_SEQ_CLK_SYNC_TIME_1,
         REQ_READ_SEQ_CLK_SYNC_TIME_2,
         REQ_READ_SEQ_CLK_SYNC_TIME_3,
         READ_SEQ_CLK_SYNC_TIME_1,
         READ_SEQ_CLK_SYNC_TIME_2,
         READ_SEQ_CLK_SYNC_TIME_3
     } state_props = READ_CFP;

assign ctrl_flags = cfp[7:0];
`ifdef ENABLE_SILENT
assign SILENT = ctrl_flags[CF_SILENT];
`endif
assign FORCE_FAN = ctrl_flags[CF_FORCE_FAN];
assign fpga_info = {7'd0, THERMO};

`ifdef ENABLE_MODULATION
assign MOD_SYNC.MOD_CLK_INIT = cfp[P_MOD_INIT_IDX];
assign MOD_SYNC.MOD_CLK_CYCLE = mod_clk_cycle;
assign MOD_SYNC.MOD_CLK_DIV = mod_clk_div;
assign MOD_SYNC.MOD_CLK_SYNC_TIME_NS = mod_clk_sync_time;
`endif
`ifdef ENABLE_SEQUENCE
assign SEQ_SYNC.SEQ_CLK_INIT = cfp[P_SEQ_INIT_IDX];
assign SEQ_SYNC.SEQ_CLK_CYCLE = seq_clk_cycle;
assign SEQ_SYNC.SEQ_CLK_DIV = seq_clk_div;
assign SEQ_SYNC.SEQ_CLK_SYNC_TIME_NS = seq_clk_sync_time;
assign SEQ_SYNC.WAVELENGTH_UM = wavelength;
assign SEQ_SYNC.SEQ_MODE = ctrl_flags[CF_SEQ_MODE];
assign SEQ_SYNC.SEQ_DATA_MODE = cfp[P_SEQ_DATA_MODE_IDX];
`endif

always_ff @(posedge CLK) begin
    case(state_props)
        READ_CFP: begin
            cfp <= config_bram_dout;
            if(cfp[P_MOD_INIT_IDX]) begin
                config_web <= 0;
                config_bram_addr <= BRAM_MOD_CYCLE;
                config_bram_din <= 0;
                state_props <= REQ_READ_MOD_CLK_DIV;
            end
            else if(cfp[P_SEQ_INIT_IDX]) begin
                config_web <= 0;
                config_bram_addr <= BRAM_SEQ_CYCLE;
                config_bram_din <= 0;
                state_props <= REQ_READ_SEQ_CLK_DIV;
            end
            else begin
                config_web <= 1;
                config_bram_addr <= BRAM_FPGA_INFO;
                config_bram_din <= {8'h00, fpga_info};
                state_props <= WRITE_FPGA_INFO;
            end
        end
        WRITE_FPGA_INFO: begin
            config_web <= 0;
            config_bram_din <= 0;
            config_bram_addr <= BRAM_CFP;
            state_props <= READ_CFP;
        end

        REQ_CFP_CLEAR: begin
            config_web <= 1;
            config_bram_addr <= BRAM_CFP;
            config_bram_din <= {2'h0, cfp[13:0]};
            state_props <= REQ_CFP_CLEAR_WAIT0;
        end
        REQ_CFP_CLEAR_WAIT0: begin
            config_web <= 0;
            state_props <= REQ_CFP_CLEAR_WAIT1;
        end
        REQ_CFP_CLEAR_WAIT1: begin
            config_web <= 1;
            config_bram_addr <= BRAM_FPGA_INFO;
            config_bram_din <= {8'h00, fpga_info};
            state_props <= CFP_CLEAR;
        end
        CFP_CLEAR: begin
            config_web <= 0;
            config_bram_din <= 0;
            config_bram_addr <= BRAM_CFP;
            cfp <= config_bram_dout;
            state_props <= READ_CFP;
        end

        // Init mod clk
        REQ_READ_MOD_CLK_DIV: begin
            config_bram_addr <= BRAM_MOD_DIV;
            state_props <= REQ_READ_MOD_CLK_SYNC_TIME_0;
        end
        REQ_READ_MOD_CLK_SYNC_TIME_0: begin
            config_bram_addr <= BRAM_MOD_SYNC_TIME_0;
            state_props <= REQ_READ_MOD_CLK_SYNC_TIME_1;
        end
        REQ_READ_MOD_CLK_SYNC_TIME_1: begin
            mod_clk_cycle <= config_bram_dout;
            config_bram_addr <= BRAM_MOD_SYNC_TIME_1;
            state_props <= REQ_READ_MOD_CLK_SYNC_TIME_2;
        end
        REQ_READ_MOD_CLK_SYNC_TIME_2: begin
            mod_clk_div <= config_bram_dout;
            config_bram_addr <= BRAM_MOD_SYNC_TIME_2;
            state_props <= REQ_READ_MOD_CLK_SYNC_TIME_3;
        end
        REQ_READ_MOD_CLK_SYNC_TIME_3: begin
            mod_clk_sync_time[15:0] <= config_bram_dout;
            config_bram_addr <= BRAM_MOD_SYNC_TIME_3;
            state_props <= READ_MOD_CLK_SYNC_TIME_1;
        end
        READ_MOD_CLK_SYNC_TIME_1: begin
            mod_clk_sync_time[31:16] <= config_bram_dout;
            state_props <= READ_MOD_CLK_SYNC_TIME_2;
        end
        READ_MOD_CLK_SYNC_TIME_2: begin
            mod_clk_sync_time[47:32] <= config_bram_dout;
            state_props <= READ_MOD_CLK_SYNC_TIME_3;
        end
        READ_MOD_CLK_SYNC_TIME_3: begin
            mod_clk_sync_time[63:48] <= config_bram_dout;
            if (SYNC) begin
                state_props <= REQ_CFP_CLEAR;
            end
        end

        // Init sequence clk
        REQ_READ_SEQ_CLK_DIV: begin
            config_bram_addr <= BRAM_SEQ_DIV;
            state_props <= REQ_READ_WAVELENGTH;
        end
        REQ_READ_WAVELENGTH: begin
            config_bram_addr <= BRAM_WAVELENGTH;
            state_props <= REQ_READ_SEQ_CLK_SYNC_TIME_0;
        end
        REQ_READ_SEQ_CLK_SYNC_TIME_0: begin
            seq_clk_cycle <= config_bram_dout;
            config_bram_addr <= BRAM_SEQ_SYNC_TIME_0;
            state_props <= REQ_READ_SEQ_CLK_SYNC_TIME_1;
        end
        REQ_READ_SEQ_CLK_SYNC_TIME_1: begin
            seq_clk_div <= config_bram_dout;
            config_bram_addr <= BRAM_SEQ_SYNC_TIME_1;
            state_props <= REQ_READ_SEQ_CLK_SYNC_TIME_2;
        end
        REQ_READ_SEQ_CLK_SYNC_TIME_2: begin
            wavelength <= config_bram_dout;
            config_bram_addr <= BRAM_SEQ_SYNC_TIME_2;
            state_props <= REQ_READ_SEQ_CLK_SYNC_TIME_3;
        end
        REQ_READ_SEQ_CLK_SYNC_TIME_3: begin
            seq_clk_sync_time[15:0] <= config_bram_dout;
            config_bram_addr <= BRAM_SEQ_SYNC_TIME_3;
            state_props <= READ_SEQ_CLK_SYNC_TIME_1;
        end
        READ_SEQ_CLK_SYNC_TIME_1: begin
            seq_clk_sync_time[31:16] <= config_bram_dout;
            state_props <= READ_SEQ_CLK_SYNC_TIME_2;
        end
        READ_SEQ_CLK_SYNC_TIME_2: begin
            seq_clk_sync_time[47:32] <= config_bram_dout;
            state_props <= READ_SEQ_CLK_SYNC_TIME_3;
        end
        READ_SEQ_CLK_SYNC_TIME_3: begin
            seq_clk_sync_time[63:48] <= config_bram_dout;
            if (SYNC) begin
                state_props <= REQ_CFP_CLEAR;
            end
        end
    endcase
end

endmodule
