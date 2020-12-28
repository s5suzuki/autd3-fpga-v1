/*
 * File: normal_op_bus_if.sv
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

interface normal_op_bus_if();

logic [8:0] ADDR;
logic [15:0] DATA;

modport master_port(output ADDR, input DATA);
modport slave_port(input ADDR, output DATA);

endinterface
