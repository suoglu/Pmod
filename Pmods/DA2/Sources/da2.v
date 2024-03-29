/* ------------------------------------------------ *
 * Title       : Pmod DA2 interface v1.2            *
 * Project     : Pmod DA2 interface                 *
 * ------------------------------------------------ *
 * File        : da2.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 27/05/2021                         *
 * Licence     : CERN-OHL-W                         *
 * ------------------------------------------------ *
 * Description : Simple interfaces to communicate   *
 *               with Pmod DA2                      *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 *     v1.1    : Module to generate update signal   *
 *               automatically with a change in     *
 *               value added                        *
 *     v1.2    : Module to use an external clock    *
 *               source and rename SCLK_en to       *
 *               working                            *
 * ------------------------------------------------ */

module da2(
  input clk,
  input rst,
  //Serial data line
  input SCLK,
  output SDATA,
  output reg SYNC,
  //Enable clock
  output reg working,
  //Output value and mode
  input [1:0] chmode,
  //Channel modes: 00 Enabled, Power off modes: 01 1kOhm, 10 100kOhm, 11 High-Z 
  input [11:0] value,
  //Control signals
  input update);
  reg count;
  reg contCount;
  reg [3:0] counter; //Count edges
  wire [15:0] SDATAbuff_cont;
  reg [15:0] SDATAbuff;

  //Handle SDATA buffer
  assign SDATAbuff_cont = {2'd0, chmode, value};
  assign SDATA = SDATAbuff[15];
  always@(posedge SCLK or posedge SYNC) begin
    if(SYNC) begin
      SDATAbuff <= SDATAbuff_cont;
    end else begin
      SDATAbuff <= (count) ? {SDATAbuff[14:0], 1'b0} : SDATAbuff;
    end
  end

  //count
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      count <= 1'b0;
    end else case(count)
      1'b0: count <= SCLK & contCount;
      1'b1: count <= (counter != 4'd0) | contCount;
    endcase
  end
  
  //contCount
  always@(posedge clk or posedge SYNC) begin
    if(SYNC) begin
      contCount <= 1'b1;
    end else begin
      contCount <= working & contCount & (counter != 4'd15);
    end
  end
  
  //working
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      working <= 1'b0;
    end else case(working)
      1'b0: working <= SYNC;
      1'b1: working <= (counter != 4'd0) | contCount;
    endcase
  end
  
  //SYNC
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      SYNC <= 1'b0;
    end else case(SYNC)
      1'b0: SYNC <= update & ~(contCount | count);
      1'b1: SYNC <= 1'b0;
    endcase
  end
  
  //Count SCLK
  always@(negedge SCLK or posedge SYNC) begin
    if(SYNC) begin
      counter <= 4'd0;
    end else begin
      counter <= counter + {3'd0, count};
    end
  end 
endmodule//da2

module da2_dual(
  input clk,
  input rst,
  //Serial data line
  input SCLK,
  output [1:0] SDATA,
  output reg SYNC,
  //Enable clock
  output reg working,
  //Output value and mode
  input [1:0] chmode0,
  input [1:0] chmode1,
  //Channel modes: 00 Enabled, Power off modes: 01 1kOhm, 10 100kOhm, 11 High-Z 
  input [11:0] value0,
  input [11:0] value1,
  //Control signals
  input update);
  reg count;
  reg contCount;
  reg [3:0] counter; //Count edges
  wire [15:0] SDATAbuff_cont0, SDATAbuff_cont1;
  reg [15:0] SDATAbuff0, SDATAbuff1;

  //Handle SDATA buffer
  assign SDATAbuff_cont0 = {2'd0, chmode0, value0};
  assign SDATAbuff_cont1 = {2'd0, chmode1, value1};
  assign SDATA = {SDATAbuff1[15], SDATAbuff0[15]};
  always@(posedge SCLK or posedge SYNC) begin
    if(SYNC) begin
      SDATAbuff0 <= SDATAbuff_cont0;
      SDATAbuff1 <= SDATAbuff_cont1;
    end else begin
      SDATAbuff0 <= (count) ? {SDATAbuff0[14:0], 1'b0} : SDATAbuff0;
      SDATAbuff1 <= (count) ? {SDATAbuff1[14:0], 1'b0} : SDATAbuff1;
    end
  end

  //count
  always@(posedge clk or posedge rst) begin
    if(rst) begin
        count <= 1'b0;
    end else case(count)
      1'b0: count <= SCLK & contCount;
      1'b1:  count <= (counter != 4'd0) | contCount;
    endcase
  end
  
  //contCount
  always@(posedge clk or posedge SYNC) begin
    if(SYNC) begin
      contCount <= 1'b1;
    end else begin
      contCount <= working & contCount & (counter != 4'd15);
    end
  end
  
  
  //working
  always@(posedge clk or posedge rst) begin
    if(rst) begin
        working <= 1'b0;
    end else case(working)
      1'b0: working <= SYNC;
      1'b1: working <= (counter != 4'd0) | contCount;
    endcase
  end
  
  //SYNC
  always@(posedge clk or posedge rst) begin
    if(rst) begin
        SYNC <= 1'b0;
    end else case(SYNC)
      1'b0: SYNC <= update & ~(contCount | count);
      1'b1: SYNC <= 1'b0;
    endcase
  end
  
  //Count SCLK
  always@(negedge SCLK or posedge SYNC) begin
    if(SYNC) begin
      counter <= 4'd0;
    end else begin
      counter <= counter + {3'd0, count};
    end
  end 
endmodule//da2

module da2AutoUpdate(
  input clk,
  input rst,
  input SYNC,
  output update,
  input [1:0] chmode,
  input [11:0] value);
  reg [1:0] chmode_reg;
  reg [11:0] value_reg;

  assign update = (chmode != chmode_reg) | (value != value_reg);

  //Store values to compare
  always@(posedge SYNC or posedge rst) begin
    if(rst) begin
      chmode_reg <= 2'd0;
      value_reg <= 12'd0;
    end else begin
      chmode_reg <= chmode;
      value_reg <= value;
    end
  end
endmodule//da2AutoUpdate

module da2AutoUpdate_dual(
  input clk,
  input rst,
  input SYNC,
  output update,
  input [1:0] chmode0,
  input [1:0] chmode1,
  input [11:0] value0,
  input [11:0] value1);
  reg [1:0] chmode_reg0, chmode_reg1;
  reg [11:0] value_reg0, value_reg1;

  assign update = (chmode0 != chmode_reg0) | (value0 != value_reg0) | (chmode1 != chmode_reg1) | (value1 != value_reg1);

  //Store values to compare
  always@(posedge SYNC or posedge rst) begin
    if(rst) begin
      chmode_reg0 <= 2'd0;
      value_reg0 <= 12'd0;
      chmode_reg1 <= 2'd0;
      value_reg1 <= 12'd0;
    end else begin
      chmode_reg0 <= chmode0;
      value_reg0 <= value0;
      chmode_reg1 <= chmode1;
      value_reg1 <= value1;
    end
  end
endmodule//da2AutoUpdate

module da2ClkEn(
  input clk,
  input en,
  input ext_spi_clk,
  output SCLK);
  reg enabled;

  assign SCLK = (enabled) ? ext_spi_clk : 1'b0;

  always@(posedge clk) begin
    if(~en)
      enabled <= 1'b0;
    else
      enabled <= (enabled) ? 1'b1 : (~ext_spi_clk & en);
  end
endmodule

module clkDiv25en(
  input clk,
  input rst,
  input en,
  output reg SCLK);
  reg clk_m;

  //50 MHz
  always@(posedge clk) begin
    if(~en) begin
      clk_m <= 1'b0;
    end else begin
      clk_m <= ~clk_m;
    end
  end
  //25 MHz
  always@(posedge clk_m or negedge en) begin
    if(~en) begin
      SCLK <= 1'b0;
    end else begin
      SCLK <= ~SCLK;
    end
  end
endmodule//clkDiv25