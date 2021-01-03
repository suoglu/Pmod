/* ------------------------------------------------ *
 * Title       : Test module Pmod AD1 interface     *
 * Project     : Pmod AD1 interface                 *
 * ------------------------------------------------ *
 * File        : test_board.v                       *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 03/01/2021                         *
 * ------------------------------------------------ *
 * Description : Test module for Pmod AD1           *
 * ------------------------------------------------ */

//  `include "Pmods/AD1/Sources/ad1.v"
//  `include "Pmods/AD1/Test/ssd_util.v"
//  `include "Pmods/AD1/Test/btn_debouncer.v"

module board(
  input clk,
  input rst,
  input btnR,
  input cont,
  input SDATA,
  output SCLK,
  output CS,
  output updatingData,
  output [3:0] an,
  output [6:0] seg,
  output tx);
  wire [11:0] dat;
  wire single, getData;
  reg [11:0] data;

  assign getData = cont | single;

  always@(negedge updatingData)
    begin
      data <= dat;
    end
  

  AD1clockGEN_20MHz40 clkGENad1(clk, CS, SCLK);
  ssdController4 ssd_cntr(clk, rst, 4'b0111, , data[11:8], data[7:4], data[3:0], seg, an);
  debouncer btnDB(clk, rst, btnR, single);
  ad1 uut(clk, rst, SCLK, SDATA, CS, getData, updatingData, dat);
 endmodule