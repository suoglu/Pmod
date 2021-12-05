/* ------------------------------------------------ *
 * Title       : Pmod HB3 Interface v1              *
 * Project     : Pmod HB3 Interface                 *
 * ------------------------------------------------ *
 * File        : hb3.v                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 28/05/2021                         *
 * ------------------------------------------------ *
 * Description : Interface for HB3                  *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

module hb3(
  input clk,
  input rst,
  output reg motor_direction,
  output reg motor_enable,
  input direction_control,
  input [7:0] speed);
  reg [7:0] counter;
  wire counter_up;

  assign counter_up = (speed != 8'hff) & (speed != 8'h00);

  always@(posedge clk or posedge rst) begin
    if(rst) begin
      counter <= 8'h0;
    end else begin
      counter <= counter + {7'h0,counter_up};
    end
  end

  always@(posedge clk or posedge rst) begin
    if(rst) begin
      motor_enable <= 1'b0;
    end else case(speed)
      8'h00   : motor_enable <= 1'b0;
      8'hFF   : motor_enable <= (direction_control != motor_direction) ? 1'b0: 1'b1;
      default : 
        case(motor_enable)
          1'b0: motor_enable <= ~|counter;
          1'b1: motor_enable <= counter != speed;
        endcase
    endcase
  end

  always@(posedge clk) begin
    motor_direction <= (motor_enable) ? motor_direction : direction_control;
  end
endmodule