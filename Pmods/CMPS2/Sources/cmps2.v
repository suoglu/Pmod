/* ------------------------------------------------ *
 * Title       : Pmod CMPS2 interface v1.0          *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : cmps2.v                            *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 05/12/2021                         *
 * ------------------------------------------------ *
 * Description : Simple interface to communicate    *
 *               with Pmod CMPS2                    *
 * ------------------------------------------------ */

module cmps2(
  input clk,
  input rst,
  input clkI2Cx2, //!max 800 kHz
  //I2C pins
  input  SCL_i,
  output SCL_o,
  output SCL_t,
  input  SDA_i,
  output SDA_o,
  output SDA_t,
  //Measurement results
  output reg [15:0] x_axis,
  output reg [15:0] y_axis,
  output reg [15:0] z_axis,
  //Configs
  input [1:0] resolution,
  output reg [15:0] x_offset,
  output reg [15:0] y_offset,
  output reg [15:0] z_offset,
  //Control
  input calibrate,
  input measure,
  //Status
  output reg i2cBusy,
  output reg valid);
  localparam i2c_ADDRESS = 7'b0110000;
  //Important register addresses
  localparam DATA_REG = 8'h0, //to 8'h5
           STATUS_REG = 8'h6,
         CONTROL0_REG = 8'h7,
         CONTROL1_REG = 8'h8;
  //Register contents for control reg 0
  localparam cntr0_SET = 8'b0010_0000,
           cntr0_RESET = 8'b0100_0000,
          cntr0_REFILL = 8'b1000_0000,
         cntr0_MEASURE = 8'b0000_0001;
  //States 
  localparam  STANDBY = 5'b00000, //0x0
        //Calibrate + get new measurements
          //Get mesurement in reset state
          RSET_REFILL = 5'b01000, //0x8, write to cntr0
         RSET_A_STAT0 = 5'b11000, //0x18, addrs to stat
            RSET_WAIT = 5'b01001, //0x9, poll status
                 RSET = 5'b11001, //0x19, write to cntr0
            RSET_MEAS = 5'b01011, //0xB, write to cntr0
         RSET_A_STAT1 = 5'b11011, //0x1B, addrs to stat
            RSET_POLL = 5'b01010, //0xA, poll status
          RSET_A_DATA = 5'b11010, //0x1A, addrs to data
            RSET_READ = 5'b01110, //0xE, read data
          //Get mesurement in set state
           SET_REFILL = 5'b01111, //0xF, write to cntr0
          SET_A_STAT0 = 5'b11111, //0x1F, addrs to stat
             SET_WAIT = 5'b01101, //0xD, poll status
                  SET = 5'b11101, //0x1D, write to cntr0
             SET_MEAS = 5'b01100, //0xC, write to cntr0
          SET_A_STAT1 = 5'b11100, //0x1C, addrs to stat
             SET_POLL = 5'b00100, //0x4, poll status
           SET_A_DATA = 5'b10100, //0x14, addrs to data
             SET_READ = 5'b00110, //0x6, read data
            //Calculate offset and data
            CALIBRATE = 5'b00010, //0x2, no i2c
        //get new measurements using already calculated offset
              MEASURE = 5'b00001, //0x1, write to cntr0
              STAT_AD = 5'b10001, //0x11, addrs to stat
                 POLL = 5'b00101, //0x5, poll status
              DATA_AD = 5'b10111, //0x17, addrs to data
                 READ = 5'b00111, //0x7, read data
            CALCULATE = 5'b00011, //0x3, no i2c
            CH_RESLTN = 5'b10000; //0x10, write to cntr1
  reg [4:0] state;
  wire inI2Cstate;
  wire inStandby, inRRefill, inRAddrS0, inRWait, inRSet, inRMeasure, inRAddrS1, inRPoll, inRAddrData, inRRead, inSResfill, inSAddrS0, inSWait, inSet, inSMeasure, inSPoll, inSRead, inCalibrate, inMeasure, inAddrStat, inPoll, inAddrData, inRead, inCalculate, inChRes;
  wire ptr_write_state, poll_state, reg_write_state, data_read_state, poll_pump, poll_result;
  //I2C States
  localparam I2C_READY = 3'b000,
             I2C_START = 3'b001,
             I2C_ADDRS = 3'b011,
             I2C_WRITE = 3'b110,
         I2C_WRITE_ACK = 3'b010,
              I2C_READ = 3'b111,
          I2C_READ_ACK = 3'b101,
              I2C_STOP = 3'b100;
  //I2C state & I2C state control
  reg [2:0] I2C_state;
  wire I2C_done;
  wire I2CinReady, I2CinStart, I2CinAddrs, I2CinWrite, I2CinWriteAck, I2CinRead, I2CinReadAck, I2CinStop, I2CinAck;
  reg I2CinAck_d, I2CinStop_d, SDA_d_i2c;
  wire read_nwrite;
  //Delay I2C signals, finding edges and conditions
  reg SDA_d;
  wire startCondition, stopCondition; //I2C conditions
  wire SDA_negedge, SDA_posedge;
  //I2C send buffer
  reg [7:0] send_buffer, send_buffer_write;
  wire send_upload, send_shift; 
  //Transmisson counters
  reg [2:0] byteCounter;
  reg [2:0] bitCounter;
  reg byteCountDone;
  wire bitCountDone;
  wire byteCountUp;
  //Generate I2C signals with tri-state
  wire SDA, SCL;
  reg SCLK; //Internal I2C clock, always thicks
  wire SCL_claim;
  wire SDA_claim;
  wire SDA_write;
  //Measurement results in modes
  reg [15:0] x_set, x_reset;
  reg [15:0] y_set, y_reset;
  reg [15:0] z_set, z_reset;
  //Middle calculations
  wire [16:0] x_offset_x2, y_offset_x2, z_offset_x2;
  wire [16:0] x_axis_x2, y_axis_x2, z_axis_x2;
  //Flags
  reg sensor_ready;
  wire ch_res;
  reg [1:0] res;

  //Control signals/flags
  assign I2C_done = ~I2CinStop_d & I2CinStop;
  assign read_nwrite = poll_state | inRRead | inSRead | inRead;
  assign inI2Cstate = ~inStandby;
  assign ch_res = (res != resolution);
  always@(posedge clk) begin
    if(inStandby)
      sensor_ready <= 1'b1;
    else if(ptr_write_state)
      sensor_ready <= 1'b0;
    else if(poll_pump)
      sensor_ready <= (~|byteCounter & &bitCounter & SCL) ? ~SDA : sensor_ready;
    else if(poll_result)
      sensor_ready <= (~|byteCounter & bitCountDone & SCL) ? SDA : sensor_ready;
  end
  always@(posedge clk or posedge rst)
    if(rst) begin
      valid <= 1'b0;
    end else begin
      case(valid)
        1'b0: valid <= inCalibrate | inCalculate;
        1'b1: valid <= ~calibrate & ~measure;
      endcase
    end

  //Decode States
  assign inStandby   = (state == STANDBY);
  assign inRRefill   = (state == RSET_REFILL);
  assign inRAddrS0   = (state == RSET_A_STAT0);
  assign inRWait     = (state == RSET_WAIT);
  assign inRSet      = (state == RSET);
  assign inRMeasure  = (state == RSET_MEAS);
  assign inRAddrS1   = (state == RSET_A_STAT1);
  assign inRPoll     = (state == RSET_POLL);
  assign inRAddrData = (state == RSET_A_DATA);
  assign inRRead     = (state == RSET_READ);
  assign inSResfill  = (state == SET_REFILL);
  assign inSAddrS0   = (state == SET_A_STAT0);
  assign inSWait     = (state == SET_WAIT);
  assign inSet       = (state == SET);
  assign inSMeasure  = (state == SET_MEAS);
  assign inSAddrS1   = (state == SET_A_STAT1);
  assign inSPoll     = (state == SET_POLL);
  assign inSAddrData = (state == SET_A_DATA);
  assign inSRead     = (state == SET_READ);
  assign inCalibrate = (state == CALIBRATE);
  assign inMeasure   = (state == MEASURE);
  assign inAddrStat  = (state == STAT_AD);
  assign inPoll      = (state == POLL);
  assign inAddrData  = (state == DATA_AD);
  assign inRead      = (state == READ);
  assign inCalculate = (state == CALCULATE);
  assign inChRes     = (state == CH_RESLTN);

  //State derived signals
  assign ptr_write_state = inRAddrS0 | inRAddrS1 | inRAddrData | inSAddrS0 | inSAddrS1 | inSAddrData | inAddrStat | inAddrData;
  assign poll_state = poll_pump | poll_result;
  assign poll_result = inRPoll | inSPoll | inPoll;
  assign poll_pump = inRWait |  inSWait;
  assign reg_write_state = inRRefill | inRSet | inRMeasure | inSResfill | inSet | inSMeasure | inMeasure | inChRes;
  assign data_read_state = inRRead | inSRead | inRead;

  //Decode I2C state
  assign     I2CinRead = (I2C_state == I2C_READ);
  assign     I2CinStop = (I2C_state == I2C_STOP);
  assign    I2CinReady = (I2C_state == I2C_READY);
  assign    I2CinStart = (I2C_state == I2C_START);
  assign    I2CinAddrs = (I2C_state == I2C_ADDRS);
  assign    I2CinWrite = (I2C_state == I2C_WRITE);
  assign  I2CinReadAck = (I2C_state == I2C_READ_ACK);
  assign I2CinWriteAck = (I2C_state == I2C_WRITE_ACK);
  assign      I2CinAck = I2CinWriteAck | I2CinReadAck;

  //Tri-state control for I2C lines
  assign SCL = (SCL_claim) ?    SCLK   : SCL_i;
  assign SDA = (SDA_claim) ? SDA_write : SDA_i;
  assign SCL_o = SCL;
  assign SDA_o = SDA;
  assign SCL_claim = ~I2CinReady;
  assign SDA_claim = I2CinStart | I2CinAddrs | I2CinWrite | I2CinReadAck | I2CinStop;
  assign SDA_write = (I2CinStart | I2CinReadAck | I2CinStop) ? (I2CinReadAck & byteCountDone) : send_buffer[7];
  assign SCL_t = ~SCL_claim;
  assign SDA_t = ~SDA_claim;

  //Calculate offset
  assign x_offset_x2 = {1'b0,x_set} + {1'b0,x_reset};
  assign y_offset_x2 = {1'b0,y_set} + {1'b0,y_reset};
  assign z_offset_x2 = {1'b0,z_set} + {1'b0,z_reset};
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      x_offset <= 16'h0;
      y_offset <= 16'h0;
      z_offset <= 16'h0;
    end else begin
      x_offset <= (inCalibrate) ? x_offset_x2[16:1] : x_offset;
      y_offset <= (inCalibrate) ? y_offset_x2[16:1] : y_offset;
      z_offset <= (inCalibrate) ? z_offset_x2[16:1] : z_offset;
    end
  end
  
  //Calculate measurement results
  assign x_axis_x2 = {1'b0,x_set} - {1'b0,x_reset};
  assign y_axis_x2 = {1'b0,y_set} - {1'b0,y_reset};
  assign z_axis_x2 = {1'b0,z_set} - {1'b0,z_reset};
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      x_axis <= 16'h0;
      y_axis <= 16'h0;
      z_axis <= 16'h0;
    end else begin
      if(inCalibrate) begin
        x_axis <= x_axis_x2[16:1];
        y_axis <= y_axis_x2[16:1];
        z_axis <= z_axis_x2[16:1];
      end else if(inCalculate) begin
        x_axis <= x_set - x_offset;
        y_axis <= y_set - y_offset;
        z_axis <= z_set - z_offset;
      end else begin
        x_axis <= x_axis;
        y_axis <= y_axis;
        z_axis <= z_axis;
      end
    end
  end

  //State transactions
  always@(posedge clk or posedge rst)
    if(rst)
      state <= STANDBY;
    else case(state)
      STANDBY:
        begin
          if(calibrate)
            state <= RSET_REFILL;
          else if(ch_res)
            state <= CH_RESLTN;
          else if(measure)
            state <= MEASURE;
        end
      //Calibration mode, also updates measurement values
      //Reset measurement
      RSET_REFILL: //Write to Internal Control reg 0
        state <= (I2C_done) ? RSET_A_STAT0 : state;
      RSET_A_STAT0:
        state <= (I2C_done) ? RSET_WAIT : state;
      RSET_WAIT: 
        state <= (I2C_done) ? ((sensor_ready) ? RSET : RSET_A_STAT0) : state;
      RSET:
        state <= (I2C_done) ? RSET_MEAS : state;
      RSET_MEAS: 
        state <= (I2C_done) ? RSET_A_STAT1 : state;
      RSET_A_STAT1: 
        state <= (I2C_done) ? RSET_POLL : state;
      RSET_POLL: 
        state <= (I2C_done) ? ((sensor_ready) ? RSET_A_DATA : RSET_A_STAT1) : state;
      RSET_A_DATA: 
        state <= (I2C_done) ? RSET_READ : state;
      RSET_READ: 
        state <= (I2C_done) ? SET_REFILL : state;
      //Set measurement
      SET_REFILL: 
        state <= (I2C_done) ? SET_A_STAT0 : state;
      SET_A_STAT0: 
        state <= (I2C_done) ? SET_WAIT : state;
      SET_WAIT: 
        state <= (I2C_done) ? ((sensor_ready) ? SET : SET_A_STAT0) : state;
      SET: 
        state <= (I2C_done) ? SET_MEAS : state;
      SET_MEAS: 
        state <= (I2C_done) ? SET_A_STAT1 : state;
      SET_A_STAT1: 
        state <= (I2C_done) ? SET_POLL : state;
      SET_POLL: 
        state <= (I2C_done) ? ((sensor_ready) ? SET_A_DATA : SET_A_STAT1) : state;
      SET_A_DATA: 
        state <= (I2C_done) ? SET_READ : state;
      SET_READ: 
        state <= (I2C_done) ? CALIBRATE : state;
      //Calculate all
      CALIBRATE: 
        state <= STANDBY;
      //Normal measurement mode
      MEASURE: 
        state <= (I2C_done) ? STAT_AD : state;
      STAT_AD: 
        state <= (I2C_done) ? POLL : state;
      POLL: 
        state <= (I2C_done) ? ((sensor_ready) ? DATA_AD : STAT_AD) : state;
      DATA_AD: 
        state <= (I2C_done) ? READ : state;
      READ: 
        state <= (I2C_done) ? CALCULATE : state;
      CALCULATE: 
        state <= STANDBY;
      //Change resolution
      CH_RESLTN:
        state <= (I2C_done) ? STANDBY : state;
    endcase

  //I2C state transactions
  always@(negedge clkI2Cx2 or posedge rst)
    if(rst)
        I2C_state <= I2C_READY;
    else case(I2C_state)
      I2C_READY: 
        I2C_state <= (inI2Cstate & SCLK & ~i2cBusy) ? I2C_START : I2C_state;
      I2C_START: 
        I2C_state <= (~SCL) ? I2C_ADDRS : I2C_state;
      I2C_ADDRS: 
        I2C_state <= (~SCL & bitCountDone) ? I2C_WRITE_ACK : I2C_state;
      I2C_WRITE_ACK: 
        I2C_state <= (~SCL) ? ((~SDA_d_i2c & ~byteCountDone) ? ((~read_nwrite) ? I2C_WRITE : I2C_READ): I2C_STOP) : I2C_state;
      I2C_WRITE: 
        I2C_state <= (~SCL & bitCountDone) ? I2C_WRITE_ACK : I2C_state;
      I2C_READ: 
        I2C_state <= (~SCL & bitCountDone) ? I2C_READ_ACK : I2C_state;
      I2C_READ_ACK: 
        I2C_state <= (~SCL) ? ((byteCountDone) ? I2C_STOP : I2C_READ) : I2C_state;
      I2C_STOP: 
        I2C_state <= (SCL) ? I2C_READY : I2C_state;
    endcase
  
  //Raw data from sensor
  always@(negedge clkI2Cx2 or posedge rst) begin
    if(rst) begin
      x_set <= 16'h0;
      x_reset <= 16'h0;
      y_set <= 16'h0;
      y_reset <= 16'h0;
      z_set <= 16'h0;
      z_reset <= 16'h0;
    end else begin
      if(I2CinRead) begin
        if(inRRead) //Reset measurements
          case(byteCounter[2:1])
            2'd0: x_reset <= (SCL) ? {x_reset[14:0], SDA} : x_reset;
            2'd1: y_reset <= (SCL) ? {y_reset[14:0], SDA} : y_reset;
            2'd2: z_reset <= (SCL) ? {z_reset[14:0], SDA} : z_reset;
          endcase
        if(inSRead | inRead) //Set measurements
          case(byteCounter[2:1])
            2'd0: x_set <= (SCL) ? {x_set[14:0], SDA} : x_set;
            2'd1: y_set <= (SCL) ? {y_set[14:0], SDA} : y_set;
            2'd2: z_set <= (SCL) ? {z_set[14:0], SDA} : z_set;
          endcase  
      end 
    end
  end
  
  //Delays
  always@(posedge clk) begin
    SDA_d <= SDA;
    I2CinAck_d <= I2CinAck;
    I2CinStop_d <= I2CinStop;
  end
  always@(negedge clkI2Cx2) begin
    SDA_d_i2c <= SDA;
  end

  //Buffer control
  assign send_upload = I2CinStart | I2CinWriteAck;
  assign send_shift = I2CinAddrs | I2CinWrite;
  always@(negedge clkI2Cx2) begin
    if(send_upload)
      send_buffer <= send_buffer_write;
    else if(send_shift & ~SCL & |bitCounter)
      send_buffer <= {send_buffer << 1};
  end
  always@* //Buffer write
    case(byteCounter)
      3'b111: send_buffer_write = {i2c_ADDRESS, read_nwrite};
      3'd0: //Register address
        case(state)
          //Calib reset
          RSET_REFILL: send_buffer_write = CONTROL0_REG;
          RSET_A_STAT0: send_buffer_write = STATUS_REG;
          RSET: send_buffer_write = CONTROL0_REG;
          RSET_MEAS: send_buffer_write = CONTROL0_REG;
          RSET_A_STAT1: send_buffer_write = STATUS_REG;
          RSET_A_DATA: send_buffer_write = DATA_REG;
          //Calib set
          SET_REFILL: send_buffer_write = CONTROL0_REG;
          SET_A_STAT0: send_buffer_write = STATUS_REG;
          SET: send_buffer_write = CONTROL0_REG;
          SET_MEAS: send_buffer_write = CONTROL0_REG;
          SET_A_STAT1: send_buffer_write = STATUS_REG;
          SET_A_DATA: send_buffer_write = DATA_REG;
          //Normal meas
          MEASURE: send_buffer_write = CONTROL0_REG;
          STAT_AD: send_buffer_write = STATUS_REG;
          DATA_AD: send_buffer_write = DATA_REG;
          //ch res
          CH_RESLTN: send_buffer_write = CONTROL1_REG;
          default: send_buffer_write = 8'h0;
        endcase
      3'd1: //Register content
        case(state)
          //Calib reset
          RSET_REFILL: send_buffer_write = cntr0_REFILL;
          RSET: send_buffer_write = cntr0_RESET;
          RSET_MEAS: send_buffer_write = cntr0_MEASURE;
          //Calib set
          SET_REFILL: send_buffer_write = cntr0_REFILL;
          SET: send_buffer_write = cntr0_SET;
          SET_MEAS: send_buffer_write = cntr0_MEASURE;
          //Normal meas
          MEASURE: send_buffer_write = cntr0_MEASURE;
          //ch res
          CH_RESLTN: send_buffer_write = {6'd0, res};
          default: send_buffer_write = 8'h0;
        endcase
      default: send_buffer_write = 8'h0;
    endcase

  //Listen I2C Bus & cond. gen.
  assign    SDA_negedge  = ~SDA &  SDA_d;
  assign    SDA_posedge  =  SDA & ~SDA_d;
  assign  stopCondition  =  SCL & SDA_posedge;
  assign startCondition  =  SCL & SDA_negedge;

  //bit counter
  assign bitCountDone = ~|bitCounter;
  always@(posedge SCL) begin
    if(I2CinAck|I2CinStart)
      bitCounter <= 3'd0;
    else
      bitCounter <= bitCounter + {2'd0,(I2CinAddrs|I2CinWrite|I2CinRead)};
  end
  
  //byte counter
  assign byteCountUp = ~I2CinAck_d & I2CinAck;
  always@(posedge clk) begin
    if(I2CinStart)
      byteCounter <= 3'b111;
    else
      byteCounter <= byteCounter + {2'd0,byteCountUp};
  end
  always@* begin
    if(poll_state | ptr_write_state)
      byteCountDone = (byteCounter == 3'd1);
    else if(reg_write_state)
      byteCountDone = (byteCounter == 3'd2);
    else if(data_read_state)
      byteCountDone = (byteCounter == 3'd6);
    else
      byteCountDone = 1'b1;
  end
  
  //Store resolution config
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      res <= 2'd0;
    end else begin
      res <= (inChRes) ? resolution : res;
    end
  end
  
  //Determine if an other master is using the bus
  always@(posedge clk or posedge rst) begin
    if(rst)
      i2cBusy <= 1'b0;
    else case(i2cBusy)
      1'b0: i2cBusy <= startCondition & I2CinReady;
      1'b1: i2cBusy <= ~stopCondition & I2CinReady;
    endcase
  end
  
  //Divide clkI2Cx2 to get I2C clk
  always@(posedge clkI2Cx2 or posedge rst) begin
    if(rst)
      SCLK <= 1'b1;
    else
      SCLK <= ~SCLK;
  end
endmodule
