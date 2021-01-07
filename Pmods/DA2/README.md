# Pmod DA2

## Contents of Readme

1. About
2. Brief information about Pmod DA2
3. Modules
4. Interface Description
5. Simulation
6. Test
7. Status Information

---

## About

Simple interface for the [Digilent Pmod DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start).

## Brief information about Pmod DA2

The [Digilent Pmod DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start) is a 2 channel 12-bit Digital-to-Analog Converter module capable of outputting data up to 16.5 MSa. It contains two [Texas Instruments DAC121S101](https://www.ti.com/lit/ds/symlink/dac121s101.pdf)s.

## Modules

**`da2`**

Sets the output value for one of the channels of the [DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start) or any other [DAC121S101](https://www.ti.com/lit/ds/symlink/dac121s101.pdf).

**`da2_dual`**

Controls both channels of the [DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start).

**`clkDiv25en`**

Clock divider to generate 25 MHz SCLK from 100 MHz system clock. It can be disabled.

**`da2AutoUpdate`** and **`da2AutoUpdate_dual`**

Generate `update` automatically when `value` and/or `chmod` changes.

## Interface Description

***Note:** Dual modules has two bit `SDATA` and two `chmod` and `value` ports, one for each channel.*

**`da2`** and **`da2_dual`**

This interface can be used to gather data from Pmod [DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start) (or any other [DAC121S101](https://www.ti.com/lit/ds/symlink/dac121s101.pdf)) easily.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock (100 MHz) |
|  `rst`   | I | 1 | System Reset |
|  `SCLK`   | I | 1 | Serial Clock |
|  `SDATA`   | O | 1 | Serial Data |
|  `SYNC`   | O | 1 | Sync signal |
|  `SCLK_en`   | O | 1 | Enable Serial Clock |
|  `chmod`   | I | 2 | Channel Mode |
|  `value`   | I | 12 | Channel Value |
|  `update`   | I | 1 | Update the output values, keep high to update continuously |

I: Input  O: Output

|   `chmod`   |  Description |
| :------: |  ------ |
|  2'b00   | Normal operation mode |
|  2'b01   | Power off mode, 1 kΩ |
|  2'b10   | Power off mode, 100 kΩ  |
|  2'b11   | Power off mode, High-Z  |

**`clkDiv25en`**

This module generates 25 MHz `SCLK` and can be enabled with `en`.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock (100 MHz) |
|  `rst`   | I | 1 | System Reset |
|  `en`   | I | 1 | Enable Serial Clock |
|  `SCLK`   | O | 1 | Serial Clock |

**`da2AutoUpdate`** and **`da2AutoUpdate_dual`**

These modules sets `update` when `value` or `chmod` changes, and resets when `SYNC` is high. These modules can be used to keep DAC output equal to `value` without manually updating or continuously updating.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock (100 MHz) |
|  `rst`   | I | 1 | System Reset |
|  `SYNC`   | I | 1 | Sync signal |
|  `chmod`   | I | 2 | Channel Mode |
|  `value`   | I | 12 | Channel Value |
|  `update`   | O | 1 | Update the output values |

## Simulation

Module simulated in [sim.v](Simulation/sim.v).

## Test

Interface module tested on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual) with [test.v](Test/test.v). A sawtooth value generator is implemented to generate dynamic `value` signal. Implemented generator can generate increasing or decreasing sawtooth signal, controled by the third left most switch. Source of the `value` signal can be controled via the second left most switch, and it can be either sawtooth generator or right most switches. Value of the switches shown on seven segment displays. Port `update` connected to right button and left most switch. And Pmod connecter to upper part of JB. Output of the [DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start) monitored using the oscilloscope of the [OpenScope MZ](https://reference.digilentinc.com/reference/instrumentation/openscope-mz/start).

## Status Information

**Last simulation:** 6 January 2021, with [Icarus Verilog](http://iverilog.icarus.com).

**Last test:** 6 January 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
