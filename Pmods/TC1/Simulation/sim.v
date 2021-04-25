/* ------------------------------------------------ *
 * Title       : Pmod TC1 Interface simulation      *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : sim.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 25/04/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation for Pmod TC1 Interface  *
 * ------------------------------------------------ */
`timescale 1ns / 1ps
//`include "Pmods/TC1/Sources/tc1.v"

module tb();
  reg clk, rst, clk_spi;
  wire SCLK, CS;
  reg MISO, update, update_fault, update_all;
  wire [13:0] temperature_termoc;
  wire [11:0] temperature_internal;
  wire [2:0] status;
  wire fault;

  always #5 clk = ~clk; //100MHz
  always #100 clk_spi = ~clk_spi; //5MHz

  always@(negedge SCLK or posedge rst) //MISO: 1010...
    begin
      if(rst)
        begin
          MISO <= 1;
        end
      else
        begin
          MISO <= ~MISO;
        end
    end

  tc1 uut(clk,rst,clk_spi,SCLK,MISO,CS,update,update_fault,update_all,busy,temperature_termoc,temperature_internal,status,fault);

  initial
    begin
      clk = 0;
      rst = 0;
      clk_spi = 0;
      update = 0;
      update_fault = 0;
      update_all = 0;
      #10
      rst = 1;
      #10
      rst = 0;
      #10
      update = 1;
      #10
      update = 0;
      #3100
      update_fault = 1;
      #10
      update_fault = 0;
      #3600
      update_all = 1;
    end
endmodule