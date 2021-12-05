# Pmod HYGRO

## Contents of Readme

1. About
2. Brief information about Pmod HYGRO
3. Modules
4. Interface Description
5. Utilization
6. Simulation
7. Test
8. Status Information
9. Issues

---

## About

Simple interface for the [Digilent Pmod HYGRO](https://reference.digilentinc.com/reference/pmod/pmodhygro/start). This interface uses simplified version of my [i²c](https://gitlab.com/suoglu/i2c) master module.

## Brief information about Pmod HYGRO

The [Digilent Pmod HYGRO](https://reference.digilentinc.com/reference/pmod/pmodhygro/start) contains a [Texas Instruments HDC1080](https://www.ti.com/lit/ds/symlink/hdc1080.pdf) digital humidity and temperature sensor. Module communicates with the host board via I²C protocol.

## Modules

Two modules were implemented.
Module `hygro_lite` can be used to gather sensor readings using default configurations.
In module `hygro`, sensor configurations can be changed. Both modules use same ports, `hygro` having more ports to control configurations.

## Interface Description

This interface can be used to gather data from Pmod [HYGRO](https://reference.digilentinc.com/reference/pmod/pmodhygro/start) (or any other [HDC1080](https://www.ti.com/lit/ds/symlink/hdc1080.pdf)) easily.

**`hygro_lite`:**

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock |
|  `rst`   | I | 1 | System Reset |
|  `i2c_2clk`   | I | 1 | I²C clock Source (max. 800 kHz) |
| `measure` | I | 1 | Initiate a new measurement |
|  `newData`   | O | 1 | Pulse to indicate new data available |
|  `i2c_busy`   | O | 1 | I²C Bus is busy |
|  `dataUpdating`| O | 1 | Data registers are being updated |
|  `sensNR`   | O | 1 | Sensor is not responding |
|  `tem`   | O | 14 | Most recent temperature reading |
|  `hum`   | O | 14 | Most recent humidity reading |
|  `SCL`   | O | 1 | I²C clock |
|  `SDA`   | IO | 1 | I²C data |

I: Input  O: Output

**`hygro`:**

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock |
|  `rst`   | I | 1 | System Reset |
|  `i2c_2clk`   | I | 1 | I²C clock Source (max. 800 kHz) |
| `measureT` | I | 1 | Initiate a new Temperature measurement |
| `measureH` | I | 1 | Initiate a new Humidity measurement |
|  `newData`   | O | 1 | Pulse to indicate new data available |
|  `dataUpdating`| O | 1 | Data registers are being updated |
|  `sensNR`   | O | 1 | Sensor is not responding |
|  `tem`   | O | 14 | Most recent temperature reading |
|  `hum`   | O | 14 | Most recent humidity reading |
|  `SCL`*   | IO | 1 | I²C clock |
|  `SDA`*   | IO | 1 | I²C data |
|  `heater`   | I | 1 | Heater |
|  `acMode`   | I | 1 | Acquisition Mode  |
| `TRes` | I | 1 | Temperature Measurement Resolution |
|  `HRes`   | I | 2 | Humidity Measurement Resolution  |
|  `swRst`   | I | 1 | Software Reset |

I: Input O: Output

\* contain pins \_i, \_o and \_t

I²C clock source, `i2c_2clk`, should be generated externally. Module `clockGen_i2c` can be used to generate 781,25 kHz I²C clock source (390,62 kHz I²C clock).

## (Synthesized) Utilization

### On Artix-7

|   Module   | Slice LUTs as Logic | Slice Registers as FF | Slice Registers as Latch |
| :------: | :----: | :----: | :----: |
| `hygro_lite` | 50 | 55 | 1 |
| `hygro` | 62 | 69 | 0 |
| `clockGen_i2c` | 7 | 7 | 0 |

## Simulation

Module `hygro` is simulated in [fullsim.v](Simulation/fullsim.v). `SCL` connected to pullup and `SDA` connected to pulldown.

## Test

**`hygro_lite`**

Module `hygro_lite` is tested on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual) with [test_board.v](Test/test_board.v) and [Basys3_lite.xdc](Test/Basys3_lite.xdc). Right button used to initiate new measurement. Measurement results with 2 extra 0s at LSBs shown on seven segment displays. Rightmost switch used to switch between temperature and humidity reading. Pmod [HYGRO](https://reference.digilentinc.com/reference/pmod/pmodhygro/start) connected to upper JB and; `newData`, `i2c_busy` and `dataUpdating` signals connected to JA. `sensNR` signal connected to rightmost LED. I²C, `newData`, `i2c_busy` and `dataUpdating` signals are monitored with [Digital Discovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start).

**`hygro`**

Module `hygro` is tested on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual) with [testboard_full.v](Test/testboard_full.v) and [Basys3_full.xdc](Test/Basys3_full.xdc). Right and left buttons used to initiate new Temperature/Humidity measurements. Upper button does software reset. Leftmost switches are used for configurations. Rightmost switch used to switch between temperature and humidity reading. Pmod [HYGRO](https://reference.digilentinc.com/reference/pmod/pmodhygro/start) connected to upper JB and; `newData` and `dataUpdating` signals connected to JA. `sensNR` signal connected to rightmost LED. I²C signals are monitored with [Digital Discovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start).

## Status Information

**Last test of `hygro_lite`:** 2 January 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).

**Last simulation of `hygro`:** 3 Fabruary 2021, with [Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado/simulator.html).

**Last test of `hygro`:** 3 Fabruary 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).

## Issues

* **In `hygro`:** Changing measurement resolutions doesn't seem to work, even though I²C transmission looks correct.
