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

reg[15:0]bram_addr;

wire [16:0] CPU_ADDR = {bram_addr, 1'b1};
wire [15:0] CPU_DATA;
reg CPU_CKIO;
reg CPU_CS1_N;
reg CPU_WE0_N;
reg MRCC_25P6M;

reg [20:0] ref_clk_cnt, ref_clk_cnt_cycle;
reg [9:0] ref_clk_div;

wire [14:0] mod_idx;
wire [7:0] mod;
reg [7:0] mod_idx_shift;

reg [15:0] CPU_DATA_READ;

reg [15:0] bus_data_reg = 16'bz;
assign CPU_DATA = bus_data_reg;

mod_controller mod_controller(
                   .BUS_CLK(CPU_CKIO),
                   .BRAM_SELECT(bram_addr[16:15]),
                   .EN(~CPU_CS1_N),
                   .WE(~CPU_WE0_N),
                   .ADDR(bram_addr[14:1]),
                   .DATA_IN(CPU_DATA),

                   .SYS_CLK(MRCC_25P6M),
                   .MOD_IDX(mod_idx),
                   .MOD_OUT(mod)
               );

mod_synchronizer mod_synchronizer(
                     .REF_CLK_CNT(ref_clk_cnt),
                     .MOD_IDX_SHIFT(mod_idx_shift),
                     .MOD_IDX_OUT(mod_idx)
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

reg [7:0] tmp = 0;
task mod_init;
    integer i;
    begin
        for (i = 0; i < 250; i=i+1) begin
            tmp = 2*i;
            bram_write(i, {tmp+1, tmp});
        end
        for (i = 0; i < 250; i=i+1) begin
            tmp = 2*i;
            bram_write(i, {tmp+1, tmp});
        end
    end
endtask

initial begin
    ref_clk_cnt = 0;
    ref_clk_div = 0;
    mod_idx_shift = 1;
    ref_clk_cnt_cycle = 20'd39999;
    MRCC_25P6M = 1;
    CPU_CKIO = 1;
    CPU_CS1_N = 0;
    CPU_WE0_N = 1;
    CPU_DATA_READ = 0;
    bus_data_reg = 16'bz;
    bram_addr = #(TCO) 16'd0;

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
    if (ref_clk_div == 10'd639) begin
        ref_clk_div <= 0;
        ref_clk_cnt <= (ref_clk_cnt == ref_clk_cnt_cycle) ? 0 : ref_clk_cnt + 1;
    end
    else begin
        ref_clk_div <= ref_clk_div + 1;
    end
end

endmodule
