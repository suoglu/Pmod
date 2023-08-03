# Pmod CON3

## Contents of Readme

1. About
2. Brief information about Pmod CON3
3. Interface Description
4. Simulation
5. Test
6. Status Information
7. Issues
8. Licence

---

## About

Simple interface for the [Digilent Pmod CON3](https://reference.digilentinc.com/pmod/pmodcon3/start).

## Brief information about Pmod CON3

The [Digilent Pmod CON3](https://reference.digilentinc.com/pmod/pmodcon3/start) is servo motor interface, that can interface four servo motors.

## Interface Description

Module `con3` drives `servo` signal with repetitive set of cycles. There are three diffrent type of cycles:

- High Cycle
- Modulated Cycle
- Low cycle

Number of high cycles and low cycles can be controlled with parameters `HIGH_CYCLE` and `LOW_CYCLE` respectively. Duration of a cycle is determined by the period of `clk_256kHz`, which should be 1 / 256 of the desired duration of for a cycle. For 1 ms cycle duration, 256 kHz free running clock should be supplied to `clk_256kHz`. `clk_256kHz` can be generated with `con3_clk_gen` for 1 ms cycles. Parameter `CLK_PERIOD` corresponds to system clock parameter in ns. Resulting period of `servo` can be calculated via (`HIGH_CYCLE` + `LOW_CYCLE` + *1*) * [period of a cycle]. `angle` value determines the duration of high value for `servo` in the modulated cycle.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: |  ------  |
| `clk` | I | 1 | System Clock |
| `rst` | I | 1 | System Reset |
| `clk_256kHz` | I | 1 | Cycle Clock |
| `en` | I | 1 | Enable |
| `servo` | O | 1 | Servo output |
| `angle` | I | 8 | Angle |

I: Input  O: Output

### (Synthesized) Utilization

**On Artix-7:**

`con3` with `HIGH_CYCLE` = *1* and `LOW_CYCLE` = *2*:

- Slice LUTs: 16 (as Logic)
- Slice Registers: 12 (as Flip Flop)

`con3` with `HIGH_CYCLE` = *1* and `LOW_CYCLE` = *1*:

- Slice LUTs: 15 (as Logic)
- Slice Registers: 12 (as Flip Flop)

`con3` with `HIGH_CYCLE` = *1* and `LOW_CYCLE` = *18*:

- Slice LUTs: 18 (as Logic)
- Slice Registers: 15 (as Flip Flop)

`con3_clk_gen` with `CLK_PERIOD` = *10*

- Slice LUTs: 10 (as Logic)
- Slice Registers: 9 (as Flip Flop)

## Simulation

Modules `con3` and `con3_clk_gen` is simulated in [con3_sim.v](Simulation/con3_sim.v). Modules `con3` simulated with 4 diffrent parameter combinations.

## Test

Modules `con3` and `con3_clk_gen` is tested with [con3_tester.v](Test/con3_tester.v) and [Arty-A7-100.xdc](Test/Arty-A7-100.xdc). TCL script [design_con3.tcl](Test/design_con3.tcl) generate test block diagram automatically. Test block diagram includes  four `con3` modules with diffrent parameter values. All connected to same inputs, each driving diffrent servo pins of [Pmod CON3](https://reference.digilentinc.com/pmod/pmodcon3/start). [Tester module](Test/con3_tester.v) includes an uart interface, which sets `angle` to incoming byte and then echos incoming byte back. Switch 3 is used to enable `con3` modules. Uart configurations are 8 bit data, 1 bit stop bit, no parity with 115200 baud rate.

Initially `servo` pins are monitored with [DDiscovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start). After that, they were connected to a Tower Pro SG90 RC Mini Servo Motor to verify further.

## Status Information

**Last Simulation:** 30 May 2021, with [Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado/simulator.html).

**Last test:** 30 May 2021, on [Digilent Arty A7](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/start).

## License

CERN Open Hardware Licence Version 2 - Weakly Reciprocal
