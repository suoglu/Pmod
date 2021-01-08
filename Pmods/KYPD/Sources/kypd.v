/* ------------------------------------------------ *
 * Title       : Pmod KYPD decoder                  *
 * Project     : Pmod KYPD                          *
 * ------------------------------------------------ *
 * File        : kypd.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 08/01/2021                         *
 * ------------------------------------------------ *
 * Description : Decoder for Pmod KYPD              *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

 module kypd(
  input clk,
  input rst,
  input [3:0] row,
  output reg [3:0] col,
  output reg [15:0] buttons);
  reg [15:0] button_reg;
  reg [1:0] state;
  wire newCycle;

  assign newCycle = ~|state;

  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          state <= 2'd0;
        end
      else
        begin
          state <= state + 2'd1;
        end
    end
  

  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          button_reg <= 16'd0;
        end
      else
        begin
          case(state)
            2'b00:
              begin
                button_reg[1]  <= ~row[0]; //1
                button_reg[4]  <= ~row[1]; //4
                button_reg[7]  <= ~row[2]; //7
                button_reg[0]  <= ~row[3]; //0
              end
            2'b01:
              begin
                button_reg[2]  <= ~row[0]; //2
                button_reg[5]  <= ~row[1]; //5
                button_reg[8]  <= ~row[2]; //8
                button_reg[15] <= ~row[3]; //F
              end
            2'b10:
              begin
                button_reg[3]  <= ~row[0]; //3
                button_reg[6]  <= ~row[1]; //6
                button_reg[9]  <= ~row[2]; //9
                button_reg[14] <= ~row[3]; //E
              end
            2'b11:
              begin
                button_reg[10] <= ~row[0]; //A
                button_reg[11] <= ~row[1]; //B
                button_reg[12] <= ~row[2]; //C
                button_reg[13] <= ~row[3]; //D
              end
          endcase
        end
    end
  

  always@(posedge newCycle or posedge rst)
    begin
      if(rst)
        begin
          buttons <= 16'd0;
        end
      else
        begin
          buttons <= button_reg;
        end
    end
  
  always@*
    begin
      case(state)
        2'b00:
          begin
            col = 4'b1110;
          end
        2'b01:
          begin
            col = 4'b1101;
          end
        2'b10:
          begin
            col = 4'b1011;
          end
        2'b11:
          begin
            col = 4'b0111;
          end
      endcase  
    end
endmodule
