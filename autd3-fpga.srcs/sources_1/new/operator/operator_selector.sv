/*
 * File: operator_selector.sv
 * Project: operator
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 05/03/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps

module operator_selector#(
           parameter TRANS_NUM = 249
       )(
           normal_op_bus_if.master_port NORMAL_OP_BUS,
           stm_op_bus_if.master_port STM_OP_BUS,

           input var SYS_CLK,
           input var [9:0] TIME,
           input var op_mode,

           input var [15:0] STM_IDX,
           input var [15:0] STM_CLK_DIV,

           output var [7:0] DUTY[0:TRANS_NUM-1],
           output var [7:0] PHASE[0:TRANS_NUM-1]
       );

logic [7:0] normal_duty[0:TRANS_NUM-1];
logic [7:0] normal_phase[0:TRANS_NUM-1];

logic [7:0] stm_duty[0:TRANS_NUM-1];
logic [7:0] stm_phase[0:TRANS_NUM-1];

assign DUTY = op_mode ? stm_duty : normal_duty;
assign PHASE = op_mode ? stm_phase : normal_phase;

normal_operator#(.TRANS_NUM(TRANS_NUM))
               normal_operator(
                   .NORMAL_OP_BUS(NORMAL_OP_BUS),

                   .SYS_CLK(SYS_CLK),
                   .TIME(TIME),
                   .DUTY(normal_duty),
                   .PHASE(normal_phase)
               );

stm_operator#(.TRANS_NUM(TRANS_NUM))
            stm_operator(
                .STM_OP_BUS(STM_OP_BUS),

                .STM_IDX(STM_IDX),
                .STM_CLK_DIV(STM_CLK_DIV),

                .SYS_CLK(SYS_CLK),
                .DUTY(stm_duty),
                .PHASE(stm_phase)
            );

endmodule
