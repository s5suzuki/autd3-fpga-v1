/*
 * File: lm_synchronizer.sv
 * Project: new
 * Created Date: 18/06/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`include "consts.vh"

module lm_synchronizer(
           input var SYS_CLK,
           input var RST,
           input var SYNC,

           input var REF_CLK_TICK,

           input var LM_CLK_INIT,
           input var [`LM_CLK_MAX_WIDTH-1:0] LM_CLK_CYCLE,
           input var [`LM_LAP_CYCLE_CNT_WIDTH-1:0] LAP,
           output var [`LM_LAP_CYCLE_CNT_WIDTH:0] LM_INIT_LAP_OUT,
           input var LM_CLK_CALIB,
           input var [`LM_CLK_MAX_WIDTH-1:0] LM_CLK_CALIB_SHIFT,
           output var LM_CLK_CALIB_DONE_OUT,

           output var [`LM_CLK_MAX_WIDTH-1:0] LM_CLK_OUT
       );

logic lm_clk_init_flag = 0;
logic lm_clk_calib_flag = 0;
logic [`LM_CLK_MAX_WIDTH-1:0] lm_cnt = 0;
logic [`LM_CLK_MAX_WIDTH-1:0] lm_cnt_cycle = 0;
logic [`LM_CLK_MAX_WIDTH-1:0] lm_cnt_shift = 0;
logic lm_shift_done = 0;

logic [`LM_LAP_CYCLE_CNT_WIDTH:0] lm_clk_init_lap = 0;

assign LM_CLK_OUT = lm_cnt;
assign LM_INIT_LAP_OUT = lm_clk_init_lap;
assign LM_CLK_CALIB_DONE_OUT = lm_shift_done;

initial begin
    lm_clk_init_flag = 0;
    lm_clk_calib_flag = 0;

    lm_cnt = 0;
    lm_cnt_shift = 0;
    lm_cnt_cycle = 0;
    lm_shift_done = 0;
end

always_ff @(posedge SYS_CLK) begin
    if(RST) begin
        lm_clk_init_flag <= 0;
        lm_cnt_cycle <= 0;
    end
    else if(LM_CLK_INIT) begin
        lm_clk_init_flag <= 1;
        lm_cnt_cycle <= LM_CLK_CYCLE - 1;
    end
    else if(lm_clk_init_lap[`LM_LAP_CYCLE_CNT_WIDTH]) begin
        lm_clk_init_flag <= 0;
    end
end

always_ff @(posedge SYS_CLK) begin
    if(RST) begin
        lm_cnt <= 0;
        lm_shift_done <= 0;
        lm_clk_init_lap <= 0;
    end
    else begin
        if(SYNC & lm_clk_init_flag) begin
            lm_cnt <= 0;
            lm_clk_init_lap <= {1'b1, LAP};
        end
        else begin
            lm_clk_init_lap <= 0;
            if(lm_cnt_shift != 0) begin
                if(REF_CLK_TICK) begin
                    lm_cnt <= ({1'd0, lm_cnt} + 1 + `SYNC_CYCLE_CNT) % (lm_cnt_cycle + 1);
                end
                else begin
                    lm_cnt <= ({1'd0, lm_cnt} + `SYNC_CYCLE_CNT) % (lm_cnt_cycle + 1);
                end
                lm_cnt_shift <= lm_cnt_shift - 1;
                lm_shift_done <= lm_cnt_shift == 1 ? 1 : 0;
            end
            else begin
                if(LM_CLK_CALIB) begin
                    lm_cnt_shift <= LM_CLK_CALIB_SHIFT;
                end
                if(REF_CLK_TICK) begin
                    lm_cnt <= lm_cnt == lm_cnt_cycle ? 0 : lm_cnt + 1;
                end
                lm_shift_done <= 0;
            end
        end
    end
end

endmodule
