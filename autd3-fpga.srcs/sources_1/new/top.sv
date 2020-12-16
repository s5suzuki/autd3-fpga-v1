/*
 * File: top.sv
 * Project: new
 * Created Date: 02/10/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 16/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2019 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module top(
           input var [16:0] CPU_ADDR,
           inout tri [15:0] CPU_DATA,
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
           output var [252:1] XDCR_OUT,
           output var [3:0]GPIO_OUT
       );

`include "consts.vh"

logic [2:0] sync0;
logic [15:0]cpu_data_out;

logic [7:0] ref_clk_cycle_shift;
logic ref_clk_init;
logic ref_clk_init_done;
logic stm_clk_init;
logic [15:0] stm_clk_cycle;
logic [15:0] stm_div;
logic [10:0] stm_clk_init_lap;
logic stm_clk_calib;
logic [15:0] stm_clk_calib_shift;
logic stm_clk_calib_done;
logic [7:0] mod_idx_shift;

logic soft_rst;
logic force_fan;
logic silent;
logic op_mode;

logic [9:0] time_cnt;
logic [`MOD_BUF_IDX_WIDTH-1:0] mod_idx;
logic [15:0] stm_idx;

logic [7:0] duty[0:`TRANS_NUM-1];
logic [7:0] phase[0:`TRANS_NUM-1];

logic [7:0] mod;

assign FORCE_FAN = force_fan;
assign CPU_DATA  = (~CPU_CS1_N && ~CPU_RD_N && CPU_RDWR) ? cpu_data_out : 16'bz;

cpu_bus_if cpu_bus();
assign cpu_bus.BUS_CLK = CPU_CKIO;
assign cpu_bus.EN = ~CPU_CS1_N;
assign cpu_bus.WE = ~CPU_WE0_N;
assign cpu_bus.BRAM_SELECT = CPU_ADDR[16:15];
assign cpu_bus.BRAM_ADDR = CPU_ADDR[14:1];
assign cpu_bus.DATA_IN = CPU_DATA;

global_config global_config(
                  .CPU_BUS(cpu_bus.slave_port),
                  .CPU_DATA_OUT(cpu_data_out),

                  .SYS_CLK(MRCC_25P6M),
                  .SOFT_RST_OUT(soft_rst),

                  .REF_CLK_CYCLE_SHIFT(ref_clk_cycle_shift),
                  .REF_CLK_INIT_OUT(ref_clk_init),
                  .REF_CLK_INIT_DONE(ref_clk_init_done),
                  .STM_CLK_INIT_OUT(stm_clk_init),
                  .STM_CLK_CYCLE(stm_clk_cycle),
                  .STM_CLK_DIV(stm_div),
                  .STM_LAP(stm_clk_init_lap),
                  .STM_CLK_CALIB_OUT(stm_clk_calib),
                  .STM_CLK_CALIB_SHIFT(stm_clk_calib_shift),
                  .STM_CLK_CALIB_DONE(stm_clk_calib_done),
                  .MOD_IDX_SHIFT(mod_idx_shift),

                  .SILENT_MODE(silent),
                  .FORCE_FAN(force_fan),
                  .OP_MODE(op_mode)
              );

synchronizer synchronizer(
                 .SYS_CLK(MRCC_25P6M),
                 .RST(soft_rst),
                 .SYNC(sync0 == 3'b011),

                 .REF_CLK_CYCLE_SHIFT(ref_clk_cycle_shift),

                 .REF_CLK_INIT(ref_clk_init),
                 .REF_CLK_INIT_DONE_OUT(ref_clk_init_done),

                 .STM_CLK_INIT(stm_clk_init),
                 .STM_CLK_CYCLE(stm_clk_cycle),
                 .LAP_OUT(stm_clk_init_lap),
                 .STM_CLK_CALIB(stm_clk_calib),
                 .STM_CLK_CALIB_SHIFT(stm_clk_calib_shift),
                 .STM_CLK_CALIB_DONE_OUT(stm_clk_calib_done),

                 .MOD_IDX_SHIFT(mod_idx_shift),

                 .TIME_CNT_OUT(time_cnt),
                 .MOD_IDX_OUT(mod_idx),
                 .STM_IDX_OUT(stm_idx)
             );

operator_selector operator_selector(
                      .CPU_BUS(cpu_bus.slave_port),

                      .SYS_CLK(MRCC_25P6M),
                      .op_mode(op_mode),

                      .STM_IDX(stm_idx),
                      .STM_CLK_DIV(stm_div),

                      .DUTY(duty),
                      .PHASE(phase)
                  );

mod_controller mod_cnt(
                   .CPU_BUS(cpu_bus.slave_port),

                   .SYS_CLK(MRCC_25P6M),
                   .MOD_IDX(mod_idx),
                   .MOD_OUT(mod)
               );

transducers_array transducers_array(
                      .TIME(time_cnt),
                      .DUTY(duty),
                      .PHASE(phase),
                      .MOD(mod),
                      .SILENT(silent),
                      .XDCR_OUT(XDCR_OUT)
                  );

initial begin
    sync0 = 0;
end

always_ff @(posedge MRCC_25P6M) begin
    sync0 <= {sync0[1:0], CAT_SYNC0};
end

endmodule
