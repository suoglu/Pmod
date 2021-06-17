/* ------------------------------------------------ *
 * Title       : Pmod CMPS2 interface tester        *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : cmps2_tester.v                     *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 17/06/2021                         *
 * ------------------------------------------------ *
 * Description : Tester module for pmod cmps2       *
 *               interface                          *
 * ------------------------------------------------ */
// `include "Utils/uart.v"
// `include "Utils/uart_clock.v"
// `include "Utils/btn_debouncer.v"

module cmps2_tester(
  input clk,
  input rst,
  //UART to computer, 8bit No parity 1bit stop 115200
  output tx,
  //Interface connections
  input [15:0] x_axis,
  input [15:0] y_axis,
  input [15:0] z_axis,
  output [1:0] resolution,
  input [15:0] x_offset,
  input [15:0] y_offset,
  input [15:0] z_offset,
  output calibrate, //btnR
  output measure, //btnL
  input valid,
  //Board connections
  input btnR,
  input btnL,
  output [1:0] debug,
  input [15:0] sw,
  output [15:0] led,
  output [6:0] seg,
  output [3:0] an);
  wire clk_uart, uart_enable, uart_ready;
  wire new_measure;
  wire [3:0] digit0, digit1, digit2, digit3;
  reg [15:0] ssd_in;
  reg uart_send;
  reg [7:0] uart_data_send;
  reg valid_d, uart_send_d;
  wire valid_posedge, uart_send_negedge;
  localparam IDLE = 0,
             WAIT = 1,
             XDATA_MSB = 2,
             XDATA_LSB = 3,
             YDATA_MSB = 4,
             YDATA_LSB = 5,
             ZDATA_MSB = 6,
             ZDATA_LSB = 7,
             XOFFS_MSB = 8,
             XOFFS_LSB = 9,
             YOFFS_MSB = 10,
             YOFFS_LSB = 11,
             ZOFFS_MSB = 12,
             ZOFFS_LSB = 13;
  reg [3:0] state;

  assign resolution = sw[1:0];

  assign new_measure = calibrate|measure;

  assign {digit3, digit2, digit1, digit0} = ssd_in;
  assign debug[1] = valid;
  assign debug[0] = new_measure | (state == WAIT);

  assign valid_posedge = ~valid_d & valid;
  assign uart_send_negedge = ~uart_send & uart_send_d;
  always@(posedge clk) begin
    valid_d <= valid;
    uart_send_d <= uart_send;
  end

  always@* begin
    case(sw[15:14])
      2'b01: ssd_in = y_axis;
      2'b10: ssd_in = z_axis;
      default: ssd_in = x_axis;
    endcase
  end

  always@(posedge clk or posedge rst)
    if(rst) begin
      uart_send <= 0;
    end else begin
      case(uart_send)
        1'b0: uart_send <= uart_ready & (state != IDLE) & (state != WAIT);
        1'b1: uart_send <= uart_ready;
      endcase
    end

  debouncer dbL(clk, rst, btnR, calibrate);
  debouncer dbR(clk, rst, btnL, measure);

  always@(posedge clk or posedge rst)
    if(rst) begin
      state <= IDLE;
    end else begin
      case(state)
        IDLE: state <= (new_measure) ? WAIT : IDLE;
        WAIT: state <= (valid_posedge) ? XDATA_MSB : WAIT;
        ZOFFS_LSB: state <= (uart_send_negedge) ? IDLE : state;
        default: state <= (uart_send_negedge) ? state + 1 : state;
      endcase
      
    end

  always@* begin
    case(state)
/*       XDATA_MSB: uart_data_send = x_axis[15:8];
      XDATA_LSB: uart_data_send = x_axis[7:0];
      YDATA_MSB: uart_data_send = y_axis[15:8];
      YDATA_LSB: uart_data_send = y_axis[7:0];
      ZDATA_MSB: uart_data_send = z_axis[15:8];
      ZDATA_LSB: uart_data_send = z_axis[7:0];
      XOFFS_MSB: uart_data_send = x_offset[15:8];
      XOFFS_LSB: uart_data_send = x_offset[7:0];
      YOFFS_MSB: uart_data_send = y_offset[15:8];
      YOFFS_LSB: uart_data_send = y_offset[7:0];
      ZOFFS_MSB: uart_data_send = z_offset[15:8];
      ZOFFS_LSB: uart_data_send = z_offset[7:0];
      default: uart_data_send = 8'hff; */

      XDATA_LSB: uart_data_send = x_axis[15:8]; 
      YDATA_MSB: uart_data_send = x_axis[7:0];
      YDATA_LSB: uart_data_send = y_axis[15:8];
      ZDATA_MSB: uart_data_send = y_axis[7:0];
      ZDATA_LSB: uart_data_send = z_axis[15:8];
      XOFFS_MSB: uart_data_send = z_axis[7:0];
      XOFFS_LSB: uart_data_send = x_offset[15:8];
      YOFFS_MSB: uart_data_send = x_offset[7:0];
      YOFFS_LSB: uart_data_send = y_offset[15:8];
      ZOFFS_MSB: uart_data_send = y_offset[7:0];
      ZOFFS_LSB: uart_data_send = z_offset[15:8];
      default: uart_data_send = z_offset[7:0];
    endcase
  end

  ssdController4 ssd(clk, rst, 4'b1111, digit3, digit2, digit1, digit0, seg, an);

  //UART modules
  uart_tx uartconn(clk,rst,tx,clk_uart,uart_enable,1'b1,1'b0,2'b0,1'b0,uart_data_send,uart_ready,uart_send);
  uart_clk_gen uartclk(clk,rst,uart_enable,clk_uart,1'b1, 3'd2);
endmodule