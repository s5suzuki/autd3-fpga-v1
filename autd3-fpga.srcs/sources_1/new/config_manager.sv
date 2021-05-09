/*
 * File: config_manager.sv
 * Project: new
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 09/05/2021
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
           output var CLK_SYNC,
           output var FORCE_FAN,
           input var THERMO
       );

localparam int CTRL_FLAGS_ADDR = 0;
localparam int FPGA_INFO_ADDR = 1;
localparam int CLK_SYNC_ADDR = 2;

localparam int SILENT_MODE_IDX = 3;
localparam int FORCE_FAN_IDX = 4;

logic [8:0] config_bram_addr;
logic [15:0] config_bram_din;
logic config_web;

logic [7:0] ctrl_flags;
logic [7:0] fpga_info;
logic silent;
logic clk_sync;

enum logic [2:0] {
         CTRL_FLAGS_READ,
         FPGA_INFO_WRITE,
         CLK_SYNC_READ
     } config_state;

assign CONFIG_BUS.WE = config_web;
assign CONFIG_BUS.IDX = config_bram_addr;
assign CONFIG_BUS.DATA_IN = config_bram_din;

assign silent = ctrl_flags[SILENT_MODE_IDX];
assign FORCE_FAN = ctrl_flags[FORCE_FAN_IDX];
assign fpga_info = {7'd0, THERMO};

assign CLK_SYNC = clk_sync;

always_ff @(posedge CLK) begin
    if (RST) begin
        config_state <= CTRL_FLAGS_READ;
        config_bram_addr <= 0;
        config_bram_din <= 0;
        config_web <= 0;
        ctrl_flags <= 0;
        clk_sync <= 0;
    end
    else begin
        case(config_state)
            CTRL_FLAGS_READ: begin
                config_bram_addr <= CTRL_FLAGS_ADDR;
                ctrl_flags <= CONFIG_BUS.DATA_OUT[7:0];
                config_state <= FPGA_INFO_WRITE;
            end
            FPGA_INFO_WRITE: begin
                config_bram_addr <= FPGA_INFO_ADDR;
                config_bram_din <= fpga_info;
                config_web <= 1'b1;
                config_state <= CLK_SYNC_READ;
            end
            CLK_SYNC_READ: begin
                config_bram_addr <= CLK_SYNC_ADDR;
                clk_sync <= CONFIG_BUS.DATA_OUT[0];
                config_web <= 1'b0;
                config_state <= CTRL_FLAGS_READ;
            end
        endcase
    end
end

endmodule
