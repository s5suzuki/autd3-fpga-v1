`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/10/2020 08:31:42 AM
// Design Name:
// Module Name: sim_tr_cnt
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

module sim_tr_cnt();

parameter TCO = 10; // bus delay 10ns

reg[1:0]bram_select;
reg[13:0]bram_addr;

wire [15:0] CPU_DATA;
reg CPU_CKIO;
reg CPU_CS1_N;
reg CPU_WE0_N;
reg MRCC_25P6M;

reg [15:0] CPU_DATA_READ;

reg [15:0] bus_data_reg = 16'bz;
assign CPU_DATA = bus_data_reg;

transducer_controller transducer_controller(
                          .BUS_CLK(CPU_CKIO),
                          .BRAM_SELECT(bram_select),
                          .EN(~CPU_CS1_N),
                          .WE(~CPU_WE0_N),
                          .ADDR(bram_addr),
                          .DATA_IN(CPU_DATA),

                          .SYS_CLK(MRCC_25P6M),
                          .TIME(),
                          .STM_IDX(),
                          .STM_CLK_DIV(),
                          .MOD_IDX(),
                          .SILENT(),
                          .OP_MODE(1'b0),
                          .XDCR_OUT()
                      );

task bram_write (input [1:0] select, input [13:0] addr, input [15:0] data_in);
    repeat (20) @(posedge CPU_CKIO);
    bram_select <= #(TCO) select;
    bram_addr <= #(TCO) addr;
    CPU_CS1_N <= #(TCO) 0;
    bus_data_reg <= #(TCO) data_in;
    @(posedge CPU_CKIO);
    @(negedge CPU_CKIO);

    CPU_WE0_N <= #(TCO) 0;
    repeat (10) @(posedge CPU_CKIO);

    @(negedge CPU_CKIO);
    CPU_WE0_N <= #(TCO) 1;
endtask

task mod_init;
    integer i;
    begin
        for (i = 0; i < 4000; i=i+1) begin
            bram_write(1, i, 16'hFFFF);
        end
    end
endtask

initial begin
    MRCC_25P6M = 1;
    CPU_CKIO = 1;
    CPU_CS1_N = 0;
    CPU_WE0_N = 1;
    bus_data_reg = 16'bz;
    bram_select = #(TCO) 0;
    bram_addr = #(TCO) 0;
    mod_init();

    #(1000);
    bram_write(2'd2, 8'd0, 16'hABCD);
    bram_write(2'd2, 8'd7, 16'h1234);
end

// main clock 25.6MHz
always begin
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.531 MRCC_25P6M = !MRCC_25P6M;
    #19.532 MRCC_25P6M = !MRCC_25P6M;
end

always
    #6.65 CPU_CKIO = !CPU_CKIO; // bus clock 75MHz


endmodule
