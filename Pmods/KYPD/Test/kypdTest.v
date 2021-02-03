/* ------------------------------------------------ *
 * Title       : Pmod KYPD Test                     *
 * Project     : Pmod KYPD                          *
 * ------------------------------------------------ *
 * File        : kypdTest.v                         *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 03/02/2021                         *
 * ------------------------------------------------ *
 * Description : Test for Pmod KYPD                 *
 * ------------------------------------------------ */

module kypd_test(
  input clk,
  input rst,
  output [15:0] led,
  input [3:0] row,
  output [3:0] col,
  output [3:0] num_val);
  
  kypd uur(clk,rst,row,col,led,num_val);
endmodule