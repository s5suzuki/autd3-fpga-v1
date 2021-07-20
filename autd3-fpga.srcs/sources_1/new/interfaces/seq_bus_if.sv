/*
 * File: seq_bus_if.sv
 * Project: interfaces
 * Created Date: 13/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 20/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

interface seq_bus_if();

logic [15:0] IDX;
logic [63:0] DATA_OUT;

modport master_port(input IDX, output DATA_OUT);
modport slave_port(output IDX, input DATA_OUT);

endinterface
