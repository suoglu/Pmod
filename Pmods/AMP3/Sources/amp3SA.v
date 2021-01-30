/* ------------------------------------------------- *
 * Title       : Pmod AMP3 standalone interface v0.2 *
 * Project     : Pmod AMP3 interface                 *
 * ------------------------------------------------- *
 * File        : amp3SA.v                            *
 * Author      : Yigit Suoglu                        *
 * Last Edit   : 24/01/2021                          *
 * ------------------------------------------------- *
 * Description : Simple interface to communicate     *
 *               with Pmod AMP3 in standalone Mode   *
 * ------------------------------------------------- *
 * Revisions                                         *
 *     v1      :                                     *
 * ------------------------------------------------- */

//I2S Stand-Alone Mode, NOT WORKING
//TODO: Solve the problem
module amp3_SA#(parameter DATASIZE = 12)(
  input clk,
  input rst,
  //AMP3 Interface
  output SDATA,
  output reg LRCLK,
  output nSHUT,
  output BCLK_o,
  input BCLK_i,
  //Data interface
  input [(DATASIZE-1):0] dataR,
  input [(DATASIZE-1):0] dataL,
  input enable,
  output reg RightNLeft);
  //Current channel
  localparam LEFT = 1'b0, RIGHT = 1'b1;
  //Bit counter
  localparam counterSIZE = $clog2(DATASIZE-1);
  reg [counterSIZE-1:0] bitCounter;
  wire bitCounterDone;
  //Bit clock
  wire BCLK;
  //Data buffer to transmit
  reg [DATASIZE-1:0] dataBuff;
  wire updatePulse;

  //Shutdown when not enabled
  assign nSHUT = enable;

  assign BCLK = BCLK_i;
  assign BCLK_o = BCLK & enable;

  //Serial data
  assign SDATA = dataBuff[DATASIZE-1];
  assign updatePulse = LRCLK ^ RightNLeft;
  always@(negedge BCLK)
    begin
      if(updatePulse)
        dataBuff[DATASIZE-1:0] <= (LRCLK == RIGHT) ? dataR : dataL;
      else
        dataBuff <= (enable) ? (dataBuff << 1) : dataBuff;
    end
  
  //Handle LRCLK
  always@(negedge BCLK or posedge rst)
    begin
      if(rst)
        begin
          LRCLK <= LEFT;
        end
      else
        begin
          LRCLK <= (bitCounterDone) ? ~RightNLeft : LRCLK;
        end
    end
  //Bit counter
  assign bitCounterDone = bitCounter == (DATASIZE-1);
  always @(negedge BCLK or posedge rst) 
    begin
      if(rst)
        bitCounter <= DATASIZE-1;
      else
        bitCounter <= (bitCounterDone) ? {counterSIZE{1'b0}} : (bitCounter + {{counterSIZE-1{1'b0}}, enable});
    end

  //Actual channel comes one edge after
  always@(negedge BCLK)
    begin
      RightNLeft <= LRCLK;
    end
endmodule

//Output 3.125 MHz
module BCLKGen(clk, rst, BCLK);
  input clk, rst;
  output BCLK;  
  reg [4:0] clk_array; //Clock generation array, asynchronous reset

  assign BCLK = clk_array[4];

  //Clock dividers
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          clk_array[0] <= 0;
        end
      else
        begin
          clk_array[0] <= ~clk_array[0];
        end
    end

    genvar i;
    generate
      for (i = 0; i < 4; i = i + 1) 
        begin
          always@(posedge clk_array[i] or posedge rst)
            begin
              if(rst)
                begin
                  clk_array[i+1] <= 0;
                end
              else
                begin
                  clk_array[i+1] <= ~clk_array[i+1];
                end
            end
        end
    endgenerate
endmodule
