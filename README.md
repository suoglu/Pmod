# Pmod Collection

## Contents of Readme

1. About
2. List of Available Pmods
3. Information about Test Codes

[![Repo on GitLab](https://img.shields.io/badge/repo-GitLab-6C488A.svg)](https://gitlab.com/suoglu/pmod)
[![Repo on GitHub](https://img.shields.io/badge/repo-GitHub-3D76C2.svg)](https://github.com/suoglu/Pmod)

---

## About

This repository contains interfaces for some of the [Digilent Pmod](https://reference.digilentinc.com/reference/pmod/start)s. More information about individual modules is available on their directory.

## List of Available Pmods

|   Name   | Bus | ICs | Description | Notes |
| :------: | :----: | :----: | ------ | ------ |
|  AD1   |   SPI   | [AD7476A](https://www.analog.com/media/cn/technical-documentation/evaluation-documentation/AD7476A_7477A_7478A.pdf) | Analog-to-digital converter | - |
|  AMP3   |  GPIO/I²C  | [SSM2518](https://www.analog.com/media/en/technical-documentation/data-sheets/SSM2518.pdf) | Stereo Power Amplifier  | Not working |
|  COLOR   |   I²C   | [TCS3472](https://ams.com/documents/20143/36005/TCS3472_DS000390_3-00.pdf/6fe47e15-e32f-7fa7-03cb-22935da44b26) | Color Sensor Module | - |
|  DA2   |   GPIO   | [DAC121S101-Q1](https://www.ti.com/lit/ds/symlink/dac121s101.pdf) | Digital-to-analog converter | - |
|  HYGRO   |   I²C   | [HDC1080](https://www.ti.com/lit/ds/symlink/hdc1080.pdf) | Relative humidity and temperature sensor | - |
|  KYPD   |   GPIO   | none | 4x4 Keypad | - |
|  MIC3   |   SPI   | [ADCS7476](http://www.ti.com/lit/ds/symlink/adcs7476.pdf), [SPA2410LR5H-B](https://reference.digilentinc.com/_media/reference/pmod/pmodmic3/mic3microphone_datasheet.pdf) | Small microphone module | Needs more verification |

## Information about Test Codes

Test modules use utility modules such as button debouncers. Verilog code for these utility modules can be found in [Utils](Utils) directory of this repository, as well as their own [repository](https://gitlab.com/suoglu/verilog-utilty-modules).
