/* ------------------------------------------------ *
 * Title       : Pmod AMP3 Simulation               *
 * Project     : Pmod AMP3 interface                *
 * ------------------------------------------------ *
 * File        : simlite.v                          *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : /01/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation for Pmod AMP3 interface *
 * ------------------------------------------------ */

`include "Pmods/AMP3/Sources/amp3.v"

module testbench();
  reg clk, rst, enable;
  wire SDATA, BCLK, LRCLK, nSHUT, idle;
  reg [11:0] dataR, dataL;

  always #5 clk <= ~clk;

  amp3_Lite uut(clk, rst, SDATA, BCLK, LRCLK, nSHUT, dataR, dataL, enable, idle);

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
        $dumpvars(9, idle);
        #40000
        $finish;
      end
  initial
    begin
      clk = 0;
      dataR = 12'hA5A;
      dataL = 12'h468;
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