/*
 * File: sim_seq.sv
 * Project: new
 * Created Date: 30/09/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 30/09/2021
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

logic [7:0] duty[0:TRANS_NUM-1];
logic [7:0] phase[0:TRANS_NUM-1];

logic [8:0] time_cnt;
logic [15:0] ctrl_flag;

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

seq_sync_if seq_sync();
assign seq_sync.REF_CLK_TICK = ref_clk_tick;
assign seq_sync.SYNC = sync;

mod_sync_if mod_sync();
assign mod_sync.REF_CLK_TICK = ref_clk_tick;
assign mod_sync.SYNC = sync;

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(RST),
                           .clk_out1(CLK),
                           .clk_out2()
                       );

seq_operator #(
                 .TRANS_NUM(TRANS_NUM)
             ) seq_operator(
                 .CLK,
                 .CPU_BUS(cpu_bus.slave_port),
                 .SEQ_SYNC(seq_sync.slave_port),
                 .DUTY(duty),
                 .PHASE(phase)
             );

config_manager config_manager(
                   .CLK,
                   .SYNC(sync0_edge),
                   .CPU_BUS(cpu_bus.slave_port),
                   .DATA_OUT(cpu_data_out),
                   .MOD_SYNC(mod_sync.master_port),
                   .SEQ_SYNC(seq_sync.master_port),
                   .SILENT(silent),
                   .FORCE_FAN(FORCE_FAN),
                   .THERMO(THERMO),
                   .OUTPUT_EN(output_en),
                   .OUTPUT_BALANCE(output_balance)
               );

synchronizer#(
                .TRANS_NUM(TRANS_NUM)
            ) synchronizer(
                .CLK(CLK),
                .SYNC(sync),
                .TIME(time_cnt),
                .REF_CLK_TICK(ref_clk_tick),
                .UPDATE(update)
            );

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

task sync_seq_clk();
    @(posedge CAT_SYNC0);
    #50000;
    bram_write(0, 14'h0009, ECAT_SYNC0_TIME[15:0]);
    bram_write(0, 14'h000A, ECAT_SYNC0_TIME[31:16]);
    bram_write(0, 14'h000B, ECAT_SYNC0_TIME[47:32]);
    bram_write(0, 14'h000C, ECAT_SYNC0_TIME[63:48]);
    ctrl_flag = ctrl_flag | 16'h8000 | 16'h0010;
    bram_write(0, 14'h0000, ctrl_flag);
    @(posedge CAT_SYNC0);
    #50000;
    ctrl_flag = ctrl_flag & 16'h7fff;
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

    ctrl_flag = 0;

    MRCC_25P6M = 0;
    CPU_CKIO = 0;
    RST = 1;
    CPU_WE0_N = 1;
    bram_addr = 0;
    #1000;
    RST = 0;
    #1000;
    bram_write(0, 14'h0007, 0); // offset
    bram_write(0, 14'h0008, 16'd8500); // wavelength
    bram_write(0, 14'h0002, 16'd2 - 1); // cycle
    bram_write(0, 14'h0003, 16'd1); // div

    sync_seq_clk();

    // FOCI
    focus_write(0, 18'sd0, 18'sd0, 18'sd6000, 8'h01);
    focus_write(1, 18'sd0, 18'sd0, -18'sd6000, 8'h04);
    @(posedge CLK);
    #10000000;

    // Raw duty phase
    ctrl_flag = ctrl_flag | 16'h0020;
    bram_write(0, 14'h0000, ctrl_flag);
    bram_write(0, 14'h0002, 16'd4 - 1); // cycle
    sync_seq_clk();

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
