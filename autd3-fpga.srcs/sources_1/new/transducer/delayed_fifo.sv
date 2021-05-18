/*
 * File: delayed_fifo.sv
 * Project: transducer
 * Created Date: 18/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 18/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */


`timescale 1ns / 1ps
module delayed_fifo(
           input var CLK,
           input var RST,
           input var UPDATE,
           input var [7:0] DELAY,
           input var [15:0] DATA_IN,
           output var [15:0] DATA_OUT
       );

logic [15:0] mem[0:255];
logic [7:0] ptr;

assign DATA_OUT = (DELAY == 8'd0) ? DATA_IN : mem[ptr];

always_ff @(posedge CLK) begin
    if (RST) begin
        ptr <= 0;
    end
    else if(UPDATE) begin
        mem[ptr] <= DATA_IN;
        ptr <= ({1'b0, ptr} + 9'd1 < {1'b0, DELAY}) ? ptr + 1 : 0;
    end
end

endmodule
