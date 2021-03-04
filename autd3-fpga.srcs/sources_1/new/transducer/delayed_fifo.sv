/*
 * File: delayed_fifo.sv
 * Project: new
 * Created Date: 16/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 04/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module delayed_fifo#(
           parameter WIDTH = 8,
           parameter DEPTH_RADIX = 7
       )(
           input var CLK,
           input var UPDATE,
           input var [7:0] DELAY,
           input var [2*WIDTH-1:0] DATA_IN,
           output var [2*WIDTH-1:0] DATA_OUT
       );

localparam DEPTH = 1 << DEPTH_RADIX;

logic [2*WIDTH-1:0] mem[0:DEPTH-1] = '{DEPTH{0}};
logic [DEPTH_RADIX:0] ptr = 0;
logic [2*WIDTH-1:0] data_out = 0;
logic [DEPTH_RADIX:0] delay = 0;

assign DATA_OUT = (DELAY == 8'd0) ? DATA_IN : data_out;

always_ff @(posedge CLK) begin
    if (UPDATE) begin
        mem[ptr] <= DATA_IN;
        delay <= DELAY;
        ptr <= (ptr + 1 < delay) ? ptr + 1 : 0;
    end
end

always_comb begin
    data_out = mem[ptr];
end

endmodule
