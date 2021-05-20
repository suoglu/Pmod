/* ------------------------------------------------ *
 * Title       : Pmod OLED Demo                     *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : oled_bitmap_test.v                 *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 20/05/2021                         *
 * ------------------------------------------------ *
 * Description : Test for bitmap oled interface     *
 * ------------------------------------------------ */
//`include "Utils/btn_debouncer.v"
module oled_bitmap_tester(
  input clk,
  input n_rst,
  output rst,
  //Interface connections
  output power_on,
  output display_reset,
  output display_off,
  output update,
  output [4095:0] bitmap,
  /*
   * bitmap pixel addresses
   *  | 4095 | 4094 | ... | 3968 |
   *  | 3967 | ...           :   |
   *  |  :                | 128  |
   *  | 127  | ...  |  1  |  0   |
   */
  output [7:0] contrast,
  input CS,
  input MOSI,
  input SCK,
  input data_command_cntr,
  input power_rst,
  input vbat_c,
  input vdd_c,
  //Board connections
  output [7:0] pmod_header,
  input [3:0] sw,
  input [3:0] btn);
  wire [4095:0] defined_bitmaps[0:3];
  wire [3:0] bitmap_select;
  wire bitmap_update;
  reg bitmap_update_d;
  reg [1:0] display_content;

  always@(posedge clk or negedge n_rst)
    begin
      if(~n_rst)
        begin
          display_content <= 2'b0;
        end
      else
        casex(bitmap_select)
          4'b1000: display_content <= 2'd3;
          4'bx100: display_content <= 2'd2;
          4'bxx10: display_content <= 2'd1;
          4'bxxx1: display_content <= 2'd0;
          default: display_content <= display_content;
        endcase
    end
  
  assign defined_bitmaps[0] =  {128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'hFF00FF00FF00FF00FF00FF00FF00FF00,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF,
                                128'h00FF00FF00FF00FF00FF00FF00FF00FF};

  assign defined_bitmaps[1] =  {128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301,
                                128'h0080C0E0F0F8FCFEFF7F3F1F0F070301};

  assign defined_bitmaps[2] =  {128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'hFFFFFFFFFFFFFFFF0000000000000000,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'h0000000000000000FFFFFFFFFFFFFFFF,
                                128'h0000000000000000FFFFFFFFFFFFFFFF};

  assign defined_bitmaps[3] =  {128'hFF00FF00F0F0F0F0FFFFFFFFF0F0F0F0,
                                128'hFF00FF00F0F0F0F0FFFFFFFFF0F0F0F0,
                                128'hFF00FF00F0F0F0F000000000F0F0F0F0,
                                128'hFF00FF00F0F0F0F000000000F0F0F0F0,
                                128'hFF00FF000F0F0F0FFFFFFFFF0F0F0F0F,
                                128'hFF00FF000F0F0F0FFFFFFFFF0F0F0F0F,
                                128'hFF00FF000F0F0F0F000000000F0F0F0F,
                                128'hFF00FF000F0F0F0F000000000F0F0F0F,
                                128'hFF00FF00F0F0F0F0FFFFFFFFF0F0F0F0,
                                128'hFF00FF00F0F0F0F0FFFFFFFFF0F0F0F0,
                                128'hFF00FF00F0F0F0F000000000F0F0F0F0,
                                128'hFF00FF00F0F0F0F000000000F0F0F0F0,
                                128'hFF00FF000F0F0F0FFFFFFFFF0F0F0F0F,
                                128'hFF00FF000F0F0F0FFFFFFFFF0F0F0F0F,
                                128'hFF00FF000F0F0F0F000000000F0F0F0F,
                                128'hFF00FF000F0F0F0F000000000F0F0F0F,
                                128'hFF00FF00F0F0F0F0FFFFFFFFF0F0F0F0,
                                128'hFF00FF00F0F0F0F0FFFFFFFFF0F0F0F0,
                                128'hFF00FF00F0F0F0F000000000F0F0F0F0,
                                128'hFF00FF000F0F0F0F00000000F0F0F0F0,
                                128'hFF00FF00F0F0F0F0FFFFFFFF0F0F0F0F,
                                128'hFF00FF000F0F0F0FFFFFFFFF0F0F0F0F,
                                128'hFF00FF00F0F0F0F0000000000F0F0F0F,
                                128'hFF00FF000F0F0F0F000000000F0F0F0F,
                                128'hFF00FF00F0F0F0F0FFFFFFFFF0F0F0F0,
                                128'hFF00FF000F0F0F0FFFFFFFFFF0F0F0F0,
                                128'hFF00FF00F0F0F0F000000000F0F0F0F0,
                                128'hFF00FF000F0F0F0F00000000F0F0F0F0,
                                128'hFF00FF00F0F0F0F0FFFFFFFF0F0F0F0F,
                                128'hFF00FF000F0F0F0FFFFFFFFF0F0F0F0F,
                                128'hFF00FF00F0F0F0F0000000000F0F0F0F,
                                128'hFF00FF000F0F0F0F000000000F0F0F0F};
  
  assign bitmap = defined_bitmaps[display_content];

  assign rst = ~n_rst;

  assign update = bitmap_update_d & ~bitmap_update;
  assign bitmap_update = |bitmap_select;

  assign power_on = sw[3];
  assign display_off = ~sw[3];

  always@(posedge clk)
    begin
      bitmap_update_d <= bitmap_update;
    end

  assign contrast = {sw[2:0],sw[2:0],sw[1:0]};

  assign pmod_header = {vdd_c,vbat_c,power_rst,data_command_cntr,SCK,1'd0,MOSI,CS};

  debouncer db0(clk, rst, btn[0], bitmap_select[0]);
  debouncer db1(clk, rst, btn[1], bitmap_select[1]);
  debouncer db2(clk, rst, btn[2], bitmap_select[2]);
  debouncer db3(clk, rst, btn[3], bitmap_select[3]);
endmodule