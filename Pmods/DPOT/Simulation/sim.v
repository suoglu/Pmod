/* ------------------------------------------------ *
 * Title       : Pmod DPOT interface Simulation     *
 * Project     : Pmod DPOT interface                *
 * ------------------------------------------------ *
 * File        : sim.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 01/04/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation code for Pmod DPOT      *
 *               interface                          *
 * ------------------------------------------------ */

`timescale 1ns / 1ps
//`include "Pmods/DPOT/Sources/dpot.v"

module tb();
  reg clk, rst, update;
  wire nCS, MOSI, spi_clk_i, SCLK, ready;
  reg [7:0] value;

  always #5 clk <= ~clk;

  dpot uut(rst, nCS, MOSI, SCLK, spi_clk_i, value, update, ready);
  clkDiv4 clkGen(clk, rst, spi_clk_i);

  initial
    begin
      clk <= 0;
      update <= 0;
      rst <= 0;
      value <= 8'hA5;
      #7
      rst <= 1;
      #10
      rst <= 0;
      #50
      update <= 1;
      #50
      update <= 0;
      #200
      value <= 8'hCE;
      #400
      update <= 1;
    end
endmodule