/* ------------------------------------------------ *
 * Title       : Pmod OLED simulation               *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : oled_sim.v                         *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 13/05/2021                         *
 * ------------------------------------------------ *
 * Description : Simulation code for Pmod OLED      *
 * ------------------------------------------------ */
`timescale 1ns / 100ps
//`include "Pmods/OLED/Sources/oled.v"

module tb();
  reg clk, rst,ext_spi_clk;
  wire CS, MOSI, SCK, data_command_cntr, power_rst, vbat_c, vdd_c;
  reg power_on, display_reset, display_off, update;
  reg [511:0] display_data;
  reg [1:0] line_count;
  reg [7:0] contrast;
  reg [7:0] display_array[0:63];
  integer i;

  always #5 clk <= ~clk;
  always #20 ext_spi_clk <= ~ext_spi_clk;

  //Map display_data into display_array
  always@* //Inside of this always generated automatically
    begin
      display_array[0]  = display_data[511:504];
      display_array[1]  = display_data[503:496];
      display_array[2]  = display_data[495:488];
      display_array[3]  = display_data[487:480];
      display_array[4]  = display_data[479:472];
      display_array[5]  = display_data[471:464];
      display_array[6]  = display_data[463:456];
      display_array[7]  = display_data[455:448];
      display_array[8]  = display_data[447:440];
      display_array[9]  = display_data[439:432];
      display_array[10] = display_data[431:424];
      display_array[11] = display_data[423:416];
      display_array[12] = display_data[415:408];
      display_array[13] = display_data[407:400];
      display_array[14] = display_data[399:392];
      display_array[15] = display_data[391:384];
      display_array[16] = display_data[383:376];
      display_array[17] = display_data[375:368];
      display_array[18] = display_data[367:360];
      display_array[19] = display_data[359:352];
      display_array[20] = display_data[351:344];
      display_array[21] = display_data[343:336];
      display_array[22] = display_data[335:328];
      display_array[23] = display_data[327:320];
      display_array[24] = display_data[319:312];
      display_array[25] = display_data[311:304];
      display_array[26] = display_data[303:296];
      display_array[27] = display_data[295:288];
      display_array[28] = display_data[287:280];
      display_array[29] = display_data[279:272];
      display_array[30] = display_data[271:264];
      display_array[31] = display_data[263:256];
      display_array[32] = display_data[255:248];
      display_array[33] = display_data[247:240];
      display_array[34] = display_data[239:232];
      display_array[35] = display_data[231:224];
      display_array[36] = display_data[223:216];
      display_array[37] = display_data[215:208];
      display_array[38] = display_data[207:200];
      display_array[39] = display_data[199:192];
      display_array[40] = display_data[191:184];
      display_array[41] = display_data[183:176];
      display_array[42] = display_data[175:168];
      display_array[43] = display_data[167:160];
      display_array[44] = display_data[159:152];
      display_array[45] = display_data[151:144];
      display_array[46] = display_data[143:136];
      display_array[47] = display_data[135:128];
      display_array[48] = display_data[127:120];
      display_array[49] = display_data[119:112];
      display_array[50] = display_data[111:104];
      display_array[51] = display_data[103:96];
      display_array[52] = display_data[95:88];
      display_array[53] = display_data[87:80];
      display_array[54] = display_data[79:72];
      display_array[55] = display_data[71:64];
      display_array[56] = display_data[63:56];
      display_array[57] = display_data[55:48];
      display_array[58] = display_data[47:40];
      display_array[59] = display_data[39:32];
      display_array[60] = display_data[31:24];
      display_array[61] = display_data[23:16];
      display_array[62] = display_data[15:8];
      display_array[63] = display_data[7:0];
    end

  oled #(10000) uut(clk, rst, ext_spi_clk, CS, MOSI, SCK, data_command_cntr, power_rst, vbat_c, vdd_c, power_on, display_reset, display_off, update, display_data, line_count, contrast, 1'b0, 1'b0, );

  initial
    begin
      clk = 0;
      rst = 0;
      ext_spi_clk = 0;
      contrast = 8'h7f;
      line_count = 2'h3;
      for (i = 0; i < 64; i = i + 1) 
        begin
          {display_data[i*8+7],
          display_data[i*8+6],
          display_data[i*8+5],
          display_data[i*8+4],
          display_data[i*8+3],
          display_data[i*8+2],
          display_data[i*8+1],
          display_data[i*8]} = 8'h10 + (i % 10);
        end
      power_on = 0;
      display_reset = 0;
      display_off = 0;
      update = 0;
      #3
      rst = 1;
      #7
      rst = 0;
      #20
      power_on = 1;
      #120000
      contrast = 8'h7A;
      #10000
      update = 1;
      #10
      update = 0;
    end
  
endmodule
