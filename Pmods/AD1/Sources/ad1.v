/* ------------------------------------------------ *
 * Title       : Pmod AD1 interface v1.0            *
 * Project     : Pmod AD1 interface                 *
 * ------------------------------------------------ *
 * File        : ad1.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 03/01/2021                         *
 * ------------------------------------------------ *
 * Description : Simple interfaces to communicate   *
 *               with Pmod AD1                      *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

module ad1(
  input clk,
  input rst,
  //Serial Interface
  input SCLK,
  input SDATA,
  output reg CS,
  //Data interface
  input getData,
  output updatingData,
  output reg [11:0] data);
  reg gettingData; //State
  reg [3:0] counter;
  reg sdataValid;
  reg CS_d;

  assign updatingData = sdataValid;

  //CS
  always@(posedge clk)
    begin
      if(rst)
        begin
          CS <= 1'b1;
        end
      else
        case(CS)
          1'b1:
            begin
              CS <= (~getData) | (~CS_d);
            end
          1'b0:
            begin
              CS <= SCLK & (counter == 4'd0) & sdataValid;
            end
        endcase
    end
  always@(posedge clk)
    begin
      CS_d <= CS; //Delay CS
    end
  
  //Output data
  always@(posedge SCLK)
    begin
      data <= (sdataValid & (counter != 4'd0)) ? {data[10:0], SDATA} : data;
    end
  
  //Data valid
  always@(posedge clk)
    begin
      sdataValid <= (sdataValid | (counter == 4'd4)) & ~CS;
    end
  
  //count SCLK Edges
  always@(negedge SCLK or posedge rst)
    begin
      if(rst)
        counter <= 4'd0;
      else
        counter <= counter + 4'd1;
    end
endmodule

module ad1_dual(
  input clk,
  input rst,
  //Serial Interface
  input SCLK,
  input SDATA0,
  input SDATA1,
  output reg CS,
  //Data interface
  input getData,
  output updatingData,
  input [1:0] activeCH,
  output reg [11:0] data0,
  output reg [11:0] data1);
  reg gettingData; //State
  reg [3:0] counter;
  reg sdataValid;
  reg CS_d;

  assign updatingData = sdataValid;

  //CS
  always@(posedge clk)
    begin
      if(rst)
        begin
          CS <= 1'b1;
        end
      else
        case(CS)
          1'b1:
            begin
              CS <= (~getData) | (~CS_d);
            end
          1'b0:
            begin
              CS <= SCLK & (counter == 4'd0) & sdataValid;
            end
        endcase
    end
  always@(posedge clk)
    begin
      CS_d <= CS; //Delay CS
    end
  
  //Output data
  always@(posedge SCLK)
    begin
      data0 <= (sdataValid & (counter != 4'd0) & activeCH[0]) ? {data0[10:0], SDATA0} : data0;
      data1 <= (sdataValid & (counter != 4'd0) & activeCH[1]) ? {data1[10:0], SDATA1} : data1;
    end
  
  //Data valid
  always@(posedge clk)
    begin
      sdataValid <= (sdataValid | (counter == 4'd4)) & ~CS;
    end
  
  //count SCLK Edges
  always@(negedge SCLK or posedge rst)
    begin
      if(rst)
        counter <= 4'd0;
      else
        counter <= counter + 4'd1;
    end
endmodule

//Generate 16,67 MHz sclk for AD1
module AD1clockGEN_16_67MHz(
  input clk,
  input CS,
  output reg SCLK);
  reg [1:0] counter;
  
  //SCLK
  always@(posedge clk)
    begin
      if(CS)
        begin
          SCLK <= 1'b1;
        end
      else
        begin
          SCLK <= (counter == 2'd2) ^ SCLK ;
        end
    end
  
  //Counter
  always@(posedge clk)
    begin
      if(CS)
        begin
          counter <= 2'd1;
        end
      else
        begin
          counter <= (counter == 2'd2) ? 2'd0 : (counter + 2'd1);
        end
    end 
endmodule//clockGEN

//Generate 20 MHz sclk with 40% duty cycle for AD1
module AD1clockGEN_20MHz40(
  input clk,
  input CS,
  output reg SCLK);
  reg [1:0] counter;

  //SCLK
  always@(posedge clk)
    begin
      if(CS)
        SCLK <= 1'b1;
      else
        case(SCLK)
          1'b1:
            begin
              SCLK <= (counter == 2'd1) ? ~SCLK : SCLK;
            end
          1'b0:
            begin
              SCLK <= (counter == 2'd2) ? ~SCLK : SCLK;
            end
        endcase    
    end

  //Counter
  always@(posedge clk)
    begin
      if(CS)
        counter <= 2'd0;
      else
        case(SCLK)
          1'b1:
            begin
              counter <= (counter == 2'd1) ? 2'd0 : (counter + 2'd1);
            end
          1'b0:
            begin
              counter <= (counter == 2'd2) ? 2'd0 : (counter + 2'd1);
            end
        endcase    
    end
endmodule

//Disable external clock when not in use 
module AD1clockEN(
  input clk,
  input SCLK_i,
  input CS,
  output SCLK_o);
  reg hold;

  assign SCLK_o = SCLK_i | hold;

  always@(posedge clk)
    begin
      if(CS | (~SCLK_i & hold))
        begin
          hold <= 1'b1;
        end
      else
        begin
          hold <= 1'b0;
        end
    end
endmodule