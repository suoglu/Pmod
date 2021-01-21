# Pmod AD1

## Contents of Readme

1. About
2. Brief information about Pmod AD1
3. Modules
4. Interface Description
5. Simulation
6. Test
7. Status Information

---

## About

Simple interface for the [Digilent Pmod AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start). This interface uses modified version of my [SPI](https://gitlab.com/suoglu/spi) master module.

## Brief information about Pmod AD1

The [Digilent Pmod AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start) contains two [Analog Devices AD7476A](https://www.analog.com/media/cn/technical-documentation/evaluation-documentation/AD7476A_7477A_7478A.pdf) 12 bit analog-to-digital converters. Module communicates with the host board via SPI-like protocol.

## Modules

**`ad1`**

Gathers data from one of the ADC channels of [AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start).

**`ad1_dual`**

Gathers data from both of the ADC channels of [AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start). Active channel can be controlled with `activeCH` signal.

**`AD1clockGEN_16_67MHz`**

Generates 16,67 MHz 50% duty cycle SCLK for [AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start) serial interface.

**`AD1clockGEN_20MHz40`**

Generates 20 MHz 40% duty cycle SCLK for [AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start) serial interface.

**`AD1clockEN`**

Generates a SCLK for [AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start) serial interface from an external clock.

## Interface Description

This interface can be used to gather data from Pmod [AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start) (or any other [AD7476A](https://www.analog.com/media/cn/technical-documentation/evaluation-documentation/AD7476A_7477A_7478A.pdf)) easily.

**AD1 Modules:**

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock (100 MHz) |
|  `rst`   | I | 1 | System Reset |
|  `SCLK`   | I | 1 | Serial Clock |
|  `SDATA`   | I | 1/2 | Serial Data |
|  `CS`   | O | 1 | Chip Select |
|  `getData`   | I | 1 | Initiate a new conversion, hold high for continuous conversion |
|  `updatingData`   | O | 1 | Data registers are being updated, thus not valid |
|  `activeCH`   | I | 0/2 | Activates the reading of corresponding channel |
|  `data`   | O | 12 | Last read conversion results |

I: Input  O: Output

**Clock Generation Modules:**

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock (100 MHz) |
|  `CS`   | I | 1 | Chip select from AD1 Modules |
|  `SCLK`   | O | 1 | Generated Serial Clock |
|  `SCLK_i`   | I | 1 | External Clock for Serial Clock generation |
|  `SCLK_o`   | O | 1 | Generated Serial Clock |

I: Input  O: Output

**Note:** `clk` should be faster than `SCLK_i`.

## Simulation

Module simulated in [sim.v](Simulation/sim.v). `SDATA` is connected to a  10 MHz clock signal.

## Test

Module is tested on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual) with [test_board.v](Test/test_board.v). Module `ad1` tested with `AD1clockGEN_20MHz40`. [AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start) connected to JB, and convertion results shown at seven segment display. Arbitary voltage level provided from DC power supply of [OpenScope MZ](https://reference.digilentinc.com/reference/instrumentation/openscope-mz/start?redirect=1).

## Status Information

**Last simulation:** 3 January 2021, with [Icarus Verilog](http://iverilog.icarus.com).

**Last test:** 3 January 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
