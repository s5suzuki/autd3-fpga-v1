`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/23/2020 03:23:32 PM
// Design Name:
// Module Name: sim_ref_clk_sync
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


module sim_ref_clk_sync();

parameter SIMULATION_FREQ = 1000 * 1000 * 1000;
parameter SYSTEM_CLOCK_FREQ = 25.6 * 1000 * 1000;

parameter SYSTEM_CLOCK_CNT = SIMULATION_FREQ/SYSTEM_CLOCK_FREQ;

parameter CAT_SYNC0_PULSE_WIDTH = 800;
parameter CAT_SYNC0_FREQ = 1000;

parameter int REF_CLK_FREQ = 40000;
parameter int REF_CLK_CYCLE = 1;
localparam int SYNC_CYCLE_CNT = REF_CLK_FREQ / CAT_SYNC0_FREQ; // 40
localparam int REF_CLK_DIVIDER_CNT = SYSTEM_CLOCK_FREQ / REF_CLK_FREQ; // 640
localparam int REF_CLK_CYCLE_CNT = REF_CLK_CYCLE * REF_CLK_FREQ; // 40000
localparam int REF_CLK_DIVIDER_CNT_WIDTH = $clog2(REF_CLK_DIVIDER_CNT);
localparam int LAP_CYCLE_CNT = REF_CLK_CYCLE_CNT / SYNC_CYCLE_CNT; // 1000
localparam int LAP_CYCLE_CNT_WIDTH = $clog2(LAP_CYCLE_CNT);
localparam int REF_CLK_CYCLE_CNT_WIDTH = $clog2(REF_CLK_CYCLE_CNT);

reg CAT_SYNC0;

reg sys_clk, rst;
reg [2:0] sync0;

reg ref_clk_init;
wire ref_clk_done;
wire [REF_CLK_CYCLE_CNT_WIDTH-1:0] ref_clk;

ref_clk_synchronizer ref_clk_synchronizer(
        .SYS_CLK(sys_clk),
        .RST(rst),
        .SYNC(sync0 == 3'b011),
        .REF_CLK_INIT(ref_clk_init),
        .REF_CLK_INIT_DONE_OUT(ref_clk_done),
        .REF_CLK_CNT_OUT(ref_clk),
        .LAP_CNT_OUT()
);

initial begin
    sys_clk = 0;
    sync0 = 0;
    CAT_SYNC0 = 0;
    rst = 1;
    #20000;
    rst = 0;
    @(negedge CAT_SYNC0);
    #920000;
    ref_clk_init = 1;
    #50000;
    ref_clk_init = 0;
end

always
    #(SYSTEM_CLOCK_CNT/2) sys_clk = ~sys_clk;

always begin
    #(SIMULATION_FREQ/CAT_SYNC0_FREQ - CAT_SYNC0_PULSE_WIDTH)  CAT_SYNC0 = 1;
    #(CAT_SYNC0_PULSE_WIDTH) CAT_SYNC0 = 0;
end

always @(posedge sys_clk) begin
    sync0 <= {sync0[1:0], CAT_SYNC0};
end

endmodule
