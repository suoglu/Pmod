/* ------------------------------------------------ *
 * Title       : Pmod DA2 interface simulation      *
 * Project     : Pmod DA2 interface                 *
 * ------------------------------------------------ *
 * File        : sim.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 06/01/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation code for Pmod DA2       *
 *               interface                          *
 * ------------------------------------------------ */

`timescale 1ns / 1ps
`include "Pmods/DA2/Sources/da2.v"

module tb();
  reg clk, rst, update;
  wire SYNC, SCLK_en, SCLK, SDATA;

  da2 uut(clk, rst, SCLK, SDATA, SYNC, SCLK_en, 2'd0, 12'hAAA, update);
  clkDiv25en clkgen25(clk, rst, SCLK_en, SCLK);

  always #5 clk <= ~clk;

  initial
      begin
        $dumpfile("sim.vcd");
        $dumpvars(0, clk);
        $dumpvars(1, rst);
        $dumpvars(2, update);
        $dumpvars(3, SYNC);
        $dumpvars(4, SCLK_en);
        $dumpvars(5, SCLK);
        $dumpvars(6, SDATA);
        #4000
        $finish;
      end
  initial
    begin
      clk <= 0;
      update <= 0;
      rst <= 0;
      #7
      rst <= 1;
      #10
      rst <= 0;
      #50
      update <= 1;
      #10
      update <= 0;
      #1500
      update <= 1;
    end
endmodule
