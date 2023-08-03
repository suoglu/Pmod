# Pmod CMPS2

## Contents of Readme

1. About
2. Brief information about Pmod CMPS2
3. Interface Description
4. Tests
5. Status Information
6. Issues
7. Licence

---

## About

Simple interface for the [Digilent Pmod CMPS2](https://reference.digilentinc.com/reference/pmod/pmodcmps2/start) or any other module with [MMC3416xPJ](http://www.memsic.com/uploadfiles/2020/08/20200827165224614.pdf).

## Brief information about Pmod TMP3

The [Digilent Pmod CMPS2](https://reference.digilentinc.com/reference/pmod/pmodcmps2/start) is a  3-Axis Magnetometer. It contains [Memsic's MMC3416xPJ](http://www.memsic.com/uploadfiles/2020/08/20200827165224614.pdf) 3-axis Magnetic Sensor.

## Interface Description

Module `cmps2` can be used as a simple interface for the [Pmod CMPS2](https://reference.digilentinc.com/reference/pmod/pmodcmps2/start) (or any other module with [MMC3416xPJ](http://www.memsic.com/uploadfiles/2020/08/20200827165224614.pdf)).

Module `cmps2` offers two measurement modes. Normal measurement (initiated with `measure`) does a set measurement and subtracts existing offsets from measurement results. Calibration measurement (initiated with `calibrate`) does a reset measurement followed by a set measurement. Using these measurement results, calibrated measurement values and new offsets are calculated. Measurement results calculated via *(set results - reset results) / 2* and offset values calculated via *(set results + reset results) / 2*.

**IOs:**

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   |   I   | 1 | System Clock |
|  `rst`   |   I   | 1 | System Reset |
|  `clkI2Cx2`   |   I   | 1 | I²C Clock source |
|  `SCL`*   |   IO   | 1 | I²C Clock Pin |
|  `SDA`*   |   IO   | 1 | I²C Data Pin |
|  `x_axis`   |   O   | 16 | Measurement result for X axis |
|  `y_axis`   |   O   | 16 | Measurement result for Y axis |
|  `z_axis`   |   O   | 16 | Measurement result for Z axis |
|  `resolution`   |   I   | 2 | Resolution configuration of [MMC3416xPJ](http://www.memsic.com/uploadfiles/2020/08/20200827165224614.pdf) |
|  `x_offset`   |   O   | 16 | Calculated offset for X axis |
|  `y_offset`   |   O   | 16 | Calculated offset for Y axis |
|  `z_offset`   |   O   | 16 | Calculated offset for Z axis |
|  `calibrate`   |   I   | 1 | Initiate a measurement with a new calibration |
|  `measure`   |   I   | 1 | Initiate a measurement with using existing calibration |
|  `i2cBusy`   |   O   | 1 | Another master is using I²C bus |
|  `valid`   |   O   | 1 | New measurement results ready and valid |

I: Input  O: Output

\* contain pins \_i, \_o and \_t

**Note:** Maximum frequency of `clkI2Cx2` is 800 kHz, `SCL` will have half of this frequency.

**Timing:**

Time takes from initiation of new measurement and obtaining valid measurement results for diffent cases can be found at the table below.

| `resolution` | `calibrate` | `measure` |
|:---:|:---:|:---:|
| 2'b00 (16 bit)|15,98 ms|7,743ma|
| 2'b01 (16 bit)|8,927 ms|4,217 ms|
| 2'b10 (14 bit)|5,298 ms|2,402 ms|
| 2'b11 (12 bit)|3,485 ms|1,495 ms|

**(Synthesized) Utilization on Artix-7:**

* Slice LUTs: 234 (as Logic)
* Slice Registers: 251 (as Flip Flop)

## Test

The [CMPS2](https://reference.digilentinc.com/reference/pmod/pmodcmps2/start) interface module tested with test module [tester_cmps2.v](Test/tester_cmps2.v) and constrains [Basys3.xdc](Test/Basys3.xdc). I²C pins are monitored via [DDiscovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start). Right button connected to `calibrate`, left button connected to `measure`. Two right most switches are connected to `resolution`. Seven segment display is used to display `x_axis`, `y_axis` and `z_axis`; controled via two left most switches. Output values are also send via UART on positive edge of `valid`. They are send in following order: `x_axis`, `y_axis`, `z_axis`, `x_offset`, `y_offset`, `z_offset`. UART configurations are 115200, 8 bits with no parity and 1 bit stop.

## Status Information

**Last test:** 17 June 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).

## Issues

* For some measurements, least significant bit of the result is wrong, resulting 0.5mG error.

## License

CERN Open Hardware Licence Version 2 - Weakly Reciprocal
