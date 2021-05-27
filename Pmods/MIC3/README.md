# Pmod MIC3

## Contents of Readme

1. About
2. Brief information about Pmod MIC3
3. Interface Description
4. Simulation
5. Tests
6. Status Information

---

## About

Simple interface for the [Digilent Pmod MIC3](https://reference.digilentinc.com/reference/pmod/pmodmic3/start). This interface uses simplified version of my [spi](https://gitlab.com/suoglu/spi) master module.

## Brief information about Pmod MIC3

The [Digilent Pmod MIC3](https://reference.digilentinc.com/reference/pmod/pmodmic3/start) is microphone module with a digital interface. It contains a [Knowles Acoustics SPA2410LR5H-B](https://reference.digilentinc.com/_media/reference/pmod/pmodmic3/mic3microphone_datasheet.pdf) MEMs microphone and [Texas Instrument ADCS7476](http://www.ti.com/lit/ds/symlink/adcs7476.pdf) 12-bit ADC. Module communicates with the host board via SPI protocol.

## Interface Description

This interface can be used to gather data from Pmod [MIC3](https://reference.digilentinc.com/reference/pmod/pmodmic3/start) (or anything else that use [ADCS7476](http://www.ti.com/lit/ds/symlink/adcs7476.pdf)) easily.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   |   I   | 1 | System Clock |
|  `rst`   |   I   | 1 | System Reset |
|  `ext_spi_clk`   |   I   | 1 | SPI clock source |
|  `SCLK`   |   O   | 1 | SPI Clock |
|  `CS`   |   O   | 1 | SPI Chip (Slave) select |
|  `MISO`   |   I   | 1 | SPI Master In Slave Out |
|  `read`   |   I   | 1 | Initiate a new read, keep high for continuous reading |
|  `audio`   |   O   | 12 | Most recent read data |
|  `new_data`   |   O   | 1 | Pulse to indicate new data is ready |

I: Input  O: Output

Maximum frequency for `ext_spi_clk` is 20 MHz. In continuous reading mode, a new data is avaible every 1,28µs (781,25 kS/s) with 12,5 MHz `ext_spi_clk`. Later, recording with certain bitrates will be implemented (#8).

### (Synthesized) Utilization

**On Artix-7:**

- Slice LUTs: 9 (as Logic)
- Slice Registers: 33 (as Flip Flop)

## Simulation

Module simulated in [sim.v](Simulation/sim.v). MISO signal inverted every 70ns to obtain different readings.

## Test

### Test 1

Module is tested on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual) with [test_board.v](Test/test_board.v). A very simple test module is implemented. Audio output of the interface connected to LEDs. Right button is used to get a single reading. Right most switch is used to enable continuous read mode. [Pmod MIC3](https://reference.digilentinc.com/reference/pmod/pmodmic3/start) is connected to upper part of Pmod port B (JB1-4).

### Test 2

Second test utilizes pmod [DA2](Pmods/DA2) to output read audio data from pmod [MIC3](https://reference.digilentinc.com/reference/pmod/pmodmic3/start). [testBoard_dacOut.v](Test/testBoard_dacOut.v) and [Basys3_da_test.xdc](Test/Basys3_da_test.xdc) are used in second test. Analog output monitored via [OpenScope MZ](https://reference.digilentinc.com/reference/instrumentation/openscope-mz/start). Sinusoidal and triangular tones of different frequencies are applied and observed.

## Status Information

**Last simulation:** 12 December 2020, with [Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado/simulator.html).

**Last test:** 27 May 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
