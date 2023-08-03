/* -------------------------------------------- *
 * Title       : Parameterised Clock Generator  *
 * Project     : Verilog Utility Modules        *
 * -------------------------------------------- *
 * File        : clkGenParam.v                  *
 * Author      : Yigit Suoglu                   *
 * Last Edit   : 23/01/2021                     *
 * Licence     : CERN-OHL-W                     *
 * -------------------------------------------- *
 * Description : Generates various clock freq.  *
 * -------------------------------------------- */

//OUTPUT_PERIOD should be even multiple of INPUT_PERIOD
module clock_generator_parametric #(parameter OUTPUT_PERIOD = 1000, parameter INPUT_PERIOD = 10)(
  input clk_i,
  input rst,
  input en,
  output reg clk_o);
  localparam CYCLE_COUNT = (OUTPUT_PERIOD / INPUT_PERIOD) / 2;
  localparam COUNTER_SIZE = $clog2(CYCLE_COUNT-1);

  wire countDone;
  reg [COUNTER_SIZE:0] counter;

  assign countDone = (counter == (CYCLE_COUNT-1));

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
          counter <= {COUNTER_SIZE{1'd0}};
      else
          counter <= (countDone) ? {COUNTER_SIZE{1'd0}} : (counter + {{(COUNTER_SIZE-1){1'd0}},en});
    end
endmodule//bitClkGen
