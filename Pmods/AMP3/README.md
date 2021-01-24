# Pmod AMP3

## Contents of Readme

1. About
2. Brief information about Pmod AMP3
3. IOs of Modules
4. Simulation
5. Test
6. Status Information
7. Possible Future Improvements
8. Issues

---

## About

**NOT WORKING!**

Simple interface for the [Digilent Pmod AMP3](https://reference.digilentinc.com/reference/pmod/pmodamp3/start).

## Brief information about Pmod AMP3

The [Digilent Pmod AMP3](https://reference.digilentinc.com/reference/pmod/pmodamp3/start) is a Stereo Power Amplifier. It features an [Analog Devices SSM2518](https://www.analog.com/media/en/technical-documentation/data-sheets/SSM2518.pdf) 2 Watt Class-D Audio Power Amplifier. The Pmod [AMP3](https://reference.digilentinc.com/reference/pmod/pmodamp3/start) can be used in a stand-alone mode or with I²C interface.

## Interface Description

**`amp3_Lite`:**

**NOT WORKING!**

Module `amp3_Lite` communicate [AMP3](https://reference.digilentinc.com/reference/pmod/pmodamp3/start) via I²S bus. Parameter `dataW` corresponds to the size of the audio date registers, default is 12 bits to match Pmod [MIC3](https://reference.digilentinc.com/reference/pmod/pmodmic3/start).

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: |  ------  |
| `clk` | I | 1 | System Clock |
| `rst` | I | 1 | System Reset |
| `SDATA` | O | 1 | Serial Data Line |
| `BCLK` | O | 1 | Bit Clock |
| `LRCLK` | O | 1 | Left-right clock |
| `nSHUT` | O | 1 | Active Low Shutdown signal |
| `dataR` | I | `dataW` | Right Channel Data |
| `dataL` | I | `dataW` | Left Channel Data |
| `enable` | I | 1 | Enable the interface |
| `RightNLeft` | O | 1 | `LRCLK` without shift |

I: Input  O: Output

## Simulation

**`amp3_Lite`:**

Module `amp3_Lite` simulated with [simlite.v](Simulation/simlite.v). Constant values 0xFFF and 0x000 are applied to channels.

## Test

**`amp3_Lite`:**

**NOT WORKING!**

[testBoard.v](Test/testBoard.v) is used to test `amp3_Lite`. Additionaly [MIC3](MIC3/Sources/mic3.v) interface is used in [testBoard.v](Test/testBoard.v). Audio data gathered with MIC3 and send to AMP3. `amp3_Lite` is not working currently.

## Status Information

**Last Simulation:** 24 January 2021, with [Icarus Verilog](http://iverilog.icarus.com).

**Last Test:** Failed

## Possible Future Improvements

- I²C interface with configurations

## Issues

- `amp3_Lite` does not work
