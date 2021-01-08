# Pmod KYPD

## Contents of Readme

1. About
2. Brief information about Pmod KYPD
3. Interface Description

---

## About

Decoder for the [Digilent Pmod KYPD](https://reference.digilentinc.com/reference/pmod/pmodkypd/start).

## Brief information about Pmod KYPD

The [Digilent Pmod KYPD](https://reference.digilentinc.com/reference/pmod/pmodkypd/start) is a 4x4 keypad with pull-up resistors in row nets.

## Interface Description


|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   | I | 1 | System Clock (100 MHz) |
|  `rst`   | I | 1 | System Reset |
|  `row`   | I | 4 | Row pins |
|  `col`   | O | 4 | Column pins |
|  `buttons`   | O | 16 | Decoded buttons |

I: Input  O: Output

**Mapping for `buttons`**

| 15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| F | E | D | C | B | A | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
