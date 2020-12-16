`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/26/2020 03:17:21 PM
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

parameter SIMULATION_FREQ = 1000 * 1000 * 1000;

parameter SYSTEM_CLOCK_FREQ = 25.6 * 1000 * 1000;

parameter CAT_SYNC0_PULSE_WIDTH = 800;
parameter CAT_SYNC0_FREQ = 1000;

reg MRCC_25P6M;
reg CAT_SYNC0;

reg [2:0] sync0;
reg rst;

reg ref_clk_init;
wire ref_clk_init_done;

wire [9:0] time_cnt;
wire [14:0] mod_idx;
wire [15:0] stm_idx;
wire [20:0] ref_clk;

synchronizer synchronizer(
                 .SYS_CLK(MRCC_25P6M),
                 .RST(rst),
                 .SYNC(sync0 == 3'b011),

                 .REF_CLK_CYCLE_SHIFT(8'd0),

                 .REF_CLK_INIT(ref_clk_init),
                 .REF_CLK_INIT_DONE_OUT(ref_clk_init_done),

                 .STM_CLK_INIT(),
                 .STM_CLK_CYCLE(),
                 .LAP_OUT(),
                 .STM_CLK_CALIB(),
                 .STM_CLK_CALIB_SHIFT(),
                 .STM_CLK_CALIB_DONE_OUT(),

                 .MOD_IDX_SHIFT(8'd1),

                 .TIME_CNT_OUT(time_cnt),
                 .MOD_IDX_OUT(mod_idx),
                 .STM_IDX_OUT(stm_idx),
                 .REF_CLK_OUT(ref_clk)
             );

initial begin
    MRCC_25P6M = 0;
    CAT_SYNC0 = 0;
    rst = 1;
    #20000;
    rst = 0;
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = ~MRCC_25P6M;
    #19.531 MRCC_25P6M = ~MRCC_25P6M;
    #19.531 MRCC_25P6M = ~MRCC_25P6M;
    #19.532 MRCC_25P6M = ~MRCC_25P6M;
end

always begin
    #(SIMULATION_FREQ/CAT_SYNC0_FREQ - CAT_SYNC0_PULSE_WIDTH)  CAT_SYNC0 = 1;
    #(CAT_SYNC0_PULSE_WIDTH) CAT_SYNC0 = 0;
end

always @(posedge MRCC_25P6M) begin
    sync0 <= {sync0[1:0], CAT_SYNC0};
end

endmodule
