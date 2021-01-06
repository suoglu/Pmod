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

|   Name   | Bus | ICs |  Description |
| :------: | :----: | :----: | ------ |
|  MIC3   |   SPI   | [ADCS7476](http://www.ti.com/lit/ds/symlink/adcs7476.pdf), [SPA2410LR5H-B](https://reference.digilentinc.com/_media/reference/pmod/pmodmic3/mic3microphone_datasheet.pdf) | Small microphone module |
|  HYGRO   |   I²C   | [HDC1080](https://www.ti.com/lit/ds/symlink/hdc1080.pdf) | Relative humidity and temperature sensor |
|  AD1   |   SPI   | [AD7476A](https://www.analog.com/media/cn/technical-documentation/evaluation-documentation/AD7476A_7477A_7478A.pdf) | Analog-to-digital converter |
|  DA2   |   SPI   | [DAC121S101-Q1](https://www.ti.com/lit/ds/symlink/dac121s101.pdf) | Digital-to-analog converter |

## Information about Test Codes

Test modules use some utility modules such as button debouncers. Verilog codes for these utility modules can be found in [Utils](Utils) directory of this repository, as well as their own [repository](https://gitlab.com/suoglu/verilog-utilty-modules).
