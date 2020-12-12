/* ------------------------------------------------ *
 * Title       : Pmod MIC3 interface simulation     *
 * Project     : Pmod MIC3 interface                *
 * ------------------------------------------------ *
 * File        : sim.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 12/12/2020                         *
 * ------------------------------------------------ *
 * Description : Simulation code for Pmod MIC3      *
 *               interface                          *
 * ------------------------------------------------ */

`timescale 1ns / 1ps
// `include "Sources/mic3.v"

module tb();
  reg clk, rst, MISO, read;
  wire SPI_SCLK, CS, new_data;
  wire [11:0] audio;

  always #5 clk <= ~clk;

  always #70 MISO <= ~MISO; //Alternating MISO

  mic3 uut(clk, rst, SPI_SCLK, CS, MISO, read, audio, new_data);

  initial //initilizations and reset
    begin
      clk <= 0;
      rst <= 0;
      MISO <= 0;
      read <= 0;
      #3
      rst <= 1;
      #10
      rst <= 0;
    end
  initial //Testcases
    begin
      #402
      read <= 1;
      #100
      read <= 0;
      #2500
      read <= 1;
    end
  // initial //Tracked signals & Total sim time
  //   begin
  //     #10000
  //     $finish;
  //   end
endmodule//tb