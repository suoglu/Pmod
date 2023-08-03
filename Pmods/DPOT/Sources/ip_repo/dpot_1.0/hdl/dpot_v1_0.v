`timescale 1 ns / 1 ps
/* ------------------------------------------------ *
 * Title       : Pmod DPOT interface v1.0           *
 * Project     : Pmod DPOT interface                *
 * ------------------------------------------------ *
 * File        : dpot_v1_0.v                        *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 24/12/2021                         *
 * Licence     : CERN-OHL-W                         *
 * ------------------------------------------------ *
 * Description : AXI Lite interface to communicate  *
 *               with Pmod DPOT (AD5160)            *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

  module dpot_v1_0 #(
    parameter C_S_AXI_DATA_WIDTH  = 32,
    parameter C_S_AXI_ADDR_WIDTH  = 4
  )
  (
    // Ports of Axi Slave Bus Interface S_AXI
    input s_axi_aclk,
    input s_axi_aresetn,
    input [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input [2:0] s_axi_awprot,
    input s_axi_awvalid,
    output s_axi_awready,
    input [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input s_axi_wvalid,
    output s_axi_wready,
    output [1:0] s_axi_bresp,
    output s_axi_bvalid,
    input  s_axi_bready,
    input [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input [2:0] s_axi_arprot,
    input s_axi_arvalid,
    output s_axi_arready,
    output [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output [1:0] s_axi_rresp,
    output s_axi_rvalid,
    input s_axi_rready,

    input ext_spi_clk, //SPI clk, max. 25 MHz, < clk

    output MOSI,
    output SCLK,
    output reg nCS
  );
    localparam OxDEC0DEE3 = 3737181923; // this is also used by interconnect when the address doesn't exist
    localparam RES_OKAY = 2'b00,
               RES_ERR  = 2'b10; //Slave error

    reg [7:0] value, buffer; //Storage for new data


    //Addresses
    wire [C_S_AXI_ADDR_WIDTH-1:0] write_address = s_axi_awaddr;
    wire [C_S_AXI_ADDR_WIDTH-1:0]  read_address = s_axi_araddr;
    wire write_address_valid = (write_address == 0);
    wire  read_address_valid = ( read_address == 0);


    assign SCLK = (nCS) ? 1'b0 : ext_spi_clk;
    assign MOSI = buffer[7];

    wire update = s_axi_wvalid & s_axi_wready & write_address_valid;


    //Count Transmitted bits
    reg [2:0] txCounter;
    wire countDone = &txCounter;
    always@(negedge ext_spi_clk or negedge s_axi_aresetn) begin
      if(~s_axi_aresetn) begin
        txCounter <= 3'd0;
      end else begin
        txCounter <= txCounter + {2'b0, ~nCS};
      end
    end


    //Flag to indicate new write op
    reg writingNew;
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        writingNew <= 0;
      end else case(writingNew)
        1'b0: writingNew <= update;
        1'b1: writingNew <= ~countDone;
      endcase
    end


    //Shifting and setting buffer
    always@(negedge ext_spi_clk or posedge update) begin
      if(update) begin
        buffer <= s_axi_wdata;
      end else begin
        buffer <= (nCS) ? buffer : (buffer << 1);
      end
    end
    always@(posedge s_axi_aclk) begin
      value <= (write_address_valid & s_axi_wvalid & s_axi_wready) ? s_axi_wdata : value;
    end


    //chip select
    always@(negedge ext_spi_clk or negedge s_axi_aresetn) begin
      if(~s_axi_aresetn) begin
        nCS <= 1'b1;
      end else case(nCS)
        1'b1: nCS <= ~writingNew;
        1'b0: nCS <= countDone;
      endcase
    end
    reg nCS_d;
    wire nCS_posedge = ~nCS_d & nCS;
    always@(posedge s_axi_aclk) begin
      nCS_d <= nCS;
    end


    //AXI Signals
    //Write response
    reg s_axi_bvalid_hold, s_axi_bresp_MSB_hold;
    assign s_axi_bvalid = (s_axi_wvalid & s_axi_wready) | s_axi_bvalid_hold;
    assign s_axi_bresp = (s_axi_bvalid_hold) ? {s_axi_bresp_MSB_hold, 1'b0} :
                       (write_address_valid) ? RES_OKAY : RES_ERR;
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        s_axi_bvalid_hold <= 0;
      end else case(s_axi_bvalid_hold)
        1'b0: s_axi_bvalid_hold <= ~s_axi_bready & s_axi_bvalid;
        1'b1: s_axi_bvalid_hold <= ~s_axi_bready;
      endcase
      if(~s_axi_bvalid_hold) begin
        s_axi_bresp_MSB_hold <= s_axi_bresp[1];
      end
    end

    //Write Channel handshake (Data & Addr)
    wire  write_ch_ready = ~(s_axi_awvalid ^ s_axi_wvalid) & ~writingNew & ~|txCounter;
    assign s_axi_awready = write_ch_ready;
    assign s_axi_wready  = write_ch_ready;

    //Read Channel handshake (Addr & data)
    reg s_axi_rvalid_hold; //This will hold read data channel stable until master accepts tx
    assign s_axi_rvalid  =       s_axi_arvalid | s_axi_rvalid_hold;
    assign s_axi_arready = (~s_axi_rvalid_hold | s_axi_rready);
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        s_axi_rvalid_hold <= 0;
      end else case(s_axi_rvalid_hold)
        1'b0: s_axi_rvalid_hold <= ~s_axi_rready & s_axi_rvalid;
        1'b1: s_axi_rvalid_hold <= ~s_axi_rready;
      endcase
    end

    //Read response
    reg s_axi_rresp_MSB_hold;
    always@(posedge s_axi_aclk) begin
      if(~s_axi_rvalid_hold) begin
       s_axi_rresp_MSB_hold <= s_axi_rresp[1];
      end
    end
    assign s_axi_rresp = (s_axi_rvalid_hold) ? {s_axi_rresp_MSB_hold, 1'b0} :
                        (read_address_valid) ? RES_OKAY : RES_ERR;
    
    //Read data
    reg [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata_hold;
    reg [C_S_AXI_DATA_WIDTH-1:0] readReg;
    always@(posedge s_axi_aclk) begin
      if(~s_axi_rvalid_hold) begin
        s_axi_rdata_hold <= s_axi_rdata;
      end
    end
    assign s_axi_rdata = (s_axi_rvalid_hold) ? s_axi_rdata_hold : readReg;
    always@* begin
      readReg = (read_address_valid) ? value : OxDEC0DEE3;
    end
  endmodule
