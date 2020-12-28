/*
 * File: mod_bus_if.sv
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

interface mod_bus_if#(
              parameter MOD_BUF_SIZE = 32000
          )();

localparam MOD_BUF_IDX_WIDTH = $clog2(MOD_BUF_SIZE);

logic [7:0] MOD;
logic [MOD_BUF_IDX_WIDTH-1:0] MOD_IDX;

modport master_port(output MOD_IDX, input MOD);
modport slave_port(input MOD_IDX, output MOD);

endinterface
