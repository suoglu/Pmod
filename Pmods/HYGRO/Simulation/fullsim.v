/* ------------------------------------------------ *
 * Title       : Full Version Simulation Module     * 
 * Project     : Pmod HYGRO interface               *
 * ------------------------------------------------ *
 * File        : fullsim.v                          *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : /02/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation module for full version * 
 *               of Pmod HYGRO interface            *
 * ------------------------------------------------ */
`timescale 1ns / 1ps

module tb();
  reg clk, rst, measureT,measureH,heater,acMode,TRes,swRst;
  wire newData, dataUpdating, sensNR;
  wire [13:0] tem, hum;
  reg [1:0] HRes;
  wire SCL, SDA;

  always #5 clk <= ~clk;

  hygro uut(clk,rst,measureT,measureH,newData,dataUpdating,sensNR,tem,hum,heater,acMode,TRes,HRes,swRst,SCL,SDA);
  pullup(SCL);
  pulldown(SDA);

  initial
    begin
      measureT <= 0;
      measureH <= 0;
      heater <= 0;
      acMode <= 1;
      TRes <= 0;
      swRst <= 0;
      HRes <= 0;
      clk <= 1;
      rst <= 0;
      #7
      rst <= 1;
      #10
      rst <= 0;
      #50
      measureT <= 1;
       #10
      measureT <= 0;
    end
endmodule//tb