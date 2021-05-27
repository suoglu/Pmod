/* ------------------------------------------------ *
 * Title       : Pmod DA2 interface test            *
 * Project     : Pmod DA2 interface                 *
 * ------------------------------------------------ *
 * File        : test.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 06/01/2021                         *
 * ------------------------------------------------ *
 * Description : Test code for Pmod DA2 interface   *
 * ------------------------------------------------ */

//`include "Pmods/DA2/Sources/da2.v"
//`include "Utils/ssd_util.v"
//`include "Utils/btn_debouncer.v"

module board(
  input clk,
  input rst,
  input [11:0] sw,
  input btnR,
  input updateC,
  output [3:0] an,
  output [6:0] seg,
  input enR,
  input inR, 
  output SCLK,
  output SDATA,
  output SYNC);
  wire updateS, update, SCLK_en, SCLK_gen;
  reg [11:0] R_sig;
  wire [11:0] val;

  debouncer btnbd(clk, rst, btnR, updateS);
  da2 uut(clk, rst, SCLK, SDATA, SYNC, SCLK_en, 2'd0, val, update);
  clkDiv25en sclkGEN(clk, rst, 1'b1, SCLK_gen);
  ssdController4 ssdCNTR(clk, rst, 4'b0111, , sw[11:8], sw[7:4], sw[3:0], seg, an);
  da2ClkEn extClkContr(clk,SCLK_en,SCLK_gen,SCLK);
  
  assign update = updateS | updateC;
  assign val = (enR) ? R_sig : sw;
  always@(negedge SYNC or posedge rst)
    begin
      if(rst)
        begin
          R_sig <= 12'd0;
        end
      else
        begin
          R_sig <= R_sig + {11'd0, inR} + ({12{inR}} ^ {11'd0, enR});
        end
    end
endmodule//board