`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/21/2020 02:41:59 PM
// Design Name:
// Module Name: sim_global_config
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module sim_global_config();

logic MRCC_25P6M;

logic [7:0] ref_clk_cycle_shift;
logic ref_clk_init;
logic ref_clk_init_done;
logic stm_clk_init;
logic [15:0] stm_clk_cycle;
logic [15:0] stm_div;
logic [10:0] stm_clk_init_lap;
logic stm_clk_calib;
logic [15:0] stm_clk_calib_shift;
logic stm_clk_calib_done;
logic [7:0] mod_idx_shift;

logic soft_rst;
logic force_fan;
logic silent;
logic op_mode;

// CPU
parameter TCO = 10; // bus delay 10ns
logic[15:0]bram_addr;
logic [16:0] CPU_ADDR;
assign CPU_ADDR = {bram_addr, 1'b1};
logic [15:0] CPU_DATA;
logic CPU_CKIO;
logic CPU_CS1_N;
logic CPU_WE0_N;
logic MRCC_25P6M;
logic [15:0] CPU_DATA_READ;
logic [15:0] bus_data_reg = 16'bz;
assign CPU_DATA = bus_data_reg;

cpu_bus_if cpu_bus();
assign cpu_bus.BUS_CLK = CPU_CKIO;
assign cpu_bus.EN = ~CPU_CS1_N;
assign cpu_bus.WE = ~CPU_WE0_N;
assign cpu_bus.BRAM_SELECT = CPU_ADDR[16:15];
assign cpu_bus.BRAM_ADDR = CPU_ADDR[14:1];
assign cpu_bus.DATA_IN = CPU_DATA;
assign cpu_data_out = cpu_bus.DATA_OUT;

config_bus_if config_bus();
mod_bus_if mod_bus();
normal_op_bus_if normal_op_bus();
stm_op_bus_if stm_op_bus();

bram_controller bram_controller(
                    .CPU_BUS(cpu_bus.slave_port),

                    .SYS_CLK(MRCC_25P6M),
                    .CONFIG_BUS(config_bus.slave_port),
                    .MOD_BUS(mod_bus.slave_port),
                    .NORMAL_OP_BUS(normal_op_bus.slave_port),
                    .STM_OP_BUS(stm_op_bus.slave_port)
                );

global_config global_config(
                  .CONFIG_BUS(config_bus.master_port),

                  .SYS_CLK(MRCC_25P6M),
                  .SOFT_RST_OUT(soft_rst),

                  .REF_CLK_CYCLE_SHIFT(ref_clk_cycle_shift),
                  .REF_CLK_INIT_OUT(ref_clk_init),
                  .REF_CLK_INIT_DONE(ref_clk_init_done),
                  .STM_CLK_INIT_OUT(stm_clk_init),
                  .STM_CLK_CYCLE(stm_clk_cycle),
                  .STM_CLK_DIV(stm_div),
                  .STM_LAP(stm_clk_init_lap),
                  .STM_CLK_CALIB_OUT(stm_clk_calib),
                  .STM_CLK_CALIB_SHIFT(stm_clk_calib_shift),
                  .STM_CLK_CALIB_DONE(stm_clk_calib_done),
                  .MOD_IDX_SHIFT(mod_idx_shift),

                  .SILENT_MODE(silent),
                  .FORCE_FAN(force_fan),
                  .OP_MODE(op_mode)
              );

task bram_write (input [13:0] addr, input [15:0] data_in);
    repeat (20) @(posedge CPU_CKIO);
    bram_addr <= #(TCO) {2'b00, addr};
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
    MRCC_25P6M = 1;
    CPU_CKIO = 1;
    CPU_CS1_N = 0;
    CPU_WE0_N = 1;
    CPU_DATA_READ = 0;
    bus_data_reg = 16'bz;
    bram_addr = #(TCO) 16'd0;

    #(1000);
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

endmodule
