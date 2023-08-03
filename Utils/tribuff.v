/* ----------------------------------------- *
 * Title       : Tri-state Buffer            *
 * Project     : Verilog Utility Modules     *
 * ----------------------------------------- *
 * File        : trubuff.v                   *
 * Author      : Yigit Suoglu                *
 * Last Edit   : 04/12/2021                  *
 * Licence     : CERN-OHL-W                  *
 * ----------------------------------------- *
 * Description : Three state buffer          *
 * ----------------------------------------- */

module tribuff(
  inout io,
  input i,
  output o,
  input t);

  assign io = t ? 1'bz : i;
  assign o = io;
endmodule
