/*
 * File: modulator.sv
 * Project: new
 * Created Date: 26/07/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 07/12/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

module modulator#(
           parameter int TRANS_NUM = 249,
           parameter int REF_CLK_FREQ = 40000,
           localparam [31:0] REF_CLK_CYCLE_NS = 1000000000/REF_CLK_FREQ,
           parameter string ENABLE_SYNC_DBG = "TRUE"

       )(
           input var CLK,
           cpu_bus_if.slave_port CPU_BUS,
           mod_sync_if.slave_port MOD_SYNC,
           input var [7:0] DUTY[0:TRANS_NUM-1],
           output var [15:0] MOD_CLK_CYCLE,
           output var [15:0] MOD_IDX,
           output var [7:0] DUTY_MODULATED[0:TRANS_NUM-1]
       );

`include "./param.vh"

logic [15:0] mod_idx;
logic [7:0] mod_raw;

////////////////////////////////// BRAM //////////////////////////////////
logic config_ena, mod_ena;
logic [14:0] mod_addr;
logic mod_addr_offset;

assign config_ena = (CPU_BUS.BRAM_SELECT == `BRAM_CONFIG_SELECT) & CPU_BUS.EN;
assign mod_ena = (CPU_BUS.BRAM_SELECT == `BRAM_MOD_SELECT) & CPU_BUS.EN;
assign mod_addr = {mod_addr_offset, CPU_BUS.BRAM_ADDR};

BRAM_MOD mod_bram(
             .clka(CPU_BUS.BUS_CLK),
             .ena(mod_ena),
             .wea(CPU_BUS.WE),
             .addra(mod_addr),
             .dina(CPU_BUS.DATA_IN),
             .douta(),
             .clkb(CLK),
             .web('0),
             .addrb(mod_idx),
             .dinb('0),
             .doutb(mod_raw)
         );

logic [2:0] config_we_edge = 3'b000;

always_ff @(posedge CPU_BUS.BUS_CLK) begin
    config_we_edge <= {config_we_edge[1:0], (CPU_BUS.WE & config_ena)};
    if(config_we_edge == 3'b011) begin
        case(CPU_BUS.BRAM_ADDR)
            `MOD_BRAM_ADDR_OFFSET_ADDR:
                mod_addr_offset <= CPU_BUS.DATA_IN[0];
        endcase
    end
end
////////////////////////////////// BRAM //////////////////////////////////

////////////////////////////////// SYNC //////////////////////////////////
logic [15:0] mod_idx_div;

logic mod_clk_init, mod_clk_init_buf, mod_clk_init_buf_rst;
logic [95:0] mod_clk_sync_time_ref_unit;
logic [47:0] mod_tcycle;
logic [111:0] mod_shift;
logic [63:0] mod_idx_shift;
logic [31:0] mod_div_shift;

divider64 div_ref_unit_mod(
              .s_axis_dividend_tdata(MOD_SYNC.MOD_CLK_SYNC_TIME_NS),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata(REF_CLK_CYCLE_NS),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata(mod_clk_sync_time_ref_unit),
              .m_axis_dout_tvalid()
          );
mult_24 mult_tcycle_mod(
            .CLK(CLK),
            .A({8'd0, MOD_SYNC.MOD_CLK_CYCLE} + 24'd1),
            .B({8'd0, MOD_SYNC.MOD_CLK_DIV} + 24'd1),
            .P(mod_tcycle)
        );
div64_48 sync_shift_rem_mod(
             .s_axis_dividend_tdata(mod_clk_sync_time_ref_unit[95:32]),
             .s_axis_dividend_tvalid(1'b1),
             .s_axis_divisor_tdata(mod_tcycle),
             .s_axis_divisor_tvalid(1'b1),
             .aclk(CLK),
             .m_axis_dout_tdata(mod_shift),
             .m_axis_dout_tvalid()
         );
divider64 sync_shift_div_rem_mod(
              .s_axis_dividend_tdata({16'd0, mod_shift[47:0]}),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata({16'd0, MOD_SYNC.MOD_CLK_DIV} + 32'd1),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata({mod_idx_shift, mod_div_shift}),
              .m_axis_dout_tvalid()
          );

always_ff @(posedge CLK) begin
    if (MOD_SYNC.SYNC & mod_clk_init) begin
        mod_idx <= mod_idx_shift[15:0];
        mod_idx_div <= mod_div_shift[15:0];
        mod_clk_init <= '0;
    end
    else begin
        mod_clk_init_buf <= MOD_SYNC.MOD_CLK_INIT;
        mod_clk_init_buf_rst <= mod_clk_init_buf;
        mod_clk_init <= (mod_clk_init_buf & ~mod_clk_init_buf_rst) ? 1 : mod_clk_init;

        if(MOD_SYNC.REF_CLK_TICK) begin
            if(mod_idx_div == MOD_SYNC.MOD_CLK_DIV) begin
                mod_idx_div <= 0;
                mod_idx <= (mod_idx == MOD_SYNC.MOD_CLK_CYCLE) ? 0 : mod_idx + 1;
            end
            else begin
                mod_idx_div <= mod_idx_div + 1;
            end
        end
    end
end

if (ENABLE_SYNC_DBG == "TRUE") begin
    assign MOD_IDX = mod_idx;
    assign MOD_CLK_CYCLE = MOD_SYNC.MOD_CLK_CYCLE;
end
////////////////////////////////// SYNC //////////////////////////////////

logic [8:0] mod;
assign mod = {1'b0, mod_raw} + 9'd1;

for (genvar ii = 0; ii < TRANS_NUM; ii++) begin
    logic [16:0] dm;
    mult8x8 mod_mult(
                .*,
                .A(DUTY[ii]),
                .B(mod),
                .P(dm)
            );
    assign DUTY_MODULATED[ii] = dm[15:8];
end

endmodule
