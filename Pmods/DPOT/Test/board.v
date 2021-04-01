/* ------------------------------------------------ *
 * Title       : Pmod DPOT test board               *
 * Project     : Pmod DPOT interface                *
 * ------------------------------------------------ *
 * File        : board.v                            *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 01/04/2021                         *
 * ------------------------------------------------ *
 * Description : Test code for Pmod DPOT interface  *
 * ------------------------------------------------ */

module testboard(
  input clk,
  input rst,
  output nCS,
  output MOSI,
  output SCLK,
  input [7:0] sw,
  input update,
  output ready);
  
  wire spi_clk_i;

  dpot uut(rst, nCS, MOSI, SCLK, spi_clk_i, sw, update, ready);
  clkDiv4 clkGen(clk, rst, spi_clk_i);
endmodule