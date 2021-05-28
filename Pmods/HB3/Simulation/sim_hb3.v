/* ------------------------------------------------ *
 * Title       : Pmod HB3 Simulation                *
 * Project     : Pmod HB3 Interface                 *
 * ------------------------------------------------ *
 * File        : sim_hb3.v                          *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 28/05/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation for HB3 Interface       *
 * ------------------------------------------------ */
`timescale 1ns / 1ps
// `include "Pmods/HB3/Sources/hb3.v"

module tb_hb3();
  reg clk, rst, direction_control;
  wire motor_direction, motor_enable;
  reg [7:0] speed;

  always #5 clk <= ~clk;

  hb3 uut(clk, rst, motor_direction, motor_enable, direction_control, speed);

  initial
    begin
      clk <= 0;
      rst <= 0;
      direction_control <= 0;
      speed <= 0;
      #3
      rst <= 1;
      #10
      rst <= 0;
      #10000
      speed <= 8'h80;
      #10000
      speed <= 8'h40;
      #10000
      speed <= 8'hFF;
      #10000
      direction_control <= 1;
      #10000
      speed <= 8'h4A;
      #10000
      speed <= 8'h05;
    end
endmodule