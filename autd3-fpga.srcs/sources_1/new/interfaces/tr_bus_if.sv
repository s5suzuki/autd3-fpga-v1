/*
 * File: tr_bus_if.sv
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

interface tr_bus_if();

logic [7:0] IDX;
logic [15:0] DATA_OUT;

modport master_port(input IDX, output DATA_OUT);
modport slave_port(output IDX, input DATA_OUT);

endinterface
