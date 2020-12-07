/*
 * File: main.sv
 * Project: new
 * Created Date: 02/10/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module main(
           input var [16:0] CPU_ADDR,
           inout tri [15:0] CPU_DATA,
           output var [252:1] XDCR_OUT,
           input var CPU_CKIO,
           input var CPU_CS1_N,
           input var RESET_N,
           input var CPU_WE0_N,
           input var CPU_WE1_N,
           input var CPU_RD_N,
           input var CPU_RDWR,
           input var MRCC_25P6M,
           input var CAT_SYNC0,
           output var FORCE_FAN,
           input var THERMO,
           input var [3:0]GPIO_IN,
           output var [3:0]GPIO_OUT
       );

`include "consts.vh"

logic [2:0] sync0;

logic [1:0] bram_select = CPU_ADDR[16:15];
logic [13:0] bram_addr = CPU_ADDR[14:1];

logic prop_en = (bram_select == `BRAM_PROP_SELECT) & ~CPU_CS1_N;
logic [15:0]cpu_data_out;

logic bram_props_we;
logic [7:0]bram_props_addr;
logic [15:0]bram_props_datain;
logic [15:0]bram_props_dataout;

logic [9:0] time_cnt;
logic [`MOD_BUF_IDX_WIDTH-1:0] mod_idx;
logic [15:0] lm_idx;

logic [7:0] ctrl_flags;
logic [7:0] clk_props;
logic silent = ctrl_flags[`CTRL_FLAG_SILENT];
logic force_fan = ctrl_flags[`CTRL_FLAG_FORCE_FAN];
logic op_mode = ctrl_flags[`CTRL_FLAG_LM_MODE];

logic soft_rst;
logic ref_clk_init;
logic ref_clk_init_done;
logic [15:0] lm_clk_cycle;
logic [15:0] lm_div;
logic [7:0] mod_idx_shift;
logic lm_clk_init;
logic [10:0] lm_clk_init_lap;
logic [15:0] lm_clk_calib_shift;
logic lm_clk_calib;
logic lm_clk_calib_done;
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

assign FORCE_FAN = force_fan;
assign CPU_DATA  = (~CPU_CS1_N && ~CPU_RD_N && CPU_RDWR) ? cpu_data_out : 16'bz;

initial begin
    sync0 = 0;
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

transducer_controller tr_cnt(
                          .BUS_CLK(CPU_CKIO),
                          .BRAM_SELECT(bram_select),
                          .EN(~CPU_CS1_N),
                          .WE(~CPU_WE0_N),
                          .ADDR(bram_addr),
                          .DATA_IN(CPU_DATA),

                          .SYS_CLK(MRCC_25P6M),
                          .TIME(time_cnt),
                          .LM_IDX(lm_idx),
                          .LM_CLK_DIV(lm_div),
                          .MOD_IDX(mod_idx),
                          .SILENT(silent),
                          .OP_MODE(op_mode),
                          .XDCR_OUT(XDCR_OUT)
                      );

synchronizer synchronizer(
                 .SYS_CLK(MRCC_25P6M),
                 .RST(soft_rst),
                 .SYNC(sync0 == 3'b011),

                 .REF_CLK_CYCLE_SHIFT(ref_clk_cycle_shift),

                 .REF_CLK_INIT(ref_clk_init),
                 .REF_CLK_INIT_DONE_OUT(ref_clk_init_done),

                 .LM_CLK_INIT(lm_clk_init),
                 .LM_CLK_CYCLE(lm_clk_cycle),
                 .LAP_OUT(lm_clk_init_lap),
                 .LM_CLK_CALIB(lm_clk_calib),
                 .LM_CLK_CALIB_SHIFT(lm_clk_calib_shift),
                 .LM_CLK_CALIB_DONE_OUT(lm_clk_calib_done),

                 .MOD_IDX_SHIFT(mod_idx_shift),

                 .TIME_CNT_OUT(time_cnt),
                 .MOD_IDX_OUT(mod_idx),
                 .LM_IDX_OUT(lm_idx)
             );

BRAM16x256 ram_props(
               .clka(CPU_CKIO),
               .ena(prop_en),
               .wea(~CPU_WE0_N),
               .addra(bram_addr),
               .dina(CPU_DATA),
               .douta(cpu_data_out),

               .clkb(MRCC_25P6M),
               .web(bram_props_we),
               .addrb(bram_props_addr),
               .dinb(bram_props_datain),
               .doutb(bram_props_dataout)
           );

always_ff @(posedge MRCC_25P6M) begin
    sync0 <= {sync0[1:0], CAT_SYNC0};
end

always_ff @(posedge MRCC_25P6M) begin
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
