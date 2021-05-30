/* ------------------------------------------------ *
 * Title       : Pmod CON3 Simulation               *
 * Project     : Pmod CON3 Interface                *
 * ------------------------------------------------ *
 * File        : con3_sim.v                         *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 30/05/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation for CON3 interface      *
 * ------------------------------------------------ */
`timescale 1ns / 1ps
// `include "Pmods/CON3/Sources/con3.v"

module testbench();
  reg clk, rst, clk_sim, en;
  wire servo,clk_256kHz;
  reg [7:0] angle;

  always #5 clk <= ~clk;
  always #50 clk_sim <= ~clk_sim;

  con3 uut(clk, rst, clk_sim, en, servo, angle);
  con3_clk_gen uut_clkgen(clk,rst, clk_256kHz);
  con3 #(1,1) uut1(clk, rst, clk_sim, en, , angle);
  con3 #(1,8) uut2(clk, rst, clk_sim, en, , angle);
  con3 #(1,18) uut3(clk, rst, clk_sim, en, , angle);

  initial begin
    clk = 0;
    rst = 0;
    clk_sim = 0;
    en = 0;
    angle = 8'h0;
    #3
    rst = 1;
    #10
    rst = 0;
    #1000
    en = 1;
    #100000
    angle = 8'h80;
    #100000
    angle = 8'hFF;
    #100000
    angle = 8'h21;
  end
endmodule