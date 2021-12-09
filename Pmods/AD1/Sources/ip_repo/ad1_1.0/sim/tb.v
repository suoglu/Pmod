`timescale 1 ns / 1 ps
/* ------------------------------------------------ *
 * Title       : Pmod AD1 AXI Testbench             *
 * Project     : Pmod AD1 interface                 *
 * ------------------------------------------------ *
 * File        : tb.v                               *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 10/12/2021                         *
 * ------------------------------------------------ *
 * Description : Testbench for AXI Lite interface   *
 *               to communicate with Pmod AD1       *
 * ------------------------------------------------ */

module tb();
  localparam C_S_AXI_ADDR_WIDTH = 4,
             C_S_AXI_DATA_WIDTH = 32,
             OFFSET_CH0 = 0,
             OFFSET_CH1 = 4,
             OFFSET_STATUS = 8,
             OFFSET_CONFIG = 12;
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
    forever #25 ext_spi_clk = ~ext_spi_clk; //20MHz
  end

  wire SCK, CS;
  reg D0, D1;

  ad1_v1_0 uut(
    .SCK(SCK),
    .CS(CS),
    .D0(D0),
    .D1(D1),
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
    for(i=0; i<(uut.DUAL_MODE+1); i=i+1) begin
      $dumpvars(i+1,uut.data[i]);
    end
  end

  initial begin
    for(i=0; i<(uut.DUAL_MODE+1); i=i+1) begin
      uut.data[i] = 0;
    end
    D0 = 0;
    D1 = 0;
    d0_source = 0;
    d1_source = 0;
    s_axi_aresetn = 1;
    s_axi_awaddr = uut.OFFSET_CH0;
    s_axi_awvalid = 0;
    s_axi_wdata = 32'h0;
    s_axi_wvalid = 0;
    s_axi_araddr = uut.OFFSET_CH0;
    s_axi_arvalid = 0;
    s_axi_rready = 1;
    #1;
    s_axi_aresetn = 0;
    @(posedge s_axi_aclk); #1;
    s_axi_aresetn = 1;
    @(posedge s_axi_aclk); #1;
    //Basic AXI cases
    state = "valid write & read";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 32'h3;
    s_axi_araddr = uut.OFFSET_STATUS;
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
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "unvalid write & read";
    s_axi_awaddr = uut.OFFSET_STATUS;
    s_axi_wdata = 32'h0;
    s_axi_araddr = uut.OFFSET_CONFIG+1;
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
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI write data first";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 32'h0;
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
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI write addr first";
    s_axi_wdata = 32'h2;
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
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI write res wait";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 32'h1;
    s_axi_awvalid = 1;
    s_axi_wvalid = 1;
    s_axi_bready = 0;
    @(posedge s_axi_aclk); #1;
    s_axi_awvalid = 0;
    s_axi_wvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    s_axi_bready = 1;
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
    //Test AD interface
    state = "Reset";
    s_axi_aresetn = 0;
    @(posedge s_axi_aclk); #1;
    s_axi_aresetn = 1;
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Read stat";
    s_axi_araddr = uut.OFFSET_STATUS;
    s_axi_arvalid = 1;
    @(posedge s_axi_aclk); #1;
    s_axi_arvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Write to measurement reg";
    fork
      begin
        s_axi_awaddr = uut.OFFSET_CH0;
        s_axi_awvalid = 1;
        s_axi_wvalid = 1;
        d0_source = 12'h15A;
        d1_source = 12'h521;
        @(posedge s_axi_aclk); #1;
        s_axi_awvalid = 0;
        s_axi_wvalid = 0;
      end
      begin
        while(CS == 1) begin
          #1;
        end
      end 
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Provide data";
    repeat(3) @(posedge SCK); #1;
    @(negedge SCK); #1;
    for(i=0; i < 12; i=i+1) begin
      D0 = d0_source[11];
      D1 = d1_source[11];
      d0_source = (d0_source << 1);
      d1_source = (d1_source << 1);    
      @(negedge SCK); #1;  
    end
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Read Data";
    s_axi_araddr = uut.OFFSET_CH0;
    s_axi_arvalid = 1;
    @(posedge s_axi_aclk); #1;
    s_axi_araddr = uut.OFFSET_CH1;
    @(posedge s_axi_aclk); #1;
    s_axi_arvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Turn off both up";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 0;
    s_axi_wvalid = 1;
    s_axi_awvalid = 1;
    @(posedge s_axi_aclk); #1;
    s_axi_awvalid = 0;
    s_axi_wvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Write to measurement reg";
    fork
      begin
        s_axi_awaddr = uut.OFFSET_CH0;
        s_axi_awvalid = 1;
        s_axi_wvalid = 1;
        d0_source = 12'hBEE;
        d1_source = 12'hE11;
        @(posedge s_axi_aclk); #1;
        s_axi_awvalid = 0;
        s_axi_wvalid = 0;
      end
      begin
        while(CS == 1) begin
          #1;
        end
      end 
    join
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Provide data";
    repeat(3) @(posedge SCK); #1;
    @(negedge SCK); #1;
    for(i=0; i < 12; i=i+1) begin
      D0 = d0_source[11];
      D1 = d1_source[11];
      d0_source = (d0_source << 1);
      d1_source = (d1_source << 1);    
      @(negedge SCK); #1;  
    end
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Read Data";
    s_axi_araddr = uut.OFFSET_CH0;
    s_axi_arvalid = 1;
    @(posedge s_axi_aclk); #1;
    s_axi_araddr = uut.OFFSET_CH1;
    @(posedge s_axi_aclk); #1;
    s_axi_arvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Turn On Blocking";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 1;
    s_axi_wvalid = 1;
    s_axi_awvalid = 1;
    @(posedge s_axi_aclk); #1;
    s_axi_awvalid = 0;
    s_axi_wvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Read Data";
    s_axi_araddr = uut.OFFSET_CH0;
    s_axi_arvalid = 1;
    d0_source = 12'h896;
    d1_source = 12'h234;
    @(posedge s_axi_aclk); #1;
    fork
      begin
        repeat(3) @(posedge SCK); #1;
        @(negedge SCK); #1;
        for(i=0; i < 12; i=i+1) begin
          D0 = d0_source[11];
          D1 = d1_source[11];
          d0_source = (d0_source << 1);
          d1_source = (d1_source << 1);    
          @(negedge SCK); #1;  
        end
      end
      begin
        while(readAHS == 0) begin
          #1;
        end
        s_axi_arvalid = 0;
      end
      begin
        while(readDHS == 0) begin
          #1;
        end
      end
    join
    state = "Finish";
    repeat(4) @(posedge s_axi_aclk); #1;
    $finish;
  end
endmodule