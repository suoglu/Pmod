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

// `include "Pmods/AMP3/Sources/amp3.v"
// `include "Pmods/MIC3/Sources/mic3.v"

module testboard(
  input clk,
  input rst,
  input en,
  output [15:0] led,
  //Microphone interface, upper JB
  output MIC_SCLK,
  output MIC_CS,
  input MIC_MISO,
  //AMP3 Interface, JA
  output SDATA,
  output BCLK,
  output LRCLK,
  output nSHUT);
  wire new_data;
  wire idle;
  wire [11:0] audio;
  reg [11:0] audio_store;
  wire [11:0] audio_store_inv;
  assign led = {idle, 3'd0, audio_store};

  assign audio_store_inv = 12'b111111111111 - audio_store;

  always@(posedge new_data or posedge rst)
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
  

  amp3_Lite uut(clk, rst, SDATA, BCLK, LRCLK, nSHUT, audio_store, audio_store_inv,en,idle);
  mic3 micModule(clk, rst, MIC_SCLK, MIC_CS, MIC_MISO, en, audio, new_data);
endmodule