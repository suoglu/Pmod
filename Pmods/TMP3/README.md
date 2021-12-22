# Pmod TMP3

## Contents of Readme

1. About
2. Brief information about Pmod TMP3
3. Interface Description
4. Tests
5. Status Information
6. Issues

---

## About

Simple interface for the [Digilent Pmod TMP3](https://reference.digilentinc.com/reference/pmod/pmodtmp3/start) or any other module with [TCN75A](https://ww1.microchip.com/downloads/en/DeviceDoc/21935D.pdf).

## Brief information about Pmod TMP3

The [Digilent Pmod TMP3](https://reference.digilentinc.com/reference/pmod/pmodtmp3/start) is a Temperature Sensor. It contains [Microchip's TCN75A](https://ww1.microchip.com/downloads/en/DeviceDoc/21935D.pdf) 2-Wire Serial Temperature Sensor. [TCN75A](https://ww1.microchip.com/downloads/en/DeviceDoc/21935D.pdf) digital  temperature sensor converts temperatures between -40°C and +125°C to a digital word, with ±1°C (typical) accuracy. Module communicates with the host board via I²C protocol.

## Interface Description

his interface can be used to gather data from Pmod [TMP3](https://reference.digilentinc.com/reference/pmod/pmodtmp3/start) (or anything else that use [TCN75A](https://ww1.microchip.com/downloads/en/DeviceDoc/21935D.pdf)) easily.

**IOs:**

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   |   I   | 1 | System Clock |
|  `rst`   |   I   | 1 | System Reset |
|  `clkI2Cx2`   |   I   | 1 | I²C Clock source |
|  `SCL`   |   IO   | 1 | I²C Clock Pin |
|  `SDA`   |   IO   | 1 | I²C Data Pin |
|  `address_bits`   |   3   | 1 | Address pins of [TCN75A](https://ww1.microchip.com/downloads/en/DeviceDoc/21935D.pdf) |
|  `shutdown`   |   I   | 1 | Shutdown module |
|  `resolution`   |   I   | 2 | Measurement resolution |
|  `alert_polarity`   |   I   | 1 | Alert polarity |
|  `fault_queue`   |   I   | 2 | Fault queue configuration |
|  `interrupt_mode`   |   I   | 1 | Enable alert interrupt mode |
|  `i2cBusy`   |   O   | 1 | I²C in use by another master |
|  `busy`   |   O   | 1 | Module in I²C in transmission |
|  `update`   |   I   | 1 | Get temperature reading |
|  `write_temperature`   |   I   | 1 | Write to temperature register |
|  `write_hyst_nLim`   |   I   | 1 | Choose temperature register; 1: Hyst, 0: Limit |
|  `valid_o`   |   O   | 1 | Value in `temperature_o` valid |
|  `temperature_o`   |   O   | 12 | Temperature output |
|  `temperature_i`   |   O   | 9 | Temperature input |

I: Input  O: Output

\* contain pins \_i, \_o and \_t

**Note:** Maximum frequency of `clkI2Cx2` is 800 kHz, `SCL` will have half of this frequency.

**(Synthesized) Utilization on Artix-7 XC7A35T-1CPG236C:**

* Slice LUTs: 61 (as Logic)
* Slice Registers: 52 (as Flip Flop)

## Test

The [TMP3](https://reference.digilentinc.com/reference/pmod/pmodtmp3/start) interface module tested with test module [tester_tmp3.v](Test/tester_tmp3.v) and constrains [Basys3.xdc](Test/Basys3.xdc).

Test module handles getting data and commands from board IO and controls interface module accordingly. A 800 kHz clock applied to `clkI2Cx2`. Leftmost switch is connected to `shutdown`, following switch to `write_hyst_nLim`. Next switch used to read temperature continuously. Remaining switches used to gather data. Upper button used to write to temperature registers, bottom button to update configurations and right to get a new reading. Read temperature measurements displayed on seven segment displays. I²C pins connected to upper JB header. I²C pins and alert pin are monitored via [DDiscovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start).

Reading measurements, shutdown mode, writing to temperature registers and all alert options are tested.

## Status Information

**Last test:** 27 April 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).

## Issues

* Some glitches in `SDA`, only when `SCL` is low.
* Some issues with on board pull-up resistors.
* Continuous read from temperature register causes NACK after a few reads (~13). This doesn't brake the system.
