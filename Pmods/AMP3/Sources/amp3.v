/* ------------------------------------------------ *
 * Title       : Pmod AMP3 interface v1.0           *
 * Project     : Pmod AMP3 interface                *
 * ------------------------------------------------ *
 * File        : amp3.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 17/01/2021                         *
 * ------------------------------------------------ *
 * Description : Simple interface to communicate    *
 *               with Pmod AMP3 in Left Justified   *
 *               Stand-Alone Mode.                  *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version, lite interface     *
 * ------------------------------------------------ */

//Left Justified Stand-Alone Mode
module amp3_Lite#(parameter dataW = 12)(
  input clk,
  input rst,
  //AMP3 Interface
  output SDATA,
  output BCLK,
  output LRCLK,
  output nSHUT,
  //Data interface
  input [(dataW-1):0] dataR,
  input [(dataW-1):0] dataL,
  input enable,
  output idle);
  localparam counterSIZE = $clog2(dataW);
  localparam IDLE = 2'b00,
             PREP = 2'b01,
          RIGHTCH = 2'b11,
           LEFTCH = 2'b10;
  reg [1:0] state;
  reg enabled;
  wire inIDLE, inRIGHTCH, inLEFTCH, inPREP, sending;
  reg [dataW:0] dataR_buff, dataL_buff;
  reg [(counterSIZE-1):0] counter;
  wire BCLK_negedge;
  wire counterDONE;

  //Decode States
  assign inIDLE = (state == IDLE);
  assign inRIGHTCH = (state == RIGHTCH);
  assign inLEFTCH = (state == LEFTCH);
  assign inPREP= (state == PREP);
  assign sending = inRIGHTCH | inLEFTCH;
  assign nSHUT = enabled;
  assign LRCLK = ~inRIGHTCH;
  assign idle = inIDLE | (inPREP & ~enable & ~enabled);

  //State transactions
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          state <= IDLE;
        end
      else
        begin
          case(state)
            IDLE:
              begin
                state <= (enabled) ? PREP : state;
              end
            PREP:
              begin
                state <= (enabled) ? ((BCLK_negedge) ? RIGHTCH : state) : IDLE;
              end
            RIGHTCH:
              begin
                state <= (BCLK_negedge & counterDONE) ? LEFTCH : state;
              end
            LEFTCH:
              begin
                state <= (counterDONE) ? ((enable) ? PREP : ((BCLK_negedge) ? IDLE : state)) : state;
              end
          endcase
          
        end
    end
  
  //Counters
  assign counterDONE = (inRIGHTCH) ? (counter == dataW) : ~|counter;
  always@(posedge BCLK or posedge rst)
    begin
      if(rst)
        begin
          counter <= {counterSIZE{1'b0}};
        end
      else
        begin
          counter <= (counterDONE & inLEFTCH) ? {counterSIZE{1'b0}} : (counter + ({{(counterSIZE-1){1'b0}}, sending} ^ {counterSIZE{inLEFTCH}}) + {{(counterSIZE-1){1'b0}}, inLEFTCH});
        end
    end
  
  //Enabled signal
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          enabled <= 1'b0;
        end
      else
        begin
          case(enabled)
            1'b0:
              begin
                enabled <= enable;
              end
            1'b1:
              begin
                enabled <= (inIDLE) ? enable : enabled;
              end
          endcase
          
        end
    end
  
  //Data buffers
  always@(negedge BCLK or posedge inPREP)
    begin
      if(inPREP)
        begin
          dataR_buff <= {1'b0, dataR};
          dataL_buff <= {1'b0, dataL};
        end
      else
        begin
          dataR_buff <= (inRIGHTCH) ? (dataR_buff << 1) : dataR_buff;
          dataL_buff <= (inLEFTCH)  ? (dataL_buff << 1) : dataL_buff;
        end
    end
  
  //SDATA
  assign SDATA = (sending) ? ((inRIGHTCH) ? dataR_buff[dataW] : dataL_buff[dataW]) : 1'b0;

  BCLKgen bitclkGEN(clk, enabled, BCLK, BCLK_negedge);
endmodule

//Generate 10MHz BCLK with Negative edge notif.
module BCLKgen(
  input clk,
  input en,
  output reg BCLK,
  output BCLK_negedge);
  reg [2:0] counter;

  assign BCLK_negedge = BCLK & counter[2];

  always@(posedge clk)
    begin
      if(~en)
        BCLK <= 1'b0;
      else
        BCLK <= (counter[2]) ? ~BCLK : BCLK;
    end 

  always@(posedge clk)
    begin
      if(~en)
        counter <= 3'd0;
      else
        counter <= (counter[2]) ? 3'd0 : (counter + 3'd1);
    end 
endmodule