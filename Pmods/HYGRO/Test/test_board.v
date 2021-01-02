/* ------------------------------------------------ *
 * Title       : Test module Pmod HYGRO interface   *
 * Project     : Pmod HYGRO interface               *
 * ------------------------------------------------ *
 * File        : test_board.v                       *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 01/01/2021                         *
 * ------------------------------------------------ *
 * Description : Test module for Pmod HYGRO         *
 * ------------------------------------------------ */

// `include "Pmods/HYGRO/Sources/hygro.v"
// `include "Pmods/HYGRO/Test/ssd_util.v"
// `include "Pmods/HYGRO/Test/btn_debouncer.v"

module lite_test(
  input clk,
  input rst,
  output SCL, //JB3
  inout SDA, //JB4
  input btnR, //Measure
  output newData, //JA1
  output i2c_busy, //JA2
  output dataUpdating, //JA3
  output sensNR, //Led 0
  input [0:0] sw, //O: Temp, 1: Humd
  output [3:0] an,
  output [6:0] seg);
  wire measure;
  wire [13:0] tem, hum, currentD;

  assign currentD = (sw) ? hum : tem;

  ssdController4 ssd_cntr(clk, rst, 4'b1111, {currentD[13:10]}, currentD[9:6], currentD[5:2], {currentD[1:0], 2'd0}, seg, an);
  debouncer btnDB(clk, rst, btnR, measure);
  hygro_lite uut_lite(clk, rst, measure, newData, i2c_busy, dataUpdating, sensNR, tem, hum, SCL, SDA);
 endmodule