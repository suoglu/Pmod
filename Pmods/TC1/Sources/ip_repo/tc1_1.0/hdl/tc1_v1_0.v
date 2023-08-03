`timescale 1 ns / 1 ps
/* ------------------------------------------------ *
 * Title       : Pmod TC1 interface v1.0            *
 * Project     : Pmod TC1 interface                 *
 * ------------------------------------------------ *
 * File        : tc1_v1_0.v                         *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 16/06/2022                         *
 * Licence     : CERN-OHL-W                         *
 * ------------------------------------------------ *
 * Description : AXI Lite interface to communicate  *
 *               with Pmod TC1 (MAX31855)           *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

  module tc1_v1_0 #(
    parameter BUFFERED_REGS  = 1,
    parameter UPDATE_TIMER   = 1,
    parameter TIMER_CYCLES   = 3200, //640us
    parameter SOFT_TIMER     = 0,
    parameter SOFT_TIMER_MW  = 32, //! Max 32
    parameter INIT_CONF_QUI  = 0,
    parameter INIT_CONF_TAU  = 0,
    parameter INIT_CONF_MAN  = 1,
    parameter INIT_CONF_AUT  = 0,

    //Offsets
    parameter OFFSET_JUNC_TEMP =  0,
    parameter OFFSET_INT_TEMP  =  4,
    parameter OFFSET_RAW_DATA  =  8,
    parameter OFFSET_FAULT     = 12,
    parameter OFFSET_STATUS    = 16,
    parameter OFFSET_CONFIG    = 20,
    parameter OFFSET_TIMER_LMT = 24,


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 5
  )(
     // Ports of Axi Slave Bus
    input wire  s_axi_aclk,
    input wire  s_axi_aresetn,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire  s_axi_awvalid,
    output wire  s_axi_awready,
    input wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input wire  s_axi_wvalid,
    output wire  s_axi_wready,
    output wire [1:0] s_axi_bresp,
    output wire  s_axi_bvalid,
    input wire  s_axi_bready,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire  s_axi_arvalid,
    output wire  s_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0] s_axi_rresp,
    output wire  s_axi_rvalid,
    input wire  s_axi_rready,

    input wire ext_spi_clk, //max 5 MHz

    output wire SCLK,
    output wire CSn,
    input wire MISO
  );
    integer i;
    localparam OxDEC0DEE3 = 3737181923; // this is also used by interconnect when the address doesn't exist
    localparam RES_OKAY = 2'b00,
               RES_ERR  = 2'b10; //Slave error


    // Use external clk for SPI
    assign SCLK = (~CSn) ? ext_spi_clk : 1'b0;


    //Addresses
    wire [C_S_AXI_ADDR_WIDTH-1:0] write_address = s_axi_awaddr;
    wire [C_S_AXI_ADDR_WIDTH-1:0]  read_address = s_axi_araddr;


    //Internal Control signals I (Drived by only AXI)
    wire write = s_axi_awvalid & s_axi_wvalid & s_axi_wready;
    wire  read = s_axi_arvalid & s_axi_arready;

    wire configWrite = (write_address == OFFSET_CONFIG) & write;

    wire [C_S_AXI_DATA_WIDTH-1:0] data_to_write = s_axi_wdata; //renaming


    // Configurations
    reg timer_update, auto_update, quick_update, manual_update;
    /*
     *     _Bits_       _Reg_
     *      [3]       Manual Update (Writing to one of the data regs initiates a read)
     *      [2]       Timer Auto Update (Periodically update registers, only when timer included)
     *      [1]       Auto Update (Reading from one of the data regs initiates a read)
     *      [0]       Quick Update (read only junction tmp when possible)
     */
    localparam INIT_CONF = INIT_CONF_QUI | (INIT_CONF_AUT << 1) | (INIT_CONF_TAU << 2) | (INIT_CONF_MAN << 3);
    wire [3:0] config_reg = {manual_update, timer_update, auto_update, quick_update};
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn) begin
        {manual_update, timer_update, auto_update, quick_update} <= INIT_CONF;
      end else if(configWrite) begin
        {manual_update, timer_update, auto_update, quick_update} <= data_to_write;
      end
    end


    //Module state
    localparam IDLE  = 1'b0,
             UPDATE  = 1'b1;
    reg state;
 
    wire inIDLE   = (state == IDLE);
    wire inUPDATE = (state == UPDATE);

    assign CSn = inIDLE;


    //Timer
    localparam TIMER_WIDTH = SOFT_TIMER ? SOFT_TIMER_MW : $clog2(TIMER_CYCLES);
    reg [TIMER_WIDTH-1:0] timer;
    reg [TIMER_WIDTH-1:0] timer_limit_conf;
    generate
      if(UPDATE_TIMER) begin
        always@(posedge s_axi_aclk) begin
          if(~s_axi_aresetn | inUPDATE) begin
            timer <= 0;
          end else begin
            timer <= timer + timer_update;
          end
        end
      end
    endgenerate
    generate
      if(SOFT_TIMER) begin
        wire timerLimitWrite = (write_address == OFFSET_TIMER_LMT) & write;
        always@(posedge s_axi_aclk) begin
          if(~s_axi_aresetn) begin
            timer_limit_conf <= TIMER_CYCLES;
          end else if(timerLimitWrite) begin
            timer_limit_conf <= data_to_write;
          end
        end
      end
    endgenerate
    wire [TIMER_WIDTH-1:0] timer_limit = SOFT_TIMER ? timer_limit_conf : TIMER_CYCLES;
    wire timer_done = UPDATE_TIMER & (timer == timer_limit);


    //Registers for data from sensor
    reg [13:0] junc_t[BUFFERED_REGS:0];
    reg [11:0] internal_t[BUFFERED_REGS:0];
    reg fault_main[BUFFERED_REGS:0];
    reg [2:0] faults[BUFFERED_REGS:0]; //[SCV,SCG,OC]
    wire [31:0] raw_data;
    assign raw_data = {junc_t[BUFFERED_REGS], 1'b0, fault_main[BUFFERED_REGS], internal_t[BUFFERED_REGS], 1'b0, faults[BUFFERED_REGS]};

    generate
      if(BUFFERED_REGS) begin : data_buffers_gen
        always@(posedge s_axi_aclk) begin
          if(CSn) begin
            junc_t[1] <= junc_t[0];
            fault_main[1] <= fault_main[0];
            internal_t[1] <= internal_t[0];
            faults[1] <= faults[0];
          end
        end
      end
    endgenerate


    //Counter for tx bits
    reg [5:0] tx_counter;
    always@(posedge ext_spi_clk) begin
      if(CSn) begin
        tx_counter <= 0;
      end else begin
        tx_counter <= tx_counter + 1;
      end
    end

    reg quickRead;
    always@(posedge s_axi_aclk) begin
      if(inIDLE) begin
        quickRead <= quick_update & //Disable via config
                  ((manual_update & (write_address == OFFSET_JUNC_TEMP) & write) |
                   (  auto_update & ( read_address == OFFSET_JUNC_TEMP) & read ));
      end
    end
    wire [5:0] tx_counter_limit = quickRead ? 6'd15 : 6'd32;
    wire tx_counter_done = (tx_counter == tx_counter_limit);


    //Update data registers
    //? Maybe have one 32bit shift register, store all and route from there
    //? + Simpler Logic for saving
    //? - how to hadle routing, needs to support only reading junction temperature too so not always at the same place
    wire getting_junc_t = ~CSn & (tx_counter < 6'd14);
    wire getting_fault_main = ~CSn & (tx_counter == 6'd15);
    wire getting_internal_t = ~CSn & (6'd28 > tx_counter) & (tx_counter > 6'd15);
    wire getting_faults = ~CSn & (6'd28 < tx_counter);

    always@(posedge ext_spi_clk) begin
      junc_t[0]     <= (getting_junc_t)     ?     {junc_t[0][12:0], MISO} :     junc_t[0];
      fault_main[0] <= (getting_fault_main) ?                    MISO     : fault_main[0];
      internal_t[0] <= (getting_internal_t) ? {internal_t[0][10:0], MISO} : internal_t[0];
      faults[0]     <= (getting_faults)     ?      {faults[0][1:0], MISO} :     faults[0];
    end


    //Check address validity & control signals
    wire addressed_temp = (read_address == OFFSET_JUNC_TEMP)|
                          (read_address == OFFSET_INT_TEMP) |
                          (read_address == OFFSET_RAW_DATA) ;
    wire read_addr_valid =          addressed_temp            |
                           (read_address == OFFSET_FAULT)     |
                           (read_address == OFFSET_STATUS)    |
                           (read_address == OFFSET_CONFIG)    |
             (SOFT_TIMER & (read_address == OFFSET_TIMER_LMT));
    wire write_temp = (write_address == OFFSET_JUNC_TEMP)|
                      (write_address == OFFSET_INT_TEMP) |
                      (write_address == OFFSET_RAW_DATA) ;
    wire write_addr_valid =   (write_temp & manual_update)    |
                             (write_address == OFFSET_CONFIG) |
            (SOFT_TIMER & (write_address == OFFSET_TIMER_LMT));


    // Status
    wire busy = ~CSn;
    wire with_buffers = BUFFERED_REGS;
    wire with_timer = UPDATE_TIMER;
    /*
     *     _Bits_       _Reg_
     *      [2]       Data is buffered (so updated when only after tx is done)
     *      [1]       Module with timer  
     *      [0]       In transmit, module not ready
     */
    wire [2:0] status_reg = {with_buffers, with_timer, busy};


    //State Transactions
    wire start_tx = timer_done | (auto_update & addressed_temp & read) | (write_temp & manual_update & write);
    always@(negedge ext_spi_clk or negedge s_axi_aresetn) begin
      if(~s_axi_aresetn) begin
        state <= IDLE;
      end else case(state)
        IDLE:   state <=     (start_tx)    ? UPDATE : state;
        UPDATE: state <= (tx_counter_done) ? IDLE   : state;
      endcase
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
    reg auto_update_done;
    always@(posedge s_axi_aclk) begin
      if(~s_axi_aresetn | ~s_axi_arvalid) begin
        auto_update_done <= 0;
      end else begin
        auto_update_done <= auto_update_done | tx_counter_done;
      end
    end
    wire readReady = ~auto_update ?     1      :
          (~addressed_temp | auto_update_done) ; 
    reg s_axi_rvalid_hold; //This will hold read data channel stable until master accepts tx
    assign s_axi_rvalid  =       (s_axi_arvalid & readReady) | s_axi_rvalid_hold;
    assign s_axi_arready = (~s_axi_rvalid_hold | s_axi_rready) & readReady;
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
    //Following wires to silance warnings
    wire [13:0] junc_t_read = junc_t[BUFFERED_REGS];
    wire [11:0] internal_t_read = internal_t[BUFFERED_REGS];
    wire [2:0] faults_read = faults[BUFFERED_REGS];
    always@* begin
      case(read_address)
        OFFSET_JUNC_TEMP : readReg = junc_t_read;
        OFFSET_INT_TEMP  : readReg = internal_t_read;
        OFFSET_RAW_DATA  : readReg = raw_data;
        OFFSET_FAULT     : readReg = faults_read;
        OFFSET_STATUS    : readReg = status_reg;
        OFFSET_CONFIG    : readReg = config_reg;
        OFFSET_TIMER_LMT : readReg = SOFT_TIMER ? timer_limit_conf : OxDEC0DEE3;
        default          : readReg = OxDEC0DEE3;
      endcase
    end
  endmodule
