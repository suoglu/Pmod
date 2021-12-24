`timescale 1 ns / 1 ps
/* ------------------------------------------------ *
 * Title       : Pmod DPOT AXI Testbench            *
 * Project     : Pmod DPOT interface                *
 * ------------------------------------------------ *
 * File        : tb.v                               *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 24/12/2021                         *
 * ------------------------------------------------ *
 * Description : Testbench for AXI Lite interface   *
 *               to communicate with Pmod DPOT      *
 * ------------------------------------------------ */

`include "hdl/dpot_v1_0.v"

module tb();
  localparam C_S_AXI_ADDR_WIDTH = 4,
             C_S_AXI_DATA_WIDTH = 32;
  reg s_axi_aresetn;
  reg[C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
  reg[2:0] s_axi_awprot = 0;
  reg s_axi_awvalid;
  wire s_axi_awready;
  reg[C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata;
  reg[(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb = 0;
  reg s_axi_wvalid;
  wire s_axi_wready;
  wire[1:0] s_axi_bresp;
  wire s_axi_bvalid;
  reg s_axi_bready = 1;
  reg[C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr;
  reg[2:0] s_axi_arprot = 0;
  reg s_axi_arvalid;
  wire s_axi_arready;
  wire[C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata;
  wire[1:0] s_axi_rresp;
  wire s_axi_rvalid;
  reg s_axi_rready;

  reg readAHS, readDHS, writeAHS, writeDHS, writeRHS;

  always@(posedge s_axi_aclk) begin
    readAHS <= s_axi_arready & s_axi_arvalid;
    readDHS <= s_axi_rready & s_axi_rvalid;
    writeAHS <= s_axi_awready & s_axi_awvalid;
    writeDHS <= s_axi_wready & s_axi_wvalid;
    writeRHS <= s_axi_bready & s_axi_bvalid;
  end
  
  reg[30*8:0] state = "setup";
  integer i;
  genvar g;

  reg [11:0] d0_source, d1_source;

  //generate clocks
  reg s_axi_aclk, ext_spi_clk;
  always begin
    s_axi_aclk = 0;
    forever #5 s_axi_aclk = ~s_axi_aclk; //100MHz
  end
  always begin
    ext_spi_clk = 0;
    forever #20 ext_spi_clk = ~ext_spi_clk; //25MHz
  end

  wire SCK, nCS, MOSI;

  dpot_v1_0 uut(
    .SCLK(SCK),
    .MOSI(MOSI),
    .nCS(nCS),
    .ext_spi_clk(ext_spi_clk),
    .s_axi_aclk(s_axi_aclk),
    .s_axi_aresetn(s_axi_aresetn),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(s_axi_awprot),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready)
  );

  initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,tb);
  end

  initial begin
    uut.value = 8'hAA;
    s_axi_aresetn = 1;
    s_axi_awaddr = 0;
    s_axi_awvalid = 0;
    s_axi_wdata = 32'h0;
    s_axi_wvalid = 0;
    s_axi_araddr = 0;
    s_axi_arvalid = 0;
    s_axi_rready = 1;
    #1;
    s_axi_aresetn = 0;
    @(posedge s_axi_aclk); #1;
    s_axi_aresetn = 1;
    @(posedge s_axi_aclk); #1;
    //Basic AXI cases
    state = "valid write & read";
    s_axi_awaddr = 0;
    s_axi_wdata = 32'h73;
    s_axi_araddr = 0;
    s_axi_arvalid = 1;
    s_axi_wvalid = 1;
    s_axi_awvalid = 1;
    @(posedge s_axi_aclk); #1;
    fork
      begin
        while(~readAHS) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_arvalid = 0;
      end
      begin
        while(~writeAHS) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_awvalid = 0;
      end
      begin
        while(~writeDHS) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_wvalid = 0;
      end
      begin
        while(~writeRHS) begin
          @(posedge s_axi_aclk); #1;
        end
      end
      begin
        while(nCS) begin
          @(posedge s_axi_aclk); #1;
        end
        while(~nCS) begin
          @(posedge s_axi_aclk); #1;
        end
      end
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "unvalid write & read";
    s_axi_awaddr = 4;
    s_axi_wdata = 32'hab;
    s_axi_araddr = 4;
    s_axi_arvalid = 1;
    s_axi_wvalid = 1;
    s_axi_awvalid = 1;
    @(posedge s_axi_aclk); #1;
    fork
      begin
        while(~readAHS) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_arvalid = 0;
      end
      begin
        while(~writeAHS) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_awvalid = 0;
      end
      begin
        while(~writeDHS) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_wvalid = 0;
      end
      begin
        while(~writeRHS) begin
          @(posedge s_axi_aclk); #1;
        end
      end
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI write data first";
    s_axi_araddr = 0;
    s_axi_awaddr = 0;
    s_axi_wdata = 32'hc1;
    s_axi_wvalid = 1;
    @(posedge s_axi_aclk); #1;
    s_axi_awvalid = 1;
    @(posedge s_axi_aclk); #1;
    fork
      begin
        while(~writeAHS) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_awvalid = 0;
      end
      begin
        while(~writeDHS) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_wvalid = 0;
      end
      begin
        while(~writeRHS) begin
          @(posedge s_axi_aclk); #1;
        end
      end
      begin
        while(nCS) begin
          @(posedge s_axi_aclk); #1;
        end
        while(~nCS) begin
          @(posedge s_axi_aclk); #1;
        end
      end
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI write addr first";
    s_axi_wdata = 32'h25;
    s_axi_awvalid = 1;
    @(posedge s_axi_aclk); #1;
    s_axi_wvalid = 1;
    @(posedge s_axi_aclk); #1;
    fork
      begin
        while(~writeAHS) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_awvalid = 0;
      end
      begin
        while(~writeDHS) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_wvalid = 0;
      end
      begin
        while(~writeRHS) begin
          @(posedge s_axi_aclk); #1;
        end
      end
      begin
        while(nCS) begin
          @(posedge s_axi_aclk); #1;
        end
        while(~nCS) begin
          @(posedge s_axi_aclk); #1;
        end
      end
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI write res wait";
    s_axi_awaddr = 0;
    s_axi_wdata = 32'hf1;
    s_axi_awvalid = 1;
    s_axi_wvalid = 1;
    s_axi_bready = 0;
    @(posedge s_axi_aclk); #1;
    s_axi_awvalid = 0;
    s_axi_wvalid = 0;
    fork
      begin
        while(nCS) begin
          @(posedge s_axi_aclk); #1;
        end
        while(~nCS) begin
          @(posedge s_axi_aclk); #1;
        end
      end
      begin
        while(s_axi_bvalid == 0) begin
          @(posedge s_axi_aclk); #1;
        end
        repeat(2) @(posedge s_axi_aclk); #1;
        s_axi_bready = 1;
      end
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI read not ready";
    s_axi_rready = 0;
    s_axi_arvalid = 1;
    @(posedge s_axi_aclk); #1;
    s_axi_arvalid = 0;
    @(posedge s_axi_aclk); #1;
    s_axi_arvalid = 1;
    @(posedge s_axi_aclk); #1;
    s_axi_arvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    s_axi_rready = 1;
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Finish";
    repeat(4) @(posedge s_axi_aclk); #1;
    $finish;
  end
endmodule