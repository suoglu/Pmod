`timescale 1 ns / 1 ps
/* ------------------------------------------------ *
 * Title       : Pmod AD1 interface v1.0            *
 * Project     : Pmod AD1 interface                 *
 * ------------------------------------------------ *
 * File        : ad1_v1_0.v                         *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 10/12/2021                         *
 * ------------------------------------------------ *
 * Description : AXI Lite interface to communicate  *
 *               with Pmod AD1 (AD7476A)            *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

  module ad1_v1_0 #(
    parameter DUAL_MODE  =  1,

    //Offsets
    parameter OFFSET_CH0    =  0,
    parameter OFFSET_CH1    =  4,
    parameter OFFSET_STATUS =  8,
    parameter OFFSET_CONFIG = 12,

    // Parameters of Axi Slave Bus Interface
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4
  )(
    // Ports of Axi Slave Bus Interface S_AXI
    input s_axi_aclk,
    input s_axi_aresetn,
    input [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input [2:0] s_axi_awprot,
    input  s_axi_awvalid,
    output s_axi_awready,
    input [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  s_axi_wvalid,
    output s_axi_wready,
    output [1:0] s_axi_bresp,
    output s_axi_bvalid,
    input  s_axi_bready,
    input [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input [2:0] s_axi_arprot,
    input  s_axi_arvalid,
    output s_axi_arready,
    output [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output [1:0] s_axi_rresp,
    output s_axi_rvalid,
    input  s_axi_rready,

    // External SPI clock
    input ext_spi_clk,
    
    // Board Connections
    output SCK,
    input D0,
    input D1,
    output reg CS
  );
    integer i;
    wire [1:0] D = {D1, D0}; //Pack in to array
    localparam OxDEC0DEE3 = 3737181923; // this is also used by interconnect when the address doesn't exist
    localparam RES_OKAY = 2'b00,
                RES_ERR  = 2'b10; //Slave error

    reg [3:0] counter; //Bit counter for the transmisson

    localparam IDLE  = 2'd0,
               CONV  = 2'd1,
               POST  = 2'd3;
    reg [1:0] state;

    wire inIDLE = (state == IDLE);
    wire inCONV = (state == CONV);
    wire inPOST = (state == POST);


    //Addresses
    wire [C_S_AXI_ADDR_WIDTH-1:0] write_address = s_axi_awaddr;
    wire [C_S_AXI_ADDR_WIDTH-1:0]  read_address = s_axi_araddr;
    wire [C_S_AXI_ADDR_WIDTH-1:0] data_addresses[1:0];
    assign data_addresses[0] = OFFSET_CH0;
    assign data_addresses[1] = OFFSET_CH1;


    // Data registers
    reg [11:0] data[DUAL_MODE:0];
    reg [DUAL_MODE:0] updateCH;


    // Configurations
    reg blocking, keep_both_updated;

    wire [1:0] config_reg = {keep_both_updated, blocking};

    // status_reg
    wire busy = |updateCH;
    wire dual_mode = DUAL_MODE;

    wire [1:0] status_reg = {dual_mode, busy};


    //Internal Control signals
    wire write = s_axi_awvalid & s_axi_wvalid;
    wire  read = s_axi_arvalid & s_axi_arready;
    wire nonDataRead = (read_address != OFFSET_CH0) & ((read_address != OFFSET_CH1) | ~DUAL_MODE);
    wire  read_done = (~blocking | nonDataRead) ? s_axi_arvalid : inPOST;
    wire  read_addr_valid = (read_address == OFFSET_STATUS) |
                            (read_address == OFFSET_CONFIG) |
                            (read_address == OFFSET_CH0)    |
               (DUAL_MODE & (read_address == OFFSET_CH1));
    wire write_addr_valid = (write_address == OFFSET_CONFIG) | 
                  (~blocking & (write_address == OFFSET_CH0))| 
      (DUAL_MODE & ~blocking & (write_address == OFFSET_CH1));
    wire [C_S_AXI_DATA_WIDTH-1:0] data_to_write = s_axi_wdata; //renaming


    // Use external clk for SPI
    assign SCK = (inCONV) ? ext_spi_clk : 1'b1;


    //Writing config_reg
    wire updateConfig = (write_address == OFFSET_CONFIG) & write;
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        keep_both_updated <= 1;
        blocking <= 0;
      end else begin
        {keep_both_updated, blocking} <= updateConfig ? data_to_write : config_reg;
      end
    end


    //Data counter
    wire countDone = (counter == 4'h0) & inCONV;
    always@(negedge ext_spi_clk) begin
      if(inIDLE) begin
        counter = 4'h0;
      end else begin
        counter = counter + 4'h1;
      end
    end


    //Output data
    always@(posedge ext_spi_clk) begin
      for(i=0; i < (DUAL_MODE+1); i=i+1) begin
        data[i] <= (~countDone & ~CS & (keep_both_updated|updateCH[i])) ? {data[i][10:0], D[i]} : data[i];
      end
    end


    //Conditions for transfer
    reg startCond;
    always@(posedge ext_spi_clk or negedge s_axi_aresetn) begin
      if(~s_axi_aresetn) begin
        startCond <= 1'b0;
      end else begin
        startCond <= busy & (counter == 0);
      end
    end
    reg stopCond;
    always@(posedge ext_spi_clk or negedge s_axi_aresetn) begin
      if(~s_axi_aresetn) begin
        stopCond <= 1'b0;
      end else begin
        stopCond <= countDone;
      end
    end


    //CS
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        CS <= 1'b1;
      end else case(CS)
        1'b1: CS <= ~startCond;
        1'b0: CS <= inPOST;
      endcase
    end


    //State Transactions
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        state <= IDLE;
      end else case(state)
        IDLE: state <= CS ? state : CONV;
        CONV: state <= (stopCond) ? POST : state;
        //POST: state <= IDLE;
        default: state <= IDLE;
      endcase
    end


    //Start reading
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        updateCH <= 0;
      end else begin
        for(i=0; i < (DUAL_MODE+1); i=i+1) begin
          case(updateCH[i])
            1'b0: updateCH[i] <= (blocking & (read_address == data_addresses[i]) & read) | ((write_address == data_addresses[i]) & write);
            1'b1: updateCH[i] <= ~countDone;
          endcase
        end
      end
    end


    //AXI Signals
    //Write response
    reg s_axi_bvalid_hold, s_axi_bresp_MSB_hold;
    assign s_axi_bvalid = write | s_axi_bvalid_hold;
    assign s_axi_bresp = (s_axi_bvalid_hold) ? {s_axi_bresp_MSB_hold, 1'b0} :
                            write_addr_valid ? RES_OKAY : RES_ERR;
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
    wire  write_ch_ready = ~(s_axi_awvalid ^ s_axi_wvalid) & ~s_axi_bvalid_hold;
    assign s_axi_awready = write_ch_ready;
    assign s_axi_wready  = write_ch_ready;

    //Read Channel handshake (Addr & data)
    reg s_axi_rvalid_hold; //This will hold read data channel stable until master accepts tx
    assign s_axi_rvalid  =      read_done | s_axi_rvalid_hold;
    assign s_axi_arready = (~s_axi_rvalid | s_axi_rready) & (~blocking | ~busy | nonDataRead);
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
                           (read_addr_valid) ? RES_OKAY : RES_ERR;
    
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
      case(read_address)
        OFFSET_CH0    : readReg = data[0];
        OFFSET_CH1    : readReg = DUAL_MODE ? data[DUAL_MODE] : OxDEC0DEE3;
        OFFSET_CONFIG : readReg = config_reg;
        OFFSET_STATUS : readReg = status_reg;
        default       : readReg = OxDEC0DEE3;
      endcase
    end
  endmodule
