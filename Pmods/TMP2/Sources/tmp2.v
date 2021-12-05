/* ------------------------------------------------ *
 * Title       : Pmod TMP2 interface v1.0           *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : tmp2.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 29/04/2021                         *
 * ------------------------------------------------ *
 * Description : Simple interface to communicate    *
 *               with Pmod TMP2                     *
 * ------------------------------------------------ */

module tmp2(
  input clk,
  input rst,
  input clkI2Cx2, //!max 800 kHz
  //I2C pins
  inout SCL/* synthesis keep = 1 */,
  inout SDA/* synthesis keep = 1 */,
  //Configurations
  input [1:0] address_bits,
  input shutdown,
  input resolution,
  input sps1,
  input comparator_mode,
  input polarity_ct,
  input polarity_int,
  input [1:0] fault_queue,
  //Control signals
  output reg i2cBusy,
  output busy,
  input sw_rst,
  input update,
  input one_shot,
  input write_temperature,
  input [1:0] write_temp_target,
  output reg valid_o,
  //Data
  output reg [15:0] temperature_o,
  input [15:0] temperature_i);
  //register pointers
  localparam  SW_RESET = 8'h2F,
            CONFIG_PTR = 8'h03,
          AMB_TEMP_PTR = 8'h00,
          HYS_TEMP_PTR = 8'h0A,
          LOW_TEMP_PTR = 8'h06,
         HIGH_TEMP_PTR = 8'h04,
         CRIT_TEMP_PTR = 8'h08;
  //Operation modes
  localparam SPS1_MODE = 2'b10,
          ONESHOT_MODE = 2'b01,
         SHUTDOWN_MODE = 2'b11,
       CONTINUOUS_MODE = 2'b00;
  //Temperature registers
  localparam T_LOW = 2'd2, //16 bit
            T_HIGH = 2'd3, //16 bit
            T_CRIT = 2'd1, //16 bit
            T_HYST = 2'd0; //8 bit
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
  reg I2CinAck_d, I2CinStop_d, SDA_d_i2c;
  //Generate I2C signals with tri-state
  reg SCLK; //Internal I2C clock, always thicks
  wire SCL_claim;
  wire SDA_claim;
  wire SDA_write;
  //State
  localparam IDLE = 3'h0,
           SW_RST = 3'h7,
           UPDATE = 3'h1,
           CONFIG = 3'h3,
         ONE_SHOT = 3'h5,
         SHUTDOWN = 3'h2,
        WRITE_TMP = 3'h4,
        WRITE_PTR = 3'h6;
  reg [2:0] state;
  wire inIdle, inSWreset, inUpdate, inConfig, inOneShot, inShutdown, inWriteTmp, inWritePtr;
  //Address byte
  localparam FIX_ADDRS = 5'b10010;
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
  wire ch_config;
  reg resolution_reg, comparator_mode_reg, polarity_ct_reg, polarity_int_reg, sps1_reg;
  reg [1:0] fault_queue_reg;
  reg [1:0] op_mode;
  //Extra control signals
  wire register_rst;

  //Form bytes
  assign addressByte = {FIX_ADDRS,address_bits,read_nwrite};
  assign configByte = {resolution,op_mode,comparator_mode,polarity_int,polarity_ct,fault_queue};
  always@* begin
    if(inOneShot) begin
      op_mode = ONESHOT_MODE;
    end else if(shutdown) begin
      op_mode = SHUTDOWN_MODE;
    end else if(sps1) begin
      op_mode = SPS1_MODE;
    end else begin
      op_mode = CONTINUOUS_MODE;
    end
  end

  //Control Signals
  assign ch_config = (resolution_reg != resolution) | (comparator_mode_reg != comparator_mode) | (fault_queue_reg != fault_queue) | (polarity_ct_reg != polarity_ct) | (polarity_int_reg != polarity_int) | (sps1_reg != sps1);
  assign read_nwrite = inUpdate;
  assign I2C_done = I2CinStop & ~I2CinStop_d;
  assign busy = ~I2CinReady;
  assign register_rst = rst | sw_rst;
  always@(posedge clk or posedge rst) begin //Output valid
    if(rst) begin
      valid_o <= 1'b0;
    end else case(valid_o)
      1'b0: valid_o <= I2C_done & inUpdate & byteCountDone;
      1'b1: valid_o <= ~I2CinStart;
    endcase
  end
  
  //Get temperature data
  always@(negedge clkI2Cx2) begin
    if(I2CinRead & SCL & inUpdate) begin
      temperature_o <= {temperature_o[14:0], SDA};
    end
  end

  //Store configs
  always@(posedge clk or posedge register_rst) begin
    if(register_rst) begin
      fault_queue_reg <= 2'd0;
      resolution_reg <= 1'd0;
      comparator_mode_reg <= 1'd0;
      polarity_ct_reg <= 1'd0;
      polarity_int_reg <= 1'd0;
      sps1_reg <= 1'd0;
    end else begin
      if(ch_config & inConfig) begin
        fault_queue_reg <= fault_queue;
        resolution_reg <= resolution;
        comparator_mode_reg <= comparator_mode;
        polarity_ct_reg <= polarity_ct;
        polarity_int_reg <= polarity_int;
        sps1_reg <= sps1;
      end
    end
  end

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
  assign      inSWreset = (state == SW_RST);
  assign      inOneShot = (state == ONE_SHOT);
  assign     inShutdown = (state == SHUTDOWN);
  assign     inWriteTmp = (state == WRITE_TMP);
  assign     inWritePtr = (state == WRITE_PTR);

  //State transactions
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      state <= SW_RST;
    end else case(state)
      SW_RST    : state <= (I2C_done) ? IDLE : state;
      UPDATE    : state <= (I2C_done) ? ((shutdown) ? SHUTDOWN : IDLE) : state;
      WRITE_PTR : state <= (I2C_done) ? ((shutdown) ? SHUTDOWN : IDLE) : state;
      ONE_SHOT  : state <= (I2C_done) ? SHUTDOWN : state;
      CONFIG    : state <= (I2C_done) ? WRITE_PTR : state;
      WRITE_TMP : state <= (I2C_done) ? WRITE_PTR : state;
      SHUTDOWN  : begin 
        if(sw_rst) begin
          state <= SW_RST;
        end else if(~shutdown | ch_config) begin
          state <= CONFIG;
        end else if(write_temperature) begin
          state <= WRITE_TMP;
        end else if(one_shot) begin
          state <= ONE_SHOT;
        end else if(update) begin
          state <= UPDATE;
        end
      end
      IDLE      : begin 
        if(sw_rst) begin
          state <= SW_RST;
        end else if(shutdown | ch_config) begin
          state <= CONFIG;
        end else if(write_temperature) begin
          state <= WRITE_TMP;
        end else if(one_shot) begin
          state <= ONE_SHOT;
        end else if(update) begin
          state <= UPDATE;
        end
      end
    endcase
  end

  //I2C state transactions
  always@(negedge clkI2Cx2 or posedge rst) begin
      if(rst) begin
          I2C_state <= I2C_READY;
        end else case(I2C_state)
            I2C_READY     : I2C_state <= (~(inIdle | inShutdown) & SCLK & ~i2cBusy) ? I2C_START : I2C_state;
            I2C_START     : I2C_state <= (~SCL) ? I2C_ADDRS : I2C_state;
            I2C_ADDRS     : I2C_state <= (~SCL & bitCountDone) ? I2C_WRITE_ACK : I2C_state;
            I2C_WRITE_ACK : I2C_state <= (~SCL) ? ((~SDA_d_i2c & ~byteCountDone) ? ((~read_nwrite) ? I2C_WRITE : I2C_READ): I2C_STOP) : I2C_state;
            I2C_WRITE     : I2C_state <= (~SCL & bitCountDone) ? I2C_WRITE_ACK : I2C_state;
            I2C_READ      : I2C_state <= (~SCL & bitCountDone) ? I2C_READ_ACK : I2C_state;
            I2C_READ_ACK  : I2C_state <= (~SCL) ? ((byteCountDone) ? I2C_STOP : I2C_READ) : I2C_state;
            I2C_STOP      : I2C_state <= (SCL) ? I2C_READY : I2C_state;
          endcase
    end

  //Tri-state control for I2C lines
  assign SCL = (SCL_claim) ?    SCLK   : 1'bZ;
  assign SDA = (SDA_claim) ? SDA_write : 1'bZ;
  assign SCL_claim = ~I2CinReady;
  assign SDA_claim = I2CinStart | I2CinAddrs | I2CinWrite | I2CinReadAck | I2CinStop;
  assign SDA_write = (I2CinStart | I2CinReadAck | I2CinStop) ? (I2CinReadAck & byteCountDone) : send_buffer[7];

  //Buffer control
  assign send_upload = I2CinStart | I2CinWriteAck;
  assign send_shift = I2CinAddrs | I2CinWrite;
  always@(negedge clkI2Cx2) begin//Buffer
    if(send_upload)
      send_buffer <= send_buffer_write;
    else if(send_shift & ~SCL & |bitCounter)
      send_buffer <= {send_buffer << 1};
  end
  always@* begin //Buffer write
    case(byteCounter)
      2'd3: end_buffer_write = addressByte; //I2C address
      2'd0: //Register pointer
        case(state)
             SW_RST: send_buffer_write = SW_RESET;
             CONFIG: send_buffer_write = CONFIG_PTR;
           ONE_SHOT: send_buffer_write = CONFIG_PTR;
          WRITE_PTR: send_buffer_write = AMB_TEMP_PTR;
          WRITE_TMP: 
            case(write_temp_target)
               T_LOW: send_buffer_write = LOW_TEMP_PTR;
              T_HYST: send_buffer_write = HYS_TEMP_PTR;
              T_HIGH: send_buffer_write = HIGH_TEMP_PTR;
              T_CRIT: send_buffer_write = CRIT_TEMP_PTR;
            endcase
          default: send_buffer_write = 8'h0;
        endcase
      2'd1:
        case(state)
             CONFIG: send_buffer_write = configByte;
           ONE_SHOT: send_buffer_write = configByte;
          WRITE_TMP: send_buffer_write = (write_temp_target == T_HYST) ? temperature_i[7:0] : temperature_i[15:8];
            default: send_buffer_write = 8'h0;
        endcase
      2'd2: send_buffer_write = temperature_i[7:0];
    endcase
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

  //Listen I2C Bus & cond. gen.
  assign    SDA_negedge  = ~SDA &  SDA_d;
  assign    SDA_posedge  =  SDA & ~SDA_d;
  assign  stopCondition  =  SCL & SDA_posedge;
  assign startCondition  =  SCL & SDA_negedge;

  //bit counter
  assign bitCountDone = ~|bitCounter;
  always@(posedge SCL) begin
    if(I2CinAck|I2CinStart) begin
      bitCounter <= 3'd0;
    end else begin
      bitCounter <= bitCounter + {2'd0,(I2CinAddrs|I2CinWrite|I2CinRead)};
    end
  end
  
  //byte counter
  assign byteCountUp = ~I2CinAck_d & I2CinAck;
  always@(posedge clk) begin
    if(I2CinStart) begin
      byteCounter <= 2'b11;
    end else begin
      byteCounter <= byteCounter + {1'd0,byteCountUp};
    end
  end
  always@* begin
    case(state)
         SW_RST: byteCountDone = (byteCounter == 2'd1);
         UPDATE: byteCountDone = (byteCounter == 2'd2);
         CONFIG: byteCountDone = (byteCounter == 2'd2);
       ONE_SHOT: byteCountDone = (byteCounter == 2'd2);
      WRITE_PTR: byteCountDone = (byteCounter == 2'd1);
      WRITE_TMP: byteCountDone = (write_temp_target == T_HYST) ?(byteCounter == 2'd2) : (byteCounter == 2'd3);
        default:   byteCountDone = 1'b1;
    endcase
  end
  

  //Determine if an other master is using the bus
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      i2cBusy <= 1'b0;
    end else case(i2cBusy)
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
