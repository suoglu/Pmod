/* ------------------------------------------------ *
 * Title       : Pmod TC1 interface v1.0            *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : tc1.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 25/04/2021                         *
 * ------------------------------------------------ *
 * Description : Simple interface to communicate    *
 *               with Pmod TC1                      *
 * ------------------------------------------------ */

module tc1(
  input clk,
  input rst,
  input clk_spi, //Max 5 MHz
  //SPI ports
  output SCLK,
  input MISO,
  output CS,
  //interface ports
  input update,
  input update_fault,
  input update_all,
  output busy, //Busy outputs are not valid
  output reg [13:0] temp_termoc,
  output reg [11:0] temp_internal,
  output reg [2:0] status, //thermocouple is [Vcc,GND,Open]
  output reg fault);
  reg [31:0] buffer;
  reg SCLK_mask;
  localparam IDLE = 2'd0,
           UP_STD = 2'd1,
           UP_FLT = 2'd2,
           UP_ALL = 2'd3;
  reg [1:0] state;
  wire inIDLE, inSTD, inFLT, inALL;
  reg [5:0] bitCounter;
  reg bitCountDone;

  //Decode states
  assign inIDLE = (state == IDLE);
  assign inSTD  = (state == UP_STD);
  assign inFLT  = (state == UP_FLT);
  assign inALL  = (state == UP_ALL);

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
                if(clk_spi) 
                  begin//We switch when clk_spi high to met timing
                    if(update_all)
                      begin
                        state <= UP_ALL;
                      end
                    else if(update_fault)
                      begin
                        state <= UP_FLT;
                      end
                    else if(update)
                      begin
                        state <= UP_STD;
                      end
                  end
              end
            default:
              begin
                state <= (bitCountDone) ? IDLE : state;
              end
          endcase
        end
    end

  //State derived signals
  assign CS = inIDLE;
  assign busy = ~inIDLE;

  //Disable SCLK when not in use
  assign SCLK = clk_spi & SCLK_mask;

  //Store incoming data
  always@(posedge SCLK)
    begin
      buffer <= {buffer[30:0], MISO};
    end
  
  //Buffer to output ports
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          temp_termoc <= 14'd0;
          temp_internal <= 12'd0;
          status <= 2'd0;
          fault <= 1'd0;
        end
      else
        case(state)
          UP_STD:
            begin
              temp_termoc <= buffer[13:0];
            end
          UP_FLT:
            begin
              temp_termoc <= buffer[15:2];
              fault <= buffer[0];
            end
          UP_ALL:
            begin
              temp_termoc <= buffer[31:18];
              fault <= buffer[16];
              temp_internal <= buffer[15:4];
              status <= buffer[2:0];
            end
        endcase
    end
  
  //Determine bitCountDone
  always@*
    begin
      case(state)
        UP_STD:
          begin
            bitCountDone = (bitCounter == 6'd13);
          end
        UP_FLT:
          begin
            bitCountDone = (bitCounter == 6'd15);
          end
        UP_ALL:
          begin
            bitCountDone = (bitCounter == 6'd31);
          end
        default:
          begin
            bitCountDone = (bitCounter == 6'h0);
          end
      endcase
    end
  
  //Count negative edges of clock
  always@(negedge SCLK or posedge rst)
    begin
      if(rst)
        begin
          bitCounter <= 6'd0;
        end
      else
        begin
          bitCounter <= (bitCountDone) ? 6'h0 : bitCounter + 6'h1;
        end
    end
  
  //Clock mask
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          SCLK_mask <= 1'b0;
        end
      else
        begin
          case(SCLK_mask)
            1'b0:
              begin
                SCLK_mask <= ~clk_spi & ~inIDLE;
              end
            1'b1:
              begin
                SCLK_mask <= ~(~clk_spi & inIDLE);
              end
          endcase
        end
    end
endmodule