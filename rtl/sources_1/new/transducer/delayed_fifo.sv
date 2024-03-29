/*
 * File: delayed_fifo.sv
 * Project: transducer
 * Created Date: 18/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/12/2021
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
           input var [6:0] DELAY,
           input var [15:0] DATA_IN,
           output var [15:0] DATA_OUT
       );

logic [6:0] a = '0;
logic delay_rst = '0;

dist_mem_delay mem(
                   .*,
                   .d(DATA_IN),
                   .clk(CLK),
                   .we(UPDATE),
                   .spo(DATA_OUT)
               );

always_ff @(posedge CLK) begin
    if (UPDATE) begin
        delay_rst <= RST;
        a <= ((DELAY <= a) | (delay_rst^RST)) ? '0 : a + 1'b1;
    end
end

endmodule
