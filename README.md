# README

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
| 　          | 0x01             | FPGA info                         | W   |
| 　          | 0x02             | STM cycle                         | R   |
| 　          | 0x03             | STM division                      | R   |
| 　          | 0x04             | STM synchronization shift         | R   |
| 　          | 0x05             | Modulation clk shift              | R   |
| 　          | 0x06             | Reference clk cycle shift         | R  |
| 　          | 0x07             | Unused                           | 　  |
| 　          | ︙               | ︙                               | 　  |
| 　          | 0xFE             | Unused                           | 　  |
| 　          | 0xFF             | FPGA version number              | -   |

* Control flags
    * 3: silent mode
    * 4: force fan
    * 5: stm mode
* Clock property
    * 0: reference clock init
    * 1: stm clock init
    * 7: software reset

### Modulation

| BRAM_SELECT | BRAM_ADDR (15bit) | DATA (8bit) | R/W |
|-------------|-------------------|-------------|-----|
| 0x1         | 0x0000             | mod[0]      | R   |
| 　          | 0x0001             | mod[1]      | R   |
| 　          | ︙                | ︙          | ︙  |
| 　          | 0x7CFF             | mod[31999]   | R   |
| 　          | 0x7D00             | Unused      | 　  |
| 　          | ︙                | ︙          | 　  |
| 　          | 0x7FFF             | Unused      | 　  |

### Normal operation

| BRAM_SELECT | BRAM_ADDR (11bit) | DATA (16bit)        | R/W |
|-------------|-------------------|---------------------|-----|
| 0x2         | 0x000              | duty[0]/phase[0]     | R   |
| 　          | ︙                | ︙                  | ︙  |
| 　          | 0x0F8              | duty[248]/phase[248] | R   |
| 　          | 0x0F9              | Unused              | 　  |
| 　          | ︙                | ︙                  | 　  |
| 　          | 0x1FF              | Unused              | 　  |

### STM operation

| BRAM_SELECT | BRAM_ADDR (16bit) | DATA (128 bit)                                                                       | R/W |
|-------------|-------------------|--------------------------------------------------------------------------------------|-----|
| 0x3         | 0x0000            | 79:0 = {stm_duty[0], stm_z[0],   stm_y[0], stm_x[0]}      127:80 = Unused                 | R   |
| 　          | 0x0001            | 79:0 = {stm_duty[1], stm_z[1],   stm_y[1], stm_x[1]}      127:80 = Unused                 | R   |
| 　          | ︙                | ︙                                                                                   | ︙  |
| 　          | 0x9C3F            | 79:0 = {stm_duty[39999],   stm_z[39999], stm_y[39999], stm_x[39999]}      127:80 = Unused | R   |

# Author

Shun Suzuki, 2020-2021
