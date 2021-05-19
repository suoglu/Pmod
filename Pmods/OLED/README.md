# Pmod OLED

## Contents of Readme

1. About
2. Brief information about Pmod OLED
3. Interface Description
    1. `oled`
        1. Description
        2. Ports
        3. Character Mapping
        4. Utilization
    2. `oled_raw`
        1. Description
        2. Ports
        3. Utilization
4. Simulation
5. Tests
6. Status Information

---

## About

Simple interface for the [Digilent Pmod OLED](https://reference.digilentinc.com/reference/pmod/pmodoled/start).

## Brief information about Pmod OLED

The [Digilent Pmod OLED](https://reference.digilentinc.com/reference/pmod/pmodoled/start) is 128 x 32 Pixel Monochromatic OLED Display module. The [Pmod OLED](https://reference.digilentinc.com/reference/pmod/pmodoled/start) utilizes a [Solomon Systech SSD1306](https://cdn-shop.adafruit.com/datasheets/SSD1306.pdf) display controller to receive information from the host board and display the desired information on the [OLED screen](https://cdn-shop.adafruit.com/datasheets/UG-2832HSWEG04.pdf). Module communicates with the host board via SPI protocol.

An alternative breakout board that can be used with modules here is [Adafruit 128x32 SPI OLED display](https://learn.adafruit.com/monochrome-oled-breakouts/wiring-128x32-spi-oled-display).

The [Pmod OLED](https://reference.digilentinc.com/reference/pmod/pmodoled/start) needs Start-up sequence. Implemented Start-up sequence follows as:

1. Power up VDD
2. 100 ms wait
3. Power up VBAT
4. 4µs Reset
5. 1 ms wait
6. Send display off command
7. 2 ms wait
8. Send initilization commands
   1. Charge pump enable (0x8D-0x14)
   2. Set pre-charge period (0xD9-0xF1)
   3. Column inversion enable (0xA1)
   4. Invert COM Output Scan Direction (0xC8)
   5. COM pins configuration (0xDA-0x22)
   6. Set addressing mode to Horizontal (0x20-0x00)
9. 100 ms wait

Similarly there is a shutdown sequance:

1. Power down VBAT
2. 100 ms wait
3. Power down VDD

Before refreshing screen contents following commands are send:

1. Set Column Address (0x21-0x00-0x7F)
2. Set Page Address (0x22-0x00-0x03)
3. Set High Column to 0 (0x10)

With 2,5 MHz SPI clock, screen refresh takes 1,66 ms.

## Interface Description

### `oled`

Module `oled` provides a basic screen interface with coded characters, easily selectable line count and a cursor. This modules rely on an external decoder, such as `oled_decoder`, to generate 8x8 bitmap from 8 bit code.

**Ports of `oled`**

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: | ------ |
|  `clk`   |   I   | 1 | System Clock |
|  `rst`   |   I   | 1 | System Reset |
|  `ext_spi_clk`   |   I   | 1 | External SPI Clock |
|  `character_code`   |   O   | 1 | Character code to be decoded |
|  `current_bitmap`   |   I   | 64 | Decoded 8x8 bitmap |
|  `CS`   |   O   | 1 | SPI Chip Select |
|  `MOSI`   |   O   | 1 | SPI Data |
|  `SCK`   |   O   | 1 | SPI Clock |
|  `data_command_cntr`   |   O   | 1 | Data/~Command for Data |
|  `power_rst`   |   O   | 1 | Reset pin of the Display |
|  `vbat_c`   |   O   | 1 | Active low VBAT control |
|  `vdd_c`   |   O   | 1 | Active low VDD control |
|  `power_on`   |   I   | 1 | Power on module |
|  `display_reset`   |   I   | 1 | Reset display |
|  `display_off`   |   I   | 1 | Turn off display |
|  `update`   |   I   | 1 | Update display content |
|  `display_data`   |   I   | 512 | Display data |
|  `line_count`   |   I   | 2 | Number of display lines |
|  `contrast`   |   I   | 8 | DisplayContrast |
|  `cursor_enable`   |   I   | 1 | Enable cursor |
|  `cursor_flash`   |   I   | 1 | Cursor flashes |
|  `cursor_pos`   |   I   | 6 | Position of cursor |

I: Input  O: Output

`ext_spi_clk` frequency should be the double of desired SPI clock frequency. During testing 5 MHz `ext_spi_clk` is used.

|   `line_count`   | Line Count |
| :------: | :----: |
| *2'b11* | 4 |
| *2'b10* | 3 |
| *2'b01* | 2 |
| *2'b00* | 1 |

| `current_bitmap` |  | |
| ------: | :----: | :----: |
| [63] | ... | [56] |
| ... | ... | ... |
| [7] | ... | [0] |

| `display_data` |  | |
| ------: | :----: | :----: |
| [511:504] | ... | [391:384] |
| ... | ... | ... |
| [127:120] | ... | [7:0] |

**Character Mapping for `oled_decoder`:**

Full list is available at [wiki](https://gitlab.com/suoglu/pmod/-/wikis/OLED/Character-Mapping-Table).

Codes *0x00* - *0x5e* corresponds to ASCII table *0x20* - *0x7e*.

Unused codes will be displayed as empty.

Mapping can be edited easily via localparameters of `oled_decoder`. New characters can be appended by adding a new code as localparameter and bitmap to following case statement. Or compeletly new decoder module can be used.

**(Synthesized) Utilization of `oled`:**

- On Artix-7 XC7A35T-1CPG236C:
  - Slice LUTs: 316 (as Logic)
  - Slice Registers: 117 (as Flip Flop)
  - F7 Muxes: 72
  - F8 Muxes: 32

**(Synthesized) Utilization of `oled_decoder`:**

- On Artix-7 XC7A35T-1CPG236C:
  - Slice LUTs: 234 (as Logic)

## Simulation

Module `oled` simulated on [oled_sim.v](Simulation/oled_sim.v). In simulation delay times reduced to 1/1000th. Only a simple update and power up sequence is simulated.

## Test

### `oled` Test

Module `oled` is tested on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual) with [oled_test.v](Test/oled_test.v) and [Basys3.xdc](Test/Basys3.xdc). Block diagram for this test can be generated via [design_1.tcl](Test/design_1.tcl). Missing utility modules can be found under [Utils](Utils/) directory of this repository. Module `oled` is tested with the [Digilent Pmod OLED](https://reference.digilentinc.com/reference/pmod/pmodoled/start) and [Adafruit 128x32 SPI OLED display](https://learn.adafruit.com/monochrome-oled-breakouts/wiring-128x32-spi-oled-display).

Testing module in [oled_test.v](Test/oled_test.v) handles the board connections. Display signals are connected to both JB and JC header. Leftmost switch is used as power on switch, second leftmost switch is used as display on switch. Switches 9 and 8 is used to determine line count. 8 right most switches are used to get data. Depending on which button is pressed, data handled diffrently. Up button configures the cursor. Left button changes contrast. Right button saves the current data and shifts it into the next position in display. Down button is used to reset display. Display signals are monitored with [Digital Discovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start).

## Status Information

**Last simulation:** 13 May 2021, with [Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado/simulator.html).

**Last test:** 19 May 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
