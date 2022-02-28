`timescale 1 ns / 1 ps
/* ------------------------------------------------ *
 * Title       : Pmod DA2 interface v1.0            *
 * Project     : Pmod DA2 interface                 *
 * ------------------------------------------------ *
 * File        : da2_v1_0.v                         *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 27/02/2022                         *
 * ------------------------------------------------ *
 * Description : AXI Lite interface to communicate  *
 *               with Pmod DA2 (DAC121S101-Q1)      *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */


  module da2_v1_0 #(
    parameter DUAL_MODE    = 1,
    parameter FAST_REFRESH = 0, //Hard coded!

    //Offsets
    parameter OFFSET_CH0    =  0,
    parameter OFFSET_CH1    =  4,
    parameter OFFSET_STATUS =  8,
    parameter OFFSET_CONFIG = 12,

    // Parameters of Axi Slave Bus Interface
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4
  )(
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
    input ext_spi_clk, //max 30 MHz
    
    // Board Connections
    output SCK,
    output DA, //CH0
    output DB, //CH1
    output reg CS
  );
    integer i;
    localparam OxDEC0DEE3 = 3737181923; // this is also used by interconnect when the address doesn't exist
    localparam RES_OKAY = 2'b00,
               RES_ERR  = 2'b10; //Slave error

    reg [3:0] counter; //Bit counter for the transmisson

    localparam IDLE  = 1'b0,
             UPDATE  = 1'b1;
    reg state;

    wire inIDLE   = (state == IDLE);
    wire inUPDATE = (state == UPDATE);

    //Detect ext spi clk edge
    reg ext_spi_clk_d;
    always@(posedge s_axi_aclk) begin
      ext_spi_clk_d <= ext_spi_clk;
    end
    wire ext_spi_clk_posedge = ~ext_spi_clk_d & ext_spi_clk;

    //Board connections
    reg [1:0] D; //Pack in to array
    assign {DB, DA} = D;


    // Use external clk for SPI
    assign SCK = (inUPDATE) ? ext_spi_clk : 1'b1;


    //Addresses
    wire [C_S_AXI_ADDR_WIDTH-1:0] write_address = s_axi_awaddr;
    wire [C_S_AXI_ADDR_WIDTH-1:0]  read_address = s_axi_araddr;
    wire [C_S_AXI_ADDR_WIDTH-1:0] data_addresses[1:0];

    assign data_addresses[0] = OFFSET_CH0;
    assign data_addresses[1] = OFFSET_CH1;


    //Internal Control signals I (Drived by only AXI)
    wire write = s_axi_awvalid & s_axi_wvalid & s_axi_wready;
    wire  read = s_axi_arvalid & s_axi_arready;

    wire configWrite = (write_address == OFFSET_CONFIG) & write;

    wire [C_S_AXI_DATA_WIDTH-1:0] data_to_write = s_axi_wdata; //renaming

    reg updateData; //Used to initiate new transfer, see section II


    //Fast refresh mode, when refresh bit set in config write, other bits are ignored
    reg fast_refresh_soft; //Assignment at below, with other config regs
    wire fast_refresh_n = ~((FAST_REFRESH|fast_refresh_soft) & data_to_write[1]);


    // Data registers
    reg [11:0] data[DUAL_MODE:0]; //access via its own address
    reg  [1:0] pdMode[DUAL_MODE:0]; //access via config reg
    reg [2*(DUAL_MODE+1)-1:0] pdMode_array;
    always@* begin
      pdMode_array = 0;
      for (i = 0; i < (DUAL_MODE+1); i=i+1) begin
        pdMode_array = pdMode_array | (pdMode[i] << (i*2));
      end
    end
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        for (i = 0; i < (DUAL_MODE+1); i=i+1) begin
          pdMode[i] <= 0;
        end
      end else begin
        for (i = 0; i < (DUAL_MODE+1); i=i+1) begin
          pdMode[i] <= (configWrite & fast_refresh_n) ? (data_to_write >> (2 + (2*i))) : pdMode[i];
        end
      end
    end
    always@(posedge s_axi_aclk) begin
      for (i = 0; i < (DUAL_MODE+1); i=i+1) begin
        data[i] <= ((write_address == data_addresses[i]) & write) ? data_to_write[11:0] : data[i];
      end
    end


    // Configurations
    reg buffering;
    /*
     *     _Bits_       _Reg_
     *      [6]       Reconfigurable fast refresh, when refresh bit set do not update configs
     *     [5:4]      Power Down Mode (Channel B, only if dual channel)
     *     [3:2]      Power Down Mode (Channel A)
     *      [1]       Write Buffer / Refresh (read as 0)
     *      [0]       Buffering Mode, disable auto refresh
     */
    wire [6:0] config_reg = (DUAL_MODE) ? 
          {fast_refresh_soft, pdMode_array, 1'b0, buffering} :
          {fast_refresh_soft, 2'b0, pdMode_array, 1'b0, buffering};
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        buffering <= 0;
        fast_refresh_soft <= 0;
      end else begin
        buffering         <= (configWrite & fast_refresh_n) ? data_to_write[0] : buffering;
        fast_refresh_soft <= (configWrite & fast_refresh_n) ? data_to_write[6] : fast_refresh_soft;
      end
    end


    // Status
    wire busy = inUPDATE;
    wire dual_mode = DUAL_MODE;
    reg  dataInvalid; //Logic at Internal Control signals II part
    /*
     *     _Bits_       _Reg_
     *      [3]       Hard wired fast refresh hw
     *      [2]       Dual Channel Device
     *      [1]       Data on the IP and device is not same, need to refresh  
     *      [0]       In transmit, module not ready
     */
    wire [3:0] status_reg = {FAST_REFRESH, dual_mode, dataInvalid, busy};


    //Transmit Buffer
    reg [13:0] send_buffer[DUAL_MODE:0];


    //Internal Control signals II (Remaining)
    wire  read_addr_valid = (read_address == OFFSET_STATUS) |
                            (read_address == OFFSET_CONFIG) |
                            (read_address == OFFSET_CH0)    |
               (DUAL_MODE & (read_address == OFFSET_CH1));
    wire data_address = (write_address == OFFSET_CH0) |
           (DUAL_MODE & (write_address == OFFSET_CH1));
    wire dataWrite = data_address & write;
    wire write_addr_valid = (write_address == OFFSET_CONFIG) | data_address;
    wire [11:0] addressed_data = (write_address == OFFSET_CH0) ? data[0] : data[DUAL_MODE];
    wire refreshData = configWrite & data_to_write[1];
    wire dataChanged = (configWrite & ((pdMode[0] != data_to_write[3:2]) | ((pdMode[DUAL_MODE] != data_to_write[5:4]) & DUAL_MODE))) | 
                       (dataWrite & (addressed_data != data_to_write[11:0]));
    wire blockRefresh_n = ~configWrite | ~data_to_write[0];
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        updateData <= 1'b0;
      end else case(updateData)
        1'b1: updateData <= inIDLE;
        1'b0: updateData <= refreshData | (~buffering & dataChanged & blockRefresh_n);
      endcase
    end
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        dataInvalid <= 1'b1;
      end else case(dataInvalid)
        1'b0: dataInvalid <= dataChanged;
        1'b1: dataInvalid <= ~inUPDATE;
      endcase
    end


    //Data counter
    wire countDone = (counter == 4'h0);
    always@(negedge ext_spi_clk or negedge s_axi_aresetn) begin
      if(~s_axi_aresetn | inIDLE) begin
        counter = 4'h0;
      end else begin
        counter = counter + 4'h1;
      end
    end


    //State Transactions
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        state <= IDLE;
      end else case(state)
        IDLE: state <= updateData & ext_spi_clk_posedge;
        UPDATE: state <= ~CS;
      endcase
    end

    //Chip Select
    always@(posedge ext_spi_clk or negedge s_axi_aresetn) begin
      if(~s_axi_aresetn) begin
        CS <= 1'b1;
      end else case(CS)
        1'b1: CS <= ~updateData;
        1'b0: CS <= countDone;
      endcase
    end

    //Output data
    always@* begin
      for(i=0; i < (DUAL_MODE+1); i=i+1) begin
        D[i] = send_buffer[i][13];
      end
    end
    always@(posedge ext_spi_clk) begin 
      for(i=0; i < (DUAL_MODE+1); i=i+1) begin
        send_buffer[i] <= (inIDLE) ? send_buffer[i]       : //Reduce shifting activity // ? maybe remove
                 (counter == 4'h2) ? {pdMode[i], data[i]} : (send_buffer[i] << 1);
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
    wire  write_ch_ready = ~(s_axi_awvalid ^ s_axi_wvalid) & ~s_axi_bvalid_hold & ~busy;
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
