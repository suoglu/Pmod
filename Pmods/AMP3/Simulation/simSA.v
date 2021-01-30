/* ------------------------------------------------ *
 * Title       : Pmod AMP3 standalone Simulation    *
 * Project     : Pmod AMP3 interface                *
 * ------------------------------------------------ *
 * File        : simSA.v                            *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 17/01/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation for Pmod AMP3 interface *
 * ------------------------------------------------ */

`include "Pmods/AMP3/Sources/amp3SA.v"

module testbench();
  reg clk, rst, enable;
  wire SDATA, BCLK, LRCLK, nSHUT, BCLKgen,RightNLeft;
  reg [11:0] dataR, dataL;

  always #5 clk <= ~clk;

  amp3_SA uut(clk,rst,SDATA,LRCLK,nSHUT,BCLK,BCLKgen,dataR,dataL,enable,RightNLeft);
  BCLKGen uutClkGen(clk,rst,BCLKgen);

  initial
      begin
        $dumpfile("sim.vcd");
        $dumpvars(0, clk);
        $dumpvars(1, rst);
        $dumpvars(2, SDATA);
        $dumpvars(3, BCLK);
        $dumpvars(4, LRCLK);
        $dumpvars(5, nSHUT);
        $dumpvars(6, dataR);
        $dumpvars(7, dataL);
        $dumpvars(8, enable);
        $dumpvars(9, BCLKgen);
        $dumpvars(10, RightNLeft);
        #40000
        $finish;
      end
  initial
    begin
      clk = 0;
      dataR = 12'hfff;
      dataL = 12'h000;
      enable = 0;
      rst = 0;
      #13
      rst = 1;
      #10
      rst = 0;
      #40
      enable = 1;
      #20
      enable = 0;
      #3000
      enable = 1;
    end
endmodule//testbench