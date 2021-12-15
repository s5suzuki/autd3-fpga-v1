/*
 * File: seq_sync_if.sv
 * Project: interfaces
 * Created Date: 26/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 28/09/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

interface seq_sync_if();

logic [15:0] SEQ_CLK_CYCLE;
logic [15:0] SEQ_CLK_DIV;
logic [63:0] SEQ_CLK_SYNC_TIME_NS;
logic REF_CLK_TICK;
logic SEQ_CLK_INIT;
logic SYNC;
logic [15:0] WAVELENGTH_UM;
logic OP_MODE;
logic SEQ_MODE;

modport master_port(output SEQ_CLK_CYCLE, output SEQ_CLK_DIV, output SEQ_CLK_SYNC_TIME_NS, output SEQ_CLK_INIT, output WAVELENGTH_UM, output OP_MODE, output SEQ_MODE);
modport slave_port(input SEQ_CLK_CYCLE, input SEQ_CLK_DIV, input SEQ_CLK_SYNC_TIME_NS, input SEQ_CLK_INIT, input WAVELENGTH_UM, input OP_MODE, input SEQ_MODE, input REF_CLK_TICK, input SYNC);

endinterface
