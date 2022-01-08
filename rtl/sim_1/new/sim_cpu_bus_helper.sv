/*
 * File: sim_cpu_bus_helper.sv
 * Project: new
 * Created Date: 08/01/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 08/01/2022
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022 Hapis Lab. All rights reserved.
 * 
 */


module sim_cpu_bus();

parameter TCO = 10; // bus delay 10ns
bit [15:0] bram_addr;
bit [16:0] CPU_ADDR;
assign CPU_ADDR = {bram_addr, 1'b1};
logic [15:0] CPU_DATA;
bit CPU_CKIO;
bit CPU_CS1_N;
bit CPU_WE0_N;
bit [15:0] CPU_DATA_READ;
logic [15:0] bus_data_reg = 16'bz;
assign CPU_DATA = bus_data_reg;

cpu_bus_if cpu_bus();
assign cpu_bus.BUS_CLK = CPU_CKIO;
assign cpu_bus.EN = ~CPU_CS1_N;
assign cpu_bus.WE = ~CPU_WE0_N;
assign cpu_bus.BRAM_SELECT = CPU_ADDR[16:15];
assign cpu_bus.BRAM_ADDR = CPU_ADDR[14:1];
assign cpu_bus.DATA_IN = CPU_DATA;

task bram_write(input [1:0] select, input [13:0] addr, input [15:0] data_in);
    repeat (20) @(posedge CPU_CKIO);
    bram_addr <= #(TCO) {select, addr};
    CPU_CS1_N <= #(TCO) 0;
    bus_data_reg <= #(TCO) data_in;
    @(posedge CPU_CKIO);
    @(negedge CPU_CKIO);

    CPU_WE0_N <= #(TCO) 0;
    repeat (10) @(posedge CPU_CKIO);

    @(negedge CPU_CKIO);
    CPU_WE0_N <= #(TCO) 1;
endtask

initial begin
    CPU_CKIO = 0;
    CPU_CS1_N = 1;
    CPU_WE0_N = 1;
    bram_addr = 0;
end

// bus clock 75MHz
always
    #6.65 CPU_CKIO = ~CPU_CKIO;

endmodule
