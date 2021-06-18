`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/17 09:49:25
// Design Name:
// Module Name: sim_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module sim_top();

localparam int TRANS_NUM = 2;

logic MRCC_25P6M;
logic RST;
logic [252:1] XDCR_OUT;

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

// SYNC0
logic CAT_SYNC0;
logic ECAT_CLK;
logic [63:0] ECAT_SYS_TIME;
logic [63:0] ECAT_SYNC0_TIME;
logic [31:0] sync0_pulse_cnt;
localparam int SYNC0_FREQ = 2000;
localparam int SYNC0_CYCLE = 1000000000/SYNC0_FREQ;

////////////////////////////////////////////////////////
logic [2:0] sync0;
logic sys_clk, lpf_clk;

logic mod_clk_init;
logic seq_clk_init;
logic silent;
logic seq_mode;

logic [8:0] time_cnt;
logic update;
logic [15:0] mod_idx;
logic [15:0] seq_idx;

assign sync0_edge = (sync0 == 3'b011);

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(RST),
                           .clk_out1(sys_clk),
                           .clk_out2(lpf_clk)
                       );

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

mem_manager mem_manager(
                .CLK(sys_clk),
                .CPU_BUS(cpu_bus.slave_port),
                .TR_BUS(tr_bus.master_port),
                .CONFIG_BUS(config_bus.master_port),
                .SEQ_BUS(seq_bus.master_port),
                .MOD_IDX(mod_idx),
                .MOD(mod)
            );

synchronizer synchronizer(
                 .CLK(sys_clk),
                 .SYNC(sync0_edge),
                 .MOD_CLK_INIT(mod_clk_init),
                 .MOD_CLK_CYCLE(16'd4000),
                 .MOD_CLK_DIV(16'd10),
                 .MOD_CLK_SYNC_TIME_NS(ECAT_SYNC0_TIME),
                 .SEQ_CLK_INIT(seq_clk_init),
                 .SEQ_CLK_CYCLE(16'd4),
                 .SEQ_CLK_DIV(16'd1),
                 .SEQ_CLK_SYNC_TIME_NS(ECAT_SYNC0_TIME),
                 .TIME(time_cnt),
                 .UPDATE(update),
                 .MOD_IDX(mod_idx),
                 .SEQ_IDX(seq_idx)
             );
tr_cntroller #(
                 .TRANS_NUM(TRANS_NUM)
             ) tr_cntroller(
                 .CLK(sys_clk),
                 .CLK_LPF(lpf_clk),
                 .TIME(time_cnt),
                 .UPDATE(update),
                 .TR_BUS(tr_bus.slave_port),
                 .MOD(mod),
                 .SILENT(silent),
                 .SEQ_BUS(seq_bus.slave_port),
                 .SEQ_MODE(seq_mode),
                 .SEQ_IDX(seq_idx),
                 .WAVELENGTH_UM(16'd8500),
                 .XDCR_OUT(XDCR_OUT)
             );
always_ff @(posedge sys_clk)
    sync0 <= {sync0[1:0], CAT_SYNC0};
////////////////////////////////////////////////////////

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

task sync0_init();
    ECAT_CLK = 1;
    ECAT_SYS_TIME = 0;
    ECAT_SYNC0_TIME = SYNC0_CYCLE;
    sync0_pulse_cnt = 0;
endtask

task cpu_init();
    CPU_CKIO = 0;
    CPU_WE0_N = 1;
    bram_addr = 0;
endtask

task init_mod_seq();
    @(negedge CAT_SYNC0);
    mod_clk_init = 1;
    seq_clk_init = 1;
    @(negedge CAT_SYNC0);
    #1000;
    mod_clk_init = 0;
    seq_clk_init = 0;
endtask

initial begin
    MRCC_25P6M = 1;
    RST = 1;
    mod_clk_init = 0;
    seq_clk_init = 0;
    silent = 0;
    seq_mode = 0;
    sync0_init();
    cpu_init();
    #1000;
    RST = 0;
    init_mod_seq();
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

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

endmodule
