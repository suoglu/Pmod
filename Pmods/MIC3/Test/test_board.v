/* ------------------------------------------------ *
 * Title       : Pmod MIC3 interface test board     *
 * Project     : Pmod MIC3 interface                *
 * ------------------------------------------------ *
 * File        : test_board.v                       *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 12/12/2020                         *
 * ------------------------------------------------ *
 * Description : Test interface using LEDs          *
 * ------------------------------------------------ */

//`include "Sources/mic3.v"
//`include "Test/btn_debouncer.v"

module board(
  input clk,
  input rst,
  input MISO, //P3
  output CS, //P1
  output SPI_SCLK, //P4
  input sw,
  input btnR,
  output [15:0] led);
  wire [11:0] audio;
  wire new_data;
  wire read, single;

  assign read = single | sw;

  debouncer dbounce(clk, rst, btnR, single);

  //Monitor audio from LEDs
  assign led[0]  = (audio > 12'd241);
  assign led[1]  = (audio > 12'd482);
  assign led[2]  = (audio > 12'd723);
  assign led[3]  = (audio > 12'd964);
  assign led[4]  = (audio > 12'd1205);
  assign led[5]  = (audio > 12'd1446);
  assign led[6]  = (audio > 12'd1686);
  assign led[7]  = (audio > 12'd1927);
  assign led[8]  = (audio > 12'd2168);
  assign led[9]  = (audio > 12'd2409);
  assign led[10] = (audio > 12'd2650);
  assign led[11] = (audio > 12'd2891);
  assign led[12] = (audio > 12'd3132);
  assign led[13] = (audio > 12'd3373);
  assign led[14] = (audio > 12'd3614);
  assign led[15] = (audio > 12'd3855);
  
  mic3 uut(clk, rst, SPI_SCLK, CS, MISO, read, audio, new_data);
endmodule//board