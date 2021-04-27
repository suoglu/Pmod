/* ------------------------------------------------- *
 * Title       : Pmod TMP3 Tester                    *
 * Project     : Pmod Collection                     *
 * ------------------------------------------------- *
 * File        : tester_tmp3.v                       *
 * Author      : Yigit Suoglu                        *
 * Last Edit   : 27/04/2021                          *
 * ------------------------------------------------- *
 * Description : Test Module for Pmod TMP3 Interface *
 * ------------------------------------------------- */
//   `include "Utils/btn_debouncer.v"
//  `include "Utils/ssd_util.v"

module tester_tmp3(
  input clk,
  input rst,
  //Board connections
  input [13:0] sw, //{interrupt_mode,alert_polarity,fault_queue,resolution} and temperature in
  //SW[15] Shutdown
  //SW[14] write_hyst_nLim
  input btnU, //write_temperature
  input btnR, //update
  input btnD, //config
  output [2:0] led,
  output [3:0] an,
  output [6:0] seg,
  //TMP3 connections
  output reg  [1:0] resolution,
  output reg alert_polarity,
  output reg [1:0] fault_queue,
  output reg interrupt_mode,
  output update,
  input busy,
  output write_temperature,
  input valid_o,
  input i2cBusy,
  input [11:0] temperature_o,
  output reg [8:0] temperature_i);
  reg [11:0] temperature;
  wire update_config;
  //reg update_cap, write_temp_cap;
  wire update_btn;

  assign led = {i2cBusy, busy, valid_o};
  assign update = update_btn | sw[13];

  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          temperature_i <= 9'h0;
        end
      else
        begin
          temperature_i <= (write_temperature) ? sw[8:0] : temperature_i;
        end
    end

  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          temperature <= 12'h0;
        end
      else
        begin
          temperature <= (valid_o) ? temperature_o : temperature;
        end
    end
  
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          resolution <= 2'd0;
          fault_queue <= 2'd0;
          alert_polarity <= 1'd0;
          interrupt_mode <= 1'd0;
        end
      else
        begin
          if(update_config)
            begin
              resolution <= sw[1:0];
              fault_queue <= sw[3:2];
              alert_polarity <= sw[4];
              interrupt_mode <= sw[5];
            end
        end
    end

  //IO controllers
  ssdController4 ssdCntroller(clk, rst, 4'b0111, , temperature[11:8], temperature[7:4], temperature[3:0], seg, an);
  debouncer dbU(clk, rst, btnU, write_temperature);
  debouncer dbR(clk, rst, btnR, update_btn);
  debouncer dbD(clk, rst, btnD, update_config);
endmodule