/* ------------------------------------------------ *
 * Title       : Pmod TC1 Tester                    *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : tc1_test_module.v                  *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 25/04/2021                         *
 * ------------------------------------------------ *
 * Description : Test Module for Pmod TC1 Interface *
 * ------------------------------------------------ */
// `include "Utils/btn_debouncer.v"
// `include "Utils/ssd_util.v"

module tc1_tester(
  input clk,
  input rst,
  //TC1 Interface Connections
  output update,
  output update_fault,
  output update_all,
  input busy,
  input [13:0] temperature_termoc,
  input [11:0] temperature_internal,
  input [2:0] status,
  input fault,
  //SPI Ports
  input SCLK,
  input MISO,
  input CS,
  //Board GPIO
  input btnU, //update_btn
  input btnR, //update_fault_btn
  input btnD, //update_all_btn
  input [2:0] sw, //{update_all,update_fault,update}
  output [3:0] an, //SSDs temperature_termoc
  output [6:0] seg,
  output [15:0] led, //{fault, status, temperature_internal}
  output [3:0] JB);
  //Keep read values stable
  reg [13:0] Ttermoc;
  reg [11:0] Tinternal;
  reg fault_reg;
  reg [2:0] stat;
  //Clear btns
  wire update_btn;
  wire update_fault_btn;
  wire update_all_btn;

  //GPIO Routing
  assign led = {fault_reg, stat, Tinternal};
  assign update = update_btn | sw[0];
  assign update_fault = update_fault_btn | sw[1];
  assign update_all = update_all_btn | sw[2];
  assign JB = {SCLK,MISO,CS,busy};

  //Keep module outputs stable
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          Ttermoc <= 14'd0;
          Tinternal <= 12'd0;
          fault_reg  <= 1'd0;
          stat  <= 3'd0;
        end
      else
        begin
          if(~busy)
            begin
              Ttermoc <= temperature_termoc;
              Tinternal <= temperature_internal;
              fault_reg  <= fault;
              stat  <= status;
            end
        end
    end

  //GPIO Controllers
  debouncer dbU(clk, rst, btnU, update_btn);
  debouncer dbR(clk, rst, btnR, update_fault_btn);
  debouncer dbD(clk, rst, btnD, update_all_btn);
  ssdController4 ssdCntrol(clk, rst, 4'b1111, {2'b0,Ttermoc[13:12]}, Ttermoc[11:8], Ttermoc[7:4], Ttermoc[3:0], seg, an);

endmodule
