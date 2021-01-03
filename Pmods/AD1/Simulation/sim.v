/* ------------------------------------------------ *
 * Title       : Pmod AD1 Simulation                *
 * Project     : Pmod AD1 interface                 *
 * ------------------------------------------------ *
 * File        : sim.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 03/01/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation for Pmod AD1            *
 * ------------------------------------------------ */
`timescale 1ns / 1ps
`include "Pmods/AD1/Sources/ad1.v"

module tb();
  reg clk, rst, getData, SDATA;
  wire SCLK, CS, updatingData;
  wire [11:0] data;

  always #5 clk <= ~clk;
  always #50 SDATA <= ~SDATA; 
  
  AD1clockGEN_20MHz40 sclkgen(clk, CS, SCLK);
  ad1 uut(clk, rst, SCLK, SDATA, CS, getData, updatingData, data);

  initial
      begin
        $dumpfile("sim.vcd");
        $dumpvars(0, clk);
        $dumpvars(1, rst);
        $dumpvars(2, getData);
        $dumpvars(3, updatingData);
        $dumpvars(4, CS);
        $dumpvars(5, SCLK);
        $dumpvars(6, SDATA);
        $dumpvars(7, data);
        #4000
        $finish;
      end
  initial
    begin
      clk <= 1;
      SDATA <= 1;
      getData <= 0;
      rst <= 0;
      #7
      rst <= 1;
      #10
      rst <= 0;
      #50
      getData <= 1;
      #10
      getData <= 0;
      #1500
      getData <= 1;
    end
endmodule//tb