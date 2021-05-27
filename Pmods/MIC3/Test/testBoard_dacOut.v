/* ------------------------------------------------ *
 * Title       : Pmod MIC3 interface test board     *
 *               with DAC output                    *
 * Project     : Pmod MIC3 interface                *
 * ------------------------------------------------ *
 * File        : testBoard_dacOut.v                 *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 31/03/2021                         *
 * ------------------------------------------------ *
 * Description : Test interface using a DAC, this   *
 *               also requires DA2 interface mode.  *
 * ------------------------------------------------ */

module testboard(
  input clk,
  input rst,
  input [11:0] audio,
  // input MISO_mic, //P3
  // output CS_mic, //P1
  // output SPI_SCLK_mic, //P4
  output SYNC_dac, //P1
  output SCLK_dac, //P4
  output SDATA_dac,
  output SDATA_dac2); //P2-3

  wire update, new_data, SCLKdac_en;

  assign SDATA_dac2 = SDATA_dac;

  da2AutoUpdate dacUpdater(clk,rst,SYNC_dac,update,2'd0,audio);
  da2 dac(clk, rst, SCLK_dac, SDATA_dac, SYNC_dac, SCLKdac_en, 2'd0, audio, update);
  clkDiv25en sclkGEN(clk, rst, SCLKdac_en, SCLK_dac);
endmodule