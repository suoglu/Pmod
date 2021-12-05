/* ------------------------------------------------ *
 * Title       : Pmod DPOT interface v1             *
 * Project     : Pmod DPOT interface                *
 * ------------------------------------------------ *
 * File        : dpot.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 01/04/2021                         *
 * ------------------------------------------------ *
 * Description : Simple interfaces to communicate   *
 *               with Pmod DPOT                     *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

module dpot(
  input rst,
  //DPOT connection
  output reg nCS,
  output MOSI,
  output SCLK,
  //GPIO
  input spi_clk_i, //SPI clk, max. 25 MHz, < clk
  input [7:0] value,
  input update,
  output reg ready);

  reg [2:0] txCounter;
  wire inTx;
  reg [7:0] buffer;
  wire countDone;

  assign SCLK = spi_clk_i;

  assign countDone = &txCounter;

  assign inTx = ~nCS & ~ready;

  //Shift and load buffer
  assign MOSI = buffer[7];
  always@(negedge SCLK) begin
    if(~inTx) begin
      buffer <= value;
    end else begin
      buffer <= (buffer << 1);
    end
  end
  
  //Transmisson counter
  always@(negedge SCLK or posedge rst) begin
    if(rst) begin
      txCounter <= 3'd0;
    end else begin
      txCounter <= txCounter + {2'd0, inTx};
    end
  end
  
  //chip select
  always@(negedge SCLK or posedge rst) begin
    if(rst) begin
      nCS <= 1'b1;
    end else case(nCS)
      1'b1: nCS <= ready;
      1'b0: nCS <= countDone;
    endcase
  end

  //ready
  always@(posedge SCLK or posedge rst) begin
    if(rst) begin
      ready <= 1'b1;
    end else case(ready)
      1'b1: ready <= ~update;
      1'b0: ready <= nCS;
    endcase
  end
endmodule

module clkDiv4(
  input clk_i,
  input rst,
  output reg clk_o);

  reg clk_m;

  always@(posedge clk_i or posedge rst) begin
    if(rst) begin
      clk_m <= 1'b0;
    end else begin
      clk_m <= ~clk_m;
    end
  end

  always@(posedge clk_m or posedge rst) begin
    if(rst) begin
      clk_o <= 1'b0;
    end else begin
      clk_o <= ~clk_o;
    end
  end
endmodule

module autoUpdate(
  input clk,
  input rst,
  input ready,
  input [7:0] value,
  output reg update);
  
  reg [7:0] valueStore;

  wire notEqual;

  assign notEqual = ~(value == valueStore);

  always@(posedge update or posedge rst) begin
    if(rst) begin
      valueStore <= value;
    end else begin
      valueStore <= value;
    end
  end

  always@(posedge clk or posedge rst) begin
    if(rst) begin
      update <= 1'd0;
    end else case(update)
      1'd0:update <= notEqual & ready;
      1'd1: update <= ready;
    endcase
  end
endmodule
