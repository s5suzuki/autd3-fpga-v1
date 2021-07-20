/*
 * File: sim_seq.sv
 * Project: new
 * Created Date: 14/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 20/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module sim_seq();

localparam TRANS_NUM = 249;

logic MRCC_25P6M;
logic CLK;
logic RST;

logic [15:0] SEQ_IDX;
logic [7:0] duty[0:TRANS_NUM-1];
logic [7:0] phase[0:TRANS_NUM-1];
logic seq_data_mode;

// SYNC
logic sync;
logic [2:0] sync0_edge;
assign sync = sync0_edge == 3'b011;
localparam int SYNC0_FREQ = 2000;
localparam int SYNC0_CYCLE = 1000000000/SYNC0_FREQ;
logic ECAT_CLK;
logic CAT_SYNC0;
logic [63:0] ECAT_SYS_TIME;
logic [63:0] ECAT_SYNC0_TIME;
logic [31:0] sync0_pulse_cnt;
logic seq_clk_init;
logic [63:0] seq_clk_sync_time;

// CPU
parameter TCO = 10; // bus delay 10ns
logic[15:0] bram_addr;
logic [16:0] CPU_ADDR;
assign CPU_ADDR = {bram_addr, 1'b1};
logic [15:0] CPU_DATA;
logic CPU_CKIO;
logic CPU_CS1_N;
logic CPU_WE0_N;
logic [15:0] CPU_DATA_READ;
logic [15:0] bus_data_reg = 16'bz;
assign CPU_DATA = bus_data_reg;

cpu_bus_if cpu_bus();
assign cpu_bus.BUS_CLK = CPU_CKIO;
assign cpu_bus.EN = ~CPU_CS1_N;
assign cpu_bus.WE = ~CPU_WE0_N;
assign cpu_bus.BRAM_SELECT = CPU_ADDR[16:15];
assign cpu_bus.BRAM_ADDR = CPU_ADDR[14:1];
assign cpu_bus.DATA_IN = CPU_DATA;
assign cpu_data_out = cpu_bus.DATA_OUT;

tr_bus_if tr_bus();
config_bus_if config_bus();
seq_bus_if seq_bus();

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(RST),
                           .clk_out1(CLK),
                           .clk_out2()
                       );

synchronizer synchronizer
             (
                 .CLK,
                 .SYNC(sync),
                 .SEQ_CLK_INIT(seq_clk_init),
                 .MOD_CLK_INIT(),
                 .SEQ_CLK_CYCLE(2),
                 .SEQ_CLK_DIV(10),
                 .MOD_CLK_CYCLE(),
                 .MOD_CLK_DIV(),
                 .SEQ_CLK_SYNC_TIME_NS(seq_clk_sync_time),
                 .MOD_CLK_SYNC_TIME_NS(),
                 .SEQ_DATA_MODE(seq_data_mode),
                 .TIME(),
                 .UPDATE(),
                 .MOD_IDX(),
                 .SEQ_IDX
             );

seq_operator #(
                 .TRANS_NUM(TRANS_NUM)
             ) seq_operator(
                 .CLK,
                 .SEQ_BUS(seq_bus.slave_port),
                 .SEQ_IDX,
                 .WAVELENGTH_UM(16'd8500),
                 .SEQ_DATA_MODE(seq_data_mode),
                 .DUTY(duty),
                 .PHASE(phase)
             );

mem_manager mem_manager(
                .CLK,
                .CPU_BUS(cpu_bus.slave_port),
                .TR_BUS(tr_bus.master_port),
                .SEQ_BUS(seq_bus.master_port),
                .CONFIG_BUS(config_bus.master_port),
                .MOD_IDX(),
                .MOD()
            );

task sync_seq_clk();
    @(posedge CAT_SYNC0);
    #50000;
    seq_clk_init = 1;
    seq_clk_sync_time = ECAT_SYNC0_TIME;
    @(posedge CAT_SYNC0);
    #50000;
    seq_clk_init = 0;
endtask

task bram_write (input [1:0] select, input [13:0] addr, input [15:0] data_in);
    repeat (20) @(posedge CPU_CKIO);
    bram_addr <= #(TCO) {select, addr};
    CPU_CS1_N <= #(TCO) 0;
    bus_data_reg <= #(TCO) data_in;
    @(posedge CPU_CKIO);
    @(negedge CPU_CKIO);

    CPU_WE0_N <= #(TCO) 0;
    repeat (10) @(posedge CPU_CKIO);

    @(negedge CPU_CKIO);
    CPU_WE0_N <= #(TCO) 1;
endtask

task focus_write(input [15:0] idx, input signed [17:0] x, input signed [17:0] y, input signed [17:0] z, input [7:0] amp);
    bram_write(2'd3, idx * 4, x[15:0]);
    bram_write(2'd3, idx * 4 + 1, {y[13:0], x[17:16]});
    bram_write(2'd3, idx * 4 + 2, {z[11:0], y[17:14]});
    bram_write(2'd3, idx * 4 + 3, {2'b00, amp, z[17:12]});
endtask

task raw_duty_phase_write(input [15:0] idx, input [15:0] trans_idx, input [7:0] d, input [7:0] p);
    bram_write(2'd3, (idx << 8) + trans_idx, {d, p});
endtask

initial begin
    ECAT_CLK = 1;
    ECAT_SYS_TIME = 0;
    ECAT_SYNC0_TIME = SYNC0_CYCLE;
    sync0_pulse_cnt = 0;

    MRCC_25P6M = 0;
    CPU_CKIO = 0;
    RST = 1;
    SEQ_IDX = 0;
    CPU_WE0_N = 1;
    bram_addr = 0;
    #1000;
    RST = 0;
    #1000;
    bram_write(0, 14'h0007, 0); // offset

    sync_seq_clk();

    // // FOCI
    // seq_data_mode = 0;
    // focus_write(0, 18'sd0, 18'sd0, 18'sd6000, 8'h01);
    // focus_write(1, 18'sd0, 18'sd0, -18'sd6000, 8'h04);
    // @(posedge CLK);
    // #100000;

    // Raw duty phase
    seq_data_mode = 1;
    raw_duty_phase_write(0, 0, 8'h11, 8'h22);
    raw_duty_phase_write(0, 248, 8'h33, 8'h44);
    raw_duty_phase_write(1, 0, 8'haa, 8'hbb);
    raw_duty_phase_write(1, 248, 8'hcc, 8'hdd);
    @(posedge CLK);
    #100000;
end

always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

// bus clock 75MHz
always
    #6.65 CPU_CKIO = ~CPU_CKIO;

always
    #0.5 ECAT_CLK = ~ECAT_CLK;

always @(posedge ECAT_CLK) begin
    ECAT_SYS_TIME <= ECAT_SYS_TIME + 1;
    if (ECAT_SYS_TIME == ECAT_SYNC0_TIME) begin
        CAT_SYNC0 = 1;
        ECAT_SYNC0_TIME = ECAT_SYNC0_TIME + SYNC0_CYCLE;
        sync0_pulse_cnt = 0;
    end
    else if (sync0_pulse_cnt == 800) begin
        CAT_SYNC0 = 0;
    end
    else begin
        sync0_pulse_cnt = sync0_pulse_cnt + 1;
    end
end

always @(posedge CLK) begin
    sync0_edge <= RST ? 0 : {sync0_edge[1:0], CAT_SYNC0};
end

endmodule
