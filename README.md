# Pmod Collection

## Contents of Readme

1. About
2. List of Available Pmods
3. Information about Test Codes
4. Licence

[![Repo on GitLab](https://img.shields.io/badge/repo-GitLab-6C488A.svg)](https://gitlab.com/suoglu/pmod)
[![Repo on GitHub](https://img.shields.io/badge/repo-GitHub-3D76C2.svg)](https://github.com/suoglu/Pmod)

---

## About

This repository contains interfaces for some of the [Digilent Pmod](https://reference.digilentinc.com/reference/pmod/start)s. More information about individual modules is available on their directory.

## List of Available Modules

|   Name   | Bus | Module Interfaces | ICs | Description | Notes |
| :------: | :----: | :----: | :----: | ------ | ------ |
|  [AD1](Pmods/AD1)   |   SPI   |   Native, AXI4-Lite   | [AD7476A](https://www.analog.com/media/cn/technical-documentation/evaluation-documentation/AD7476A_7477A_7478A.pdf) | Analog-to-digital converter | - |
|  [CMPS2](Pmods/CMPS2)   |   I²C   |   Native   | [MMC3416xPJ](http://www.memsic.com/uploadfiles/2020/08/20200827165224614.pdf) |  3-Axis Magnetometer   | - |
|  [COLOR](Pmods/COLOR)   |   I²C   |   Native   | [TCS3472](https://ams.com/documents/20143/36005/TCS3472_DS000390_3-00.pdf/6fe47e15-e32f-7fa7-03cb-22935da44b26) | Color Sensor Module | - |
|  [CON3](Pmods/CON3)   |   GPIO   |   Native   | None |  R/C Servo Connectors  | - |
|  [DA2](Pmods/DA2)   |   GPIO   |   Native, AXI4-Lite   | [DAC121S101-Q1](https://www.ti.com/lit/ds/symlink/dac121s101.pdf) | Digital-to-analog converter | - |
|  [DPOT](Pmods/DPOT)   |   SPI   |   Native, AXI4-Lite   | [AD5160](https://www.analog.com/media/en/technical-documentation/data-sheets/AD5160.pdf) | Digital Potentiometer | - |
|  [ENC](Pmods/ENC)   |   GPIO   |   Native   | None | Rotary Encoder | - |
|  [HB3](Pmods/HB3)   |   GPIO   |   Native   | H-bridge |  H-bridge Driver with Feedback Inputs  | - |
|  [HYGRO](Pmods/HYGRO)   |   I²C   |   Native   | [HDC1080](https://www.ti.com/lit/ds/symlink/hdc1080.pdf) | Relative humidity and temperature sensor | - |
|  [KYPD](Pmods/KYPD)   |   GPIO   |   Native   | None | 4x4 Keypad | - |
|  [MIC3](Pmods/MIC3)   |   SPI   |   Native   | [ADCS7476](http://www.ti.com/lit/ds/symlink/adcs7476.pdf), [SPA2410LR5H-B](https://reference.digilentinc.com/_media/reference/pmod/pmodmic3/mic3microphone_datasheet.pdf) | Small microphone module | - |
|  [OLED](Pmods/OLED)   |   SPI   |   Native   | [SSD1306](https://cdn-shop.adafruit.com/datasheets/SSD1306.pdf), [OLED](https://cdn-shop.adafruit.com/datasheets/UG-2832HSWEG04.pdf) |  128x32 OLED Display  | - |
|  [TC1](Pmods/TC1)   |   SPI   |   Native, AXI4-Lite    | [MAX31855](https://datasheets.maximintegrated.com/en/ds/MAX31855.pdf) | K-Type Thermocouple Module | - |
|  [TMP2](Pmods/TMP2)   |   I²C   |   Native   | [ADT7420](https://www.analog.com/media/en/technical-documentation/data-sheets/ADT7420.pdf) |  Temperature Sensor  | - |
|  [TMP3](Pmods/TMP3)   |   I²C   |   Native   | [TCN75A](https://ww1.microchip.com/downloads/en/DeviceDoc/21935D.pdf) |  Temperature Sensor  | - |

## Information about Test Codes

Test modules use utility modules such as button debouncers. Verilog code for these utility modules can be found in [Utils](Utils) directory of this repository, as well as their own [repository](https://gitlab.com/suoglu/verilog-utilty-modules).

## License

CERN Open Hardware Licence Version 2 - Weakly Reciprocal

---

<small>This repository is not sponsored or endorsed by any organization or anyone.</small>
