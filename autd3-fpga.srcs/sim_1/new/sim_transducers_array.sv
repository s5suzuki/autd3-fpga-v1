`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/20/2020 05:51:44 PM
// Design Name:
// Module Name: sim_transducers_array
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


module sim_transducers_array();

logic MRCC_25P6M;

logic [9:0] time_cnt;
logic [7:0] DUTY [0:1];
logic [7:0] PHASE [0:1];
logic [7:0] DELAY [0:1];
logic [7:0] MOD;
logic [252:1] XDCR_OUT;

transducers_array#(.TRANS_NUM(2))
                 transducers_array(
                     .TIME(time_cnt),
                     .DUTY,
                     .PHASE,
                     .DELAY,
                     .MOD,
                     .SILENT(1'b0),
                     .XDCR_OUT
                 );

assign tr1 = XDCR_OUT[1];
assign tr2 = XDCR_OUT[2];

initial begin
    MRCC_25P6M = 0;
    time_cnt = 0;
    DUTY = {8'hFF, 8'h80};
    PHASE = {8'h00, 8'h00};
    DELAY = {8'h00, 8'h0F};
    MOD = 8'hFF;
end

// main clock 25.6MHz
always @(posedge MRCC_25P6M) begin
    time_cnt = (time_cnt == 10'd639) ? 0 : time_cnt + 1;
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

endmodule
