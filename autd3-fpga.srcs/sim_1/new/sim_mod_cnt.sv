`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06/26/2020 03:15:11 PM
// Design Name:
// Module Name: sim_mod_cnt
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

module sim_mod_cnt();

parameter TCO = 10; // bus delay 10ns

logic[15:0]bram_addr;

logic [16:0] CPU_ADDR;
assign CPU_ADDR = {bram_addr, 1'b1};
logic [15:0] CPU_DATA;
logic CPU_CKIO;
logic CPU_CS1_N;
logic CPU_WE0_N;
logic MRCC_25P6M;

logic [14:0] mod_idx;
logic [7:0] mod;
logic [31:0] mod_update_cnt;

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

mod_controller#(.MOD_BUF_SIZE(32000))
              mod_controller(
                  .MOD_BUS(mod_bus.master_port),
                  .MOD_IDX(mod_idx),
                  .MOD_OUT(mod)
              );

task bram_write (input [13:0] addr, input [15:0] data_in);
    repeat (20) @(posedge CPU_CKIO);
    bram_addr <= #(TCO) {2'b01, addr};
    CPU_CS1_N <= #(TCO) 0;
    bus_data_reg <= #(TCO) data_in;
    @(posedge CPU_CKIO);
    @(negedge CPU_CKIO);

    CPU_WE0_N <= #(TCO) 0;
    repeat (10) @(posedge CPU_CKIO);

    @(negedge CPU_CKIO);
    CPU_WE0_N <= #(TCO) 1;
endtask

logic [7:0] tmp = 0;
task mod_init;
    begin
        for (integer i = 0; i < 250; i=i+1) begin
            tmp = 2*i;
            bram_write(i, {tmp+1, tmp});
        end
        for (integer i = 0; i < 250; i=i+1) begin
            tmp = 2*i;
            bram_write(i, {tmp+1, tmp});
        end
    end
endtask

initial begin
    MRCC_25P6M = 1;
    CPU_CKIO = 1;
    CPU_CS1_N = 0;
    CPU_WE0_N = 1;
    CPU_DATA_READ = 0;
    bus_data_reg = 16'bz;
    bram_addr = #(TCO) 16'd0;
    mod_idx = 0;
    mod_update_cnt = 0;

    #(1000);
    mod_init();
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

always
    #6.65 CPU_CKIO = ~CPU_CKIO; // bus clock 75MHz

always @(posedge MRCC_25P6M) begin
    if (mod_update_cnt == 32'd6399) begin// 4kHz
        mod_update_cnt = 0;
        mod_idx = (mod_idx == 15'd3999) ? 0 : mod_idx + 1;
    end
    else begin
        mod_update_cnt = mod_update_cnt + 1;
    end
end

endmodule
