/*
 * File: config_bus_if.sv
 * Project: memory
 * Created Date: 17/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

interface config_bus_if();

logic WE;
logic [7:0] ADDR;
logic [15:0] DATA_IN;
logic [15:0] DATA_OUT;

modport master_port(output WE, output ADDR, output DATA_IN, input DATA_OUT);
modport slave_port(input WE, input ADDR, input DATA_IN, output DATA_OUT);

endinterface
