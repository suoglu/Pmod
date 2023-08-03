/* ------------------------------------------------ *
 * Title       : UART interface  v1.2               *
 * Project     : Simple UART                        *
 * ------------------------------------------------ *
 * File        : uart.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 23/05/2021                         *
 * Licence     : CERN-OHL-W                         *
 * ------------------------------------------------ *
 * Description : UART communication modules         *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 *     v1.1    : Redeclerations of clk_uart in     *
 *               Tx and Rx modules removed          *
 *     v1.2    : Move UART generation into outside  *
 *               of UART modules                    *
 * ------------------------------------------------ */

module uart_transceiver(
  input clk,
  input rst,
  //UART
  output tx,
  input rx,
  //Uart clock connection
  input clk_uart_tx,
  input clk_uart_rx,
  output uart_enable_tx,
  output uart_enable_rx,
  //Config signals 
  input data_size, //0: 7bit; 1: 8bit
  input parity_en,
  input [1:0] parity_mode, //11: odd; 10: even, 01: mark(1), 00: space(0)
  input stop_bit_size, //0: 1bit; 1: 2bit
  //Data interface
  input [7:0] data_i,
  output [7:0] data_o,
  output valid,
  output new_data,
  output ready_tx,
  output ready_rx,
  input send);
  
  uart_rx RxUART(clk, rst, rx, clk_uart_rx, uart_enable_rx, data_size, parity_en, parity_mode, data_o, valid, ready_rx, new_data);

  uart_tx TxUART(clk, rst, tx, clk_uart_tx, uart_enable_tx, data_size, parity_en, parity_mode, stop_bit_size, data_i, ready_tx, send);
endmodule//uart_dual

module uart_tx(
  input clk,
  input rst,
  //UART transmit
  output reg tx,
  //Uart clock connection
  input clk_uart,
  output uart_enable,
  //Config signals
  input data_size, //0: 7bit; 1: 8bit
  input parity_en,
  input [1:0] parity_mode, //11: odd; 10: even, 01: mark(1), 00: space(0)
  input stop_bit_size, //0: 1bit; 1: 2bit
  //Data interface
  input [7:0] data,
  output ready,
  input send);
  localparam READY = 3'b000,
             START = 3'b001,
              DATA = 3'b011,
            PARITY = 3'b110,
               END = 3'b100;
  reg [2:0] counter;
  reg [2:0] state;
  reg [7:0] data_buff;
  wire in_Ready, in_Start, in_Data, in_Parity, in_End;
  reg en, parity_calc, in_End_d;
  wire countDONE;
  
  //Decode states
  assign in_Ready = (state == READY);
  assign in_Start = (state == START);
  assign in_Data = (state == DATA);
  assign in_Parity = (state == PARITY);
  assign in_End = (state == END);
  assign ready = in_Ready;


  assign countDONE = (in_End & (counter[0] == stop_bit_size)) | (in_Data & (counter == {2'b11, data_size}));
  assign uart_enable = en & (~in_End_d | in_End);

  //Internal enable signal
  always@(posedge clk)
    begin
      if(rst)
        begin
          en <= 1'd0;
        end
      else
        begin
          case(en)
            1'b0:
              begin
                en <= send;
              end
            1'b1:
              begin
                en <= ~in_End_d | in_End; //only high on negative edge
              end
          endcase
        end
    end
  
  //State transactions
  always@(negedge clk_uart or posedge rst)
    begin
      if(rst)
        begin
          state <= READY;
        end
      else
        begin
          case(state)
            READY:
              begin
                state <= (en) ? START : state;
              end
            START:
              begin
                state <= DATA;
              end
            DATA:
              begin
                state <= (countDONE) ? ((parity_en) ? PARITY : END) : state;
              end
            PARITY:
              begin
                state <= END;
              end
            END:
              begin
                state <= (countDONE) ? READY : state;
              end
            default:
              begin
                state <= READY;
              end
          endcase
        end
    end
  
  //delay in_End
  always@(posedge clk) in_End_d <= in_End;

  //Counter
  always@(negedge clk_uart or posedge rst)
    begin
      if(rst)
        begin
          counter <= 3'd0;
        end
      else
        begin
          case(state)
            DATA:
              begin
                counter <= (countDONE) ? 3'd0 : (counter + 3'd1);
              end
            END:
              begin
                counter <= (countDONE) ? 3'd0 : (counter + 3'd1);
              end
            default:
              begin
                counter <= 3'd0;
              end
          endcase
          
        end
    end
  
  //handle data_buff
  always@(negedge clk_uart)
    begin
      case(state)
        START:
          begin
            data_buff <= data;
          end
        DATA:
          begin
            data_buff <= (data_buff >> 1);
          end
        default:
          begin
            data_buff <= data_buff;
          end
      endcase
    end
  
  //tx routing
  always@*
    begin
      case(state)
        START:
          begin
            tx = 1'b0;
          end
        DATA:
          begin
            tx = data_buff[0];
          end
        PARITY:
          begin
            tx = parity_calc;
          end
        default:
          begin
            tx = 1'b1;
          end
      endcase
      
    end
  
  //Parity calc
  always@(posedge clk_uart)
    begin
      if(in_Start) //reset
        begin
          parity_calc <= parity_mode[0];
        end
      else
        begin
          parity_calc <= (in_Data) ? (parity_calc ^ (tx & parity_mode[1])) : parity_calc;
        end
    end
endmodule//uart_tx

module uart_rx(
  input clk,
  input rst,
  //UART receive
  input rx,
  //Uart clock connection
  input clk_uart,
  output uart_enable,
  //Config signals
  input data_size, //0: 7bit; 1: 8bit
  input parity_en,
  input [1:0] parity_mode, //11: odd; 10: even, 01: mark(1), 00: space(0)
  //Data interface
  output reg [7:0] data,
  output reg valid,
  output ready,
  output newData);
  localparam READY = 3'b000,
             START = 3'b001,
              DATA = 3'b011,
            PARITY = 3'b110,
               END = 3'b100;
  reg [2:0] counter; 
  reg [2:0] state;
  reg [7:0] data_buff;
  wire in_Ready, in_Start, in_Data, in_Parity, in_End;
  reg parity_calc, in_End_d, en;

  //Decode states
  assign in_Ready = (state == READY);
  assign in_Start = (state == START);
  assign in_Data = (state == DATA);
  assign in_Parity = (state == PARITY);
  assign in_End = (state == END);
  assign ready = in_Ready;

  assign newData = ~in_End & in_End_d; //New data add negedge of in_End
  assign countDONE = in_Data & (counter == {2'b11, data_size});
  assign uart_enable = en & (~in_End_d | in_End);

  //internal enable
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          en <= 1'b0;
        end
      else
        begin
          case(en)
            1'b0:
              begin
                en <= (rx) ? en : 1'b1;
              end
            1'b1:
              begin
                en <= ~in_End_d | in_End;
              end
          endcase
          
        end
    end
  
  //Counter
  always@(negedge clk_uart or posedge rst)
    begin
      if(rst)
        begin
          counter <= 3'd0;
        end
      else
        begin
          case(state)
            DATA:
              begin
                counter <= (countDONE) ? 3'd0 : (counter + 3'd1);
              end
            default:
              begin
                counter <= 3'd0;
              end
          endcase
        end
    end
  
  //State transactions
  always@(negedge clk_uart or posedge rst)
    begin
      if(rst)
        begin
          state <= READY;
        end
      else
        begin
          case(state)
            READY:
              begin
                state <= (en) ? START : state;
              end
            START:
              begin
                state <= DATA;
              end
            DATA:
              begin
                state <= (countDONE) ? ((parity_en) ? PARITY : END) : state;
              end
            PARITY:
              begin
                state <= END;
              end
            END:
              begin
                state <= READY;
              end
            default:
              begin
                state <= READY;
              end
          endcase
        end
    end

  //delay in_End
  always@(posedge clk) in_End_d <= in_End;

  //Store received data
  always@(posedge clk)
    begin
      if(in_End)
        data <= data_buff;
    end
  
  //Handle data_buff
  always@(posedge clk_uart)
    begin
      case(state)
        START:
          begin //clear buffer
            data_buff <= 8'd0;
          end
        DATA:
          begin //Shift in new data from MS
            data_buff <= {rx, data_buff[7:1]};
          end
        END:
          begin //Shift one more 7bit data mode
            data_buff <= (data_size) ? data_buff : (data_buff >> 1);
          end
        default:
          begin
            data_buff <= data_buff;
          end
      endcase
      
    end
  
  //Parity check
  always@(posedge clk)
    begin
      if(rst)
        begin
          valid <= 1'b0;
        end
      else
        begin
          valid <= (in_Parity) ? (rx == parity_calc) : valid;
        end
    end
  
  //Parity calc
  always@(posedge clk_uart)
    begin
      if(in_Start) //reset
        begin
          parity_calc <= parity_mode[0];
        end
      else
        begin
          parity_calc <= (in_Data) ? (parity_calc ^ (rx & parity_mode[1])) : parity_calc;
        end
    end
endmodule//uart_tx
