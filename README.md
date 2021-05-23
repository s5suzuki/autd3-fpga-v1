# AUTD3 FPGA firmware

Version: 1.0

This repository contains the FPGA design of [AUTD3](https://hapislab.org/airborne-ultrasound-tactile-display?lang=en).

The code is written in SystemVerilog with Vivado 2020.2.

# Connection

* [IN] [16:0] CPU_ADDR,
* [IN/OUT] [15:0] CPU_DATA
* [OUT] [252:1] XDCR_OUT
* [IN] CPU_CKIO
* [IN] CPU_CS1_N
* [IN] RESET_N
* [IN] CPU_WE0_N
* [IN] CPU_WE1_N
* [IN] CPU_RD_N
* [IN] CPU_RDWR
* [IN] MRCC_25P6M
* [IN] CAT_SYNC0
* [OUT] FORCE_FAN
* [IN] THERMO
* [IN] [3:0] GPIO_IN
* [OUT] [3:0] GPIO_OUT

## Address map

### Properties

| BRAM_SELECT | BRAM_ADDR (8bit) | DATA (16 bit)                    | R/W |
|-------------|------------------|----------------------------------|-----|
| 0x0         | 0x00             | 7:0=Control flags<br>15:8=Clock property | R/W |
| 　          | 0x01             | 7:0=FPGA info                         | W   |
| 　          | 0x02             | Seq cycle                         | R   |
| 　          | 0x03             | Seq clk division                  | R   |
| 　          | 0x04             | -                                 | -   |
| 　          | 0x05             | -                                 | -   |
| 　          | 0x06             | -                                 | -  |
| 　          | 0x07             | Seq bram addr offset	             | R  |
| 　          | 0x08             | Wavelength     	                 | R  |
| 　          | 0x09             | Seq clk sync time[15:0]           | R  |
| 　          | 0x0A             | Seq clk sync time[31:16]           | R  |
| 　          | 0x0B             | Seq clk sync time[47:32]           | R  |
| 　          | 0x0C             | Seq clk sync time[63:48]           | R  |
| 　          | 0x0D             | Modulation cycle   	             | R  |
| 　          | 0x0E             | Modulation clock division         | R  |
| 　          | 0x0F             | Mod clk sync time[15:0]           | R  |
| 　          | 0x10             | Mod clk sync time[31:16]           | R  |
| 　          | 0x11             | Mod clk sync time[47:32]           | R  |
| 　          | 0x12             | Mod clk sync time[63:48]           | R  |
| 　          | 0x13             | Unused                           | -  |
| 　          | ︙               | ︙                               |　︙  |
| 　          | 0xFE             | Unused                           | -　  |
| 　          | 0xFF             | FPGA version number              | R   |

* Control flags
    * 3: silent mode
    * 4: force fan
    * 5: seq mode
* Clock property
    * 0: modulation clock init
    * 1: seq clock init

### Modulation

| BRAM_SELECT | BRAM_ADDR (15bit) | DATA (8bit) | R/W |
|-------------|-------------------|-------------|-----|
| 0x1         | 0x0000             | mod[0]      | R   |
| 　          | 0x0001             | mod[1]      | R   |
| 　          | ︙                | ︙          | ︙  |
| 　          | 0x7CFF             | mod[31999]   | R   |
| 　          | 0x7D00             | Unused      | -  |
| 　          | ︙                | ︙          | 　︙ |
| 　          | 0x7FFF             | Unused      | -　 |

### Normal operation

| BRAM_SELECT | BRAM_ADDR (11bit) | DATA (16bit)        | R/W |
|-------------|-------------------|---------------------|-----|
| 0x2         | 0x000              | duty[0]/phase[0]     | R   |
| 　          | ︙                | ︙                  | ︙  |
| 　          | 0x0F8              | duty[248]/phase[248] | R   |
| 　          | 0x0F9              | Unused              | -  |
| 　          | ︙                | ︙                  | ︙  |
| 　          | 0x0FF              | Unused              | -  |
|             | 0x100              | delay[0]           | R   |
| 　          | ︙                | ︙                  | ︙  |
| 　          | 0x0F8              | delay[248]        | R   |
| 　          | 0x1F9              | Unused              | -  |
| 　          | ︙                | ︙                  | ︙  |
| 　          | 0x1FF              | Unused              | -  |

### SEQ operation

| BRAM_SELECT | BRAM_ADDR (16bit) | DATA (128 bit)                                                                       | R/W |
|-------------|-------------------|--------------------------------------------------------------------------------------|-----|
| 0x3         | 0x0000            | 79:0 = {seq_duty[0], seq_z[0],   seq_y[0], seq_x[0]}      127:80 = Unused                 | R   |
| 　          | 0x0001            | 79:0 = {seq_duty[1], seq_z[1],   seq_y[1], seq_x[1]}      127:80 = Unused                 | R   |
| 　          | ︙                | ︙                                                                                   | ︙  |
| 　          | 0x9C3F            | 79:0 = {seq_duty[39999],   seq_z[39999], seq_y[39999], seq_x[39999]}      127:80 = Unused | R   |

# Author

Shun Suzuki, 2020-2021
