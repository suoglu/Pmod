/* ------------------------------------------------ *
 * Title       : Pmod TMP2 Test module              *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : tester_tmp2.v                      *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 29/04/2021                         *
 * ------------------------------------------------ *
 * Description : This module is used to test Pmod   *
 *               TMP2 interface on Basys3           *
 * ------------------------------------------------ */
//    `include "Utils/btn_debouncer.v"
//  `include "Utils/ssd_util.v"

module testter_tmp2(
  input clk,
  input rst,
  //TMP2 pins
  output reg shutdown,
  output reg resolution,
  output reg sps1,
  output reg comparator_mode,
  output reg polarity_ct,
  output reg polarity_int,
  output reg [1:0] fault_queue,
  input i2cBusy,
  input busy,
  output sw_rst,
  output update, //btnR or SW[15]
  output reg one_shot,
  output write_temperature,
  output [1:0] write_temp_target,
  input valid_o,
  input [15:0] temperature_o,
  output reg [15:0] temperature_i,
  //Basys3 GPIO
  input [15:0] sw, //{fault_queue(2bit),polarity_int,polarity_ct,sps1,comparator_mode,one_shot,resolution}
  output [15:0] led,
  input btnR, //Update
  input btnL, //Write temp
  input btnD, //Config
  input btnU, //Shutdown
  output [3:0] an,
  output [6:0] seg);
  wire update_btn, shutdown_btn, config_btn;
  reg [15:0] temperature_o_reg;

  always@(posedge clk)
    begin
      if(valid_o)
        begin
          temperature_o_reg <= temperature_o;
        end
    end

  always@(posedge clk)
    begin
      if(write_temperature)
        begin
          temperature_i <= sw;
        end
    end
  
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          shutdown <= 1'b0;
        end
      else
        begin
          shutdown <= shutdown ^ shutdown_btn;
        end
    end
  
  assign write_temp_target = 2'd3; //T High
  assign sw_rst = 1'b0;
  assign update = update_btn | sw[15];
  assign led = {13'd0,valid_o,i2cBusy,busy};

  always@(posedge clk or posedge rst)
    begin
      if(rst) begin
        sps1 <= 1'b0;
        resolution <= 1'b0;
        comparator_mode  <= 1'b0;
        one_shot <= 1'b0;
        polarity_ct <= 1'b0;
        polarity_int <= 1'b0;
        fault_queue <= 2'b0;
      end else begin
        if(config_btn) 
          begin
            sps1 <= sw[3];
            resolution <= sw[0];
            comparator_mode  <= sw[2];
            one_shot <= sw[1];
            polarity_ct <= sw[4];
            polarity_int <= sw[5];
            fault_queue <= sw[7:6];
          end else begin
            one_shot <= one_shot & ~busy;
          end
      end
    end
  
  //GPIO controllers
  ssdController4 ssdCntrol(clk, rst, 4'b1111, temperature_o_reg[15:12], temperature_o_reg[11:8], temperature_o_reg[7:4], temperature_o_reg[3:0], seg, an);
  debouncer dbR(clk, rst, btnR, update_btn);
  debouncer dbU(clk, rst, btnU, shutdown_btn);
  debouncer dbL(clk, rst, btnL, write_temperature);
  debouncer dbD(clk, rst, btnD, config_btn);
endmodule