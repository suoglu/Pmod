# Pmod DPOT

## Contents of Readme

1. About
2. Brief information about Pmod DPOT
3. Standalone
   1. Interface Description
   2. Simulation
   3. Test
4. IP Core
   1. Basic Information on IP
   2. Interfaces/Ports
   3. Register Map
   4. Utilization
5. Status Information

---

## About

Simple interface for the [Digilent Pmod DPOT](https://reference.digilentinc.com/reference/pmod/pmoddpot/start). SPI protocol is used to communicate with [AD5160](https://www.analog.com/media/en/technical-documentation/data-sheets/AD5160.pdf).

## Brief information about Pmod DPOT

The [Digilent Pmod DPOT](https://reference.digilentinc.com/reference/pmod/pmoddpot/start) contains a [Analog Devices AD5160](https://www.analog.com/media/en/technical-documentation/data-sheets/AD5160.pdf) digital potentiometer. [AD5160](https://www.analog.com/media/en/technical-documentation/data-sheets/AD5160.pdf) can be utilized in two diffrent way: a rheostat where users set a desired resistance between one outside terminal and the wiper terminal or in a voltage divider mode where the two outside terminals are powered at set voltages and a ratio of resistance is specified.

## Standalone

### Standalone Interface Description

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

### Standalone Simulation

Modules `dpot` and `autoUpdate` simulated on [sim.v](Simulation/sim.v).

### Standalone Test

Module `dpot` tested with [board.v](Test/board.v) and [Basys3.xdc](Test/Basys3.xdc) with clock divider `clkDiv`. Module `autoUpdate` is not tested. `update` connected to leftmost switch and `value` is connected to eight rightmost switches. Pmod [DPOT](https://reference.digilentinc.com/reference/pmod/pmoddpot/start) used as voltage divider. Approximately  1 V applied between ports A and B. Voltage value of port W observed with [OpenScope MZ](https://reference.digilentinc.com/reference/instrumentation/openscope-mz/start).

## IP Core

### Basic Information on IP

IP core provides a basic interface with [DPOT](https://reference.digilentinc.com/reference/pmod/pmoddpot/start) (or any other [AD5160](https://www.analog.com/media/en/technical-documentation/data-sheets/AD5160.pdf)) with [AXI4-Lite](https://developer.arm.com/documentation/ihi0022/latest) protocol.

### Interfaces/Ports

- AXI4-Lite
  - Following ports are not implemented:
    - Write strobes (WSTRB)
    - Non-secure and Secure accesses (AxPROT)
- External SPI Clock Input
  - Clock to be used in SPI connection, max 25 MHz.
- SPI
  - nCS: Chip Select
  - SCLK: SPI clock
  - MISO: Data channel

### Register Map

**0x0 Potentiometer Value:**

Read and write to control potentiometer value. This is the only register in this IP.

### (Synthesized) Utilization of IP on Artix-7

- Slice LUTs as Logic: 69
- Slice Registers as Flip Flop: 54
- Slice Registers as Latch: 8

## Status Information

### Standalone Status

**Last simulation:** 1 April 2021, with [Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado/simulator.html).

**Last test:** 1 April 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).

### IP Status

**Last simulation:** 24 December 2021, with [Icarus Verilog](http://iverilog.icarus.com).

**Last test:** 24 December 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
