/*
 * File: seq_operator.sv
 * Project: sequence
 * Created Date: 13/05/2021
 * Author: Shun Suzuki
 * -----
 * Last Modified: 09/12/2021
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2021 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
module seq_operator#(
           parameter TRANS_NUM = 249,
           parameter int REF_CLK_FREQ = 40000,
           localparam [31:0] REF_CLK_CYCLE_NS = 1000000000/REF_CLK_FREQ,
           parameter string PHASE_INVERTED = "TRUE",
           parameter string ENABLE_SYNC_DBG = "TRUE"
       )(
           input var CLK,
           cpu_bus_if.slave_port CPU_BUS,
           seq_sync_if.slave_port SEQ_SYNC,
           output var [15:0] SEQ_CLK_CYCLE,
           output var [15:0] SEQ_IDX,
           output var [7:0] DUTY[0:TRANS_NUM-1],
           output var [7:0] PHASE[0:TRANS_NUM-1]
       );

`include "../cvt_uid.vh"
`include "../param.vh"

logic [16:0] seq_idx;
logic [63:0] data_out;

////////////////////////////////// BRAM //////////////////////////////////
logic config_ena, seq_ena;
logic [18:0] seq_addr;
logic [4:0] seq_addr_offset;

assign config_ena = (CPU_BUS.BRAM_SELECT == `BRAM_CONFIG_SELECT) & CPU_BUS.EN;
assign seq_ena = (CPU_BUS.BRAM_SELECT == `BRAM_SEQ_SELECT) & CPU_BUS.EN;
assign seq_addr = {seq_addr_offset, CPU_BUS.BRAM_ADDR};

BRAM_SEQ seq_ram(
             .clka(CPU_BUS.BUS_CLK),
             .ena(seq_ena),
             .wea(CPU_BUS.WE),
             .addra(seq_addr),
             .dina(CPU_BUS.DATA_IN),
             .douta(),
             .clkb(CLK),
             .web('0),
             .addrb(seq_idx),
             .dinb('0),
             .doutb(data_out)
         );

logic [2:0] config_we_edge = 3'b000;

always_ff @(posedge CPU_BUS.BUS_CLK) begin
    config_we_edge <= {config_we_edge[1:0], (CPU_BUS.WE & config_ena)};
    if(config_we_edge == 3'b011) begin
        case(CPU_BUS.BRAM_ADDR)
            `SEQ_BRAM_ADDR_OFFSET_ADDR:
                seq_addr_offset <= CPU_BUS.DATA_IN[4:0];
        endcase
    end
end
////////////////////////////////// BRAM //////////////////////////////////

////////////////////////////////// SYNC //////////////////////////////////
logic [15:0] seq_cnt;
logic [15:0] seq_cnt_div;
logic [16:0] raw_buf_mode_offset;

assign seq_idx = (SEQ_SYNC.SEQ_MODE == `SEQ_MODE_FOCI) ? {1'b0, seq_cnt} : {seq_cnt[10:0], 6'h0} + raw_buf_mode_offset;

logic seq_clk_init, seq_clk_init_buf, seq_clk_init_buf_rst;
logic [95:0] seq_clk_sync_time_ref_unit;
logic [47:0] seq_tcycle;
logic [111:0] seq_shift;
logic [63:0] seq_cnt_shift;
logic [31:0] seq_div_shift;

divider64 div_ref_unit_seq(
              .s_axis_dividend_tdata(SEQ_SYNC.SEQ_CLK_SYNC_TIME_NS),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata(REF_CLK_CYCLE_NS),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata(seq_clk_sync_time_ref_unit),
              .m_axis_dout_tvalid()
          );
mult_24 mult_tcycle(
            .CLK(CLK),
            .A({8'd0, SEQ_SYNC.SEQ_CLK_CYCLE} + 24'd1),
            .B({8'd0, SEQ_SYNC.SEQ_CLK_DIV} + 24'd1),
            .P(seq_tcycle)
        );
div64_48 sync_shift_rem(
             .s_axis_dividend_tdata(seq_clk_sync_time_ref_unit[95:32]),
             .s_axis_dividend_tvalid(1'b1),
             .s_axis_divisor_tdata(seq_tcycle),
             .s_axis_divisor_tvalid(1'b1),
             .aclk(CLK),
             .m_axis_dout_tdata(seq_shift),
             .m_axis_dout_tvalid()
         );
divider64 sync_shift_div_rem(
              .s_axis_dividend_tdata({16'd0, seq_shift[47:0]}),
              .s_axis_dividend_tvalid(1'b1),
              .s_axis_divisor_tdata({16'd0, SEQ_SYNC.SEQ_CLK_DIV} + 32'd1),
              .s_axis_divisor_tvalid(1'b1),
              .aclk(CLK),
              .m_axis_dout_tdata({seq_cnt_shift, seq_div_shift}),
              .m_axis_dout_tvalid()
          );

always_ff @(posedge CLK) begin
    if (SEQ_SYNC.SYNC & seq_clk_init) begin
        seq_cnt <= seq_cnt_shift[15:0];
        seq_cnt_div <= seq_div_shift[15:0];
        raw_buf_mode_offset <= '0;
        seq_clk_init <= '0;
    end
    else begin
        seq_clk_init_buf <= SEQ_SYNC.SEQ_CLK_INIT;
        seq_clk_init_buf_rst <= seq_clk_init_buf;
        seq_clk_init <= (seq_clk_init_buf & ~seq_clk_init_buf_rst) ? 1 : seq_clk_init;

        if(SEQ_SYNC.REF_CLK_TICK) begin
            if(seq_cnt_div == SEQ_SYNC.SEQ_CLK_DIV) begin
                seq_cnt_div <= '0;
                seq_cnt <= (seq_cnt == SEQ_SYNC.SEQ_CLK_CYCLE) ? '0 : seq_cnt + 1'b1;
                raw_buf_mode_offset <= '0;
            end
            else begin
                seq_cnt_div <= seq_cnt_div + 1'b1;
            end
        end
        else begin
            raw_buf_mode_offset <= raw_buf_mode_offset == {3'b000, TRANS_NUM[15:2]} ? raw_buf_mode_offset : raw_buf_mode_offset + 1'b1;
        end
    end
end

if (ENABLE_SYNC_DBG == "TRUE") begin
    assign SEQ_IDX = seq_cnt;
    assign SEQ_CLK_CYCLE = SEQ_SYNC.SEQ_CLK_CYCLE;
end
////////////////////////////////// SYNC //////////////////////////////////

localparam [7:0] TRANS_NUM_X = 8'd18;

// The unit of focus calculation is WAVELENGTH/256
localparam [23:0] TRANS_SPACING_UNIT = 24'd2600960; // TRNAS_SPACING*256 = 10.16e3 um * 256
localparam int MULT_DIVIDER_LATENCY = 10 + 4 + 28;

logic [$clog2(MULT_DIVIDER_LATENCY)-1:0] wait_cnt;

logic fc_trig;
logic signed [17:0] focus_x, focus_y, focus_z;
logic [31:0] trans_x, trans_y;
logic [7:0] phase_out;
logic phase_out_valid;

logic [16:0] seq_idx_old = '0;
logic idx_change;

logic [7:0] duty[0:TRANS_NUM-1];
logic [7:0] phase[0:TRANS_NUM-1];
logic [8:0] tr_cnt;
logic [7:0] tr_cnt_uid;
logic [7:0] tr_cnt_x, tr_cnt_y;
logic [47:0] tr_x_u, tr_y_u;
logic [7:0] tr_cnt_in;

logic [15:0] _unused_x, _unused_y;

enum logic [2:0] {
         WAIT,
         DIV_WAIT,
         FC_DATA_IN_STREAM,
         LOAD_DUTY_PHASE_WAIT,
         LOAD_DUTY_PHASE
     } state_calc = WAIT;

assign idx_change = (seq_idx != seq_idx_old);

assign DUTY = duty;
assign PHASE = phase;

assign tr_cnt_uid = cvt_uid(tr_cnt[7:0]);

div8 div_tr(
         .s_axis_dividend_tdata(tr_cnt_uid),
         .s_axis_dividend_tvalid(1'b1),
         .s_axis_divisor_tdata(TRANS_NUM_X),
         .s_axis_divisor_tvalid(1'b1),
         .aclk(CLK),
         .m_axis_dout_tdata({tr_cnt_y, tr_cnt_x}),
         .m_axis_dout_tvalid()
     );
mult_24 mult_24_tr_x(
            .*,
            .A({16'h0000, tr_cnt_x}),
            .B(TRANS_SPACING_UNIT),
            .P(tr_x_u)
        );
mult_24 mult_24_tr_y(
            .*,
            .A({16'h0000, tr_cnt_y}),
            .B(TRANS_SPACING_UNIT),
            .P(tr_y_u)
        );
divider div_x(
            .s_axis_dividend_tdata(tr_x_u[31:0]),
            .s_axis_dividend_tvalid(1'b1),
            .s_axis_divisor_tdata(SEQ_SYNC.WAVELENGTH_UM),
            .s_axis_divisor_tvalid(1'b1),
            .aclk(CLK),
            .m_axis_dout_tdata({trans_x, _unused_x}),
            .m_axis_dout_tvalid()
        );
divider div_y(
            .s_axis_dividend_tdata(tr_y_u[31:0]),
            .s_axis_dividend_tvalid(1'b1),
            .s_axis_divisor_tdata(SEQ_SYNC.WAVELENGTH_UM),
            .s_axis_divisor_tvalid(1'b1),
            .aclk(CLK),
            .m_axis_dout_tdata({trans_y, _unused_y}),
            .m_axis_dout_tvalid()
        );

focus_calculator #(
                     .PHASE_INVERTED(PHASE_INVERTED)
                 ) focus_calculator(
                     .*,
                     .DVALID_IN(fc_trig),
                     .FOCUS_X(focus_x),
                     .FOCUS_Y(focus_y),
                     .FOCUS_Z(focus_z),
                     .TRANS_X(trans_x[17:0]),
                     .TRANS_Y(trans_y[17:0]),
                     .TRANS_Z('0),
                     .PHASE(phase_out),
                     .PHASE_CALC_DONE(phase_out_valid)
                 );

always_ff @(posedge CLK)
    seq_idx_old <= seq_idx;

always_ff @(posedge CLK) begin
    case(SEQ_SYNC.SEQ_MODE)
        `SEQ_MODE_FOCI: begin
            if(phase_out_valid) begin
                phase[tr_cnt_in] <= phase_out;
                tr_cnt_in <= tr_cnt_in + 1'b1;
            end
            else begin
                tr_cnt_in <= '0;
            end

            case(state_calc)
                WAIT: begin
                    if (idx_change) begin
                        fc_trig <= '0;
                        tr_cnt <= '0;
                        wait_cnt <= '0;
                        state_calc <= DIV_WAIT;
                    end
                end
                DIV_WAIT: begin
                    tr_cnt <= tr_cnt + 1'b1;
                    wait_cnt <= wait_cnt + 1'b1;
                    if (wait_cnt == MULT_DIVIDER_LATENCY - 1'b1) begin
                        focus_x <= data_out[17:0];
                        focus_y <= data_out[35:18];
                        focus_z <= data_out[53:36];
                        duty <= '{TRANS_NUM{data_out[61:54]}};
                        fc_trig <= 1'b1;
                        state_calc <= FC_DATA_IN_STREAM;
                    end
                end
                FC_DATA_IN_STREAM: begin
                    tr_cnt <= tr_cnt + 1'b1;
                    if (tr_cnt == TRANS_NUM + MULT_DIVIDER_LATENCY - 1) begin
                        state_calc <= WAIT;
                        fc_trig <= '0;
                    end
                end
                default: begin
                    duty <= '{TRANS_NUM{8'h00}};
                    phase <= '{TRANS_NUM{8'h00}};
                    state_calc <= WAIT;
                end
            endcase
        end
        `SEQ_MODE_RAW_DUTY_PHASE: begin
            case(state_calc)
                WAIT: begin
                    if (idx_change) begin
                        tr_cnt <= '0;
                        state_calc <= LOAD_DUTY_PHASE_WAIT;
                    end
                end
                LOAD_DUTY_PHASE_WAIT: begin
                    state_calc <= LOAD_DUTY_PHASE;
                end
                LOAD_DUTY_PHASE: begin
                    if (tr_cnt < {TRANS_NUM[8:2], 2'b00}) begin
                        {duty[tr_cnt], phase[tr_cnt]} <= data_out[15:0];
                        {duty[tr_cnt + 1], phase[tr_cnt + 1]} <= data_out[31:16];
                        {duty[tr_cnt + 2], phase[tr_cnt + 2]} <= data_out[47:32];
                        {duty[tr_cnt + 3], phase[tr_cnt + 3]} <= data_out[63:48];
                        tr_cnt <= tr_cnt + 9'd4;
                    end
                    else begin
                        {duty[tr_cnt], phase[tr_cnt]} <= data_out[15:0];
                        state_calc <= WAIT;
                    end
                end
                default: begin
                    duty <= '{TRANS_NUM{8'h00}};
                    phase <= '{TRANS_NUM{8'h00}};
                    state_calc <= WAIT;
                end
            endcase
        end
    endcase
end

endmodule
