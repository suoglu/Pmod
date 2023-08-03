/* ----------------------------------------------------- *
 * Title       : 8bit RGB LED driver                     *
 * Project     : Verilog Utility Modules                 *
 * ----------------------------------------------------- *
 * File        : rgb_led_pwm.v                           *
 * Author      : Yigit Suoglu                            *
 * Last Edit   : 19/01/2021                              *
 * Licence     : CERN-OHL-W                              *
 * ----------------------------------------------------- *
 * Description : Generate PWM signals to control RGB led *
 * ----------------------------------------------------- */

module rgb_led_controller8(clk, rst, rcolor_i, gcolor_i, bcolor_i, sync, half, r_o, g_o, b_o, an);
  input clk, rst;
  output sync, half; //start of a new cycle, second half of the cycle

  input an; //High when connecting to anode, low for cathode

  input [7:0] rcolor_i, gcolor_i, bcolor_i; //Color data ins
  output r_o, g_o, b_o; //Connected to LEDs

  reg [7:0] rcolor_reg, gcolor_reg, bcolor_reg;
  reg red, green, blue;
  reg [7:0] counter;

  assign r_o = red ^ an;
  assign g_o = green ^ an;
  assign b_o = blue ^ an;
  assign half = counter[7]; 
  assign sync = ~|counter;

  //Counter for full cycle
  always @(posedge clk or posedge rst) 
    begin
      if(rst)
        begin
          counter <= 8'd0;
        end
      else
        begin
          counter <= counter + 8'd1;
        end
    end

  //Only change color in new cycles
  always@(posedge sync or posedge rst)
    begin
      if(rst)
        begin
          rcolor_reg <= rcolor_i;
          gcolor_reg <= gcolor_i;
          bcolor_reg <= bcolor_i;
        end
      else
        begin
          rcolor_reg <= rcolor_i;
          gcolor_reg <= gcolor_i;
          bcolor_reg <= bcolor_i;
        end
    end
  
  //Drive LED pins
  always@(posedge clk)
    begin //       All 1s          All 0s         New cycle           Pulse end
        red <= (&rcolor_reg) | ((|rcolor_reg) & ((~|counter) | ((counter != rcolor_reg) & red)));
       blue <= (&bcolor_reg) | ((|bcolor_reg) & ((~|counter) | ((counter != bcolor_reg) & blue)));
      green <= (&gcolor_reg) | ((|gcolor_reg) & ((~|counter) | ((counter != gcolor_reg) & green)));
    end
endmodule//RGB LED controller with 8 bit resolution 

module dimmer(sync, rst, led_i, led_o, brightness, an);
  input rst, an, led_i, sync;
  input [2:0] brightness;
  output led_o;
  wire pass;
  reg [2:0] counter;
  assign led_o = (pass) ? led_i : an;
  assign pass = ~(brightness < counter);
  always@(posedge sync or posedge rst)
    begin
      if(rst)
        begin
          counter <= 3'd0;
        end
      else
        begin
          counter <= counter + 3'd1;
        end
    end
endmodule

module dimmerRGB(sync, rst, rgb_i, rgb_o, brightness, an);
  input rst, an, sync;
  input [2:0] brightness, rgb_i;
  output [2:0] rgb_o;
  wire pass;
  reg [2:0] counter;
  assign rgb_o = (pass) ? rgb_i : {3{an}};
  assign pass = ~(brightness < counter);
  always@(posedge sync or posedge rst)
    begin
      if(rst)
        begin
          counter <= 3'd0;
        end
      else
        begin
          counter <= counter + 3'd1;
        end
    end
endmodule
