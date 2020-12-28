/*
 * File: global_config.sv
 * Project: new
 * Created Date: 16/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 23/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 *
 */

`timescale 1ns / 1ps
module global_config(
           config_bus_if.master_port CONFIG_BUS,

           input var SYS_CLK,
           output var SOFT_RST_OUT,

           output var [7:0] REF_CLK_CYCLE_SHIFT,
           output var REF_CLK_INIT_OUT,
           input var REF_CLK_INIT_DONE,
           output var STM_CLK_INIT_OUT,
           output var [15:0] STM_CLK_CYCLE,
           output var [15:0] STM_CLK_DIV,
           input var [10:0] STM_LAP,
           output var STM_CLK_CALIB_OUT,
           output var [15:0] STM_CLK_CALIB_SHIFT,
           output var STM_CLK_CALIB_DONE,
           output var [7:0] MOD_IDX_SHIFT,

           output var SILENT_MODE,
           output var FORCE_FAN,
           output var OP_MODE
       );

localparam CTRL_FLAG_SILENT    = 3;
localparam CTRL_FLAG_FORCE_FAN = 4;
localparam CTRL_FLAG_STM_MODE  = 5;

localparam [13:0] BRAM_CF_AND_CP_IDX       = 14'd0;
localparam [13:0] BRAM_STM_CYCLE           = 14'd1;
localparam [13:0] BRAM_STM_DIV             = 14'd2;
localparam [13:0] BRAM_STM_INIT_LAP        = 14'd3;
localparam [13:0] BRAM_STM_CALIB_SHIFT     = 14'd4;
localparam [13:0] BRAM_MOD_IDX_SHIFT       = 14'd6;
localparam [13:0] BRAM_REF_CLK_CYCLE_SHIFT = 14'd7;

localparam PROPS_REF_INIT_IDX  = 0;
localparam PROPS_STM_INIT_IDX  = 1;
localparam PROPS_STM_CALIB_IDX = 2;
localparam PROPS_RST_IDX       = 7;

logic we = 0;
logic [7:0]addr = 0;
logic [15:0]data_in = 0;
logic [15:0]data_out;

logic [7:0] ctrl_flags = 0;
logic [7:0] clk_props = 0;
logic silent;
logic force_fan;
logic op_mode;

logic soft_rst = 0;
logic ref_clk_init = 0;
logic ref_clk_init_done;
logic [15:0] stm_clk_cycle = 0;
logic [15:0] stm_div = 0;
logic [7:0] mod_idx_shift = 0;
logic stm_clk_init = 0;
logic [10:0] stm_clk_init_lap;
logic [15:0] stm_clk_calib_shift = 0;
logic stm_clk_calib = 0;
logic stm_clk_calib_done;
logic [7:0] ref_clk_cycle_shift = 0;

// CF: Control Flag
// CP: Clock Properties
enum logic [4:0] {
         READ_CF_AND_CP,
         READ_STM_CLK_CYCLE,
         READ_STM_CLK_DIV,
         READ_MOD_IDX_SHIFT,

         SOFT_RST,

         REQ_CP_CLEAR,
         REQ_CP_CLEAR_WAIT0,
         REQ_CP_CLEAR_WAIT1,
         CP_CLEAR,

         REQ_REF_CLK_SHIFT_READ,
         REQ_REF_CLK_SHIFT_READ_WAIT0,
         REQ_REF_CLK_SHIFT_READ_WAIT1,
         REF_CLK_INIT,

         STM_CLK_INIT,
         STM_CLK_LOAD_SHIFT,
         STM_CLK_LOAD_SHIFT_WAIT0,
         STM_CLK_LOAD_SHIFT_WAIT1,
         STM_CLK_CALIB
     } state_props = READ_CF_AND_CP;

assign CONFIG_BUS.WE = we;
assign CONFIG_BUS.ADDR = addr;
assign CONFIG_BUS.DATA_IN = data_in;
assign data_out = CONFIG_BUS.DATA_OUT;

assign silent = ctrl_flags[CTRL_FLAG_SILENT];
assign force_fan = ctrl_flags[CTRL_FLAG_FORCE_FAN];
assign op_mode = ctrl_flags[CTRL_FLAG_STM_MODE];

assign SOFT_RST_OUT = soft_rst;
assign REF_CLK_CYCLE_SHIFT = ref_clk_cycle_shift;
assign REF_CLK_INIT_OUT = ref_clk_init;
assign STM_CLK_INIT_OUT = stm_clk_init;
assign STM_CLK_CYCLE = stm_clk_cycle;
assign STM_CLK_DIV = stm_div;
assign STM_CLK_CALIB_OUT = stm_clk_calib;
assign STM_CLK_CALIB_SHIFT = stm_clk_calib_shift;
assign MOD_IDX_SHIFT = mod_idx_shift;
assign SILENT_MODE = silent;
assign FORCE_FAN = force_fan;
assign OP_MODE = op_mode;

assign ref_clk_init_done = REF_CLK_INIT_DONE;
assign stm_clk_calib_done = STM_CLK_CALIB_DONE;
assign stm_clk_init_lap = STM_LAP;

always_ff @(posedge SYS_CLK) begin
    case(state_props)
        READ_CF_AND_CP: begin
            we <= 0;

            clk_props <= data_out[15:8];
            ctrl_flags <= data_out[7:0];

            if(clk_props[PROPS_RST_IDX]) begin
                soft_rst <= 1;
                state_props <= SOFT_RST;
            end
            else if(clk_props[PROPS_REF_INIT_IDX]) begin
                addr <= BRAM_REF_CLK_CYCLE_SHIFT;
                state_props <= REQ_REF_CLK_SHIFT_READ;
            end
            else if(clk_props[PROPS_STM_INIT_IDX]) begin
                stm_clk_init <= 1;
                state_props <= STM_CLK_INIT;
            end
            else if(clk_props[PROPS_STM_CALIB_IDX]) begin
                addr <= BRAM_STM_CALIB_SHIFT;
                state_props <= STM_CLK_LOAD_SHIFT_WAIT0;
            end
            else begin
                addr <= BRAM_MOD_IDX_SHIFT;
                state_props <= READ_STM_CLK_CYCLE;
            end
        end
        READ_STM_CLK_CYCLE: begin
            addr <= BRAM_CF_AND_CP_IDX;
            stm_clk_cycle <= data_out;

            state_props <= READ_STM_CLK_DIV;
        end
        READ_STM_CLK_DIV: begin
            addr <= BRAM_STM_CYCLE;
            stm_div <= data_out;

            state_props <= READ_MOD_IDX_SHIFT;
        end
        READ_MOD_IDX_SHIFT: begin
            addr <= BRAM_STM_DIV;
            mod_idx_shift <= data_out[7:0];

            state_props <= READ_CF_AND_CP;
        end

        SOFT_RST: begin
            soft_rst <= 0;
            state_props <= REQ_CP_CLEAR;
        end

        REQ_CP_CLEAR: begin
            we <= 1;
            addr <= BRAM_CF_AND_CP_IDX;
            data_in <= {8'h00, ctrl_flags};
            state_props <= REQ_CP_CLEAR_WAIT0;
        end
        REQ_CP_CLEAR_WAIT0: begin
            we <= 0;
            state_props <= REQ_CP_CLEAR_WAIT1;
        end
        REQ_CP_CLEAR_WAIT1: begin
            addr <= BRAM_STM_CYCLE;
            state_props <= CP_CLEAR;
        end
        CP_CLEAR: begin
            addr <= BRAM_STM_DIV;
            clk_props <= data_out[15:8];
            ctrl_flags <= data_out[7:0];
            state_props <= READ_CF_AND_CP;
        end

        REQ_REF_CLK_SHIFT_READ: begin
            state_props <= REQ_REF_CLK_SHIFT_READ_WAIT0;
        end
        REQ_REF_CLK_SHIFT_READ_WAIT0: begin
            state_props <= REQ_REF_CLK_SHIFT_READ_WAIT1;
        end
        REQ_REF_CLK_SHIFT_READ_WAIT1: begin
            ref_clk_init <= 1;
            ref_clk_cycle_shift <= data_out[7:0];
            state_props <= REF_CLK_INIT;
        end
        REF_CLK_INIT: begin
            ref_clk_init <= 0;
            if (ref_clk_init_done) begin
                state_props <= REQ_CP_CLEAR;
            end
        end

        STM_CLK_INIT: begin
            stm_clk_init <= 0;
            if (stm_clk_init_lap[10]) begin
                we <= 1;
                addr <= BRAM_STM_INIT_LAP;
                data_in <= stm_clk_init_lap[10:0];
                state_props <= REQ_CP_CLEAR;
            end
        end

        STM_CLK_LOAD_SHIFT_WAIT0: begin
            state_props <= STM_CLK_LOAD_SHIFT_WAIT1;
        end
        STM_CLK_LOAD_SHIFT_WAIT1: begin
            state_props <= STM_CLK_LOAD_SHIFT;
        end
        STM_CLK_LOAD_SHIFT: begin
            stm_clk_calib_shift <= data_out;
            stm_clk_calib <= 1;
            state_props <= STM_CLK_CALIB;
        end
        STM_CLK_CALIB: begin
            stm_clk_calib <= 0;
            if (stm_clk_calib_done) begin
                state_props <= REQ_CP_CLEAR;
            end
        end
    endcase
end

endmodule
