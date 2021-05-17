/*
 * File: config_manager.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module config_manager(
           input var CLK,
           input var RST,
           config_bus_if.slave_port CONFIG_BUS,
           input var SYNC,
           output var MOD_CLK_INIT,
           output var [15:0] MOD_CLK_CYCLE,
           output var [15:0] MOD_CLK_DIV,
           output var [63:0] MOD_CLK_SYNC_TIME_NS,
           output var SEQ_CLK_INIT,
           output var [15:0] SEQ_CLK_CYCLE,
           output var [15:0] SEQ_CLK_DIV,
           output var [63:0] SEQ_CLK_SYNC_TIME_NS,
           output var [15:0] WAVELENGTH_UM,
           output var SEQ_MODE,
           output var SILENT,
           output var FORCE_FAN,
           input var THERMO
       );

// CF: Control Flag
// CP: Clock Properties
localparam [7:0] BRAM_CF_AND_CP           = 8'h00;
localparam [7:0] BRAM_FPGA_INFO           = 8'h01;
localparam [7:0] BRAM_SEQ_CYCLE           = 8'h02;
localparam [7:0] BRAM_SEQ_DIV             = 8'h03;
localparam [7:0] BRAM_WAVELENGTH          = 8'h08;
localparam [7:0] BRAM_SEQ_SYNC_TIME_0     = 8'h09;
localparam [7:0] BRAM_SEQ_SYNC_TIME_1     = 8'h0A;
localparam [7:0] BRAM_SEQ_SYNC_TIME_2     = 8'h0B;
localparam [7:0] BRAM_SEQ_SYNC_TIME_3     = 8'h0C;
localparam [7:0] BRAM_MOD_CYCLE           = 8'h0D;
localparam [7:0] BRAM_MOD_DIV             = 8'h0E;
localparam [7:0] BRAM_MOD_SYNC_TIME_0     = 8'h0F;
localparam [7:0] BRAM_MOD_SYNC_TIME_1     = 8'h10;
localparam [7:0] BRAM_MOD_SYNC_TIME_2     = 8'h11;
localparam [7:0] BRAM_MOD_SYNC_TIME_3     = 8'h12;

localparam CF_SILENT    = 3;
localparam CF_FORCE_FAN = 4;
localparam CF_SEQ_MODE  = 5;

localparam CP_MOD_INIT_IDX  = 0;
localparam CP_SEQ_INIT_IDX  = 1;

logic [7:0] config_bram_addr;
logic [15:0] config_bram_din;
logic [15:0] config_bram_dout;
logic config_web;

logic [7:0] ctrl_flags;
logic [7:0] clk_props;
logic [7:0] fpga_info;

logic [15:0] mod_clk_cycle;
logic [15:0] mod_clk_div;
logic [63:0] mod_clk_sync_time;
logic [15:0] seq_clk_cycle;
logic [15:0] seq_clk_div;
logic [63:0] seq_clk_sync_time;
logic [15:0] wavelength;

enum logic [4:0] {
         READ_CF_AND_CP,
         WRITE_FPGA_INFO,

         REQ_CP_CLEAR,
         REQ_CP_CLEAR_WAIT0,
         REQ_CP_CLEAR_WAIT1,
         CP_CLEAR,

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
     } state_props;

assign CONFIG_BUS.WE = config_web;
assign CONFIG_BUS.IDX = config_bram_addr;
assign CONFIG_BUS.DATA_IN = config_bram_din;
assign config_bram_dout = CONFIG_BUS.DATA_OUT;

assign SILENT = ctrl_flags[CF_SILENT];
assign SEQ_MODE = ctrl_flags[CF_SEQ_MODE];
assign FORCE_FAN = ctrl_flags[CF_FORCE_FAN];
assign fpga_info = {7'd0, THERMO};

assign MOD_CLK_INIT = clk_props[CP_MOD_INIT_IDX];
assign MOD_CLK_CYCLE = mod_clk_cycle;
assign MOD_CLK_DIV = mod_clk_div;
assign MOD_CLK_SYNC_TIME_NS = mod_clk_sync_time;
assign SEQ_CLK_INIT = clk_props[CP_SEQ_INIT_IDX];
assign SEQ_CLK_CYCLE = seq_clk_cycle;
assign SEQ_CLK_DIV = seq_clk_div;
assign SEQ_CLK_SYNC_TIME_NS = seq_clk_sync_time;
assign WAVELENGTH_UM = wavelength;

always_ff @(posedge CLK) begin
    if(RST) begin
        state_props <= READ_CF_AND_CP;
    end
    else begin
        case(state_props)
            READ_CF_AND_CP: begin
                clk_props <= config_bram_dout[15:8];
                ctrl_flags <= config_bram_dout[7:0];
                if(clk_props[CP_MOD_INIT_IDX]) begin
                    config_web <= 0;
                    config_bram_addr <= BRAM_MOD_CYCLE;
                    config_bram_din <= 0;
                    state_props <= REQ_READ_MOD_CLK_DIV;
                end
                else if(clk_props[CP_SEQ_INIT_IDX]) begin
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
                config_bram_addr <= BRAM_CF_AND_CP;
                state_props <= READ_CF_AND_CP;
            end

            REQ_CP_CLEAR: begin
                config_web <= 1;
                config_bram_addr <= BRAM_CF_AND_CP;
                config_bram_din <= {8'h00, ctrl_flags};
                state_props <= REQ_CP_CLEAR_WAIT0;
            end
            REQ_CP_CLEAR_WAIT0: begin
                config_web <= 0;
                state_props <= REQ_CP_CLEAR_WAIT1;
            end
            REQ_CP_CLEAR_WAIT1: begin
                config_web <= 1;
                config_bram_addr <= BRAM_FPGA_INFO;
                config_bram_din <= {8'h00, fpga_info};
                state_props <= CP_CLEAR;
            end
            CP_CLEAR: begin
                config_web <= 0;
                config_bram_din <= 0;
                config_bram_addr <= BRAM_CF_AND_CP;
                clk_props <= config_bram_dout[15:8];
                ctrl_flags <= config_bram_dout[7:0];
                state_props <= READ_CF_AND_CP;
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
                    state_props <= REQ_CP_CLEAR;
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
                    state_props <= REQ_CP_CLEAR;
                end
            end
        endcase
    end
end

endmodule
