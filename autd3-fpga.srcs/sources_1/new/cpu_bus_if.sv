/*
 * File: cpu_bus_if.sv
 * Project: new
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 16/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

interface cpu_bus_if();

logic BUS_CLK;
logic EN;
logic WE;
logic [1:0] BRAM_SELECT;
logic [13:0] BRAM_ADDR;
logic [15:0] DATA_IN;

modport slave_port(input BUS_CLK, input EN, input WE, input BRAM_SELECT, input BRAM_ADDR, input DATA_IN);

endinterface
