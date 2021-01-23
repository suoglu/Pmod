# Pmod COLOR

## Contents of Readme

1. About
2. Brief information about Pmod COLOR (and TCS3472)
3. Interface Description
4. Test
5. Status Information
6. Issues
7. Possible Future Improvements

---

## About

Simple interface for the [Digilent Pmod COLOR](https://reference.digilentinc.com/reference/pmod/pmodcolor/start) or any other [TCS3472](https://ams.com/documents/20143/36005/TCS3472_DS000390_3-00.pdf/6fe47e15-e32f-7fa7-03cb-22935da44b26). This interface uses modified version of my [I²C](https://gitlab.com/suoglu/i2c) module.

## Brief information about Pmod COLOR (and TCS3472)

The [Digilent Pmod COLOR](https://reference.digilentinc.com/reference/pmod/pmodcolor/start) contains [AMS TCS3472](https://ams.com/documents/20143/36005/TCS3472_DS000390_3-00.pdf/6fe47e15-e32f-7fa7-03cb-22935da44b26), a color sensor with IR blocking filter. Module communicates with the host board via I²C bus, and has the address of 0x29. Module measures red, green, blue and clear light with 16 bit precision and has adjustable gain.

## Interface Description

**`colorlite` Module:**

Module `colorlite` provides a simple interface for [TCS3472](https://ams.com/documents/20143/36005/TCS3472_DS000390_3-00.pdf/6fe47e15-e32f-7fa7-03cb-22935da44b26) with basic functionality. Module `colorlite` reads red, green and blue data, however not the clear one. Module does not do any calculations on the gathered data, and outputs raw data.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: |  ------  |
| `clk` | I | 1 | System Clock (100MHz) |
| `rst` | I | 1 | System Reset |
| `SCL` | O | 1 | I²C Clock (390.625kHz) |
| `SDA` | IO | 1 | System Reset |
| `LEDenable` | O | 1 | Enable sensor LED for reflective measurement |
| `measure` | I | 1 | Get RGB data, keep high for getting continuously  |
| `enable` | I | 1 | Low: Put sensor in sleep mode, High: Put sensor in RGBC mode  |
| `gain` | I | 2 | Gain setting (Updates automatically when changed) |
| `reflectiveMode` | I | 1 | Reflective measurement mode, enables LED when measuring |
| `red` | O | 16 | Red data |
| `green` | O | 16 | Green data |
| `blue` | O | 16 | Blue data |
| `ready` | O | 1 | Ready for a new measurement |

I: Input  O: Output

## Test

**`colorlite` Module:**

Module `colorlite` tested with [color_test.v](Pmods/COLOR/Test/color_test.v) and [Arty-A7-100-0.xdc](Pmods/COLOR/Test/Arty-A7-100-0.xdc). Two `colorlite` modules are used; one connected to a [Digilent Pmod COLOR](https://reference.digilentinc.com/reference/pmod/pmodcolor/start) other to a [Adafruit TCS34725 Color Sensor](https://learn.adafruit.com/adafruit-color-sensors). Outer RGB LEDs connected to Pmod inners connected to Adafruit sensor. Switch 0 used to enable/disable sensor (by putting it into sleep mode). Switches 2 and 1 are connected to `gain` ports. Switch 3 is connected to `reflectiveMode`. I²C signals and MSByte of RGB data registers (`red`, `green`, `blue`) are monitored with [Digilent Digital Discovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start).

## Status Information

**Last Test:** 21 January 2021, on [Digilent Arty A7](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/start).

## Issues

- Nothing for now

## Possible Future Improvements

- Full module that enables more features, such as interrupts
- Some processing over color data to make it more accurate
