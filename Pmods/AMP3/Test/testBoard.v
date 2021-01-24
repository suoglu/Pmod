/* ------------------------------------------------ *
 * Title       : AMP3 Test                          *
 * Project     : Pmod AMP3 interface                *
 * ------------------------------------------------ *
 * File        : testBoard.v                        *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 17/01/2021                         *
 * ------------------------------------------------ *
 * Description : Test board for AMP3 interface,     *
 *               Requires Pmod MIC3 interface       *
 *               additionally to AMP3 interface     *
 * ------------------------------------------------ */

//`include "Pmods/AMP3/Sources/amp3.v"
//`include "Pmods/MIC3/Sources/mic3.v"

module testboard(
  input clk,
  input rst,
  input en,
  output [15:0] led,
  input enable,//SW15
  //Microphone interface, upper JB
  output MIC_SCLK,
  output MIC_CS,
  input MIC_MISO,
  //Microphone probe, upper JC
  output MIC_SCLK_copy,
  output MIC_CS_copy,
  output MIC_MISO_copy,
  //AMP3 Interface, JA
  output SDATA,
  output BCLK,
  output LRCLK,
  output nSHUT);
  wire new_data;
  wire BCLK_i;
  wire [11:0] audio;
  wire [11:0] audioInL, audioInR;
  reg [11:0] audio_store;
  wire [11:0] audio_store_inv;

  assign led = {RightNLeft,nSHUT,2'd0,audio_store};
  assign {MIC_SCLK_copy, MIC_CS_copy, MIC_MISO_copy} = {MIC_SCLK, MIC_CS, MIC_MISO};

  assign audio_store_inv = 12'b111111111111 - audio_store;
  assign audioInR = audio_store;
  assign audioInL = audio_store_inv;

  always@(negedge LRCLK or posedge rst)
    begin
      if(rst)
        begin
          audio_store <= 12'd0;
        end
      else
        begin
          audio_store <= audio;
        end
    end
  
  BCLKGen bitclkGen(clk, rst, BCLK_i);
  amp3_Lite uut(clk, rst, SDATA, LRCLK, nSHUT, BCLK, BCLK_i, audioInR, audioInL, enable, RightNLeft);
  mic3 micModule(clk, rst, MIC_SCLK, MIC_CS, MIC_MISO, enable, audio, new_data);
endmodule