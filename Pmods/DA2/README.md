# Pmod DA2

## Contents of Readme

1. About
2. Brief information about Pmod DA2
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

Simple interface for the [Digilent Pmod DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start).

## Brief information about Pmod DA2

The [Digilent Pmod DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start) is a 2 channel 12-bit Digital-to-Analog Converter module capable of outputting data up to 16.5 MSa. It contains two [Texas Instruments DAC121S101](https://www.ti.com/lit/ds/symlink/dac121s101.pdf)s.

## Native Interface

### Native Interface Modules

**`da2`**

Sets the output value for one of the channels of the [DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start) or any other [DAC121S101](https://www.ti.com/lit/ds/symlink/dac121s101.pdf).

**`da2_dual`**

Controls both channels of the [DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start).

**`clkDiv25en`**

Clock divider to generate 25 MHz SCLK from 100 MHz system clock. It can be disabled.

**`da2AutoUpdate`** and **`da2AutoUpdate_dual`**

Generate `update` automatically when `value` and/or `chmod` changes.

**`da2ClkEn`**

Can be used to generate SCLK from external clock source. It does not change clock frequnecy but disables it when not in use.

### Native Interface Ports

***Note:** Dual modules has two bit `SDATA` and two `chmod` and `value` ports, one for each channel.*

**`da2`** and **`da2_dual`**

This interface can be used to gather data from Pmod [DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start) (or any other [DAC121S101](https://www.ti.com/lit/ds/symlink/dac121s101.pdf)) easily.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock |
|  `rst`   | I | 1 | System Reset |
|  `SCLK`   | I | 1 | Serial Clock |
|  `SDATA`   | O | 1 | Serial Data |
|  `SYNC`   | O | 1 | Sync signal |
|  `working`   | O | 1 | Enable Serial Clock |
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
|  `clk`   | I | 1 | System Clock |
|  `rst`   | I | 1 | System Reset |
|  `SYNC`   | I | 1 | Sync signal |
|  `chmod`   | I | 2 | Channel Mode |
|  `value`   | I | 12 | Channel Value |
|  `update`   | O | 1 | Update the output values |

**`da2ClkEn`**

This module generates `SCLK` from `ext_spi_clk`.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock |
|  `en`   | I | 1 | Enable Serial Clock |
|  `ext_spi_clk`   | I | 1 | SPI clock source |
|  `SCLK`   | O | 1 | Serial Clock |

### Native Interface (Synthesized) Utilization on Artix-7

|   Module   | Slice LUTs as Logic | Slice Registers as FF | Slice Registers as Latch |
| :------: | :----: | :----: | :----: |
| `da2` | 63 | 37 | 14 |
| `da2_dual` | 117  | 66 | 28 |
| `clkDiv25en` | 3 | 2 | 0 |
| `da2AutoUpdate` | 5 | 14 | 0 |
| `da2AutoUpdate_dual` | 11 | 28 | 0 |
|`da2ClkEn`  | 1 | 1 | 0 |

### Native Interface Simulation

Module simulated in [sim.v](Simulation/sim.v).

### Native Interface Test

Interface module tested on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual) with [test.v](Test/test.v). A sawtooth value generator is implemented to generate dynamic `value` signal. Implemented generator can generate increasing or decreasing sawtooth signal, controled by the third left most switch. Source of the `value` signal can be controled via the second left most switch, and it can be either sawtooth generator or right most switches. Value of the switches shown on seven segment displays. Port `update` connected to right button and left most switch. And Pmod connecter to upper part of JB. Output of the [DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start) monitored using the oscilloscope of the [OpenScope MZ](https://reference.digilentinc.com/reference/instrumentation/openscope-mz/start).

## AXI4-Lite IP Core

### Basic Information on IP

IP core provides a basic interface to [DA2](https://reference.digilentinc.com/reference/pmod/pmodda2/start) (or any other [DAC121S101](https://www.ti.com/lit/ds/symlink/dac121s101.pdf)) with [AXI4-Lite](https://developer.arm.com/documentation/ihi0022/latest) protocol.

When dual mode disabled, only one of the data channels is active.

In fast update mode; when refresh bit is set during a write to configuration register, remaining bits are ignored and not changed.

When buffering mode enabled; writing to data registers does not automatically update DAC outputs, a refresh is needed.

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
  - DA: Data channel 0 MOSI
  - DB: Data channel 1 MOSI (Only in dual mode)

### Register Map

**0x0 Data Channel A:**

Channel A output value. Writing updates the output value when buffering mode is not enabled.

**0x4 Data Channel B:**

Channel B output value. Writing updates the output value when buffering mode is not enabled. Valid only in dual mode.

**0x8 Status Register:**

|31:4|3|2|1|0|
|:---:|:---:|:---:|:---:|:---:|
|Reserved|Fast Refresh HW|Dual Mode|Data Invalid|Busy|

- Fast Refresh HW: Fast refresh implementation.
- Dual Mode: Dual channel implementation.
- Data Invalid: The data on IP and the output of the DAC are not the same.
- Busy: On going transmission.

**0xC Configuration Register:**

|31:2|6|5:4|3:2|1|0|
|:---:|:---:|:---:|:---:|:---:|:---:|
|Reserved|Fast Refresh|PDM B|PDM A|Refresh|Buffering Mode|

- Fast refresh: Software fast refresh mode. When enabled; setting refresh bit makes other bits to be ignored while writing to the configuration register.
- PDM: Power down mode for respective channels. PDM B is only valid in dual mode. See below for power down modes.
- Refresh: Update DAC output with IP values.
- Buffering Mode: Disables auto refreshing when data registers or power down modes were written.

**Power Down Modes:**

|Value|Mode|
|:---:|---|
|0x0|Normal Operation|
|0x1|1kΩ to ground|
|0x2|100kΩ to ground|
|0x3|High Impedance|

### (Synthesized) Utilization of IP on Artix-7

**Dual Channel Mode:**

- Slice LUTs as Logic: 79
- Slice Registers as Flip Flop: 94

**Single Channel Mode:**

- Slice LUTs as Logic: 53
- Slice Registers as Flip Flop: 55

**Dual Channel Mode with fast refresh implementation:**

- Slice LUTs as Logic: 78
- Slice Registers as Flip Flop: 94

## Status Information

### Native Interface Status

**Last simulation:** 6 January 2021, with [Icarus Verilog](http://iverilog.icarus.com).

**Last test:** 27 May 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).

### AXI4-Lite IP Status

**Last simulation:** 28 February 2022, with [Icarus Verilog](http://iverilog.icarus.com).

**Last test:** 13 March 2021, on [Digilent Arty A7](https://digilent.com/reference/programmable-logic/arty-a7/reference-manual).
