# Pmod OLED

## Contents of Readme

1. About
2. Brief information about Pmod OLED
3. Interface Description
4. Character Mapping
5. Simulation
6. Tests
7. Status Information

---

## About

Simple interface for the [Digilent Pmod OLED](https://reference.digilentinc.com/reference/pmod/pmodoled/start).

## Brief information about Pmod OLED

The [Digilent Pmod OLED](https://reference.digilentinc.com/reference/pmod/pmodoled/start) is 128 x 32 Pixel Monochromatic OLED Display module. The [Pmod OLED](https://reference.digilentinc.com/reference/pmod/pmodoled/start) utilizes a [Solomon Systech SSD1306](https://cdn-shop.adafruit.com/datasheets/SSD1306.pdf) display controller to receive information from the host board and display the desired information on the [OLED screen](https://cdn-shop.adafruit.com/datasheets/UG-2832HSWEG04.pdf). Module communicates with the host board via SPI protocol.

Workin progress...

## Interface Description

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   |   I   | 1 | System Clock |
|  `rst`   |   I   | 1 | System Reset |

I: Input  O: Output

Work in progress...

## Character Mapping

|   Character Code   |  Displayed | Description |
| :------: | :----: |  ------ |
| *0x00* |  | Empty/Space |
| *0x01* | ! | Exclamation mark |

Work in progress...

Codes *0x00* - *0x5e* corresponds to ASCII table *0x20* - *0x7e*.

Unused codes will be displayed as empty.

Mapping can be edited easily via localparameters of `decode8x8`. New characters can be appended by adding a new code as localparameter and bitmap to following case statement.

## Simulation

Work in progress...

## Test

Work in progress...

## Status Information

**Last simulation:** 13 May 2021, with [Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado/simulator.html).

**Last test:** XXX, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
