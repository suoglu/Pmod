# Pmod HB3

## Contents of Readme

1. About
2. Brief information about Pmod HB3
3. Interface Description
4. Simulation
5. Test
6. Status Information
7. Issues

---

## About

Simple interface for the [Digilent Pmod HB3](https://reference.digilentinc.com/pmod/pmodhb3/start).

## Brief information about Pmod HB3

The [Digilent Pmod HB3](https://reference.digilentinc.com/pmod/pmodhb3/start) contains a 2A H-Bridge circuit with external feedback to drive small to medium sized DC motors. It has an external voltage source for the DC motor.

## Interface Description

Module `hb3` provides a motor interface with 256 speed levels. It ensures that no potential short happens within the circuitry, by never changing `motor_direction` when `motor_enable` is set. It will clear `motor_enable`, will change `motor_direction` next cycle, and then set `motor_enable` back next cycle if needed. However, it will drive the motor in the opposite direction with `speed` immediately afterwards. The module also does not have any offset, so for some low `speed` values the motor may not turn.

|   Port   | Type | Width |  Description |
| :------: | :----: | :----: |  ------  |
| `clk` | I | 1 | System Clock |
| `rst` | I | 1 | System Reset |
| `motor_direction` | O | 1 | Direction Pin for the Motor |
| `motor_enable` | O | 1 | Enable Pin for the Motor |
| `direction_control` | I | 1 | Direction Control |
| `speed` | I | 8 | Speed Control |

I: Input  O: Output

### (Synthesized) Utilization

**On Artix-7:**

- Slice LUTs: 15 (as Logic)
- Slice Registers: 10 (as Flip Flop)
- F7 Muxes: 1

## Simulation

Simulation testbench can be found in [sim_hb3.v](Simulation/sim_hb3.v). Testbench simulates various speeds, including full stop and full speed, as well as changing direction in full speed.

## Test

Module `hb3` direcly with [Basys3.xdc](Test/Basys3.xdc). First `motor_direction` and `motor_enable` pins are monitored with [DDiscovery](https://reference.digilentinc.com/reference/instrumentation/digital-discovery/start). After that an actual DC motor with small fan attached to it is tested. 7,5 V power source is attached to motor power pins of the [Pmod HB3](https://reference.digilentinc.com/pmod/pmodhb3/start) Fan attached DC motor begin turning (very slow) when speed was *0x31* (~1.43 V), and was power full enough at *0xFF* to move the FPGA, the breadboard and the DC motor itself.

## Status Information

**Last Simulation:** 28 May 2021, with [Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado/simulator.html).

**Last test:** 28 May 2021, on [Digilent Basys 3](https://reference.digilentinc.com/reference/programmable-logic/basys-3/reference-manual).
