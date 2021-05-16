`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/15/2021 03:34:39 PM
// Design Name:
// Module Name: sim_sync
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


module sim_sync();

localparam int SYNC0_FREQ = 1000;
localparam int SYNC0_CYCLE = 1000000000/SYNC0_FREQ;

logic ECAT_CLK;
logic [63:0] ECAT_SYS_TIME;
logic [63:0] ECAT_SYNC0_TIME;
logic [31:0] sync0_pulse_cnt;

logic MRCC_25P6M;
logic RST;
logic CAT_SYNC0;

logic sys_clk;
logic sync;
logic [2:0] sync0_edge;
assign sync = sync0_edge == 3'b011;

logic ref_clk_init;

logic seq_clk_init_0;
logic [8:0] time_t_0;
logic [14:0] mod_idx_0;
logic [15:0] seq_idx_0;
logic [63:0] seq_clk_sync_time_0;

logic seq_clk_init_1;
logic [8:0] time_t_1;
logic [14:0] mod_idx_1;
logic [15:0] seq_idx_1;
logic [63:0] seq_clk_sync_time_1;

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(RST),
                           .clk_out1(sys_clk),
                           .clk_out2()
                       );

synchronizer synchronizer0(
                 .CLK(sys_clk),
                 .RST(RST),
                 .SYNC(sync),
                 .REF_CLK_INIT(ref_clk_init),
                 .REF_CLK_CYCLE_SHIFT(8'd0),
                 .MOD_IDX_SHIFT(8'd1),
                 .SEQ_CLK_INIT(seq_clk_init_0),
                 .SEQ_CLK_CYCLE(16'd3),
                 .SEQ_CLK_DIV(16'd7),
                 .SEQ_CLK_SYNC_TIME_NS(seq_clk_sync_time_0),
                 .TIME(time_t_0),
                 .MOD_IDX(mod_idx_0),
                 .SEQ_IDX(seq_idx_0)
             );

synchronizer synchronizer1(
                 .CLK(sys_clk),
                 .RST(RST),
                 .SYNC(sync),
                 .REF_CLK_INIT(ref_clk_init),
                 .REF_CLK_CYCLE_SHIFT(8'd0),
                 .MOD_IDX_SHIFT(8'd1),
                 .SEQ_CLK_INIT(seq_clk_init_1),
                 .SEQ_CLK_CYCLE(16'd3),
                 .SEQ_CLK_DIV(16'd7),
                 .SEQ_CLK_SYNC_TIME_NS(seq_clk_sync_time_1),
                 .TIME(time_t_1),
                 .MOD_IDX(mod_idx_1),
                 .SEQ_IDX(seq_idx_1)
             );


task sync_ref_clk();
    @(posedge CAT_SYNC0);
    #50000;
    ref_clk_init = 1;
    @(posedge CAT_SYNC0);
    ref_clk_init = 0;
endtask

task sync_seq_clk(int id);
    if(id == 0)  begin
        @(posedge CAT_SYNC0);
        #50000;
        seq_clk_init_0 = 1;
        seq_clk_sync_time_0 = ECAT_SYNC0_TIME;
        @(posedge CAT_SYNC0);
        #50000;
        seq_clk_init_0 = 0;
    end
    else begin
        @(posedge CAT_SYNC0);
        #50000;
        seq_clk_init_1 = 1;
        seq_clk_sync_time_1 = ECAT_SYNC0_TIME;
        @(posedge CAT_SYNC0);
        #50000;
        seq_clk_init_1 = 0;
    end
endtask

initial begin
    ECAT_CLK = 1;
    ECAT_SYS_TIME = 0;
    ECAT_SYNC0_TIME = SYNC0_CYCLE;
    sync0_pulse_cnt = 0;
    MRCC_25P6M = 1;
    RST = 1;

    ref_clk_init = 0;
    seq_clk_init_0 = 0;
    seq_clk_init_1 = 0;
    seq_clk_sync_time_0 = 0;
    seq_clk_sync_time_1 = 0;
    #1000;
    RST = 0;

    sync_ref_clk();

    #2000000;
    sync_seq_clk(0);

    #1000000;
    sync_seq_clk(1);

end

always @(posedge sys_clk) begin
    sync0_edge <= RST ? 0 : {sync0_edge[1:0], CAT_SYNC0};
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

