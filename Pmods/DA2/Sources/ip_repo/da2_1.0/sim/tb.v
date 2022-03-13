`timescale 1 ns / 1 ps
/* ------------------------------------------------ *
 * Title       : Pmod DA2 AXI Testbench             *
 * Project     : Pmod DA2 interface                 *
 * ------------------------------------------------ *
 * File        : tb.v                               *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 27/02/2022                         *
 * ------------------------------------------------ *
 * Description : Testbench for AXI Lite interface   *
 *               to communicate with Pmod DA2       *
 * ------------------------------------------------ */

module tb();
  localparam C_S_AXI_ADDR_WIDTH = 4,
             C_S_AXI_DATA_WIDTH = 32,
             OFFSET_CH0 = 0,
             OFFSET_CH1 = 4,
             OFFSET_STATUS = 8,
             OFFSET_CONFIG = 12,
             DUAL_MODE  =  1;
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

  wire SCK, CS, DA, DB;
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

  reg  [13:0] da_shift0 = 0, da_shift1 = 0;
  wire  [1:0] da_mode0, da_mode1;
  wire [11:0] da_data0, da_data1;

  assign {da_mode0, da_data0} = da_shift0;
  assign {da_mode1, da_data1} = da_shift1;

  always@(negedge SCK) begin
    if(~CS) begin
      da_shift0 <= {da_shift0[12:0], DA};
      da_shift1 <= {da_shift1[12:0], DB};
    end
  end

  da2_v1_0 #(
    .DUAL_MODE(DUAL_MODE)
  )uut(
    .SCK(SCK),
    .CS(CS),
    .DA(DA),
    .DB(DB),
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
    for(i=0; i<(uut.DUAL_MODE+1); i=i+1) begin
      $dumpvars(i+2+DUAL_MODE,uut.pdMode[i]);
    end
    for(i=0; i<(uut.DUAL_MODE+1); i=i+1) begin
      $dumpvars(i+3+DUAL_MODE*2,uut.send_buffer[i]);
    end
  end

  initial begin
    for(i=0; i<(uut.DUAL_MODE+1); i=i+1) begin
      uut.data[i] = 0;
      uut.pdMode[i] = 0;
      uut.send_buffer[i] = 0;
    end
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
    repeat(2) @(posedge ext_spi_clk); #1;
    //Basic AXI cases
    state = "valid write & read";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 32'h1;
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
    repeat(2) @(posedge ext_spi_clk); #1;
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
    repeat(2) @(posedge ext_spi_clk); #1;
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
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "AXI write addr first";
    s_axi_wdata = 32'h1;
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
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "AXI write res wait";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 32'h0;
    s_axi_awvalid = 1;
    s_axi_wvalid = 1;
    s_axi_bready = 0;
    @(posedge s_axi_aclk); #1;
    s_axi_awvalid = 0;
    s_axi_wvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    s_axi_bready = 1;
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "AXI read not ready";
    s_axi_rready = 0;
    s_axi_arvalid = 1;
    s_axi_araddr = uut.OFFSET_STATUS;
    @(posedge s_axi_aclk); #1;
    s_axi_arvalid = 0;
    @(posedge s_axi_aclk); #1;
    s_axi_araddr = uut.OFFSET_CONFIG;
    s_axi_arvalid = 1;
    @(posedge s_axi_aclk); #1;
    s_axi_arvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    s_axi_rready = 1;
    repeat(2) @(posedge ext_spi_clk); #1;
    //Test AD interface
    state = "Reset";
    s_axi_aresetn = 0;
    @(posedge s_axi_aclk); #1;
    s_axi_aresetn = 1;
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "Update one channel";
    s_axi_awaddr = uut.OFFSET_CH0;
    s_axi_wdata = 32'h1A;
    s_axi_araddr = uut.OFFSET_STATUS;
    s_axi_wvalid = 1;
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
    repeat(4) @(posedge s_axi_aclk); #1;
    s_axi_arvalid = 1;
    @(posedge s_axi_aclk); #1;
    while(~readAHS) begin
      @(posedge s_axi_aclk); #1;
    end
    s_axi_arvalid = 0;
    while(uut.busy) begin
      @(posedge s_axi_aclk); #1;
    end
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "Write same value";
    s_axi_awaddr = uut.OFFSET_CH0;
    s_axi_wdata = 32'h1A;
    s_axi_wvalid = 1;
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
    repeat(2) @(posedge ext_spi_clk); #1;
    while(uut.busy) begin
      @(posedge s_axi_aclk); #1;
    end
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "Update channel mode";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 32'b1000;
    s_axi_wvalid = 1;
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
    repeat(2) @(posedge ext_spi_clk); #1;
    while(uut.busy) begin
      @(posedge s_axi_aclk); #1;
    end
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "Enable Buff & Ch Modes";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 32'b11001;
    s_axi_wvalid = 1;
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
    repeat(2) @(posedge ext_spi_clk); #1;
    while(uut.busy) begin
      @(posedge s_axi_aclk); #1;
    end
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "Read Status";
    s_axi_araddr = uut.OFFSET_STATUS;
    s_axi_arvalid = 1;
    @(posedge s_axi_aclk); #1;
    while(~readAHS) begin
      @(posedge s_axi_aclk); #1;
    end
    s_axi_arvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Refresh & ch refresh mode";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 32'b1000010 | uut.config_reg;
    s_axi_wvalid = 1;
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
    while(uut.busy | uut.dataInvalid) begin
      @(posedge s_axi_aclk); #1;
    end
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "Update channel A";
    s_axi_awaddr = uut.OFFSET_CH0;
    s_axi_wdata = 32'hBCA;
    s_axi_wvalid = 1;
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
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "Update channel B";
    s_axi_awaddr = uut.OFFSET_CH1;
    s_axi_wdata = 32'hAF5;
    s_axi_wvalid = 1;
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
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "Read Status";
    s_axi_araddr = uut.OFFSET_STATUS;
    s_axi_arvalid = 1;
    @(posedge s_axi_aclk); #1;
    while(~readAHS) begin
      @(posedge s_axi_aclk); #1;
    end
    s_axi_arvalid = 0;
    repeat(2) @(posedge s_axi_aclk); #1;
    state = "Refresh & ch refresh mode";
    s_axi_awaddr = uut.OFFSET_CONFIG;
    s_axi_wdata = 32'b1000010 | uut.config_reg;
    s_axi_wvalid = 1;
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
    while(uut.busy | uut.dataInvalid) begin
      @(posedge s_axi_aclk); #1;
    end
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "Finish";
    repeat(4) @(posedge s_axi_aclk); #1;
    $finish;
  end
endmodule