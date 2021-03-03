/*
 * File: top.sv
 * Project: new
 * Created Date: 02/10/2019
 * Author: Shun Suzuki
 * -----
 * Last Modified: 03/03/2021
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

localparam TRANS_NUM = 1;

localparam SYS_CLK_FREQ = 25600000;
localparam ULTRASOUND_FREQ  = 40000;
localparam REF_CLK_FREQ = 40000;
localparam REF_CLK_CYCLE_BASE = 1;
localparam REF_CLK_CYCLE_MAX = 32;
localparam SYNC_FREQ = 1000;
localparam SYNC_CYCLE_CNT = 40;
localparam STM_CLK_MAX = 40000;
localparam MOD_BUF_SIZE = 32000;
localparam MOD_BUF_IDX_WIDTH = $clog2(MOD_BUF_SIZE);

logic [2:0] sync0 = 0;
logic sync0_pos_edge;

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
logic [MOD_BUF_IDX_WIDTH-1:0] mod_idx;
logic [15:0] stm_idx;

logic [7:0] duty[0:TRANS_NUM-1];
logic [7:0] phase[0:TRANS_NUM-1];
logic [7:0] delay[0:TRANS_NUM-1];

logic [7:0] mod;

assign FORCE_FAN = force_fan;
assign CPU_DATA  = (~CPU_CS1_N && ~CPU_RD_N && CPU_RDWR) ? cpu_data_out : 16'bz;

assign sync0_pos_edge = (sync0 == 3'b011);

cpu_bus_if cpu_bus();
assign cpu_bus.BUS_CLK = CPU_CKIO;
assign cpu_bus.EN = ~CPU_CS1_N;
assign cpu_bus.WE = ~CPU_WE0_N;
assign cpu_bus.BRAM_SELECT = CPU_ADDR[16:15];
assign cpu_bus.BRAM_ADDR = CPU_ADDR[14:1];
assign cpu_bus.DATA_IN = CPU_DATA;
assign cpu_data_out = cpu_bus.DATA_OUT;

config_bus_if config_bus();
mod_bus_if mod_bus();
normal_op_bus_if normal_op_bus();
stm_op_bus_if stm_op_bus();

bram_controller bram_controller(
                    .CPU_BUS(cpu_bus.slave_port),

                    .SYS_CLK(MRCC_25P6M),
                    .CONFIG_BUS(config_bus.slave_port),
                    .MOD_BUS(mod_bus.slave_port),
                    .NORMAL_OP_BUS(normal_op_bus.slave_port),
                    .STM_OP_BUS(stm_op_bus.slave_port)
                );

global_config global_config(
                  .CONFIG_BUS(config_bus.master_port),

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

synchronizer#(
                .SYS_CLK_FREQ(SYS_CLK_FREQ),
                .ULTRASOUND_FREQ(ULTRASOUND_FREQ),
                .REF_CLK_FREQ(REF_CLK_FREQ),
                .REF_CLK_CYCLE_BASE(REF_CLK_CYCLE_BASE),
                .REF_CLK_CYCLE_MAX(REF_CLK_CYCLE_MAX),
                .SYNC_FREQ(SYNC_FREQ),
                .SYNC_CYCLE_CNT(SYNC_CYCLE_CNT),
                .STM_CLK_MAX(STM_CLK_MAX),
                .MOD_BUF_SIZE(MOD_BUF_SIZE)
            )
            synchronizer(
                .SYS_CLK(MRCC_25P6M),
                .RST(soft_rst),
                .SYNC(sync0_pos_edge),

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

operator_selector#(.TRANS_NUM(TRANS_NUM))
                 operator_selector(
                     .NORMAL_OP_BUS(normal_op_bus.master_port),
                     .STM_OP_BUS(stm_op_bus.master_port),

                     .SYS_CLK(MRCC_25P6M),
                     .op_mode(op_mode),
                     .TIME(time_cnt),

                     .STM_IDX(stm_idx),
                     .STM_CLK_DIV(stm_div),

                     .DUTY(duty),
                     .PHASE(phase),
                     .DELAY(delay)
                 );

mod_controller#(.MOD_BUF_SIZE(MOD_BUF_SIZE))
              mod_controller(
                  .MOD_BUS(mod_bus.master_port),
                  .MOD_IDX(mod_idx),
                  .MOD_OUT(mod)
              );

logic aclk;
clk_lpf clk_lpf(
            .clk_in1(MRCC_25P6M),
            .clk_out1(aclk)
        );
transducers_array#(.TRANS_NUM(TRANS_NUM))
                 transducers_array(
                     .CLK(MRCC_25P6M),
                     .CLK_LPF(aclk),
                     .TIME(time_cnt),
                     .DUTY(duty),
                     .PHASE(phase),
                     .DELAY(delay),
                     .MOD(mod),
                     .SILENT(silent),
                     .XDCR_OUT(XDCR_OUT)
                 );

always_ff @(posedge MRCC_25P6M) begin
    sync0 <= {sync0[1:0], CAT_SYNC0};
end

endmodule
