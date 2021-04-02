/* ------------------------------------------------ *
 * Title       : ENC Simulator                      *
 * Project     : Pmod ENC Decoder                   *
 * ------------------------------------------------ *
 * File        : sim.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 05/02/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation code for ENC            *
 * ------------------------------------------------ */

// `include "Sources/enc.v"

module tb();
  reg clk, A, B, rst;
  wire dir0, dir1;

  always #5 clk <= ~clk;

  enc uut(clk,A,B,dir0,dir1,,,,);
  initial
      begin
        $dumpfile("sim.vcd");
        $dumpvars(0, clk);
        $dumpvars(1, A);
        $dumpvars(2, B);
        $dumpvars(3, dir0);
        $dumpvars(4, dir1);
        #40000
        $finish;
      end
  initial
    begin
      clk <= 1;
      A <= 1;
      B <= 1;
      rst <= 0;
      #4
      rst <= 1;
      #10
      rst <= 0;
      #10000
      A <= 0;
      #5000
      B <= 0;
      #500
      A <= 1;
      #100
      B <= 1;
      #10000
      B <= 0;
      #5000
      A <= 0;
      #500
      B <= 1;
      #100
      A <= 1;
    end
endmodule