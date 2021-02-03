/* ------------------------------------------------ *
 * Title       : Full Version Test Module           * 
 * Project     : Pmod HYGRO interface               *
 * ------------------------------------------------ *
 * File        : testBoard_full.v                   *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 03/02/2021                         *
 * ------------------------------------------------ *
 * Description : Test module for full version of    * 
 *               Pmod HYGRO interface               *
 * ------------------------------------------------ */

// `include "Pmods/HYGRO/Sources/hygro.v"
// `include "Utils/ssd_util.v"
// `include "Utils/btn_debouncer.v"

module full_test(
  input clk,
  input rst,
  inout SCL, //JB3
  inout SDA, //JB4
  input btnR, //measureT
  input btnL, //measureH
  input btnU, //SWRTS
  output newData, //JA1
  output dataUpdating, //JA3
  output sensNR, //Led 0
  input [15:0] sw, 
  output [3:0] an,
  output [6:0] seg);
  wire measureT, measureH, TRes, heater, acMode;
  wire [1:0] HRes;
  wire [13:0] tem, hum, currentD;

  assign currentD = (sw[0]) ? hum : tem;
  assign acMode = sw[15];
  assign TRes = sw[14];
  assign HRes = sw[13:12];
  assign heater = sw[11];

  ssdController4 ssd_cntr(clk, rst, 4'b1111, {currentD[13:10]}, currentD[9:6], currentD[5:2], {currentD[1:0], 2'd0}, seg, an);
  debouncer btnDB0(clk, rst, btnR, measureT);
  debouncer btnDB1(clk, rst, btnL, measureH);
  debouncer btnDB2(clk, rst, btnU, swRst);

  hygro uut(clk,rst,measureT,measureH,newData,dataUpdating,sensNR,tem,hum,heater,~acMode,TRes,HRes,swRst,SCL,SDA);
 endmodule