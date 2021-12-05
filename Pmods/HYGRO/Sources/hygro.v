/* ------------------------------------------------ *
 * Title       : Pmod HYGRO interface v2.0          *
 * Project     : Pmod HYGRO interface               *
 * ------------------------------------------------ *
 * File        : hygro.v                            *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 02/02/2021                         *
 * ------------------------------------------------ *
 * Description : Simple interfaces to communicate   *
 *               with Pmod HYGRO                    *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version for lite interface  *
 *     v2      : Full module                        *
 * ------------------------------------------------ */

module hygro(
  input clk,
  input rst,
  input i2c_2clk, //Used to shifting and sampling, max 800kHz
  //Control signals
  input measureT,
  input measureH,
  output newData,
  output dataUpdating,
  output reg sensNR, //Sensor is not responding
  //Data output
  output reg [13:0] tem,
  output reg [13:0] hum,
  //Configurations
  input heater,
  input acMode,
  input TRes,
  input [1:0] HRes,
  input swRst,
  //I2C pins
  inout SCL/* synthesis keep = 1 */, 
  inout SDA/* synthesis keep = 1 */);
  localparam CHIPADDRS = 7'h40,
          TEMPREGADDRS = 8'h00,
           HUMREGADDRS = 8'h01,
        CONFIGREGADDRS = 8'h02,
        CONFIGRSTVALUE = 8'h90;
  reg i2c_clk; //390.625kHz
  wire SDA_Claim;
  wire SDA_Write;
  reg SCL_d;
  //I2C flow control
  wire gettingTEM, gettingHUM;
  reg SDA_d, SDA_dd;
  //Module states
  reg [2:0] state;
  localparam SLEEP = 3'b000,
            CONFIG = 3'b101,
             SWRST = 3'b111,
            TADDRS = 3'b001,
            HADDRS = 3'b100,
            GETRES = 3'b010;
  wire inSLEEP, inCONFIG, inSWRST, inTADDRS, inHADDRS, inGETRES;
  //I2C states
  reg [2:0] i2c_state;
  localparam I2C_READY = 3'b000,
             I2C_START = 3'b001,
             I2C_ADDRS = 3'b011,
             I2C_WRITE = 3'b110,
         I2C_WRITE_ACK = 3'b010,
              I2C_READ = 3'b111,
          I2C_READ_ACK = 3'b101,
              I2C_STOP = 3'b100;
  wire I2Cin_READY, I2Cin_START, I2Cin_ADDRS, I2Cin_WRITE, I2Cin_WRITE_ACK, I2Cin_READ, I2Cin_READ_ACK, I2Cin_STOP, I2Cin_ACK;
  //Initiate I2C transaction
  wire I2Cinit;
  wire I2Cdone;
  reg i2c_busy;
  //Counters
  reg [2:0] i2cBitCounter; //Count current bit
  reg [2:0] i2cByteCounter; //Count databytes
  wire i2cBitCounterDONE;
  reg i2cByteCounterDONE;
  wire SDA_posedge, SDA_negedge;
  wire startCond, stopCond;
  reg [7:0] SDAbuff;
  reg [7:0] SDAbuffin;

  //Store config regs
  reg heater_reg,acMode_reg, TRes_reg;
  reg [1:0]  HRes_reg;
  wire configUp;
  wire modeSingle, modeBoth;
  reg tempM, humM;
  wire updateConfig;

  //States and state driven signals
  assign inSLEEP  = (state == SLEEP);
  assign inCONFIG = (state == CONFIG);
  assign inSWRST  = (state == SWRST);
  assign inTADDRS = (state == TADDRS);
  assign inHADDRS = (state == HADDRS);
  assign inGETRES = (state == GETRES);
  assign I2Cinit = ~inSLEEP;

  //State transactions
  always@(posedge clk or posedge rst) begin
      if(rst) begin
        state <= SLEEP;
      end else case(state)
        SLEEP: begin
          if(swRst)
            state <= SWRST;
          else if(updateConfig)
            state <= CONFIG;
          else if(measureT)
            state <= TADDRS;
          else if(measureH) begin
            if(modeBoth)
              state <= TADDRS;
            else
              state <= HADDRS;
          end
        end
        CONFIG: state <= (I2Cdone) ? SLEEP : state;
        SWRST : state <= (I2Cdone) ? SLEEP : state;
        TADDRS: state <= (I2Cdone) ? GETRES : state;
        HADDRS: state <= (I2Cdone) ? GETRES : state;
        GETRES: state <= (I2Cdone) ? SLEEP : state;
      endcase
    end

  //I2C states and I2C state drived signals
  assign I2Cin_READY = (i2c_state == I2C_READY);
  assign I2Cin_START = (i2c_state == I2C_START);
  assign I2Cin_ADDRS = (i2c_state == I2C_ADDRS);
  assign I2Cin_WRITE = (i2c_state == I2C_WRITE);
  assign I2Cin_WRITE_ACK = (i2c_state == I2C_WRITE_ACK);
  assign I2Cin_READ = (i2c_state == I2C_READ);
  assign I2Cin_READ_ACK = (i2c_state == I2C_READ_ACK);
  assign I2Cin_STOP = (i2c_state == I2C_STOP);
  assign I2Cin_ACK = I2Cin_WRITE_ACK | I2Cin_READ_ACK;
  assign newData = inGETRES & I2Cdone;

  //I2C state transactions
  assign I2Cdone = i2cByteCounterDONE & I2Cin_STOP;
  always@(negedge i2c_2clk) begin
    SDA_dd <= SDA;
  end
  always@(negedge i2c_2clk or posedge rst) begin
    if(rst)
      i2c_state <= I2C_READY;
    else case(i2c_state)
      I2C_READY     : i2c_state <= (~i2c_busy & I2Cinit & i2c_clk) ? I2C_START : i2c_state;
      I2C_START     : i2c_state <= (~SCL) ? I2C_ADDRS : i2c_state;
      I2C_ADDRS     : i2c_state <= (~SCL & i2cBitCounterDONE) ? I2C_WRITE_ACK : i2c_state;
      I2C_WRITE_ACK : i2c_state <= (~SCL) ? ((~SDA_dd & ~i2cByteCounterDONE) ? ((~inGETRES) ? I2C_WRITE : I2C_READ): I2C_STOP) : i2c_state;
      I2C_WRITE     : i2c_state <= (~SCL & i2cBitCounterDONE) ? I2C_WRITE_ACK : i2c_state;
      I2C_READ      : i2c_state <= (~SCL & i2cBitCounterDONE) ? I2C_READ_ACK : i2c_state;
      I2C_READ_ACK  : i2c_state <= (~SCL) ? ((i2cByteCounterDONE) ? I2C_STOP : I2C_READ) : i2c_state;
      I2C_STOP      : i2c_state <= (SCL) ?  I2C_READY : i2c_state;
    endcase
  end

  //SDA content control
  assign dataUpdating = I2Cin_READ | I2Cin_READ_ACK;
  assign gettingTEM = ((i2cByteCounter == 3'd1) | ((i2cByteCounter == 3'd2) & (i2cBitCounter < 3'd6))) & (modeBoth | tempM);
  assign gettingHUM = ((i2cByteCounter == 3'd3) | ((i2cByteCounter == 3'd4) & (i2cBitCounter < 3'd6))) | ((i2cByteCounter == 3'd1) | ((i2cByteCounter == 3'd2) & (i2cBitCounter < 3'd6))) & humM;
  always@(posedge clk) begin
    case(state)
      SLEEP: begin
        tempM <= 1'd0;
         humM <= 1'd0;
      end
      TADDRS: tempM <= modeSingle;
      HADDRS: humM <= modeSingle;
    endcase 
  end

  //I2C signals control
  assign SCL = (I2Cin_READY) ? 1'bZ : i2c_clk;
  assign SDA = (SDA_Claim) ? SDA_Write : 1'bZ;
  assign SDA_Claim = I2Cin_START | I2Cin_ADDRS | I2Cin_WRITE | I2Cin_READ_ACK | I2Cin_STOP;
  assign SDA_Write = (I2Cin_READ_ACK | I2Cin_START | I2Cin_STOP) ? (I2Cin_READ_ACK & i2cByteCounterDONE) : SDAbuff[7];
  always@(posedge clk) begin
    SDA_d <= SDA;
  end
  always@(posedge i2c_2clk) begin
    SCL_d <= SCL;
  end
  
  //I2C multi master control
  assign SDA_posedge = SDA & ~SDA_d;
  assign SDA_negedge = ~SDA & SDA_d;
  assign startCond = SCL & SDA_negedge;
  assign stopCond = SCL & SDA_posedge;
  always@(posedge clk) begin
    if(I2Cin_READY) begin //? is it needed?
      if(startCond)
        i2c_busy <= 1'd1;
      else if(stopCond)
        i2c_busy <= 1'd0;
    end else begin
      i2c_busy <= 1'd0;
    end
  end

  //Responded
  always@(negedge i2c_2clk) begin
    if(i2c_clk & I2Cin_WRITE_ACK & (i2cByteCounterDONE == 3'd1))begin
      sensNR <= SDA;
    end
  end

  //I2C bit counter
  assign i2cBitCounterDONE = ~|i2cBitCounter;
  always@(posedge SCL_d) begin
    case(i2c_state)
      I2C_ADDRS : i2cBitCounter <= i2cBitCounter + 3'd1;
      I2C_WRITE : i2cBitCounter <= i2cBitCounter + 3'd1;
      I2C_READ  : i2cBitCounter <= i2cBitCounter + 3'd1;
      default   : i2cBitCounter <= 3'd0;
    endcase
  end

  //I2C byte counter
  always@(posedge I2Cin_ACK or posedge I2Cin_START) begin
    if(I2Cin_START) begin
      i2cByteCounter <= 3'd0;
    end else begin
      i2cByteCounter <= i2cByteCounter + 3'd1;
    end
  end
  always@* begin
    case(state)
      CONFIG  : i2cByteCounterDONE = (i2cByteCounter == 3'd4);
      SWRST   : i2cByteCounterDONE = (i2cByteCounter == 3'd4);
      TADDRS  : i2cByteCounterDONE = (i2cByteCounter == 3'd2);
      HADDRS  : i2cByteCounterDONE = (i2cByteCounter == 3'd2);
      GETRES  : i2cByteCounterDONE = (modeSingle) ? (i2cByteCounter == 3'd3) : (i2cByteCounter == 3'd5);
      default : i2cByteCounterDONE = 1'd1;
    endcase
  end
  
  //SDA buffer
  always@* begin
    case(i2cByteCounter)
      3'd0: SDAbuffin <= {CHIPADDRS,inGETRES};
      3'd1:
        case(state)
          CONFIG  : SDAbuffin <= CONFIGREGADDRS;
          SWRST   : SDAbuffin <= CONFIGREGADDRS;
          TADDRS  : SDAbuffin <= TEMPREGADDRS;
          HADDRS  : SDAbuffin <= HUMREGADDRS;
          default : SDAbuffin <= 8'h00;
        endcase
      3'd2:
        case(state)
          CONFIG  : SDAbuffin <= {2'b0,heater,acMode,1'b0,TRes,HRes};
          SWRST   : SDAbuffin <= CONFIGRSTVALUE;
          default : SDAbuffin <= 8'h00;
        endcase
      default: SDAbuffin <= 8'h00;
    endcase
  end
  always@(negedge i2c_2clk) begin
    if(~i2c_clk)
      case(i2c_state)
        I2C_START: SDAbuff <= SDAbuffin;
        I2C_WRITE_ACK: SDAbuff <= SDAbuffin;
        I2C_ADDRS: SDAbuff <= (SDAbuff << 1);
        I2C_WRITE: SDAbuff <= (SDAbuff << 1);
      endcase
  end

  //Temperature register
  always@(negedge i2c_2clk or posedge rst) begin
    if(rst) begin
      tem <= 14'd0;
    end else if (i2c_clk & I2Cin_READ) begin
      tem <= (gettingTEM) ? {tem[12:0], SDA}: tem;
    end
  end

  //Humidity register
  always@(negedge i2c_2clk or posedge rst) begin
    if(rst) begin
      hum <= 14'd0;
    end else if (i2c_clk & I2Cin_READ) begin
      hum <= (gettingHUM) ? {hum[12:0], SDA}: hum;
    end
  end
  
  //Handle config regs
  assign configUp = inCONFIG | rst;
  assign updateConfig = ({heater_reg, TRes_reg, HRes_reg, acMode_reg} !=  {heater, TRes, HRes, acMode});
  assign modeBoth = acMode_reg;
  assign modeSingle = ~acMode_reg;
  always@(posedge configUp or posedge inSWRST) begin
    if(inSWRST) begin
      {heater_reg, TRes_reg, HRes_reg, acMode_reg} <= {1'd0, 1'd0,2'd0, 1'd1};
    end else begin
      {heater_reg, TRes_reg, HRes_reg, acMode_reg} <=  {heater, TRes, HRes, acMode};
    end
  end
  
  always@(posedge i2c_2clk or posedge rst) begin
    if(rst) begin
        i2c_clk <= 1'b0;
    end else begin
        i2c_clk <= ~i2c_clk;
    end
  end
endmodule

//Lite module uses default settings of sensor
module hygro_lite(
  input clk,
  input rst,
  input i2c_2clk,//Used to shifting and sampling, max 800kHz
  //Control signals
  input measure,
  output newData,
  output i2c_busy,
  output dataUpdating,
  output reg sensNR, //Sensor is not responding
  //Data output
  output reg [13:0] tem,
  output reg [13:0] hum,
  //I2C pins
  output SCL/* synthesis keep = 1 */, 
  inout SDA/* synthesis keep = 1 */);
  reg i2c_clk; //390.625kHz
  wire SDA_Claim;
  wire SDA_Write;
  //I2C flow control
  wire gettingTEM, gettingHUM;
  reg givingADDRS;
  reg SDA_d;
  reg noMoreByte;
  reg [7:0] SDA_w_buff;
  //Module states
  reg [1:0] state; 
  localparam IDLE = 2'b00,
         BEG_MEAS = 2'b01,
             WAIT = 2'b11,
          GET_DAT = 2'b10;
  wire in_IDLE, in_BEG_MEAS, in_WAIT, in_GET_DAT;
  //I2C states
  reg [2:0] i2c_state;
  localparam I2C_READY = 3'b000,
             I2C_START = 3'b001,
             I2C_ADDRS = 3'b011,
             I2C_WRITE = 3'b110,
         I2C_WRITE_ACK = 3'b010,
              I2C_READ = 3'b111,
          I2C_READ_ACK = 3'b101,
              I2C_STOP = 3'b100;
  wire I2Cin_READY, I2Cin_START, I2Cin_ADDRS, I2Cin_WRITE, I2Cin_WRITE_ACK, I2Cin_READ, I2Cin_READ_ACK, I2Cin_STOP;
  //Initiate I2C transaction
  reg I2Cinit;
  //Counters
  reg [2:0] bitCounter; //Count current bit
  reg [1:0] byteCounter; //Count databytes
  //Check whether sensor responded
  reg responded;
  //Edge detection for i2c_2clk
  reg i2c_2clk_d;
  wire i2c_2clk_negedge;
  //I2C decode states and I2C state drived signals
  assign I2Cin_READY = (i2c_state == I2C_READY);
  assign I2Cin_START = (i2c_state == I2C_START);
  assign I2Cin_ADDRS = (i2c_state == I2C_ADDRS);
  assign I2Cin_WRITE = (i2c_state == I2C_WRITE);
  assign I2Cin_WRITE_ACK = (i2c_state == I2C_WRITE_ACK);
  assign I2Cin_READ = (i2c_state == I2C_READ);
  assign I2Cin_READ_ACK = (i2c_state == I2C_READ_ACK);
  assign I2Cin_STOP = (i2c_state == I2C_STOP);
  assign i2c_busy = ~I2Cin_READY;

  //Decode states
  assign in_IDLE = (state == IDLE);
  assign in_BEG_MEAS = (state == BEG_MEAS);
  assign in_WAIT = (state == WAIT);
  assign in_GET_DAT = (state == GET_DAT);
  assign newData = ~sensNR & I2Cin_STOP & in_IDLE;

  //SDA content control
  assign dataUpdating = I2Cin_READ | I2Cin_READ_ACK;
  assign gettingTEM = (byteCounter == 2'd0) | ((byteCounter == 2'd1) & (bitCounter < 3'd6));
  assign gettingHUM = (byteCounter == 2'd2) | ((byteCounter == 2'd3) & (bitCounter < 3'd6));

  //I2C signals control
  assign SCL = (I2Cin_READY) ? 1'b1 : i2c_clk;
  assign SDA = (SDA_Claim) ? SDA_Write : 1'bZ;
  assign SDA_Claim = I2Cin_START | I2Cin_ADDRS | I2Cin_WRITE | I2Cin_READ_ACK | I2Cin_STOP;
  always@(negedge i2c_2clk) begin
    SDA_d <= SDA;
  end

  //State transactions
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      state <= IDLE;
    end else case(state)
      IDLE     : state <= (measure & I2Cin_READY) ? BEG_MEAS : state;
      BEG_MEAS : state <= (I2Cin_WRITE_ACK & SCL & i2c_2clk_negedge) ? ((SDA_d) ? IDLE : WAIT) : state;
      WAIT     : state <= (I2Cin_READY) ? GET_DAT : state;
      GET_DAT  : state <= (I2Cin_STOP) ? WAIT : ((I2Cin_READ) ? IDLE : state);
    endcase
  end

  //sensNR & responded
  always@(posedge in_IDLE) begin
    sensNR <= ~responded;
  end
  always@(posedge clk) begin
    responded <= (responded & ~in_WAIT) | in_GET_DAT;
  end
  
  
  //I2Cinit
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      I2Cinit <= 1'b0;
    end else case(I2Cinit)
      1'b0: I2Cinit <= (in_BEG_MEAS | in_WAIT) & I2Cin_READY;
      1'b1: I2Cinit <= I2Cin_READY;
    endcase
  end
  
  //Edge detection for i2c_2clk
  assign i2c_2clk_negedge = i2c_2clk_d & i2c_2clk;
  always@(posedge clk) begin
    i2c_2clk_d <= i2c_2clk;
  end
  

  //givingADDRS
  always@(posedge clk) begin
    if(I2Cin_START)
      givingADDRS <= 1'b1;
    else if(I2Cin_READ | I2Cin_WRITE | I2Cin_STOP)
      givingADDRS <= 1'b0;
  end
  
  //I2C State transactions
  always@(negedge i2c_2clk or posedge rst) begin
    if(rst) begin
      i2c_state <= I2Cin_READ;
    end else case(i2c_state)
      I2C_READY     :i2c_state <= (I2Cinit & i2c_clk) ? I2C_START : i2c_state;
      I2C_START     : i2c_state <= (~SCL) ? I2C_ADDRS : i2c_state;
      I2C_ADDRS     : i2c_state <= (~SCL & &bitCounter) ? I2C_WRITE_ACK : i2c_state;
      I2C_WRITE_ACK : i2c_state <= (~SCL) ? ((~SDA_d & givingADDRS) ? ((in_WAIT) ?  I2C_WRITE : I2C_READ): I2C_STOP) : i2c_state;
      I2C_WRITE     : i2c_state <= (~SCL & &bitCounter) ? I2C_WRITE_ACK : i2c_state;
      I2C_READ      : i2c_state <= (~SCL & &bitCounter) ? I2C_READ_ACK : i2c_state;
      I2C_READ_ACK  : i2c_state <= (~SCL) ? ((noMoreByte) ? I2C_STOP : I2C_READ) : i2c_state;
      I2C_STOP      : i2c_state <= (SCL) ? I2C_READY : i2c_state;
    endcase
  end
  //noMoreByte
  always@(negedge I2Cin_READ_ACK or posedge I2Cin_ADDRS) begin
    if(I2Cin_ADDRS)
      noMoreByte <= 1'b0;
    else
      noMoreByte <= noMoreByte | (byteCounter == 2'd3);
  end
  

  //Count read bytes
  always@(negedge i2c_2clk) begin //Count during read ack and stop counting when max reached, auto reset while giving address
    byteCounter <= (I2Cin_ADDRS) ? 2'd0 : (byteCounter + {1'd0, (I2Cin_READ_ACK & i2c_clk)});
  end

  //Count Bits
  always@(posedge i2c_clk) begin
    if(I2Cin_READ_ACK | I2Cin_READY | I2Cin_WRITE_ACK)
      bitCounter <= 3'b111;
    else if(I2Cin_ADDRS | I2Cin_READ | I2Cin_WRITE)
      bitCounter <= bitCounter + 3'd1;
  end
  

  //Handle sending addresses
  assign SDA_Write = (I2Cin_READ_ACK | I2Cin_START | I2Cin_STOP) ? (I2Cin_READ_ACK & noMoreByte) : SDA_w_buff[7];
  always@(negedge i2c_2clk) begin
    if(I2Cin_START)
      SDA_w_buff <= {7'b1000000, in_GET_DAT};
    else if(~SCL)
      SDA_w_buff <= {SDA_w_buff[6:0], 1'b0};
  end
  
  //Temperature register
  always@(negedge i2c_2clk or posedge rst) begin
    if(rst) begin
      tem <= 14'd0;
    end else if (i2c_clk & I2Cin_READ) begin
      tem <= (gettingTEM) ? {tem[12:0], SDA}: tem;
    end
  end

  //Humidity register
  always@(negedge i2c_2clk or posedge rst) begin
    if(rst) begin
      hum <= 14'd0;
    end else if (i2c_clk & I2Cin_READ) begin
      hum <= (gettingHUM) ? {hum[12:0], SDA}: hum;
    end
  end

  always@(posedge i2c_2clk or posedge rst) begin
    if(rst) begin
        i2c_clk <= 1'b0;
    end else begin
        i2c_clk <= ~i2c_clk;
    end
  end
endmodule//hygro_lite

//Generate 781.25kHz clock signal for i2c
module clockGen_i2c(
  input clk_i,
  input rst,
  output clk_781k);

  reg [6:0] clk_d;

  assign clk_781k = clk_d[6];

  //50MHz
  always@(posedge clk_i or posedge rst)  begin
    if(rst) begin
      clk_d[0] <= 0;
    end  else  begin
      clk_d[0] <= ~clk_d[0];
    end
  end
  //25MHz
  always@(posedge clk_d[0] or posedge rst)  begin
    if(rst) begin
      clk_d[1] <= 0;
    end  else  begin
      clk_d[1] <= ~clk_d[1];
    end
  end
  //12.5MHz
  always@(posedge clk_d[1] or posedge rst)  begin
    if(rst) begin
      clk_d[2] <= 0;
    end  else  begin
      clk_d[2] <= ~clk_d[2];
    end
  end
  //6.25MHz
  always@(posedge clk_d[2] or posedge rst)  begin
    if(rst) begin
      clk_d[3] <= 0;
    end  else  begin
      clk_d[3] <= ~clk_d[3];
    end
  end
  //3.125MHz
  always@(posedge clk_d[3] or posedge rst)  begin
    if(rst) begin
      clk_d[4] <= 0;
    end  else  begin
      clk_d[4] <= ~clk_d[4];
    end
  end
  //1.562MHz
  always@(posedge clk_d[4] or posedge rst)  begin
    if(rst) begin
      clk_d[5] <= 0;
    end  else  begin
      clk_d[5] <= ~clk_d[5];
    end
  end
  //781.25kHz
  always@(posedge clk_d[5] or posedge rst)  begin
    if(rst) begin
      clk_d[6] <= 0;
    end  else  begin
      clk_d[6] <= ~clk_d[6];
    end
  end
endmodule
