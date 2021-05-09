/*
 * File: config_bus_if.sv
 * Project: interfaces
 * Created Date: 09/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 09/05/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

interface config_bus_if();

logic WE;
logic [8:0] IDX;
logic [15:0] DATA_IN;
logic [15:0] DATA_OUT;

modport master_port(input WE, input IDX, input DATA_IN, output DATA_OUT);
modport slave_port(output WE, output IDX, output DATA_IN, input DATA_OUT);

endinterface
