`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/05/13 14:59:05
// Design Name:
// Module Name: sim_div
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


module sim_div();

logic MRCC_25P6M;
logic RST;

logic [15:0] div;
logic div_tvalid;

logic [23:0] dout;
logic [15:0] _unused;
logic dout_tvalid;

div_22_by_16 div_22_by_16(
                 .s_axis_dividend_tdata(22'd2590800),
                 .s_axis_dividend_tvalid(1'b1),
                 .s_axis_divisor_tdata(div),
                 .s_axis_divisor_tvalid(div_tvalid),
                 .aclk(sys_clk),
                 .m_axis_dout_tdata({dout, _unused}),
                 .m_axis_dout_tvalid(dout_tvalid)
             );

ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen(
                           .clk_in1(MRCC_25P6M),
                           .reset(RST),
                           .clk_out1(sys_clk),
                           .clk_out2()
                       );

initial begin
    MRCC_25P6M = 0;
    RST = 1;
    div = 0;
    div_tvalid = 0;
    #10000;
    RST = 0;
    @(posedge sys_clk);

    #10000;
    div = 10;
    div_tvalid  = 1;
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

endmodule
