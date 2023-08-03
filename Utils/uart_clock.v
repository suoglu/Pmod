/* ------------------------------------------------ *
 * Title       : UART Clock Modules v1.2            *
 * Project     : Simple UART                        *
 * ------------------------------------------------ *
 * File        : uart_clock.v                       *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 23/05/2021                         *
 * Licence     : CERN-OHL-W                         *
 * ------------------------------------------------ *
 * Description : Clock generation for UART modules  *
 * ------------------------------------------------ */

//Generate a clock freqency for various baudrates, just clock divider 
module uart_clk_gen#(parameter CLOCK_PERIOD = 10)(
  input clk,
  input rst,
  input en,
  output clk_uart,
  input baseClock_freq, //0: 76,8kHz (13us) 1: 460,8kHz (2,17us)
  input [2:0] divRatio); //Higher the value lower the freq

  localparam sec6_5u = (6500 / CLOCK_PERIOD) - 1;
  localparam sec1_08u = (1080 / CLOCK_PERIOD) - 1;
  localparam counterWIDTH = $clog2(sec6_5u);
  localparam CLKRST = 1'b0;
  localparam CLKDEF = 1'b1;

  wire en_rst;

  reg baseClock;
  wire countDONE;

  reg [(counterWIDTH-1):0] counter;
  wire [(counterWIDTH-1):0] countTO;

  wire [7:0] clockArray;
  reg [6:0] divClock;

  assign en_rst = en | rst;

  assign countTO = (baseClock_freq) ? sec1_08u : sec6_5u;
  assign countDONE = (countTO == counter);

  assign clockArray = {divClock, baseClock};
  assign clk_uart = (en) ? clockArray[divRatio] : CLKDEF;

  //Counter
  always@(posedge clk)
    begin
      if(~en)
        counter <= 0;
      else
        counter <= (countDONE) ? 0 : (counter +  1);
    end
  
  //Generate base clock with counter
  always@(posedge clk)
    begin
      if(~en)
        baseClock <= CLKRST;
      else
        baseClock <= (countDONE) ? ~baseClock : baseClock;
    end
  
  //Clock dividers
  // 1/2
  always@(posedge baseClock or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[0] <= CLKRST;
        end
      else
        begin
          divClock[0] <= ~divClock[0];
        end
    end
  // 1/4
  always@(posedge divClock[0] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[1] <= CLKRST;
        end
      else
        begin
          divClock[1] <= ~divClock[1];
        end
    end
  // 1/8
  always@(posedge divClock[1] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[2] <= CLKRST;
        end
      else
        begin
          divClock[2] <= ~divClock[2];
        end
    end
  // 1/16
  always@(posedge divClock[2] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[3] <= CLKRST;
        end
      else
        begin
          divClock[3] <= ~divClock[3];
        end
    end
  // 1/32
  always@(posedge divClock[3] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[4] <= CLKRST;
        end
      else
        begin
          divClock[4] <= ~divClock[4];
        end
    end
  // 1/64
  always@(posedge divClock[4] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[5] <= CLKRST;
        end
      else
        begin
          divClock[5] <= ~divClock[5];
        end
    end
  // 1/128
  always@(posedge divClock[5] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[6] <= CLKRST;
        end
      else
        begin
          divClock[6] <= ~divClock[6];
        end
    end
endmodule

//Generate a clock freqency for non standard higher frequencies
module uart_clk_gen_hs(
  input clk,
  input rst,
  input en,
  output clk_uart,
  input [1:0] divRatio); //Higher the value lower the freq

  localparam CLKRST = 1'b0;
  localparam CLKDEF = 1'b1;

  wire en_rst;

  reg baseClock;

  reg [3:0] divClock;

  assign en_rst = en | rst;

  assign clk_uart = (en) ? divClock[divRatio] : CLKDEF;

  //Generate base clock with counter
  always@(posedge clk)
    begin
      if(~en)
        baseClock <= CLKRST;
      else
        baseClock <= ~baseClock;
    end

  //Clock dividers
  // 1/2
  always@(posedge baseClock or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[0] <= CLKRST;
        end
      else
        begin
          divClock[0] <= ~divClock[0];
        end
    end
  // 1/4
  always@(posedge divClock[0] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[1] <= CLKRST;
        end
      else
        begin
          divClock[1] <= ~divClock[1];
        end
    end
  // 1/8
  always@(posedge divClock[1] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[2] <= CLKRST;
        end
      else
        begin
          divClock[2] <= ~divClock[2];
        end
    end
  // 1/16
  always@(posedge divClock[2] or negedge en_rst)
    begin
      if(~en_rst)
        begin
          divClock[3] <= CLKRST;
        end
      else
        begin
          divClock[3] <= ~divClock[3];
        end
    end
endmodule

//Generate a clock freqency for various baudrates, just clock divider 
module uart_clk_en(
  input clk,
  input rst,
  input ext_uart_clk,
  input en,
  output clk_uart);

  reg clk_enabled;

  assign clk_uart = ext_uart_clk | clk_enabled;

  always@(posedge clk or posedge rst)
    begin
      if(rst)
        clk_enabled <= 1'b0;
      else
        case(clk_enabled)
          1'b0: clk_enabled <=  ext_uart_clk & en;
          1'b1: clk_enabled <= ~ext_uart_clk | en;
        endcase
    end
endmodule
