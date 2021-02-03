# Pmod KYPD

## Contents of Readme

1. About
2. Brief information about Pmod KYPD
3. Interface Description
4. Test
5. Status

---

## About

Decoder for the [Digilent Pmod KYPD](https://reference.digilentinc.com/reference/pmod/pmodkypd/start).

## Brief information about Pmod KYPD

The [Digilent Pmod KYPD](https://reference.digilentinc.com/reference/pmod/pmodkypd/start) is a 4x4 keypad with pull-up resistors in row nets.

## Interface Description

Port discriptions of the interface module can be found below.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock (100 MHz) |
|  `rst`   | I | 1 | System Reset |
|  `row`   | I | 4 | Row pins |
|  `col`   | O | 4 | Column pins |
|  `buttons` | O | 16 | Decoded buttons |
|  `num_val` | O | 4 | Numaric key number |

I: Input  O: Output

**NOTE:**

* Multiple presses on same column is detected however not on same row.

* `num_val` shows higher key when multiple keys are pressed.

**Mapping for `buttons`**

| 15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| F | E | D | C | B | A | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |

## Test

Module `kypd` tested with [kypdTest.v](Test/kypdTest.v) and [Basys3.xdc](Test/Basys3.xdc). [Pmod KYPD](https://reference.digilentinc.com/reference/pmod/pmodkypd/start) connected to JC header and `num_val` connected to upper JB header. Post `buttons` is connected to LEDs.

## Status Information

**Last test:** 3 Fabruary 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
