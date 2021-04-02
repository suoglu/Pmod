# Pmod ENC

## Contents of Readme

1. About
2. Brief information about Pmod ENC
3. Interface Description
4. Simulation
5. Test
6. Status Information
7. Warning

---

## About

Simple interface for the [Digilent Pmod ENC](https://reference.digilentinc.com/reference/pmod/pmodenc/start). This will automatically cleans glitches and creates pules for turn directions.

## Brief information about Pmod ENC

The [Digilent Pmod ENC](https://reference.digilentinc.com/reference/pmod/pmodenc/start) is a rotary shaft encoder with an integral push-button and a switch.

## Interface Description

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clkSys`   | I | 1 | System Clock |
|  `rst`   | I | 1 | System Reset |
|  `A`   | I | 1 | A pin of Pmod ENC |
|  `B`   | I | 1 | B pin of Pmod ENC |
|  `dir0`   | O | 1 | Pulse to indicate one click in diraction 0 |
|  `dir1`   | O | 1 | Pulse to indicate one click in diraction 1 |
|  `btn_i`   | I | 1 | Directly connected to `btn_o` |
|  `sw_i`   | I | 1 | Directly connected to `sw_o` |
|  `btn_o`   | O | 1 | Directly connected to `btn_i` |
|  `sw_o`   | O | 1 | Directly connected to `sw_i` |

I: Input  O: Output

There is also an internal clock divider in `enc`. Controller by following parameters:

|   Parameter   | Default Value | Description |
| :------: | :----: | ------ |
|  `DIVIDER_EN`   | 1 | Enable Divider, assign 0 to disable |
| `CLOCKDIVISION` | 10 | Division value |

Cleaning glitches implemented via use of a 16 bit shift register. A and B values are shifted in the register and AND of all bits of corresponding shift register is used as A and B values.

## Simulation

Decoder module, without glitch cleaning and clock dividing hardware, simulated in [sim.v](Simulation/sim.v).

## Test

Module `enc` tested on [test.v](Test/test.v). Positive edges of `dir0` and `dir1` are connected to 4 bit counters. Counter values are displayed on leftmost and rightmost seven segment displays.

## Status Information

**Last simulation:** 5 February 2021, with [Icarus Verilog](http://iverilog.icarus.com).

**Last test:** 2 April 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
