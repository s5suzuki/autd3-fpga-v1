`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2019/10/29 10:44:59
// Design Name:
// Module Name: sim_main
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


module sim_main();

parameter SIMULATION_FREQ = 1000 * 1000 * 1000;

parameter SYSTEM_CLOCK_FREQ = 25.6 * 1000 * 1000;
parameter CPU_BUS_CLOCK_FREQ = 75.0 * 1000 * 1000;

parameter SYSTEM_CLOCK_CNT = SIMULATION_FREQ/SYSTEM_CLOCK_FREQ;
parameter CPU_BUS_CLOCK_CNT = SIMULATION_FREQ/CPU_BUS_CLOCK_FREQ;

parameter CAT_SYNC0_PULSE_WIDTH = 800;
parameter CAT_SYNC0_1S_FREQ = 1;
parameter CAT_SYNC0_1MS_FREQ = 1000;

parameter DELAY_1S = 1000 * 1000 * 1000;

parameter TCO = 10; // bus delay 10ns

parameter MOD_BUF_ADDR_BASE = 12'd256;
parameter CTRL_FLAG_ADDR = 12'd2256;
parameter MOD_IDX_BASE_ADDR = 12'd2257;
parameter MOD_IDX_BASE_SHIFT_ADDR = 12'd2258;

reg [16:0] CPU_ADDR;
wire [15:0] CPU_DATA;
wire [252:1] XDCR_OUT;
reg CPU_CKIO;
reg CPU_CS1_N;
reg RESET_N;
reg CPU_WE0_N;
reg CPU_WE1_N;
reg CPU_RD_N;
reg CPU_RDWR;

reg CAT_SYNC0_1ms;
reg CAT_SYNC0_1s;

reg sys_clk;
wire [11:0] mod_idx;
reg sync0_sel;
wire sync0 = sync0_sel == 0 ? CAT_SYNC0_1ms: CAT_SYNC0_1s;

main main(
         .MRCC_25P6M(sys_clk),
         .CAT_SYNC0(sync0),
         .FORCE_FAN(),
         .THERMO(),
         .GPIO_IN(),
         .GPIO_OUT(),

         .*
     );

reg [15:0]bus_data_reg;
assign CPU_DATA = bus_data_reg;

task initilalize;
    begin
        sys_clk = 1;
        CPU_CKIO = 1;
        CAT_SYNC0_1ms = 1;
        CAT_SYNC0_1s = 1;
        CPU_CS1_N = 1;
        CPU_RD_N = 1;
        CPU_WE0_N = 1;
        CPU_WE1_N = 1;
        CPU_RDWR = 1;
        sync0_sel = 0;
        bus_data_reg = #(TCO) 16'hzzzz;
        CPU_ADDR = #(TCO) 17'd0;
        RESET_N = 0;
        repeat (2) @(posedge CPU_CKIO);
        RESET_N = 1;
    end
endtask

task write_task; // writeタスク (addr,data)
    input [15:0] addr;
    input [15:0] data;
    begin
        CPU_ADDR <= #(TCO) {addr, 1'b0};
        CPU_CS1_N <= #(TCO) 0;
        CPU_RDWR <= #(TCO) 0;
        bus_data_reg <= #(TCO) data;
        @(posedge CPU_CKIO);
        @(negedge CPU_CKIO);
        CPU_WE0_N <= #(TCO) 0;
        CPU_WE1_N <= #(TCO) 0;
        CPU_RDWR <= #(TCO)0;
        repeat (10) @(posedge CPU_CKIO);
        @(negedge CPU_CKIO);
        CPU_WE0_N <= #(TCO) 1;
        CPU_WE1_N <= #(TCO) 1;
        @(posedge CPU_CKIO);
        CPU_ADDR <= #(TCO) 17'd0;
        CPU_CS1_N <= #(TCO) 1;
        CPU_RDWR <= #(TCO) 1;
        bus_data_reg <= #(TCO) 16'hzzzz;
        @(posedge CPU_CKIO);
    end
endtask

task mod_init;
    integer i;
    begin
        for (i = 0; i < 2000; i=i+1) begin
            write_task(MOD_BUF_ADDR_BASE + i, 16'hFFFF);
        end
    end
endtask

initial begin
    initilalize();
    mod_init();

    write_task(16'h0000, 16'hFF00);
end

always
    #(SYSTEM_CLOCK_CNT/2) sys_clk = !sys_clk;

always
    #(CPU_BUS_CLOCK_CNT/2) CPU_CKIO = !CPU_CKIO;

always begin
    #(SIMULATION_FREQ/CAT_SYNC0_1MS_FREQ - CAT_SYNC0_PULSE_WIDTH)  CAT_SYNC0_1ms = 1;
    #(CAT_SYNC0_PULSE_WIDTH) CAT_SYNC0_1ms = 0;
end

always begin
    #(SIMULATION_FREQ/CAT_SYNC0_1S_FREQ - CAT_SYNC0_PULSE_WIDTH)  CAT_SYNC0_1ms = 1;
    #(CAT_SYNC0_PULSE_WIDTH) CAT_SYNC0_1ms = 0;
end

endmodule
