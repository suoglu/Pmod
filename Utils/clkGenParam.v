/* -------------------------------------------- *
 * Title       : Parameterised Clock Generator  *
 * Project     : Verilog Utility Modules        *
 * -------------------------------------------- *
 * File        : clkGenParam.v                  *
 * Author      : Yigit Suoglu                   *
 * Last Edit   : 23/01/2021                     *
 * -------------------------------------------- *
 * Description : Generates various clock freq.  *
 * -------------------------------------------- */

module clkGenP #(parameter PERIOD = 1020, parameter CLKPERIOD = 10)(
  input clk_i,
  input rst,
  input en,
  output reg clk_o);
  localparam CYCLESinHALFP = PERIOD / (2 * CLKPERIOD);
  localparam COUNTERSIZE = $clog2(CYCLESinHALFP-1);

  wire countDone;
  reg [COUNTERSIZE-1:0] counter;

  assign countDone = (counter == (CYCLESinHALFP-1));

  always@(posedge clk_i or posedge rst)
    begin
      if(rst)
        clk_o <= 1'd0;
      else
        clk_o <= (countDone) ? ~clk_o : clk_o;
    end
  
  always@(posedge clk_i or posedge rst)
    begin
      if(rst)
          counter <= {COUNTERSIZE{1'd0}};
      else
          counter <= (countDone) ? {COUNTERSIZE{1'd0}} : (counter + {{(COUNTERSIZE-1){1'd0}},en});
    end
endmodule//bitClkGen
