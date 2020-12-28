`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/23/2020 05:16:11 PM
// Design Name:
// Module Name: sim_op_sel
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


module sim_op_sel();

localparam TRANS_NUM = 2;

logic MRCC_25P6M;
logic op_mode;
logic [9:0] time_cnt;
logic [15:0] stm_idx, stm_div;

logic [7:0] duty[0:TRANS_NUM-1];
logic [7:0] phase[0:TRANS_NUM-1];
logic [7:0] delay[0:TRANS_NUM-1];

// CPU
parameter TCO = 10; // bus delay 10ns
logic[15:0]bram_addr;
logic [16:0] CPU_ADDR;
assign CPU_ADDR = {bram_addr, 1'b1};
logic [15:0] CPU_DATA;
logic CPU_CKIO;
logic CPU_CS1_N;
logic CPU_WE0_N;
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

operator_selector#(.TRANS_NUM(TRANS_NUM))
                 operator_selector(
                     .NORMAL_OP_BUS(normal_op_bus.master_port),
                     .STM_OP_BUS(stm_op_bus.master_port),

                     .SYS_CLK(MRCC_25P6M),
                     .op_mode(op_mode),
                     .TIME(time_cnt),

                     .STM_IDX(stm_idx),
                     .STM_CLK_DIV(stm_div),

                     .DUTY(duty),
                     .PHASE(phase),
                     .DELAY(delay)
                 );

task bram_write (input [1:0] select, input [13:0] addr, input [15:0] data_in);
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

task focus_write(input [15:0] idx, input signed [23:0] x, input signed [23:0] y, input signed [23:0] z, input [7:0] amp);
    bram_write(2'd3, idx * 8, x[15:0]);
    bram_write(2'd3, idx * 8 + 1, {y[7:0], x[23:16]});
    bram_write(2'd3, idx * 8 + 2, y[23:8]);
    bram_write(2'd3, idx * 8 + 3, z[15:0]);
    bram_write(2'd3, idx * 8 + 4, {amp, z[23:16]});
endtask

initial begin
    MRCC_25P6M = 1;
    CPU_CKIO = 1;
    CPU_CS1_N = 0;
    CPU_WE0_N = 1;
    CPU_DATA_READ = 0;
    bus_data_reg = 16'bz;
    bram_addr = #(TCO) 16'd0;

    op_mode = 1;
    time_cnt = 0;
    stm_div = 1;
    stm_idx = 0;

    #(1000);

    focus_write(0, 24'sd0, 24'sd0, 24'sd0, 8'haa);
    focus_write(1, 24'sd10, 24'sd10, 24'sd0, 8'hbb);
    focus_write(2, 24'sd10, 24'sd10, 24'sd10, 8'hcc);
    focus_write(3, 24'sd100, 24'sd10, 24'sd10, 8'hdd);

    #(10);
    stm_idx = 1;
    repeat (640) @(posedge MRCC_25P6M);
    stm_idx = 2;
    repeat (640) @(posedge MRCC_25P6M);
    stm_idx = 3;
    repeat (640) @(posedge MRCC_25P6M);
    stm_idx = 0;
    repeat (640) @(posedge MRCC_25P6M);
    stm_idx = 1;
    repeat (640) @(posedge MRCC_25P6M);
    stm_idx = 2;
    repeat (640) @(posedge MRCC_25P6M);
    stm_idx = 3;
    repeat (640) @(posedge MRCC_25P6M);
    stm_idx = 0;
    repeat (640) @(posedge MRCC_25P6M);
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
    time_cnt = (time_cnt == 10'd639) ? 0 : time_cnt + 1;
end

endmodule
