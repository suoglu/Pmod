# Pmod DPOT

## Contents of Readme

1. About
2. Brief information about Pmod DPOT
3. Interface Description
4. Simulation
5. Test
6. Status Information
7. Warning

---

## About

Simple interface for the [Digilent Pmod DPOT](https://reference.digilentinc.com/reference/pmod/pmoddpot/start). SPI protocol is used to communicate with [AD5160](https://www.analog.com/media/en/technical-documentation/data-sheets/AD5160.pdf).

## Brief information about Pmod DPOT

The [Digilent Pmod DPOT](https://reference.digilentinc.com/reference/pmod/pmoddpot/start) contains a [Analog Devices AD5160](https://www.analog.com/media/en/technical-documentation/data-sheets/AD5160.pdf) digital potentiometer. [AD5160](https://www.analog.com/media/en/technical-documentation/data-sheets/AD5160.pdf) can be utilized in two diffrent way: a rheostat where users set a desired resistance between one outside terminal and the wiper terminal or in a voltage divider mode where the two outside terminals are powered at set voltages and a ratio of resistance is specified.

## Interface Description

This interface can be used to gather data from Pmod [DPOT](https://reference.digilentinc.com/reference/pmod/pmoddpot/start) (or any other [AD5160](https://www.analog.com/media/en/technical-documentation/data-sheets/AD5160.pdf)) easily.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `rst`   | I | 1 | System Reset |
|  `nCS`   | O | 1 | Active Low Chip Select |
|  `MOSI`   | O | 1 | Serial Data |
|  `SCLK`   | O | 1 | Serial Clock output |
|  `spi_clk_i`   | I | 1 | Serial Clock input |
|  `value`   | I | 8 | Potentiometer value|
|  `update`   | I | 1 | Initiate a new transmission |
|  `ready`   | O | 1 | Module is not busy |

I: Input  O: Output

**Note:** `spi_clk_i` and `SCLK` are the same clock and the maximum allowed frequency is 25 MHz.

25 MHz `spi_clk_i` can be generated from 100 MHz clock with `clkDiv`.

## Simulation

Modules `dpot` and `autoUpdate` simulated on [sim.v](Simulation/sim.v).

## Test

Module `dpot` tested with [board.v](Test/board.v) and [Basys3.xdc](Test/Basys3.xdc) with clock divider `clkDiv`. Module `autoUpdate` is not tested. `update` connected to leftmost switch and `value` is connected to eight rightmost switches. Pmod [DPOT](https://reference.digilentinc.com/reference/pmod/pmoddpot/start) used as voltage divider. Approximately  1 V applied between ports A and B. Voltage value of port W observed with [OpenScope MZ](https://reference.digilentinc.com/reference/instrumentation/openscope-mz/start).

## Status Information

**Last simulation:** 1 April 2021, with [Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado/simulator.html).

**Last test:** 1 April 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
