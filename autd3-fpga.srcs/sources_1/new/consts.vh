`define BRAM_PROP_SELECT (2'h0)
`define BRAM_MOD_SELECT (2'h1)
`define BRAM_NORMAL_OP_SELECT (2'h2)
`define BRAM_LM_SELECT (2'h3)

`define CTRL_FLAG_SILENT (8'd3)
`define CTRL_FLAG_FORCE_FAN (8'd4)
`define CTRL_FLAG_LM_MODE (8'd5)

`define PROPS_REF_INIT_IDX (0) 
`define PROPS_LM_INIT_IDX (1)
`define PROPS_LM_CALIB_IDX (2)
`define PROPS_RST_IDX (7)

`define BRAM_CF_AND_CP_IDX (14'd0)
`define BRAM_LM_CYCLE (14'd1)
`define BRAM_LM_DIV (14'd2)
`define BRAM_LM_INIT_LAP (14'd3)
`define BRAM_LM_CALIB_SHIFT (14'd4)
`define BRAM_MOD_IDX_SHIFT (14'd6)
`define BRAM_REF_CLK_CYCLE_SHIFT (14'd7)

`define TRANS_NUM (8'd249)
`define TRANS_NUM_X (18)
`define TRANS_NUM_Y (14)

`define SYS_CLK_FREQ (25600000)
`define ULTRASOUND_FREQ (40000)
`define SYNC_FREQ (1000)

`define REF_CLK_FREQ (40000)
`define REF_CLK_CYCLE_BASE (1)
`define REF_CLK_CYCLE_MAX (32)
`define REF_CLK_CYCLE_CNT_BASE (`REF_CLK_CYCLE_BASE * `REF_CLK_FREQ)
`define REF_CLK_CYCLE_CNT_MAX (`REF_CLK_CYCLE_MAX * `REF_CLK_FREQ)
`define REF_CLK_CYCLE_CNT_WIDTH ($clog2(`REF_CLK_CYCLE_CNT_MAX))

`define TIME_CNT_CYCLE (`SYS_CLK_FREQ / `ULTRASOUND_FREQ)
`define TIME_CNT_CYCLE_WIDTH ($clog2(`TIME_CNT_CYCLE))

`define LM_CLK_CYCLE (1)
`define LM_LAP_CYCLE_CNT (`LM_CLK_CYCLE * `SYNC_FREQ)
`define LM_LAP_CYCLE_CNT_WIDTH ($clog2(`LM_LAP_CYCLE_CNT))
`define LM_CLK_MAX (40000)
`define LM_CLK_MAX_WIDTH ($clog2(`LM_CLK_MAX))

`define MOD_BUF_SIZE (32000)
`define MOD_BUF_IDX_WIDTH ($clog2(`MOD_BUF_SIZE))

`define SYNC_CYCLE_CNT (`REF_CLK_FREQ / `SYNC_FREQ)
