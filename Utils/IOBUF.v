
module io_buff #(
    parameter DRIVE = 12, // Specify the output drive strength
    parameter IBUF_LOW_PWR = "TRUE", // Low Power - "TRUE", High Perforrmance = "FALSE"
    parameter IOSTANDARD = "DEFAULT", // Specify the I/O standard
    parameter SLEW = "SLOW"// Specify the output slew rate
  )(
    output O,
    inout IO,
    input I,
    input T
  ); 

  // IOBUF: Single-ended Bi-directional Buffer
  // All devices
  // Xilinx HDL Libraries Guide, version 2012.2
  IOBUF #(
  .DRIVE(DRIVE), // Specify the output drive strength
  .IBUF_LOW_PWR(IBUF_LOW_PWR), // Low Power - "TRUE", High Perforrmance = "FALSE"
  .IOSTANDARD(IOSTANDARD), // Specify the I/O standard
  .SLEW(SLEW) // Specify the output slew rate
  ) IOBUF_inst (
  .O(O), // Buffer output
  .IO(IO), // Buffer inout port (connect directly to top-level port)
  .I(I), // Buffer input
  .T(T) // 3-state enable input, high=input, low=output
  );
endmodule
