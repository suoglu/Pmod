# Pmod TC1

## Contents of Readme

1. About
2. Brief information about Pmod TC1
3. Interface Description
4. Simulation
5. Tests
6. Status Information

---

## About

Simple interface for the [Digilent Pmod TC1](https://reference.digilentinc.com/reference/pmod/pmodtc1/start) or any other module with [MAX31855](https://datasheets.maximintegrated.com/en/ds/MAX31855.pdf).

## Brief information about Pmod TC1

The [Digilent Pmod TC1](https://reference.digilentinc.com/reference/pmod/pmodtc1/start) is a K-Type Thermocouple Module. It contains [Maxim Integrated's MAX31855](https://datasheets.maximintegrated.com/en/ds/MAX31855.pdf) cold-junction compensated thermocouple-to-digital converter. Module communicates with the host board via SPI protocol.

## Interface Description

This interface can be used to gather data from Pmod [TC1](https://reference.digilentinc.com/reference/pmod/pmodtc1/start) (or anything else that use [MAX31855](https://datasheets.maximintegrated.com/en/ds/MAX31855.pdf)) easily.

Any of the `update`, `update_fault` and `update_all` can be held high for continuous reading. Output data register values are not valid when `busy` is set.

**IOs:**

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   |   I   | 1 | System Clock (Max 100 MHz)|
|  `rst`   |   I   | 1 | System Reset |
|  `clk_spi`   |   I   | 1 | SPI Clock Input (Max 5 MHz) |
|  `SCLK`   |   O   | 1 | SPI Clock Pin |
|  `MISO`   |   I   | 1 | SPI MISO Data Pin |
|  `CS`   |   O   | 1 | SPI Chip Select Pin |
|  `update`   |   I   | 1 | Update Termocoupled Temperature Register |
|  `update_fault`   |   I   | 1 | Update Termocoupled Temperature and Fault Register |
|  `update_all`   |   I   | 1 | Update All Registers |
|  `busy`   |   O   | 1 | Module is working and data outputs are not valid |
|  `temperature_termoc`   |   O   | 14 | Thermocouple Temperature Data |
|  `temperature_internal`   |   O   | 12 | Reference Junction Temperature Data |
|  `status`   |   O   | 3 | Fault flags, {Vcc,GND,Open} |
|  `fault`   |   O   | 1 | Indicates a fault in Termocouple |

I: Input  O: Output

**(Synthesized) Utilization on Artix-7 XC7A35T-1CPG236C:**

* Slice LUTs: 39 (as Logic)
* Slice Registers: 77 (76 as Flip Flop and 1 as Latch)

## Simulation

[TC1](https://reference.digilentinc.com/reference/pmod/pmodtc1/start) is simulated in [sim.v](Simulation/sim.v). Alterating MISO is generated. Pulses of `update`, `update_fault` and `update_all` as well as keeping `update_all` high simulated.

## Test

The [TC1](https://reference.digilentinc.com/reference/pmod/pmodtc1/start) interface module tested with test module [tc1_test_module.v](Test/tc1_test_module.v) and constrains [Basys3.xdc](Test/Basys3.xdc).

[tc1_test_module.v](Test/tc1_test_module.v) is used to control input and outputs of [tc1.v](Sources/tc1.v). `clk_spi` connected to a 5 MHz clock. Same named ports of [tc1_test_module.v](Test/tc1_test_module.v) and [tc1.v](Sources/tc1.v) connected to each other. SPI signals and `busy` signal are copied to upper JB header and monitored via [DDiscovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start). The Pmod [TC1](https://reference.digilentinc.com/reference/pmod/pmodtc1/start) is connected to upper JC header.

`temperature_termoc` is displayed on seven segment display. Left most LED is connected to `fault`, following 3 LEDs are connected to `status` and remaining LEDs are connected to `temperature_internal`. Buttons are used to get pulse input and switches are used to get continuous reading.

|   Connected Signal   | Push Button | Switch |
| :------: | :----: | :----: |
|  `update`   |   *btnU*   | *sw[0]* |
|  `update_fault`   |   *btnR*   | *sw[1]* |
|  `update_all`   |   *btnD*   | *sw[2]* |

## Status Information

**Last simulation:** 25 April 2021, with [Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado/simulator.html).

**Last test:** 25 April 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
