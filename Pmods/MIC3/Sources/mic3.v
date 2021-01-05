/* ------------------------------------------------ *
 * Title       : Pmod MIC3 interface v1.0           *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : mic3.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 12/12/2020                         *
 * ------------------------------------------------ *
 * Description : Simple interface to communicate    *
 *               with Pmod MIC3                     *
 * ------------------------------------------------ */

module mic3(
  input clk, //designed for 100 MHz, should work up to 160 MHz
  input rst,
  //SPI signals
  output SPI_SCLK, //Pin 4
  output CS, //Pin 1
  input MISO, //Pin 3
  //General Interface
  input read,
  output reg [11:0] audio,
  output new_data);
  
  localparam   IDLE = 2'b00,
                PRE = 2'b01, 
            WORKING = 2'b11,
               POST = 2'b10;
  
  wire in_IDLE, in_PRE, in_WORKING, in_POST;
  reg last_POST, stopper;

  reg [2:0] clk_array; //Generate SPI clock (12,5 MHz)

  reg [3:0] transaction_counter;
  reg [1:0] state;
  reg [12:0] rx_buff;

  //decode states for better readability
  assign in_IDLE    = (state == IDLE);
  assign in_PRE     = (state == PRE);
  assign in_WORKING = (state == WORKING);
  assign in_POST    = (state == POST);

  //Pulse for new data avaible
  assign new_data = last_POST & in_IDLE;

  //delayed in_POST
  always@(posedge clk)
    begin
      last_POST <= in_POST;
    end
  
  //stopper
  always @(posedge clk) 
    begin
      stopper <= (in_IDLE) ? 1'b1 : ((transaction_counter == 4'd8) ? 1'b0 : stopper);
    end
  
  //SPI states
  always@(posedge clk)
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
                state <= (read) ? PRE : state;
              end
            PRE:
              begin
                state <= (~clk_array[2]) ? WORKING : state;
              end
            WORKING:
              begin
                state <= (~|{transaction_counter, stopper}) ? POST : state;
              end
            POST:
              begin
                state <= IDLE;
              end
          endcase
        end
    end

  //SPI transaction counter
  always@(posedge SPI_SCLK or posedge rst)
    begin
      if(rst)
        begin
          transaction_counter <= 4'd0;
        end
      else
        begin
          transaction_counter <= transaction_counter + 4'd1;
        end
    end

  //Receive buffer
  always@(posedge SPI_SCLK or posedge rst)
    begin
      if(rst)
        begin
          rx_buff <= 12'd0;
        end
      else
        begin
          rx_buff <= {rx_buff[11:0], MISO};
        end
    end

  //Store receive buffer data to audio
  always@(posedge clk)
    begin  
      audio <= (in_POST) ? rx_buff[12:1] : audio;
    end

  assign CS = in_IDLE;

  //SPI clock should not work when not in use
  assign SPI_SCLK = (in_WORKING) ? ~clk_array[2] : 1'b1;

  //Clock dividers
  //50 MHz
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
  //25 MHz
  always@(posedge clk_array[0] or posedge rst)
    begin
      if(rst)
        begin
          clk_array[1] <= 0;
        end
      else
        begin
          clk_array[1] <= ~clk_array[1];
        end
    end
  //12,5 MHz
  always@(posedge clk_array[1] or posedge rst)
    begin
      if(rst)
        begin
          clk_array[2] <= 0;
        end
      else
        begin
          clk_array[2] <= ~clk_array[2];
        end
    end
endmodule//mic3
