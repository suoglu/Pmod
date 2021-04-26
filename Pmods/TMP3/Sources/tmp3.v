/* ------------------------------------------------ *
 * Title       : Pmod TMP3 interface v1.0           *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : tmp3.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 26/04/2021                         *
 * ------------------------------------------------ *
 * Description : Simple interface to communicate    *
 *               with Pmod TMP3                     *
 * ------------------------------------------------ */

module tmp3(
  input clk,
  input rst,
  input clkI2Cx2, //!max 800 kHz
  //I2C pins
  inout SCL/* synthesis keep = 1 */,
  inout SDA/* synthesis keep = 1 */,
  //Configurations
  input [2:0] address_bits,
  input shutdown,
  input [1:0] resolution,
  input alert_polarity,
  input [1:0] fault_queue,
  input interrupt_mode,
  //Control signals
  output reg i2cBusy,
  output busy,
  input update,
  input write_temperature,
  input write_hyst_nLim,
  output reg valid_o,
  //Data
  output reg [11:0] temperature_o,
  input [8:0] temperature_i);
  localparam CONFIG_PTR = 2'b01,
           AMB_TEMP_PTR = 2'b00,
           HYS_TEMP_PTR = 2'b10,
           LMT_TEMP_PTR = 2'b11;
  localparam IDLE = 3'b000,
           CONFIG = 3'b100,
           UPDATE = 3'b001,
         SHUTDOWN = 3'b110,
        WRITE_TMP = 3'b010,
        WRITE_PTR = 3'b011;
  reg [2:0] state;
  wire inIdle, inConfig, inUpdate, inShutdown, inWriteTemp, inWritePointer;
  //I2C State names
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
  reg I2CinAck_d, I2CinStop_d;
  //Generate I2C signals with tri-state
  reg SCLK; //Internal I2C clock, always thicks
  wire SCL_claim;
  wire SDA_claim;
  wire SDA_write;
  //Address byte
  localparam FIX_ADDRS = 4'b1001;
  wire [7:0] addressByte, configByte;
  wire read_nwrite;
  //Delay I2C signals, finding edges and conditions
  reg SDA_d;
  wire startCondition, stopCondition; //I2C conditions
  wire SDA_negedge, SDA_posedge;
  //Buffer & Content
  reg [7:0] send_buffer, send_buffer_write;
  //Buffer control
  wire send_upload, send_shift; 
  //Transmisson counters
  reg [1:0] byteCounter;
  reg [2:0] bitCounter;
  reg byteCountDone;
  wire bitCountDone;
  wire byteCountUp;
  //Store Local Configs
  reg [1:0] resolution_reg, fault_queue_reg;
  reg alert_polarity_reg, interrupt_mode_reg;
  wire ch_config;

  //Form bytes
  assign addressByte = {FIX_ADDRS,address_bits,read_nwrite};
  assign configByte = {1'b0,resolution,fault_queue,alert_polarity,interrupt_mode,shutdown};

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

  //Decode States
  assign         inIdle = (state == IDLE);
  assign       inConfig = (state == CONFIG);
  assign       inUpdate = (state == UPDATE);
  assign     inShutdown = (state == SHUTDOWN);
  assign    inWriteTemp = (state == WRITE_TMP);
  assign inWritePointer = (state == WRITE_PTR);

  //Tri-state control for I2C lines
  assign SCL = (SCL_claim) ?    SCLK   : 1'bZ;
  assign SDA = (SDA_claim) ? SDA_write : 1'bZ;
  assign SCL_claim = ~I2CinReady;
  assign SDA_claim = I2CinStart | I2CinAddrs | I2CinWrite | I2CinReadAck | I2CinStop;
  assign SDA_write = (I2CinStart | I2CinReadAck | I2CinStop) ? (I2CinReadAck & byteCountDone) : send_buffer[7];

  //Temperature Output
  always@(negedge clkI2Cx2 or posedge rst)
    begin
      if(rst)
        begin
          temperature_o <= 12'h0;
        end
      else
        begin
          if(inUpdate & SCL)
            case(byteCounter)
              2'd0: temperature_o <= {temperature_o[10:0],SDA};
              2'd1: temperature_o <= (bitCounter < 3'd5) ? {temperature_o[10:0],SDA} : temperature_o;
            endcase
        end
    end

  //Control Signals
  assign read_nwrite = inUpdate;
  assign I2C_done = I2CinStop & ~I2CinStop_d;
  assign busy = ~I2CinReady;
  always@(posedge clk or posedge rst) //Output valid
    begin
      if(rst)
        begin
          valid_o <= 1'b0;
        end
      else
        case(valid_o)
          1'b0: valid_o <= I2C_done & inUpdate;
          1'b1: valid_o <= ~I2CinStart;
        endcase
    end
  
  //State Transactions
  always@(posedge clk or posedge rst) //state ch
    begin
      if(rst)
        begin
          state <= IDLE;
        end
      else
        begin
          case(state)
            IDLE:
              begin
                if(shutdown | ch_config)
                  state <= CONFIG;
                else if(write_temperature)
                  state <= WRITE_TMP;
                else if(update)
                  state <= UPDATE;
              end
            SHUTDOWN:
              begin
                state <= (~shutdown | ch_config) ? CONFIG : state;
              end
            CONFIG:
              begin
                state <= (I2C_done) ? ((shutdown) ? SHUTDOWN : WRITE_PTR) : state;
              end
            UPDATE:
              begin
                state <= (I2C_done) ? IDLE : state;
              end
            WRITE_TMP:
              begin
                state <= (I2C_done) ? WRITE_PTR : state;
              end
            WRITE_PTR:
              begin
                state <= (I2C_done) ? IDLE : state;
              end
            default:
              begin
                state <= IDLE;
              end
          endcase
        end
    end
    
  //Delays
  always@(posedge clk)
    begin
      SDA_d <= SDA;
      I2CinAck_d <= I2CinAck;
      I2CinStop_d <= I2CinStop;
    end
  
  //Buffer control
  assign send_upload = I2CinStart | I2CinWriteAck;
  assign send_shift = I2CinAddrs | I2CinWrite;
  always@(negedge clkI2Cx2) //Buffer
    begin
      if(send_upload)
        send_buffer <= send_buffer_write;
      else if(send_shift & ~SCL & |bitCounter)
        send_buffer <= {send_buffer << 1};
    end
  always@* //Buffer write
    begin
      case(byteCounter)
        2'd3: //I2C address
          begin
            send_buffer_write = addressByte;
          end
        2'd0: //Register pointer
          begin
            case(state)
              CONFIG:
                begin
                  send_buffer_write[1:0] = CONFIG_PTR;
                end
              WRITE_PTR:
                begin
                  send_buffer_write[1:0] = AMB_TEMP_PTR;
                end
              WRITE_TMP:
                begin
                  send_buffer_write[1:0] = (write_hyst_nLim) ? HYS_TEMP_PTR : LMT_TEMP_PTR;
                end
              default:
                begin
                  send_buffer_write[1:0] = 2'd0;
                end
            endcase
            send_buffer_write[7:2] = 6'd0;
          end
        2'd1: 
          begin
            send_buffer_write = (inConfig) ? configByte : temperature_i[8:1];
          end
        2'd2:
          begin
            send_buffer_write = {temperature_i[0],7'd0};
          end
        default:
          begin
            send_buffer_write = 8'h0;
          end
      endcase
    end

  //Listen I2C Bus & cond. gen.
  assign    SDA_negedge  = ~SDA &  SDA_d;
  assign    SDA_posedge  =  SDA & ~SDA_d;
  assign  stopCondition  =  SCL & SDA_posedge;
  assign startCondition  =  SCL & SDA_negedge;

  //bit counter
  assign bitCountDone = ~|bitCounter;
  always@(posedge SCL) 
    begin
      if(I2CinAck|I2CinStart)
        begin
          bitCounter <= 3'd0;
        end
      else
        begin
          bitCounter <= bitCounter + {2'd0,(I2CinAddrs|I2CinWrite|I2CinRead)};
        end
    end
  
  //byte counter
  assign byteCountUp = ~I2CinAck_d & I2CinAck;
  always@(posedge clk) 
    begin
      if(I2CinStart)
        begin
          byteCounter <= 2'b11;
        end
      else
        begin
          byteCounter <= byteCounter + {1'd0,byteCountUp};
        end
    end
  always@*
    begin
      case(state)
        CONFIG:    byteCountDone = (byteCounter == 2'd2);
        UPDATE:    byteCountDone = (byteCounter == 2'd2);
        WRITE_TMP: byteCountDone = (byteCounter == 2'd3);
        WRITE_PTR: byteCountDone = (byteCounter == 2'd1);
        default:   byteCountDone = 1'b1;
      endcase
    end
  
  //Store configurations
  assign ch_config = (resolution_reg != resolution) | (alert_polarity_reg != alert_polarity) | (fault_queue_reg != fault_queue) | (interrupt_mode_reg != interrupt_mode);
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          alert_polarity_reg <= 1'b0;
          resolution_reg <= 2'b00;
          fault_queue_reg <= 2'b00;
          interrupt_mode_reg <= 1'b0;
        end
      else
        begin
          if(ch_config & inConfig)
            begin
              alert_polarity_reg <= alert_polarity;
              resolution_reg <= resolution;
              fault_queue_reg <= fault_queue;
              interrupt_mode_reg <= interrupt_mode;
            end
        end
    end

  //Determine if an other master is using the bus
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          i2cBusy <= 1'b0;
        end
      else
        begin
          case(i2cBusy)
            1'b0:
              begin
                i2cBusy <= startCondition & I2CinReady;
              end
            1'b1:
              begin
                i2cBusy <= ~stopCondition & I2CinReady;
              end
          endcase
        end
    end
  
  //Divide clkI2Cx2 to get I2C clk
  always@(posedge clkI2Cx2 or posedge rst)
    begin
      if(rst)
        begin
          SCLK <= 1'b1;
        end
      else
        begin
          SCLK <= ~SCLK;
        end
    end
endmodule