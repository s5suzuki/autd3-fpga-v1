/*
 * File: config_manager.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 13/05/2021
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
           output var REF_CLK_INIT,
           output var [7:0] REF_CLK_CYCLE_SHIFT,
           output var [7:0] MOD_IDX_SHIFT,
           output var SEQ_CLK_INIT,
           output var [15:0] SEQ_CLK_CYCLE,
           output var [15:0] SEQ_CLK_DIV,
           output var SEQ_MODE,
           output var SILENT,
           output var FORCE_FAN,
           output var SOFT_RST,
           input var THERMO
       );

// CF: Control Flag
// CP: Clock Properties
localparam [7:0] BRAM_CF_AND_CP           = 8'd0;
localparam [7:0] BRAM_FPGA_INFO           = 8'd1;
localparam [7:0] BRAM_SEQ_CYCLE           = 8'd2;
localparam [7:0] BRAM_SEQ_DIV             = 8'd3;
localparam [7:0] BRAM_SEQ_SYNC_SHIFT      = 8'd4;
localparam [7:0] BRAM_MOD_IDX_SHIFT       = 8'd5;
localparam [7:0] BRAM_REF_CLK_CYCLE_SHIFT = 8'd6;

localparam CF_SILENT    = 3;
localparam CF_FORCE_FAN = 4;
localparam CF_SEQ_MODE  = 5;

localparam CP_REF_INIT_IDX  = 0;
localparam CP_SEQ_INIT_IDX  = 1;
localparam CP_RST_IDX       = 7;

logic [7:0] config_bram_addr;
logic [15:0] config_bram_din;
logic [15:0] config_bram_dout;
logic config_web;

logic [7:0] ctrl_flags;
logic [7:0] clk_props;
logic [7:0] fpga_info;
logic soft_rst;

logic [15:0] seq_clk_cycle;
logic [15:0] seq_div;
logic [7:0] mod_idx_shift;
logic [7:0] ref_clk_cycle_shift;

enum logic [4:0] {
         READ_CF_AND_CP,
         WRITE_FPGA_INFO,

         SOFT_RST,

         REQ_CP_CLEAR,
         REQ_CP_CLEAR_WAIT0,
         REQ_CP_CLEAR_WAIT1,
         CP_CLEAR,

         REQ_READ_REF_MOD_IDX_SHIFT,
         REQ_READ_REF_CLK_SHIFT_WAIT,
         READ_REF_CLK_SHIFT,
         READ_MOD_IDX_SHIFT,

         REQ_READ_SEQ_CLK_DIV,
         REQ_READ_SEQ_CLK_CYCLE_WAIT,
         READ_SEQ_CLK_CYCLE,
         READ_SEQ_CLK_DIV
     } state_props;

assign CONFIG_BUS.WE = config_web;
assign CONFIG_BUS.IDX = config_bram_addr;
assign CONFIG_BUS.DATA_IN = config_bram_din;
assign config_bram_dout = CONFIG_BUS.DATA_OUT;

assign SILENT = ctrl_flags[CF_SILENT];
assign SEQ_MODE = ctrl_flags[CF_SEQ_MODE];
assign FORCE_FAN = ctrl_flags[CF_FORCE_FAN];
assign fpga_info = {7'd0, THERMO};
assign SOFT_RST = soft_rst;

assign REF_CLK_INIT = clk_props[CP_REF_INIT_IDX];
assign REF_CLK_CYCLE_SHIFT = ref_clk_cycle_shift;
assign MOD_IDX_SHIFT = mod_idx_shift;
assign SEQ_CLK_INIT = clk_props[CP_SEQ_INIT_IDX];
assign SEQ_CLK_CYCLE = seq_clk_cycle;
assign SEQ_CLK_DIV = seq_clk_div;

always_ff @(posedge CLK) begin
    if(RST) begin
        config_web <= 0;
        clk_props <= 0;
        ctrl_flags <= 0;
        config_bram_addr <= 0;
        config_bram_din <= 0;

        ref_clk_cycle_shift <= 0;
        mod_idx_shift <= 0;

        soft_rst <= 0;
        state_props <= READ_CF_AND_CP;
    end
    else begin
        case(state_props)
            READ_CF_AND_CP: begin
                clk_props <= config_bram_dout[15:8];
                ctrl_flags <= config_bram_dout[7:0];
                if(clk_props[CP_RST_IDX]) begin
                    config_web <= 0;
                    config_bram_addr <= 0;
                    config_bram_din <= 0;
                    soft_rst <= 1;
                    state_props <= SOFT_RST;
                end
                else if(clk_props[CP_REF_INIT_IDX]) begin
                    config_web <= 0;
                    config_bram_addr <= BRAM_REF_CLK_CYCLE_SHIFT;
                    config_bram_din <= 0;
                    state_props <= REQ_READ_REF_MOD_IDX_SHIFT;
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
                config_bram_addr <= BRAM_CF_AND_CP;
                state_props <= READ_CF_AND_CP;
            end

            READ_SEQ_CLK_CYCLE: begin
                config_bram_addr <= BRAM_CF_AND_CP;
                seq_clk_cycle <= config_bram_dout;

                state_props <= READ_SEQ_CLK_DIV;
            end
            READ_SEQ_CLK_DIV: begin
                config_bram_addr <= BRAM_SEQ_CYCLE;
                seq_div <= config_bram_dout;

                state_props <= READ_MOD_IDX_SHIFT;
            end
            READ_MOD_IDX_SHIFT: begin
                config_bram_addr <= BRAM_SEQ_DIV;
                mod_idx_shift <= config_bram_dout[7:0];

                state_props <= READ_CF_AND_CP;
            end

            SOFT_RST: begin
                clk_props <= 0;
                ctrl_flags <= 0;
                soft_rst <= 0;
                state_props <= REQ_CP_CLEAR;
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
                config_bram_addr <= BRAM_CF_AND_CP;
                clk_props <= config_bram_dout[15:8];
                ctrl_flags <= config_bram_dout[7:0];
                state_props <= READ_CF_AND_CP;
            end

            // Init reference clk
            REQ_READ_REF_MOD_IDX_SHIFT: begin
                config_bram_addr <= BRAM_MOD_IDX_SHIFT;
                state_props <= REQ_READ_REF_CLK_SHIFT_WAIT;
            end
            REQ_READ_REF_CLK_SHIFT_WAIT: begin
                state_props <= READ_REF_CLK_SHIFT;
            end
            READ_REF_CLK_SHIFT: begin
                ref_clk_cycle_shift <= config_bram_dout[7:0];
                state_props <= READ_MOD_IDX_SHIFT;
            end
            READ_MOD_IDX_SHIFT: begin
                mod_idx_shift <= config_bram_dout[7:0];
                if (SYNC) begin
                    state_props <= REQ_CP_CLEAR;
                end
            end

            // Init sequence clk
            REQ_READ_SEQ_CLK_DIV: begin
                config_bram_addr <= BRAM_SEQ_DIV;
                state_props <= REQ_READ_SEQ_CLK_CYCLE_WAIT;
            end
            REQ_READ_SEQ_CLK_CYCLE_WAIT: begin
                state_props <= READ_SEQ_CLK_CYCLE;
            end
            READ_SEQ_CLK_CYCLE: begin
                seq_clk_cycle <= config_bram_dout;
                state_props <= READ_SEQ_CLK_DIV;
            end
            READ_SEQ_CLK_DIV: begin
                seq_clk_div <= config_bram_dout;
                if (SYNC) begin
                    state_props <= REQ_CP_CLEAR;
                end
            end
        endcase
    end
end

endmodule
