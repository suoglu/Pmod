/* ------------------------------------------------ *
 * Title       : ENC Test                           *
 * Project     : Pmod ENC Decoder                   *
 * ------------------------------------------------ *
 * File        : test.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 05/02/2021                         *
 * ------------------------------------------------ *
 * Description : Test code for ENC                  *
 * ------------------------------------------------ */

module testboard(
  input clk,
  input rst,
  input A,
  input B,
  output A_o,
  output B_o,
  output dir0,
  output dir1,
  output [6:0] seg,
  output [3:0] an);

  wire clk_ENC;

  reg [3:0] counter0, counter1;

  assign {A_o,B_o} = {A,B};

  always@(posedge dir1 or posedge rst)
    begin
      if(rst)
        begin
          counter1 <= 0;
        end
      else
        begin
          counter1 <= counter1 + 4'd1;
        end
    end

  always@(posedge dir0 or posedge rst)
    begin
      if(rst)
        begin
          counter0 <= 0;
        end
      else
        begin
          counter0 <= counter0 + 4'd1;
        end
    end

  cclk_div6 testClkGen(clk, rst, clk_ENC);
  ssdController4 ssdCntr(clk, rst, 4'b1001, counter1, , , counter0, seg, an);
  enc uut(clk_ENC, rst, A,B,dir0,dir1,1'd0,1'd0,,);
endmodule