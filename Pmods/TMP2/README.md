# Pmod TMP2

## Contents of Readme

1. About
2. Brief information about Pmod TMP3
3. Interface Description
4. Tests
5. Status Information
6. Issues

---

## About

Simple interface for the [Digilent Pmod TMP2](https://reference.digilentinc.com/reference/pmod/pmodtmp2/start).

## Brief information about Pmod TMP3

The [Digilent Pmod TMP2](https://reference.digilentinc.com/reference/pmod/pmodtmp2/start) is a Temperature Sensor. It contains [Analog Devices ADT7420](https://www.analog.com/media/en/technical-documentation/data-sheets/ADT7420.pdf) 16-Bit Digital Temperature Sensor with ±0.25°C accuracy. Module communicates with the host board via I²C protocol.

## Interface Description

This interface can be used to gather data from Pmod [TMP2](https://reference.digilentinc.com/reference/pmod/pmodtmp2/start) (or anything else that use [ADT7420](https://www.analog.com/media/en/technical-documentation/data-sheets/ADT7420.pdf)) easily.

**IOs:**

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   |   I   | 1 | System Clock |
|  `rst`   |   I   | 1 | System Reset |
|  `clkI2Cx2`   |   I   | 1 | I²C Clock source |
|  `SCL`   |   IO   | 1 | I²C Clock Pin |
|  `SDA`   |   IO   | 1 | I²C Data Pin |
|  `address_bits`   |   I   | 2 | Address Ports of the [ADT7420](https://www.analog.com/media/en/technical-documentation/data-sheets/ADT7420.pdf) |
|  `shutdown`   |   I   | 1 | Shutdown the module |
|  `resolution`   |   I   | 1 | Increase resolution, 16 bit vs 13 bit |
|  `sps1`   |   I   | 1 | Enable 1 SPS mode, one measurent per second |
|  `comparator_mode`   |   I   | 1 | Enable comparator mode, when low interrupt mode enabled |
|  `polarity_ct`   |   I   | 1 | Polarity of CT Pin |
|  `polarity_int`   |   I   | 1 | Polarity of INT Pin |
|  `fault_queue`   |   I   | 2 | Fault queue configuration |
|  `i2cBusy`   |   O   | 1 | I²C in use by another master |
|  `busy`   |   O   | 1 | Module in I²C in transmisson |
|  `sw_rst`   |   I   | 1 | Software reset the [ADT7420](https://www.analog.com/media/en/technical-documentation/data-sheets/ADT7420.pdf) |
|  `update`   |   I   | 1 | Get temperature reading |
|  `one_shot`   |   I   | 1 | Get one shot measurement, does not read the result |
|  `write_temperature`   |   I   | 1 | Write to temperature register |
|  `write_temp_target`   |   I   | 2 | Choose target temperature register |
|  `valid_o`   |   O   | 1 | Value in `temperature_o` valid |
|  `temperature_o`   |   O   | 16 | Temperature output |
|  `temperature_i`   |   O   | 16 | Temperature input |

I: Input  O: Output

**Note:** `rst` will also software resets the [ADT7420](https://www.analog.com/media/en/technical-documentation/data-sheets/ADT7420.pdf).

**Note:** Maximum frequency of `clkI2Cx2` is 800 kHz, `SCL` will have half of this frequency (400 kHz). However during testing `SCL` frequencies above 263 kHz showed some problems during transmisson, 250 kHz worked without issues.

|   `write_temp_target`   | Register name | Width |
| :------: | :----: | :----: |
|  *0x0*   |   Hysteresis   | 8 bits (only lower 4 bits are used) |
|  *0x1*   |   Critical   | 16 bits |
|  *0x2*   |   Low   | 16 bits |
|  *0x3*   |   High   | 16 bits |

**(Synthesized) Utilization on Artix-7 XC7A35T-1CPG236C:**

* Slice LUTs: 76 (as Logic)
* Slice Registers: 54 (as Flip Flop)

## Test

The [TMP2](https://reference.digilentinc.com/reference/pmod/pmodtmp2/start) interface module tested with test module [tester_tmp2.v](Test/tester_tmp2.v) and constrains [Basys3.xdc](Test/Basys3.xdc).

Test module handles getting data and commands from board IO and controls interface module accrodingly. A 500 kHz clock applied to `clkI2Cx2`. Read temperature measurements displayed on seven segment displays. I²C pins connected to upper JB header. I²C pins and alert pin are monitored via [DDiscovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start). Up push button used to enable/disable shutdown mode. Left push button writes the switch value in to high temperature register. Bottom push button changes configuration, taken from switches. Right push button and/or leftmost switch is used to get new reading.

Reading measurements, shutdown mode, writing to temperature registers, interrupt pin, one shot mode, changing configurations and software reset are tested.

## Status Information

**Last test:** 29 April 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).

## Issues

* Some issues with `SCL` frequency. See the notes in *Interface Description* section.
