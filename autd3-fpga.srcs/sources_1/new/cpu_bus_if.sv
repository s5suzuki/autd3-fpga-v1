/*
 * File: cpu_bus_if.sv
 * Project: new
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 15/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

interface cpu_cbus_if(
              input var [16:0] CPU_ADDR,
              input var [15:0] CPU_DATA,
              input var CPU_CKIO,
              input var CPU_CS1_N,
              input var CPU_WE0_N
          );
logic BUS_CLK = CPU_CKIO;
logic EN = ~CPU_CS1_N;
logic WE = ~CPU_WE0_N;
logic [1:0] BRAM_SELECT = CPU_ADDR[16:15];
logic [13:0] BRAM_ADDR = CPU_ADDR[14:1];
logic[15:0] DATA_IN = CPU_DATA;

modport slave_port(input BUS_CLK, input EN, input WE, input BRAM_SELECT, input BRAM_ADDR,input  DATA_IN);

endinterface
