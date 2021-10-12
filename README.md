# AUTD3 FPGA firmware

Version: 1.9

This repository contains the FPGA design of [AUTD3](https://hapislab.org/airborne-ultrasound-tactile-display?lang=en).

The code is written in SystemVerilog with Vivado 2021.1.

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

* When writing, the highest two bits of CPU_ADDR[16:15] are used as BRAM_SELECT to select BRAM
* When writing to Modulation BRAM, the address is 15 bits, which is 14 bits of CPU_ADDR[14:1] plus the upper 1 bit of "Mod bram addr offset".
* Also, When writing to Sequence BRAM, the address will be 18 bits ({"Seq bram addr offset", CPU_ADDR[14:1]})

### Config

| BRAM_SELECT | BRAM_ADDR (6bit) | DATA (16 bit)                    | R/W |
|-------------|------------------|----------------------------------|-----|
| 0x0         | 0x00             | 7:0 = Control flags<br>15:8 = unused | R/W |
|            | 0x01             | 7:0 = FPGA info                         | W   |
|            | 0x02             | (Seq cycle) - 1                       | R   |
|            | 0x03             | (Seq freq division ratio) - 1         | R   |
|            | 0x04             | -                                 | -   |
|            | 0x05             | -                                 | -   |
|            | 0x06             | Mod bram addr offset (1bit)       | R  |
|            | 0x07             | Seq bram addr offset	(4bit)       | R  |
|            | 0x08             | Wavelength     	                 | R  |
|            | 0x09             | Seq clk sync time[15:0]           | R  |
|            | 0x0A             | Seq clk sync time[31:16]           | R  |
|            | 0x0B             | Seq clk sync time[47:32]           | R  |
|            | 0x0C             | Seq clk sync time[63:48]           | R  |
|            | 0x0D             | (Modulation cycle) - 1   	             | R  |
|            | 0x0E             | (Modulation freq division ratio) - 1         | R  |
|            | 0x0F             | Mod clk sync time[15:0]           | R  |
|            | 0x10             | Mod clk sync time[31:16]           | R  |
|            | 0x11             | Mod clk sync time[47:32]           | R  |
|            | 0x12             | Mod clk sync time[63:48]           | R  |
|            | 0x13             | 0 = Mod clk init<br>1 = Seq clk init | R  |
|            | 0x14             | unused                           | -  |
|            | ︙               | ︙                               | ︙  |
|            | 0x3E             | unused                           | -   |
|            | 0x3F             | FPGA version number              | R   |

* Control flags
    * 0: output enable
    * 1: output balance
    * 3: silent mode
    * 4: force fan
    * 5: op mode (0: Normal, 1: Sequence)
    * 6: seq mode (0: PointSequence, 1: GainSequence)

### Modulation

| BRAM_SELECT | BRAM_ADDR (16bit) | DATA (8bit) | R/W |
|-------------|-------------------|-------------|-----|
| 0x1         | 0x0000             | mod[0]      | R   |
|            | 0x0001             | mod[1]      | R   |
|            | ︙                | ︙          | ︙  |
|            | 0xFFFF             | mod[65535]   | R   |

### Normal operation

| BRAM_SELECT | BRAM_ADDR (11bit) | DATA (16bit)        | R/W |
|-------------|-------------------|---------------------|-----|
| 0x2         | 0x000              | 15:8 = duty[0]<br>7:0 = phase[0]     | R   |
|            | ︙                | ︙                  | ︙  |
|            | 0x0F8              | 15:8 = duty[248]<br>7:0 = phase[248] | R   |
|            | 0x0F9              | unused              | -  |
|            | ︙                | ︙                  | ︙  |
|            | 0x0FF              | unused              | -  |
|             | 0x100              | 15:9 = unused<br>8 = duty offset[0]<br>7 = delay reset<br>6:0 = delay[0]           | R   |
|            | ︙                | ︙                  | ︙  |
|            | 0x0F8              | 15:9 = unused<br>8 = duty offset[248]<br>7 = delay reset<br>6:0 = delay[248]         | R   |
|            | 0x1F9              | unused              | -  |
|            | ︙                | ︙                  | ︙  |
|            | 0x1FF              | unused              | -  |

* The timing of delay is initialized at the rising and falling edge of delay reset.

### PointSequence operation (seq mode == 0)

| BRAM_SELECT | BRAM_ADDR (16bit) | DATA (64 bit)                                                                       | R/W |
|-------------|-------------------|--------------------------------------------------------------------------------------|-----|
| 0x3         | 0x0000            | 63:62 = unused<br>61:54 = duty[0]<br>53:36 = z[0]<br>35:18 = y[0]<br>17:0 = x[0]   | R   |
|            | ︙                | ︙                                                                                   | ︙  |
|            | 0xFFFF            | 63:62 = unused<br>61:54 = duty[65535]<br>53:36 = z[65535]<br>35:18 = y[65535]<br>17:0 = x[65535] | R   |

* Each position is represented by an 18-bit signed fixed-point number with a unit of λ/256.

### GainSequence operation (seq mode == 1)

| BRAM_SELECT | BRAM_ADDR (16bit) | DATA (64 bit)                                                                       | R/W |
|-------------|-------------------|--------------------------------------------------------------------------------------|-----|
| 0x3         | 0x0000            | 15:0 = duty[0][0]/phase[0][0]<br>︙<br>63:48 = duty[0][3]/phase[0][3]                | R   |
|            | ︙                 | ︙                                                                                   | ︙   |  
|             | 0x003E            | 15:0 = duty[0][248]/phase[0][248]<br>63:16 = unused                                 | ︙   |
|             | 0x003F            | unused                                                                              | ︙   |
|             | 0x0040            | 15:0 = duty[1][0]/phase[1][0]<br>︙<br>63:48 = duty[1][3]/phase[1][3]               | ︙   |
|            | ︙                | ︙                                                                                   | ︙   |
|             | 0x1FFFE            | 15:0 = duty[2047][248]/phase[2047][248]<br>63:16 = unused                                 | ︙   |
|          | 0x1FFFF            | unused                                                                                | R   |

# Author

Shun Suzuki, 2020-2021
