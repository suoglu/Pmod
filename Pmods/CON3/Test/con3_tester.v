/* ------------------------------------------------ *
 * Title       : Pmod CON3 Tester                   *
 * Project     : Pmod CON3 Interface                *
 * ------------------------------------------------ *
 * File        : con3_tester.v                      *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 30/05/2021                         *
 * ------------------------------------------------ *
 * Description : This module can be used to test    *
 *               pmod con3 interface module         *
 * ------------------------------------------------ */

module con3_tester(
  input CLK100MHZ,
  input rstn,
  output rst,
  //UART to computer, 8bit No parity 1bit stop 115200
  output tx,
  input rx,
  //board i/o
  output [3:0] led,
  //Interface connection
  output reg [7:0] angle);
  wire clk;
  wire clk_uart_tx, clk_uart_rx, uart_enable_tx, uart_enable_rx, uart_out_valid, uart_new_data;
  wire [7:0] uart_data_o, uart_data_i;
  wire ready_tx, ready_rx;
  reg uart_send_pre, uart_send;

  assign uart_data_i = uart_data_o;
  assign led = {2'd0, ready_tx, ready_rx};
  assign clk = CLK100MHZ;
  assign rst = ~rstn;

  always@(posedge clk) begin
    uart_send <= uart_send_pre;
    uart_send_pre <= uart_new_data;
  end

  always@(posedge clk or posedge rst)
    if(rst) begin
      angle <= 8'h0;
    end else begin
      angle <= (uart_new_data) ? uart_data_o : angle;
  end
  
  //UART modules
  uart_transceiver uart_conn(clk, rst, tx, rx, clk_uart_tx, clk_uart_rx, uart_enable_tx, uart_enable_rx,1'b1,1'b0,2'b0,1'b0, uart_data_i, uart_data_o, uart_out_valid, uart_new_data, ready_tx, ready_rx, uart_send);
  uart_clk_gen txclk(clk, rst, uart_enable_tx, clk_uart_tx, 1'b1, 3'd2);
  uart_clk_gen rxclk(clk, rst, uart_enable_rx, clk_uart_rx, 1'b1, 3'd2);
endmodule