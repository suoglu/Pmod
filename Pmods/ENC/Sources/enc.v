/* ------------------------------------------------ *
 * Title       : Pmod ENC Decoder v1                *
 * Project     : Pmod ENC Decoder                   *
 * ------------------------------------------------ *
 * File        : enc.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 02/04/2021                         *
 * ------------------------------------------------ *
 * Description : Decoder for Pmod ENC               *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

module enc#(
  parameter DIVIDER_EN = 1, //1: enable, 0: disable
  parameter CLOCKDIVISION = 10/*Minumum 1*/)( 
  input clkSys,
  input rst,
  input A,
  input B,//some glitches give false values
  output dir0,
  output dir1,
  //Following ports are pass through
  input btn_i,
  input sw_i,
  output btn_o,
  output sw_o);

  reg [15:0] A_buffer, B_buffer;
  reg [(CLOCKDIVISION-1):0] clockCounter;

  reg A_d, B_d, A_dd, B_dd;
  wire A_negedge, B_negedge, clk;

  //Internal clock divider
  assign clk = (DIVIDER_EN) ? clockCounter[CLOCKDIVISION-1] : clkSys;
  always@(posedge clkSys or posedge rst) begin
    if(rst) begin
      clockCounter <= 0;
    end else begin
      clockCounter <= clockCounter + 1;
    end
  end
  
  //Clean glitches
  always@(posedge clk or posedge rst) begin
    if(rst) begin 
      A_buffer <= 16'hFFFF;
      B_buffer <= 16'hFFFF;
    end else begin
      A_buffer <= {A_buffer[14:0], A};
      B_buffer <= {B_buffer[14:0], B};
    end
  end
  
  always@(posedge clk) begin
    A_d <= &A_buffer;
    B_d <= &B_buffer;
    A_dd <= A_d;
    B_dd <= B_d;
  end

  assign A_negedge = ~A_d & A_dd;
  assign B_negedge = ~B_d & B_dd;

  assign dir0 = ~B & A_negedge; //Clockwise
  assign dir1 = ~A & B_negedge; //Counter clockwise

  //directly connect
  assign btn_o = btn_i;
  assign sw_o = sw_i;
endmodule
