/*
 * File: stm_synchronizer.sv
 * Project: new
 * Created Date: 18/06/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 06/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

module stm_synchronizer#(
           parameter STM_CLK_MAX = 40000,
           parameter SYNC_CYCLE_CNT = 40,
           localparam STM_CLK_MAX_WIDTH = $clog2(STM_CLK_MAX)
       )(
           input var SYS_CLK,
           input var RST,
           input var SYNC,

           input var REF_CLK_TICK,

           input var STM_CLK_INIT,
           input var [STM_CLK_MAX_WIDTH-1:0] STM_CLK_CYCLE,
           input var [9:0] LAP,
           output var [10:0] STM_INIT_LAP_OUT,
           input var STM_CLK_CALIB,
           input var [STM_CLK_MAX_WIDTH-1:0] STM_CLK_CALIB_SHIFT,
           output var STM_CLK_CALIB_DONE_OUT,

           output var [STM_CLK_MAX_WIDTH-1:0] STM_CLK_OUT
       );

logic stm_clk_init_flag;
logic [STM_CLK_MAX_WIDTH-1:0] stm_cnt;
logic [STM_CLK_MAX_WIDTH-1:0] stm_cnt_cycle;
logic [STM_CLK_MAX_WIDTH-1:0] stm_cnt_shift;
logic stm_shift_done;

logic [10:0] stm_clk_init_lap;

assign STM_CLK_OUT = stm_cnt;
assign STM_INIT_LAP_OUT = stm_clk_init_lap;
assign STM_CLK_CALIB_DONE_OUT = stm_shift_done;

always_ff @(posedge SYS_CLK) begin
    if(RST) begin
        stm_clk_init_flag <= 0;
        stm_cnt_cycle <= 0;
    end
    else if(STM_CLK_INIT) begin
        stm_clk_init_flag <= 1;
        stm_cnt_cycle <= STM_CLK_CYCLE - 1;
    end
    else if(stm_clk_init_lap[10]) begin
        stm_clk_init_flag <= 0;
    end
end

always_ff @(posedge SYS_CLK) begin
    if(RST) begin
        stm_cnt <= 0;
        stm_shift_done <= 0;
        stm_clk_init_lap <= 0;
        stm_cnt_shift <= 0;
    end
    else begin
        if(SYNC & stm_clk_init_flag) begin
            stm_cnt <= 0;
            stm_clk_init_lap <= {1'b1, LAP};
        end
        else begin
            stm_clk_init_lap <= 0;
            if(stm_cnt_shift != 0) begin
                if(REF_CLK_TICK) begin
                    stm_cnt <= ({1'd0, stm_cnt} + 1 + SYNC_CYCLE_CNT) % (stm_cnt_cycle + 1);
                end
                else begin
                    stm_cnt <= ({1'd0, stm_cnt} + SYNC_CYCLE_CNT) % (stm_cnt_cycle + 1);
                end
                stm_cnt_shift <= stm_cnt_shift - 1;
                stm_shift_done <= stm_cnt_shift == 1 ? 1 : 0;
            end
            else begin
                if(STM_CLK_CALIB) begin
                    stm_cnt_shift <= STM_CLK_CALIB_SHIFT;
                end
                if(REF_CLK_TICK) begin
                    stm_cnt <= stm_cnt == stm_cnt_cycle ? 0 : stm_cnt + 1;
                end
                stm_shift_done <= 0;
            end
        end
    end
end

endmodule
