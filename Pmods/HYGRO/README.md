# Pmod HYGRO

## Contents of Readme

1. About
2. Brief information about Pmod HYGRO
3. Modules
4. Interface Description
5. Test
6. Status Information

---

## About

Simple interface for the [Digilent Pmod HYGRO](https://reference.digilentinc.com/reference/pmod/pmodhygro/start). This interface uses simplified version of my [i²c](https://gitlab.com/suoglu/i2c) master module.

## Brief information about Pmod HYGRO

The [Digilent Pmod HYGRO](https://reference.digilentinc.com/reference/pmod/pmodhygro/start) contains a [Texas Instruments HDC1080](https://www.ti.com/lit/ds/symlink/hdc1080.pdf) digital humidity and temperature sensor. Module communicates with the host board via I²C protocol.

## Modules

<!-- Two modules were implemented. -->
Module `hygro_lite` can be used to gather sensor readings using default configurations.
<!-- In module `hygro_full`, sensor configurations can be changed. Both modules use same ports, `hygro_full` having more ports to control configurations. -->

## Interface Description

This interface can be used to gather data from Pmod [HYGRO](https://reference.digilentinc.com/reference/pmod/pmodhygro/start) (or any other [HDC1080](https://www.ti.com/lit/ds/symlink/hdc1080.pdf)) easily.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock (100 MHz) |
|  `rst`   | I | 1 | System Reset |
| `measure` | I | 1 | Initiate a new measurement |
|  `newData`   | O | 1 | Pulse to indicate new data available |
|  `i2c_busy`   | O | 1 | I²C Bus is busy |
|  `dataUpdating`| O | 1 | Data registers are being updated |
|  `sensNR`   | O | 1 | Sensor is not responding |
|  `tem`   | O | 14 | Most recent temperature reading |
|  `hum`   | O | 14 | Most recent humidity reading |
|  `SCL`   | O | 1 | I²C clock (390.625kHz) |
|  `SDA`   | IO | 1 | I²C data |

I: Input  O: Output

## Test

**`hygro_lite`**

Module `hygro_lite` is tested on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual) with [test_board.v](Test/test_board.v). Right button used to initiate new measurement. Measurement results with 2 extra 0s at LSBs shown on seven segment displays. Rightmost switch used to switch between temperature and humidity reading. Pmod [HYGRO](https://reference.digilentinc.com/reference/pmod/pmodhygro/start) connected to upper JB and; `newData`, `i2c_busy` and `dataUpdating` signals connected to JA. `sensNR` signal connected to rightmost LED. I²C, `newData`, `i2c_busy` and `dataUpdating` signals are monitored with [Digital Discovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start).

## Status Information

**Last test of `hygro_lite`:** 2 January 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
