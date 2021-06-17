/*
 * File: delayed_fifo.sv
 * Project: transducer
 * Created Date: 18/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/06/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module delayed_fifo#(
           parameter int DEPTH = 8
       )(
           input var CLK,
           input var UPDATE,
           input var [DEPTH-1:0] DELAY,
           input var [15:0] DATA_IN,
           output var [15:0] DATA_OUT
       );

logic [DEPTH-1:0] a = 0;

dist_mem_delay mem(
                   .a(a),
                   .d(DATA_IN),
                   .clk(CLK),
                   .we(UPDATE),
                   .spo(DATA_OUT)
               );

always_ff @(posedge CLK) begin
    if(UPDATE) begin
        a <= (a < DELAY) ? a + 1 : 0;
    end
end

endmodule
