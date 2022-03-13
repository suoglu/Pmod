# Pmod AD1

## Contents of Readme

1. About
2. Brief information about Pmod AD1
3. Native Interface Core
   1. Modules
   2. Interface Description
   3. Utilization
   4. Simulation
   5. Test
4. AXI4-Lite IP Core
   1. Basic Information on IP
   2. Interfaces/Ports
   3. Register Map
   4. Utilization
5. Status Information

---

## About

Simple interface for the [Digilent Pmod AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start). This interface uses modified version of my [SPI](https://gitlab.com/suoglu/spi) master module.

## Brief information about Pmod AD1

The [Digilent Pmod AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start) contains two [Analog Devices AD7476A](https://www.analog.com/media/cn/technical-documentation/evaluation-documentation/AD7476A_7477A_7478A.pdf) 12 bit analog-to-digital converters. Module communicates with the host board via SPI-like protocol.

## Native Interface

### Native Interface Modules

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

### Native Interface Description

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

### Native Interface Core (Synthesized) Utilization (On Artix-7)

|   Module   | Slice LUTs as Logic | Slice Registers as FF |
| :------: | :----: | :----: |
| `ad1` | 6 | 19 |
| `ad1_dual` | 7  | 31 |
| `AD1clockGEN_16_67MHz` | 2 | 3 |
| `AD1clockGEN_20MHz40` | 2 | 3 |
| `AD1clockEN` | 1 | 1 |

### Native Interface Simulation

Module simulated in [sim.v](Simulation/sim.v). `SDATA` is connected to a  10 MHz clock signal.

### Native Interface Test

Module is tested on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual) with [test_board.v](Test/test_board.v). Module `ad1` tested with `AD1clockGEN_20MHz40`. [AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start) connected to JB, and convertion results shown at seven segment display. Arbitary voltage level provided from DC power supply of [OpenScope MZ](https://reference.digilentinc.com/reference/instrumentation/openscope-mz/start?redirect=1).

## AXI4-Lite IP Core

### Basic Information on IP

IP core provides a basic interface to [AD1](https://reference.digilentinc.com/reference/pmod/pmodad1/start) (or any other [AD7476A](https://www.analog.com/media/cn/technical-documentation/evaluation-documentation/AD7476A_7477A_7478A.pdf)) with [AXI4-Lite](https://developer.arm.com/documentation/ihi0022/latest) protocol.

When dual mode disabled, only one of the data channels is active.

When blocking mode enabled, reading from a data register starts a new measurement. Otherwise, writing to a data register starts a new measurement.

When update both enabled, starting a measurement saves the data from both channels. Otherwise, only initiated channels data is updated.

### Interfaces/Ports

- AXI4-Lite
  - Following ports are not implemented:
    - Write strobes (WSTRB)
    - Non-secure and Secure accesses (AxPROT)
- External SPI Clock Input
  - Clock to be used in SPI connection, max 20 MHz.
- SPI
  - CS: Chip Select
  - SCK: SPI clock
  - D0: Data channel 0 MISO
  - D1: Data channel 1 MISO (Only in dual mode)

### Register Map

**0x0 Data Channel 0:**

Writing starts a new measurement. In blocking mode, reading also starts a new measurement.

**0x4 Data Channel 1:**

Writing starts a new measurement. In blocking mode, reading also starts a new measurement. Valid only in dual mode.

**0x8 Status Register:**

|31:2|1|0|
|:---:|:---:|:---:|
|Reserved|Dual Mode|Busy|

- Dual Mode: Dual channel implementation.
- Busy: On going measurement.

**0xC Configuration Register:**

|31:2|1|0|
|:---:|:---:|:---:|
|Reserved|Update Both|Blocking Read|

- Update Both: Any measurement updates both of the data registers.
- Blocking Read: Read from data registers start a new measurement. Read is done after measurement is complicated.

### (Synthesized) Utilization of IP on Artix-7

**Dual Channel Mode:**

- Slice LUTs as Logic: 55
- Slice Registers as Flip Flop: 54

**Single Channel Mode:**

- Slice LUTs as Logic: 40
- Slice Registers as Flip Flop: 41

## Status Information

### Native Interface Status

**Last simulation:** 3 January 2021, with [Icarus Verilog](http://iverilog.icarus.com).

**Last test:** 3 January 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).

### AXI4-Lite IP Status

**Last simulation:** 12 December 2021, with [Icarus Verilog](http://iverilog.icarus.com).

**Last test:** 12 December 2021, on [Digilent Arty A7](https://digilent.com/reference/programmable-logic/arty-a7/reference-manual).
