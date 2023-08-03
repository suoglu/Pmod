`timescale 1 ns / 1 ps
/* ------------------------------------------------ *
 * Title       : Pmod TC1 AXI Testbench             *
 * Project     : Pmod TC1 interface                 *
 * ------------------------------------------------ *
 * File        : tb.v                               *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : /06/2022                         *
 * ------------------------------------------------ *
 * Description : Testbench for AXI Lite interface   *
 *               to communicate with Pmod TC1       * 
 * ------------------------------------------------ */

module tb();
  parameter MAX_SIM_CYCLES = 1000000;
  parameter C_S_AXI_DATA_WIDTH = 32;
  parameter C_S_AXI_ADDR_WIDTH = 5;
  reg[C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr0;
  reg s_axi_awvalid0;
  wire s_axi_awready0;
  reg[C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata0;
  reg s_axi_wvalid0;
  wire s_axi_wready0;
  wire[1:0] s_axi_bresp0;
  wire s_axi_bvalid0;
  reg s_axi_bready0 = 1;
  reg[C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr0;
  reg s_axi_arvalid0;
  wire s_axi_arready0;
  wire[C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata0;
  wire[1:0] s_axi_rresp0;
  wire s_axi_rvalid0;
  reg s_axi_rready0;

  reg[C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr1;
  reg s_axi_awvalid1;
  wire s_axi_awready1;
  reg[C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata1;
  reg s_axi_wvalid1;
  wire s_axi_wready1;
  wire[1:0] s_axi_bresp1;
  wire s_axi_bvalid1;
  reg s_axi_bready1 = 1;
  reg[C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr1;
  reg s_axi_arvalid1;
  wire s_axi_arready1;
  wire[C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata1;
  wire[1:0] s_axi_rresp1;
  wire s_axi_rvalid1;
  reg s_axi_rready1;

  reg[C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr2;
  reg s_axi_awvalid2;
  wire s_axi_awready2;
  reg[C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata2;
  reg s_axi_wvalid2;
  wire s_axi_wready2;
  wire[1:0] s_axi_bresp2;
  wire s_axi_bvalid2;
  reg s_axi_bready2 = 1;
  reg[C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr2;
  reg s_axi_arvalid2;
  wire s_axi_arready2;
  wire[C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata2;
  wire[1:0] s_axi_rresp2;
  wire s_axi_rvalid2;
  reg s_axi_rready2;


  reg [31:0] MISO_buff0 = 0;
  reg [31:0] MISO_buff1 = 0;
  reg [31:0] MISO_buff2 = 0;
  wire SCLK0, SCLK1, SCLK2;
  wire CSn0, CSn1, CSn2;
  wire MISO0 = MISO_buff0[31];
  wire MISO1 = MISO_buff1[31];
  wire MISO2 = MISO_buff2[31];

  wire [13:0] TC_TD0, TC_TD1, TC_TD2;
  wire [5:0] dummy;
  wire D_fault0, D_fault1, D_fault2;
  wire [11:0] I_TD0, I_TD1, I_TD2;
  wire [2:0] faults_0, faults_1, faults_2;

  assign {TC_TD0, dummy[0], D_fault0, I_TD0, dummy[1], faults_0} = MISO_buff0;
  assign {TC_TD1, dummy[2], D_fault1, I_TD1, dummy[3], faults_1} = MISO_buff1;
  assign {TC_TD2, dummy[4], D_fault2, I_TD2, dummy[5], faults_2} = MISO_buff2;



  always@(negedge SCLK0) begin
    if(!CSn0) begin
      MISO_buff0 <= (MISO_buff0 << 1);
    end
  end

  always@(negedge SCLK1) begin
    if(!CSn1) begin
      MISO_buff1 <= (MISO_buff1 << 1);
    end
  end

  always@(negedge SCLK2) begin
    if(!CSn2) begin
      MISO_buff2 <= (MISO_buff2 << 1);
    end
  end

  reg s_axi_aresetn;
  initial begin
    s_axi_aresetn = 1;
    #2
    s_axi_aresetn = 0;
    #10
    s_axi_aresetn = 1;
  end

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
  
  reg readAHS0, readAHS1, readAHS2, 
      readDHS0, readDHS1, readDHS2, 
      writeAHS0, writeAHS1, writeAHS2, 
      writeDHS0, writeDHS1, writeDHS2, 
      writeRHS0, writeRHS1, writeRHS2;

  always@(posedge s_axi_aclk) begin
    readAHS0 <= s_axi_arready0 & s_axi_arvalid0;
    readDHS0 <= s_axi_rready0 & s_axi_rvalid0;
    writeAHS0 <= s_axi_awready0 & s_axi_awvalid0;
    writeDHS0 <= s_axi_wready0 & s_axi_wvalid0;
    writeRHS0 <= s_axi_bready0 & s_axi_bvalid0;

    readAHS1 <= s_axi_arready1 & s_axi_arvalid1;
    readDHS1 <= s_axi_rready1 & s_axi_rvalid1;
    writeAHS1 <= s_axi_awready1 & s_axi_awvalid1;
    writeDHS1 <= s_axi_wready1 & s_axi_wvalid1;
    writeRHS1 <= s_axi_bready1 & s_axi_bvalid1;

    readAHS2 <= s_axi_arready2 & s_axi_arvalid2;
    readDHS2 <= s_axi_rready2 & s_axi_rvalid2;
    writeAHS2 <= s_axi_awready2 & s_axi_awvalid2;
    writeDHS2 <= s_axi_wready2 & s_axi_wvalid2;
    writeRHS2 <= s_axi_bready2 & s_axi_bvalid2;
  end
  
  reg[30*8:0] state = "setup";
  reg[10*8:0] uut_num = "2";
  integer i;
  genvar g;

  initial begin
    repeat(MAX_SIM_CYCLES) @(posedge s_axi_aclk); #1;
    $display("ERROR: Timeout! Reached %d cycles.", MAX_SIM_CYCLES);
    $finish;
  end

  initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,tb);
  end

  tc1_v1_0 #(
    .BUFFERED_REGS(1),
    .UPDATE_TIMER(1),
    .TIMER_CYCLES(3200),
    .SOFT_TIMER(1),
    .SOFT_TIMER_MW(32)
  )uut0(
    .SCLK(SCLK0),
    .CSn(CSn0),
    .MISO(MISO0),
    .ext_spi_clk(ext_spi_clk),
    .s_axi_aclk(s_axi_aclk),
    .s_axi_aresetn(s_axi_aresetn),
    .s_axi_awaddr(s_axi_awaddr0),
    .s_axi_awvalid(s_axi_awvalid0),
    .s_axi_awready(s_axi_awready0),
    .s_axi_wdata(s_axi_wdata0),
    .s_axi_wvalid(s_axi_wvalid0),
    .s_axi_wready(s_axi_wready0),
    .s_axi_bresp(s_axi_bresp0),
    .s_axi_bvalid(s_axi_bvalid0),
    .s_axi_bready(s_axi_bready0),
    .s_axi_araddr(s_axi_araddr0),
    .s_axi_arvalid(s_axi_arvalid0),
    .s_axi_arready(s_axi_arready0),
    .s_axi_rdata(s_axi_rdata0),
    .s_axi_rresp(s_axi_rresp0),
    .s_axi_rvalid(s_axi_rvalid0),
    .s_axi_rready(s_axi_rready0)
  );

  tc1_v1_0 #(
    .BUFFERED_REGS(1),
    .UPDATE_TIMER(1),
    .TIMER_CYCLES(3200),
    .SOFT_TIMER(0)
  )uut1(
    .SCLK(SCLK1),
    .CSn(CSn1),
    .MISO(MISO1),
    .ext_spi_clk(ext_spi_clk),
    .s_axi_aclk(s_axi_aclk),
    .s_axi_aresetn(s_axi_aresetn),
    .s_axi_awaddr(s_axi_awaddr1),
    .s_axi_awvalid(s_axi_awvalid1),
    .s_axi_awready(s_axi_awready1),
    .s_axi_wdata(s_axi_wdata1),
    .s_axi_wvalid(s_axi_wvalid1),
    .s_axi_wready(s_axi_wready1),
    .s_axi_bresp(s_axi_bresp1),
    .s_axi_bvalid(s_axi_bvalid1),
    .s_axi_bready(s_axi_bready1),
    .s_axi_araddr(s_axi_araddr1),
    .s_axi_arvalid(s_axi_arvalid1),
    .s_axi_arready(s_axi_arready1),
    .s_axi_rdata(s_axi_rdata1),
    .s_axi_rresp(s_axi_rresp1),
    .s_axi_rvalid(s_axi_rvalid1),
    .s_axi_rready(s_axi_rready1)
  );

  tc1_v1_0 #(
    .BUFFERED_REGS(0),
    .UPDATE_TIMER(0)
  )uut2(
    .SCLK(SCLK2),
    .CSn(CSn2),
    .MISO(MISO2),
    .ext_spi_clk(ext_spi_clk),
    .s_axi_aclk(s_axi_aclk),
    .s_axi_aresetn(s_axi_aresetn),
    .s_axi_awaddr(s_axi_awaddr2),
    .s_axi_awvalid(s_axi_awvalid2),
    .s_axi_awready(s_axi_awready2),
    .s_axi_wdata(s_axi_wdata2),
    .s_axi_wvalid(s_axi_wvalid2),
    .s_axi_wready(s_axi_wready2),
    .s_axi_bresp(s_axi_bresp2),
    .s_axi_bvalid(s_axi_bvalid2),
    .s_axi_bready(s_axi_bready2),
    .s_axi_araddr(s_axi_araddr2),
    .s_axi_arvalid(s_axi_arvalid2),
    .s_axi_arready(s_axi_arready2),
    .s_axi_rdata(s_axi_rdata2),
    .s_axi_rresp(s_axi_rresp2),
    .s_axi_rvalid(s_axi_rvalid2),
    .s_axi_rready(s_axi_rready2)
  );

  initial begin
    uut0.junc_t[0] = 0;
    uut0.fault_main[0] = 0;
    uut0.internal_t[0] = 0;
    uut0.faults[0] = 0;

    uut1.junc_t[0] = 0;
    uut1.fault_main[0] = 0;
    uut1.internal_t[0] = 0;
    uut1.faults[0] = 0;

    uut2.junc_t[0] = 0;
    uut2.fault_main[0] = 0;
    uut2.internal_t[0] = 0;
    uut2.faults[0] = 0;

    s_axi_awaddr0 = uut0.OFFSET_CONFIG;
    s_axi_awvalid0 = 0;
    s_axi_wdata0 = 32'h3;
    s_axi_wvalid0 = 0;
    s_axi_araddr0 = uut0.OFFSET_STATUS;
    s_axi_arvalid0 = 0;
    s_axi_rready0 = 1;

    s_axi_awaddr1 = uut1.OFFSET_CONFIG;
    s_axi_awvalid1 = 0;
    s_axi_wdata1 = 32'h0;
    s_axi_wvalid1 = 0;
    s_axi_araddr1 = uut1.OFFSET_STATUS;
    s_axi_arvalid1 = 0;
    s_axi_rready1 = 1;

    s_axi_awaddr2 = uut2.OFFSET_CONFIG;
    s_axi_awvalid2 = 0;
    s_axi_wdata2 = 32'h0;
    s_axi_wvalid2 = 0;
    s_axi_araddr2 = uut2.OFFSET_STATUS;
    s_axi_arvalid2 = 0;
    s_axi_rready2 = 1;


    MISO_buff0 = {14'hBA5, 1'b0, 1'b0, 12'hAFE, 1'b0, 3'b0};
    MISO_buff1 = {14'h0AF, 1'b0, 1'b0, 12'hCE, 1'b0, 3'b0};
    MISO_buff2 = {14'h111, 1'b0, 1'b0, 12'h1C0, 1'b0, 3'b1};

    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI Write";
    uut_num = "0";
    s_axi_wdata0 = 32'hF;
    s_axi_wvalid0 = 1;
    s_axi_awaddr0 = uut0.OFFSET_CONFIG;
    s_axi_awvalid0 = 1;
    fork
      begin
        while(~writeAHS0) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_awvalid0 = 0;
      end
      begin
        while(~writeDHS0) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_wvalid0 = 0;
      end
      begin
        while(~writeRHS0) begin
          @(posedge s_axi_aclk); #1;
        end
      end
    join

    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI Write Addr First";
    uut_num = "0";
    s_axi_awaddr0 = uut0.OFFSET_CONFIG;
    s_axi_awvalid0 = 1;
    fork
      begin
        while(~writeAHS0) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_awvalid0 = 0;
      end
      begin
        repeat(2) @(posedge s_axi_aclk); #1;
        s_axi_wdata0 = 32'h0;
        s_axi_wvalid0 = 1;
        while(~writeDHS0) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_wvalid0 = 0;
      end
      begin
        while(~writeRHS0) begin
          @(posedge s_axi_aclk); #1;
        end
      end
    join

    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI Write Data First";
    uut_num = "0";
    s_axi_wdata0 = 32'hF;
    s_axi_wvalid0 = 1;
    fork
      begin
        repeat(2) @(posedge s_axi_aclk); #1;
        s_axi_awaddr0 = uut0.OFFSET_CONFIG;
        s_axi_awvalid0 = 1;
        while(~writeAHS0) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_awvalid0 = 0;
      end
      begin
        while(~writeDHS0) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_wvalid0 = 0;
      end
      begin
        while(~writeRHS0) begin
          @(posedge s_axi_aclk); #1;
        end
      end
    join

    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI Write Late resp";
    uut_num = "0";
    s_axi_wdata0 = 32'h3;
    s_axi_wvalid0 = 1;
    s_axi_awaddr0 = uut0.OFFSET_CONFIG;
    s_axi_awvalid0 = 1;
    s_axi_bready0 = 0;
    fork
      begin
        while(~writeAHS0) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_awvalid0 = 0;
      end
      begin
        while(~writeDHS0) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_wvalid0 = 0;
      end
      begin
        repeat(3) @(posedge s_axi_aclk); #1;
        s_axi_bready0 = 1;
        while(~writeRHS0) begin
          @(posedge s_axi_aclk); #1;
        end
      end
    join

    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI Read";
    uut_num = "0";
    s_axi_rready0 = 1;
    s_axi_araddr0 = uut0.OFFSET_CONFIG;
    s_axi_arvalid0 = 1;
    fork
      begin
        while(~readAHS0) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_arvalid0 = 0;
      end
      begin
        while(~readDHS0) begin
          @(posedge s_axi_aclk); #1;
        end
      end
    join

    repeat(2) @(posedge s_axi_aclk); #1;
    state = "AXI Read Data wait";
    uut_num = "0";
    s_axi_rready0 = 1;
    s_axi_araddr0 = uut0.OFFSET_STATUS;
    s_axi_arvalid0 = 1;
    s_axi_rready0 = 0;
    fork
      begin
        while(~readAHS0) begin
          @(posedge s_axi_aclk); #1;
        end
        s_axi_arvalid0 = 0;
      end
      begin
        repeat(3) @(posedge s_axi_aclk); #1;
        s_axi_rready0 = 1;
        while(~readDHS0) begin
          @(posedge s_axi_aclk); #1;
        end
      end
    join
    repeat(2) @(posedge ext_spi_clk); #1;
    state = "Finish";
    repeat(4) @(posedge s_axi_aclk); #1;
    $finish;
  end
endmodule
