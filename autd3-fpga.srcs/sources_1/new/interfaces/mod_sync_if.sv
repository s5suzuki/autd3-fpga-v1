/*
 * File: mod_sync_if.sv
 * Project: interfaces
 * Created Date: 26/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 26/07/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

interface mod_sync_if();

logic [15:0] MOD_CLK_CYCLE;
logic [15:0] MOD_CLK_DIV;
logic [63:0] MOD_CLK_SYNC_TIME_NS;
logic REF_CLK_TICK;
logic MOD_CLK_INIT;
logic SYNC;

modport master_port(output MOD_CLK_CYCLE, output MOD_CLK_DIV, output MOD_CLK_SYNC_TIME_NS, output MOD_CLK_INIT);
modport slave_port(input MOD_CLK_CYCLE, input MOD_CLK_DIV, input MOD_CLK_SYNC_TIME_NS, input MOD_CLK_INIT, input REF_CLK_TICK, input SYNC);

endinterface
