/*
 * File: config_manager.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 15/12/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module config_manager#(
           parameter string ENABLE_SILENT = "TRUE",
           parameter string ENABLE_MODULATION = "TRUE",
           parameter string ENABLE_SEQUENCE = "TRUE"
       )(
           input var CLK,
           cpu_bus_if.slave_port CPU_BUS,
           output var [15:0] DATA_OUT,
           mod_sync_if.master_port MOD_SYNC,
           seq_sync_if.master_port SEQ_SYNC,
           output var SILENT,
           output var FORCE_FAN,
           input var THERMO,
           output var OUTPUT_EN,
           output var OUTPUT_BALANCE
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
assign DATA_OUT = cpu_data_out;

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

localparam [5:0] BRAM_CTRL_FLAG           = 6'h00;
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
localparam [5:0] BRAM_CLK_INIT_FLAG       = 6'h13;

localparam int OUTPUT_ENABLE_IDX  = 0;
localparam int OUTPUT_BALANCE_IDX = 1;
localparam int SILENT_IDX         = 3;
localparam int FORCE_FAN_IDX      = 4;
localparam int OP_MODE_IDX        = 5;
localparam int SEQ_MODE_IDX       = 6;

localparam MOD_INIT_IDX    = '0;
localparam SEQ_INIT_IDX    = 1'b1;

logic [6:0] ctrl_flags;
logic [15:0] clk_init_flags = '0;
logic [7:0] fpga_info;

logic [15:0] mod_clk_cycle;
logic [15:0] mod_clk_div;
logic [63:0] mod_clk_sync_time;
logic [15:0] seq_clk_cycle;
logic [15:0] seq_clk_div;
logic [63:0] seq_clk_sync_time;
logic [15:0] wavelength;

enum logic [4:0] {
         READ_CTRL_FLAG,
         READ_CLK_INIT_FLAG,
         READ_MOD_CYCLE,
         READ_MOD_FREQ_DIV,
         READ_MOD_CLK_SYNC_TIME_0,
         READ_MOD_CLK_SYNC_TIME_1,
         READ_MOD_CLK_SYNC_TIME_2,
         READ_MOD_CLK_SYNC_TIME_3,
         READ_SEQ_CYCLE,
         READ_SEQ_FREQ_DIV,
         READ_WAVELENGTH,
         READ_SEQ_CLK_SYNC_TIME_0,
         READ_SEQ_CLK_SYNC_TIME_1,
         READ_SEQ_CLK_SYNC_TIME_2,
         READ_SEQ_CLK_SYNC_TIME_3,
         CLEAR_CLK_INIT_FLAG,
         WRITE_FPGA_INFO
     } state_props = READ_CTRL_FLAG;

assign OUTPUT_EN = ctrl_flags[OUTPUT_ENABLE_IDX];
assign OUTPUT_BALANCE = ctrl_flags[OUTPUT_BALANCE_IDX];

if (ENABLE_SILENT == "TRUE") begin
    assign SILENT = ctrl_flags[SILENT_IDX];
end
assign FORCE_FAN = ctrl_flags[FORCE_FAN_IDX];
assign fpga_info = {7'd0, THERMO | ctrl_flags[FORCE_FAN_IDX]};

if (ENABLE_MODULATION == "TRUE") begin
    assign MOD_SYNC.MOD_CLK_INIT = clk_init_flags[MOD_INIT_IDX];
    assign MOD_SYNC.MOD_CLK_CYCLE = mod_clk_cycle;
    assign MOD_SYNC.MOD_CLK_DIV = mod_clk_div;
    assign MOD_SYNC.MOD_CLK_SYNC_TIME_NS = mod_clk_sync_time;
end
if (ENABLE_SEQUENCE == "TRUE") begin
    assign SEQ_SYNC.SEQ_CLK_INIT = clk_init_flags[SEQ_INIT_IDX];
    assign SEQ_SYNC.SEQ_CLK_CYCLE = seq_clk_cycle;
    assign SEQ_SYNC.SEQ_CLK_DIV = seq_clk_div;
    assign SEQ_SYNC.SEQ_CLK_SYNC_TIME_NS = seq_clk_sync_time;
    assign SEQ_SYNC.WAVELENGTH_UM = wavelength;
    assign SEQ_SYNC.OP_MODE = ctrl_flags[OP_MODE_IDX];
    assign SEQ_SYNC.SEQ_MODE = ctrl_flags[SEQ_MODE_IDX];
end

always_ff @(posedge CLK) begin
    case(state_props)
        READ_CTRL_FLAG: begin
            config_bram_addr <= BRAM_CTRL_FLAG;

            config_web <= '0;
            config_bram_din <= '0;

            seq_clk_sync_time[63:48] <= config_bram_dout;

            state_props <= READ_CLK_INIT_FLAG;
        end
        READ_CLK_INIT_FLAG: begin
            config_bram_addr <= BRAM_CLK_INIT_FLAG;

            // CLEAR_CLK_INIT_FLAG

            state_props <= READ_MOD_CYCLE;
        end
        READ_MOD_CYCLE: begin
            config_bram_addr <= BRAM_MOD_CYCLE;

            // WRITE_FPGA_INFO

            state_props <= READ_MOD_FREQ_DIV;
        end
        READ_MOD_FREQ_DIV: begin
            config_bram_addr <= BRAM_MOD_DIV;

            ctrl_flags <= config_bram_dout[6:0];

            state_props <= READ_MOD_CLK_SYNC_TIME_0;
        end
        READ_MOD_CLK_SYNC_TIME_0: begin
            config_bram_addr <= BRAM_MOD_SYNC_TIME_0;

            clk_init_flags <= config_bram_dout;

            state_props <= READ_MOD_CLK_SYNC_TIME_1;
        end
        READ_MOD_CLK_SYNC_TIME_1: begin
            config_bram_addr <= BRAM_MOD_SYNC_TIME_1;

            mod_clk_cycle <= config_bram_dout;

            state_props <= READ_MOD_CLK_SYNC_TIME_2;
        end
        READ_MOD_CLK_SYNC_TIME_2: begin
            config_bram_addr <= BRAM_MOD_SYNC_TIME_2;

            mod_clk_div <= config_bram_dout;

            state_props <= READ_MOD_CLK_SYNC_TIME_3;
        end
        READ_MOD_CLK_SYNC_TIME_3: begin
            config_bram_addr <= BRAM_MOD_SYNC_TIME_3;

            mod_clk_sync_time[15:0] <= config_bram_dout;

            state_props <= READ_SEQ_CYCLE;
        end
        READ_SEQ_CYCLE: begin
            config_bram_addr <= BRAM_SEQ_CYCLE;

            mod_clk_sync_time[31:16] <= config_bram_dout;

            state_props <= READ_SEQ_FREQ_DIV;
        end
        READ_SEQ_FREQ_DIV: begin
            config_bram_addr <= BRAM_SEQ_DIV;

            mod_clk_sync_time[47:32] <= config_bram_dout;

            state_props <= READ_WAVELENGTH;
        end
        READ_WAVELENGTH: begin
            config_bram_addr <= BRAM_WAVELENGTH;

            mod_clk_sync_time[63:48] <= config_bram_dout;

            state_props <= READ_SEQ_CLK_SYNC_TIME_0;
        end
        READ_SEQ_CLK_SYNC_TIME_0: begin
            config_bram_addr <= BRAM_SEQ_SYNC_TIME_0;

            seq_clk_cycle <= config_bram_dout;

            state_props <= READ_SEQ_CLK_SYNC_TIME_1;
        end
        READ_SEQ_CLK_SYNC_TIME_1: begin
            config_bram_addr <= BRAM_SEQ_SYNC_TIME_1;

            seq_clk_div <= config_bram_dout;

            state_props <= READ_SEQ_CLK_SYNC_TIME_2;
        end
        READ_SEQ_CLK_SYNC_TIME_2: begin
            config_bram_addr <= BRAM_SEQ_SYNC_TIME_2;

            wavelength <= config_bram_dout;

            state_props <= READ_SEQ_CLK_SYNC_TIME_3;
        end
        READ_SEQ_CLK_SYNC_TIME_3: begin
            config_bram_addr <= BRAM_SEQ_SYNC_TIME_3;

            seq_clk_sync_time[15:0] <= config_bram_dout;

            state_props <= CLEAR_CLK_INIT_FLAG;
        end
        CLEAR_CLK_INIT_FLAG: begin
            config_bram_addr <= BRAM_CLK_INIT_FLAG;
            if (|clk_init_flags) begin
                config_web <= 1'b1;
                config_bram_din <= '0;
            end

            seq_clk_sync_time[31:16] <= config_bram_dout;

            state_props <= WRITE_FPGA_INFO;
        end
        WRITE_FPGA_INFO: begin
            config_bram_addr <= BRAM_FPGA_INFO;
            config_web <= 1'b1;
            config_bram_din <= {8'h00, fpga_info};

            seq_clk_sync_time[47:32] <= config_bram_dout;

            state_props <= READ_CTRL_FLAG;
        end
    endcase
end

endmodule
