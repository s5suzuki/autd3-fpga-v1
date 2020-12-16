/*
 * File: global_config.sv
 * Project: new
 * Created Date: 16/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 16/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
`include "consts.vh"

module global_config(
           cpu_bus_if.slave_port CPU_BUS,
           output var [15:0] CPU_DATA_OUT,

           input var SYS_CLK,
           output var SOFT_RST_OUT,

           output var [7:0] REF_CLK_CYCLE_SHIFT,
           output var REF_CLK_INIT_OUT,
           input var REF_CLK_INIT_DONE,
           output var LM_CLK_INIT_OUT,
           output var [15:0] LM_CLK_CYCLE,
           output var [15:0] LM_CLK_DIV,
           input var [10:0] LM_LAP,
           output var LM_CLK_CALIB_OUT,
           output var [15:0] LM_CLK_CALIB_SHIFT,
           output var LM_CLK_CALIB_DONE,
           output var [7:0] MOD_IDX_SHIFT,

           output var SILENT_MODE,
           output var FORCE_FAN,
           output var OP_MODE
       );

logic prop_en = (CPU_BUS.BRAM_SELECT == `BRAM_PROP_SELECT) & CPU_BUS.EN;

logic [15:0]cpu_data_out;

logic bram_props_we;
logic [7:0]bram_props_addr;
logic [15:0]bram_props_datain;
logic [15:0]bram_props_dataout;

logic [7:0] ctrl_flags;
logic [7:0] clk_props;
logic silent = ctrl_flags[`CTRL_FLAG_SILENT];
logic force_fan = ctrl_flags[`CTRL_FLAG_FORCE_FAN];
logic op_mode = ctrl_flags[`CTRL_FLAG_LM_MODE];

logic soft_rst;
logic ref_clk_init;
logic ref_clk_init_done = REF_CLK_INIT_DONE;
logic [15:0] lm_clk_cycle;
logic [15:0] lm_div;
logic [7:0] mod_idx_shift;
logic lm_clk_init;
logic [10:0] lm_clk_init_lap = LM_LAP;
logic [15:0] lm_clk_calib_shift;
logic lm_clk_calib;
logic lm_clk_calib_done = LM_CLK_CALIB_DONE;
logic [7:0] ref_clk_cycle_shift;

// CF: Control Flag
// CP: Clock Properties
enum logic [4:0] {
         READ_CF_AND_CP,
         READ_LM_CLK_CYCLE,
         READ_LM_CLK_DIV,
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

         LM_CLK_INIT,
         LM_CLK_LOAD_SHIFT,
         LM_CLK_LOAD_SHIFT_WAIT0,
         LM_CLK_LOAD_SHIFT_WAIT1,
         LM_CLK_CALIB
     } state_props;

assign SOFT_RST_OUT = soft_rst;
assign CPU_DATA_OUT = cpu_data_out;
assign REF_CLK_CYCLE_SHIFT = ref_clk_cycle_shift;
assign REF_CLK_INIT_OUT = ref_clk_init;
assign LM_CLK_INIT_OUT = lm_clk_init;
assign LM_CLK_CYCLE = lm_clk_cycle;
assign LM_CLK_DIV = lm_div;
assign LM_CLK_CALIB_OUT = lm_clk_calib;
assign LM_CLK_CALIB_SHIFT = lm_clk_calib_shift;
assign MOD_IDX_SHIFT = mod_idx_shift;
assign SILENT_MODE = silent;
assign FORCE_FAN = force_fan;
assign OP_MODE = op_mode;

BRAM16x256 ram_props(
               .clka(CPU_BUS.BUS_CLK),
               .ena(prop_en),
               .wea(CPU_BUS.WE),
               .addra(CPU_BUS.BRAM_ADDR[7:0]),
               .dina(CPU_BUS.DATA_IN),
               .douta(cpu_data_out),

               .clkb(SYS_CLK),
               .web(bram_props_we),
               .addrb(bram_props_addr),
               .dinb(bram_props_datain),
               .doutb(bram_props_dataout)
           );

initial begin
    ctrl_flags = 0;
    clk_props = 0;
    ref_clk_init = 0;
    soft_rst = 0;

    mod_idx_shift = 0;
    ref_clk_cycle_shift = 0;

    bram_props_we = 0;
    bram_props_addr = 0;
    bram_props_datain = 0;

    lm_clk_cycle = 0;
    lm_div = 0;
    lm_clk_init = 0;
    lm_clk_calib_shift = 0;
    lm_clk_calib = 0;
end

always_ff @(posedge SYS_CLK) begin
    case(state_props)
        READ_CF_AND_CP: begin
            bram_props_we <= 0;

            clk_props <= bram_props_dataout[15:8];
            ctrl_flags <= bram_props_dataout[7:0];

            if(clk_props[`PROPS_RST_IDX]) begin
                soft_rst <= 1;
                state_props <= SOFT_RST;
            end
            else if(clk_props[`PROPS_REF_INIT_IDX]) begin
                bram_props_addr <= `BRAM_REF_CLK_CYCLE_SHIFT;
                state_props <= REQ_REF_CLK_SHIFT_READ;
            end
            else if(clk_props[`PROPS_LM_INIT_IDX]) begin
                lm_clk_init <= 1;
                state_props <= LM_CLK_INIT;
            end
            else if(clk_props[`PROPS_LM_CALIB_IDX]) begin
                bram_props_addr <= `BRAM_LM_CALIB_SHIFT;
                state_props <= LM_CLK_LOAD_SHIFT_WAIT0;
            end
            else begin
                bram_props_addr <= `BRAM_MOD_IDX_SHIFT;
                state_props <= READ_LM_CLK_CYCLE;
            end
        end
        READ_LM_CLK_CYCLE: begin
            bram_props_addr <= `BRAM_CF_AND_CP_IDX;
            lm_clk_cycle <= bram_props_dataout;

            state_props <= READ_LM_CLK_DIV;
        end
        READ_LM_CLK_DIV: begin
            bram_props_addr <= `BRAM_LM_CYCLE;
            lm_div <= bram_props_dataout;

            state_props <= READ_MOD_IDX_SHIFT;
        end
        READ_MOD_IDX_SHIFT: begin
            bram_props_addr <= `BRAM_LM_DIV;
            mod_idx_shift <= bram_props_dataout[7:0];

            state_props <= READ_CF_AND_CP;
        end

        SOFT_RST: begin
            soft_rst <= 0;
            state_props <= REQ_CP_CLEAR;
        end

        REQ_CP_CLEAR: begin
            bram_props_we <= 1;
            bram_props_addr <= `BRAM_CF_AND_CP_IDX;
            bram_props_datain <= {8'h00, ctrl_flags};
            state_props <= REQ_CP_CLEAR_WAIT0;
        end
        REQ_CP_CLEAR_WAIT0: begin
            bram_props_we <= 0;
            state_props <= REQ_CP_CLEAR_WAIT1;
        end
        REQ_CP_CLEAR_WAIT1: begin
            bram_props_addr <= `BRAM_LM_CYCLE;
            state_props <= CP_CLEAR;
        end
        CP_CLEAR: begin
            bram_props_addr <= `BRAM_LM_DIV;
            clk_props <= bram_props_dataout[15:8];
            ctrl_flags <= bram_props_dataout[7:0];
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
            ref_clk_cycle_shift <= bram_props_dataout[7:0];
            state_props <= REF_CLK_INIT;
        end
        REF_CLK_INIT: begin
            ref_clk_init <= 0;
            if (ref_clk_init_done) begin
                state_props <= REQ_CP_CLEAR;
            end
        end

        LM_CLK_INIT: begin
            lm_clk_init <= 0;
            if (lm_clk_init_lap[10]) begin
                bram_props_we <= 1;
                bram_props_addr <= `BRAM_LM_INIT_LAP;
                bram_props_datain <= lm_clk_init_lap[10:0];
                state_props <= REQ_CP_CLEAR;
            end
        end

        LM_CLK_LOAD_SHIFT_WAIT0: begin
            state_props <= LM_CLK_LOAD_SHIFT_WAIT1;
        end
        LM_CLK_LOAD_SHIFT_WAIT1: begin
            state_props <= LM_CLK_LOAD_SHIFT;
        end
        LM_CLK_LOAD_SHIFT: begin
            lm_clk_calib_shift <= bram_props_dataout;
            lm_clk_calib <= 1;
            state_props <= LM_CLK_CALIB;
        end
        LM_CLK_CALIB: begin
            lm_clk_calib <= 0;
            if (lm_clk_calib_done) begin
                state_props <= REQ_CP_CLEAR;
            end
        end
    endcase
end

endmodule
