/* ------------------------------------------------ *
 * Title       : Pmod OLED Tester                   *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : oled_test.v                        *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 15/05/2021                         *
 * ------------------------------------------------ *
 * Description : Master module to test OLED         *
 *               interface module, oled             *
 * ------------------------------------------------ */
//`include "Utils/btn_debouncer.v"

module oled_tester(
  input clk,
  input rst,
  //Interface connections
  output power_on,
  output display_reset,
  output display_off,
  output reg update,
  output reg [511:0] display_data, 
  /* MSB(display_data[511:504]): left-up most 
            decreases as left to right
     LSB(display_data[7:0]): right bottum most) */
  output reg [1:0] line_count,
  output reg [7:0] contrast,
  output reg cursor_enable,
  output reg cursor_flash,
  output reg [5:0] cursor_pos,
  input CS,
  input MOSI,
  input SCK,
  input data_command_cntr, //high data, low command
  input power_rst,
  input vbat_c, //low to turn on
  input vdd_c,
  //board connections
  input [15:0] sw, 
  //sw = {power on, display on,...,data[9:0]}
  output [7:0] JB,
  output [7:0] JC,
  input btnU, //cursor_update
  input btnL, //ch_contrast
  input btnR, //save_data
  input btnD); //display_reset
  wire save_data,update_pre;
  wire ch_contrast;
  wire cursor_update;

  assign JB = {vdd_c,vbat_c,power_rst,data_command_cntr,SCK,1'd0,MOSI,CS};
  assign JC = {vdd_c,vbat_c,power_rst,data_command_cntr,SCK,1'd0,MOSI,CS};

  assign display_off = ~sw[14];
  assign power_on = sw[15];
  assign update_pre = save_data | (sw[7:0] != display_data[511:504]) |  (line_count != ~sw[9:8]);
  always@(posedge clk) update <= update_pre;

  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          display_data <= 0;
          line_count <= 2'b11;
        end
      else
        begin
          if(save_data)
            begin
              display_data <= (display_data >> 8);
            end
          else
            begin
              display_data[511:504] <= sw[7:0];
              line_count <= ~sw[9:8];
            end
        end
    end
  
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          contrast <= 8'h7F;
        end
      else
        begin
          contrast <= (ch_contrast) ? sw[7:0] : contrast;
        end
    end
  
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          {cursor_enable,cursor_flash,cursor_pos} <= 8'h0;
        end
      else
        begin
          {cursor_enable,cursor_flash,cursor_pos} <= (cursor_update) ? sw[7:0] : {cursor_enable,cursor_flash,cursor_pos};
        end
    end
  
  debouncer dbL(clk, rst, btnL, ch_contrast);
  debouncer dbR(clk, rst, btnR, save_data);
  debouncer dbU(clk, rst, btnU, cursor_update);
  debouncer dbD(clk, rst, btnD, display_reset);
endmodule