/* ------------------------------------------------ *
 * Title       : Pmod CON3 Interface v1             *
 * Project     : Pmod CON3 Interface                *
 * ------------------------------------------------ *
 * File        : con3.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 29/05/2021                         *
 * Licence     : CERN-OHL-W                         *
 * ------------------------------------------------ *
 * Description : Interface for CON3                 *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

module con3#(
  parameter HIGH_CYCLE = 1,
  parameter LOW_CYCLE = 2
)(
  input clk,
  input rst,
  input clk_256kHz,
  input en,
  output reg servo,
  input [7:0] angle);

  localparam TOTAL_CYCLE = HIGH_CYCLE + LOW_CYCLE + 1;
  localparam LAST_CYCLE = HIGH_CYCLE + LOW_CYCLE;
  localparam CYCLE_C_WIDTH = $clog2(TOTAL_CYCLE);
  localparam CYCLE_C_ADD_S = CYCLE_C_WIDTH - 1;

  reg [CYCLE_C_ADD_S:0] cycle_num;
  reg [7:0] counter;
  wire servo_inv;
  reg count_max_reg, count_done_reg;
  wire count_max, count_done;
  wire module_rst;
  wire servo_change_cycle, servo_set, servo_clear;
  wire last_cycle;

  assign module_rst = ~en | rst; //disable also resets

  assign servo_change_cycle = (cycle_num == HIGH_CYCLE);

  assign count_done = ~count_max & count_max_reg;
  assign count_max = &counter;
  assign servo_inv = servo_set | servo_clear;
  assign servo_clear = (counter == angle) & servo_change_cycle & servo;
  assign servo_set = ~|{cycle_num,counter} & ~servo;
  assign last_cycle = (cycle_num == LAST_CYCLE);

  //Servo control with regisrers
  always@(posedge clk or posedge module_rst) begin
    if(module_rst) begin
      servo <= 1'b0;
    end else begin
      servo <= servo ^ servo_inv;
    end
  end

  //Count angle steps
  always@(posedge clk_256kHz or posedge module_rst) begin
    if(module_rst) begin
      counter <= 8'hFF;
    end else begin
      counter <= counter + 8'h1;
    end
  end

  //ON-Controlled-Off cycles
  always@(posedge clk or posedge module_rst) begin
    if(module_rst) begin
      cycle_num <= {CYCLE_C_WIDTH{1'b1}};
    end else begin
      cycle_num <= (last_cycle & count_done) ? {CYCLE_C_WIDTH{1'b0}}  : (cycle_num + {{(CYCLE_C_WIDTH-1){1'b0}}, count_done});
    end
  end

  //Delayed signals
  always@(posedge clk) begin
    count_max_reg <= count_max;
    count_done_reg <= count_done;
  end
endmodule

module con3_clk_gen#(
    parameter CLK_PERIOD = 10
  )(
    input clk,
    input rst,
    output reg clk_256kHz);
    localparam COUNTER_LIMIT = (3_910 / CLK_PERIOD) / 2;
    localparam COUNTER_SIZE = $clog2(COUNTER_LIMIT);
    reg [(COUNTER_SIZE-1):0] counter;
    wire count_done;

    assign count_done = (counter == COUNTER_LIMIT);

    always@(posedge clk or posedge rst) begin
      if(rst) begin
        clk_256kHz <= 1'b0;
      end else begin
        clk_256kHz <= clk_256kHz ^ count_done;
      end
    end

    always@(posedge clk or posedge rst) begin
      if(rst) begin
        counter <= {COUNTER_SIZE{1'b0}};
      end else begin
        counter <= (count_done) ? {COUNTER_SIZE{1'b0}} : (counter + {{(COUNTER_SIZE-1){1'b0}},1'b1});
      end
    end
endmodule
