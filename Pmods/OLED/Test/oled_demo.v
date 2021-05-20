/* ------------------------------------------------ *
 * Title       : Pmod OLED Demo                     *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : oled_demo.v                        *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 20/05/2021                         *
 * ------------------------------------------------ *
 * Description : Demo module OLED module, displays  *
 *               all characters, works on Arty a7   *
 * ------------------------------------------------ */
//`include "Pmods/OLED/Sources/oled.v"
module oled_demo#(parameter CHAR_LIMIT = 8'h9b,
                  parameter CLK_PERIOD = 10)(
  input clk,
  input nrst,
  output rst,
  //Interface connections
  output power_on,
  output display_reset,
  output display_off,
  output update,
  output reg [511:0] display_data, 
  /* MSB(display_data[511:504]): left-up most 
            decreases as left to right
     LSB(display_data[7:0]): right bottum most) */
  output reg [1:0] line_count,
  output reg [7:0] contrast,
  output cursor_enable,
  output cursor_flash,
  output reg [5:0] cursor_pos,
  input CS,
  input MOSI,
  input SCK,
  input data_command_cntr,
  input power_rst,
  input vbat_c,
  input vdd_c,
  //Board connections
  output [7:0] pmod_header,
  input [3:0] sw,
  input [3:0] btn);
  wire ch_line, ch_contrast, ch_cursor;
  wire shift_data;
  wire [7:0] data_next, data_current;
  reg shift_data_reg;
  localparam DATA_PERIOD = 500_000_000 / CLK_PERIOD;
  localparam DATA_COUNTER_SIZE = $clog2(DATA_PERIOD-1);
  reg [DATA_COUNTER_SIZE:0] data_counter;
  reg counter_check;
  assign pmod_header = {vdd_c,vbat_c,power_rst,data_command_cntr,SCK,1'd0,MOSI,CS};

  assign led = {1'b1,clk,nrst,data_counter[DATA_COUNTER_SIZE]};

  assign update = ~shift_data & shift_data_reg;

  assign shift_data = ~&data_counter & counter_check;

  assign rst = ~nrst;

  assign data_current = display_data[511:504];

  assign {cursor_flash,cursor_enable,display_off,power_on} = sw;

  assign data_next = (data_current == CHAR_LIMIT) ? 8'h0 : (data_current+8'h1);

  always@(posedge clk)
    begin
      shift_data_reg <= shift_data;
      counter_check <= &data_counter;
    end


  always@(posedge clk or negedge nrst) //data counter
    begin
      if(~nrst)
        begin
          data_counter <= {(DATA_COUNTER_SIZE+1){1'b0}}; 
        end
      else
        begin
          data_counter <= data_counter + {{DATA_COUNTER_SIZE{1'b0}},~display_off&power_on}; 
        end
    end

  //Handle data array
  always@(posedge clk or negedge nrst)
    begin
      if(~nrst)
        begin
          display_data <= 512'h0;
        end
      else
        begin
          display_data <= (shift_data) ? {data_next,display_data[511:8]} : display_data;
        end
    end

  //Decerease line count with button0
  always@(posedge clk or negedge nrst)
    begin
      if(~nrst)
        begin
          line_count <= 2'h3;
        end
      else
        begin
          line_count <= line_count - {1'b0,ch_line};
        end
    end

  //Change contrast with button1
  always@(posedge clk or negedge nrst)
    begin
      if(~nrst)
        begin
          contrast <= 8'h7f;
        end
      else
        begin
          contrast <= contrast + {ch_contrast,7'h0};
        end
    end

  //Inrease cursor position with button2
  always@(posedge clk or negedge nrst)
    begin
      if(~nrst)
        begin
          cursor_pos <= 6'h0;
        end
      else
        begin
          cursor_pos <= cursor_pos + {5'h0,ch_cursor};
        end
    end

  debouncer db3(clk, rst, btn[3], display_reset);
  debouncer db2(clk, rst, btn[2], ch_cursor);
  debouncer db1(clk, rst, btn[1], ch_contrast);
  debouncer db0(clk, rst, btn[0], ch_line);
endmodule

module debouncer(clk, rst, in_n, out_c);
  input clk, rst, in_n;
  output out_c;

  reg [1:0] mid;

  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          mid <= 2'b0;
        end
      else
        begin
          mid <= {mid[0], in_n};
        end
    end

  assign out_c = (~mid[1]) & mid[0]; //rising edge

endmodule // debouncer rising edge
