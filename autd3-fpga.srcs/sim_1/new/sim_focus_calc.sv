`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/05/2020 04:49:54 PM
// Design Name:
// Module Name: sim_focus_calc
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


module sim_focus_calc();

reg MRCC_25P6M;
reg trig;
reg [23:0] focus_x, focus_y, focus_z;
reg [23:0] trans_x, trans_y, trans_z;
wire [7:0] phase;

focus_calculator focus_calculator(
                     .SYS_CLK(MRCC_25P6M),
                     .DVALID_IN(trig),
                     .FOCUS_X(focus_x),
                     .FOCUS_Y(focus_y),
                     .FOCUS_Z(focus_z),
                     .TRANS_X(trans_x),
                     .TRANS_Y(trans_y),
                     .TRANS_Z(trans_z),
                     .PHASE(phase)
                 );

initial begin
    MRCC_25P6M = 0;
    focus_x = 10;
    focus_y = 20;
    focus_z = 30;
    trans_x = 0;
    trans_y = 0;
    trans_z = 0;
    trig = 0;

    #(10);
    @(posedge MRCC_25P6M);
    trans_x = 0;
    trans_y = 0;
    trans_z = 0;
    trig = 1;
    @(posedge MRCC_25P6M);
    trans_x = 10;
    trans_y = 0;
    trans_z = 0;
    @(posedge MRCC_25P6M);
    trig = 0;
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

endmodule
