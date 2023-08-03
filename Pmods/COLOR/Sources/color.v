/* ------------------------------------------------ *
 * Title       : Pmod COLOR interface v1            *
 * Project     : Pmod COLOR interface               *
 * ------------------------------------------------ *
 * File        : color.v                            *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 20/01/2021                         *
 * Licence     : CERN-OHL-W                         *
 * ------------------------------------------------ *
 * Description : Simple interface to communicate    *
 *               with Pmod COLOR                    *
 * ------------------------------------------------ *
 * Revisions                                        *
 *     v1      : Inital version                     *
 * ------------------------------------------------ */

module colorlite#(parameter CHIPADDRS = 7'h29)(
  input clk,
  input rst,
  input i2c_clk, //2x390.625kHz
  //I2C interface
  output SCL/* synthesis keep = 1 */,
  inout SDA/* synthesis keep = 1 */,
  output LEDenable,
  //Data interface
  input measure,
  input enable,
  input [1:0] gain,
  input reflectiveMode,
  output reg [15:0] red,
  output reg [15:0] green,
  output reg [15:0] blue,
  output ready);
  //Configuration registers
  localparam ENABLEregAddrs = 8'h80,
              ENABLEregCont = 8'b11, //AEN and PON enabled
               GAINregAddrs = 8'h8F,
               DATAregAddrs = 8'b10110110; //Address for RDATA with Auto-increment protocol transaction
  localparam SLEEP = 3'b000,
         SENDADDRS = 3'b001, 
             READY = 3'b011, 
            UPDATE = 3'b111,
            CHGAIN = 3'b101;
  reg [1:0] gain_reg;
  reg [2:0] state;
  wire inSLEEP, inREADY, inUPDATE, inCHGAIN, inSENDADDRS;
  wire updateGain, changeState;
  //Read bytes 
  localparam REDL = 3'd0,
             REDH = 3'd1,
           GREENL = 3'd2,
           GREENH = 3'd3,
            BLUEL = 3'd4,
            BLUEH = 3'd5;
  reg [2:0] dataCounter;
  reg [15:0] red_buff, green_buff, blue_buff;
  //I2C signals
  localparam i2cREADY = 3'b000,
             i2cSTART = 3'b001,
             i2cADDRS = 3'b011,
             i2cWRITE = 3'b110,
         i2cWRITE_ACK = 3'b010,
              i2cREAD = 3'b111,
          i2cREAD_ACK = 3'b101,
              i2cSTOP = 3'b100;
  reg [2:0] i2cState;
  reg [2:0] i2cBitCounter;
  wire i2cBitCounterDONE;
  wire I2CinREADY, I2CinSTART, I2CinADDRS, I2CinWRITE, I2CinWRITE_ACK, I2CinREAD, I2CinREAD_ACK, I2CinSTOP, I2CinACK;
  reg I2CinSTOP_d;
  reg I2CinACK_d;
  wire I2CinSTOP_posedge;
  wire i2c_clk; //Used to shifting and sampling
  reg i2c_clk_half; //Low: Shift High: Sample
  reg i2cGivingAddrs;
  wire i2c_enable;
  wire i2cWrite;
  wire SDA_Write;
  wire SDA_Claim;
  reg SDA_d;
  reg [7:0] I2Csend;
  reg [7:0] I2CsendBUFF, I2CrecBUFF;
  wire lastData;
  reg writeCount;

  assign LEDenable = reflectiveMode & (inREADY | inUPDATE | inSENDADDRS);
  assign changeState = updateGain | I2CinSTOP_posedge | (measure & inREADY);
  
  //State transactions
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      state <= SLEEP;
    end else if(changeState)
      case(state)
        SLEEP     : state <= (I2CinSTOP_posedge) ? SENDADDRS : CHGAIN;
        SENDADDRS : state <= READY;
        READY     : state <=  (measure) ? UPDATE : ((I2CinSTOP_posedge) ? SLEEP : CHGAIN);
        UPDATE    : state <= READY;
        CHGAIN    : state <= (enable) ? SENDADDRS : SLEEP;
      endcase
  end
  
  //Save buffers
  always@(posedge I2CinSTOP or posedge rst) begin
    if(rst) begin
      red <= 16'd0;
      green <= 16'd0;
      blue <= 16'd0;
    end else begin
      red <= (inUPDATE) ? red_buff : red;
      green <= (inUPDATE) ? green_buff : green;
      blue <= (inUPDATE) ? blue_buff : blue;
    end
  end
  

  //Decode states
  assign inSLEEP = (state == SLEEP);
  assign inREADY = (state == READY);
  assign inUPDATE = (state == UPDATE);
  assign inCHGAIN = (state == CHGAIN);
  assign inSENDADDRS = (state == SENDADDRS);
  assign updateGain = (gain != gain_reg);
  assign lastData = (~i2cWrite & (dataCounter == BLUEH)) | (i2cWrite & (((dataCounter == 3'd0) & inSENDADDRS) | (dataCounter == 3'd1)));
  assign ready = inREADY;
  //Store gain val
  always@(posedge inCHGAIN or posedge rst) begin
    if(rst) begin
      gain_reg <= 2'd0;
    end else begin
      gain_reg <= gain;
    end
  end
  
  //Handle data buffers
  always@(posedge I2CinREAD_ACK or posedge rst) begin
    if(rst) begin
      red_buff <= 16'd0;
      green_buff <= 16'd0;
      blue_buff <= 16'd0;
    end else case(dataCounter)
      REDL   :   red_buff[7:0]  <= I2CrecBUFF;
      REDH   :   red_buff[15:8] <= I2CrecBUFF;
      GREENL : green_buff[7:0]  <= I2CrecBUFF;
      GREENH : green_buff[15:8] <= I2CrecBUFF;
      BLUEL  :  blue_buff[7:0]  <= I2CrecBUFF;
      BLUEH  :  blue_buff[15:8] <= I2CrecBUFF;
    endcase
  end

  //Count read bytes
  always@(negedge I2CinACK or posedge I2CinSTART)
    begin
      I2CinACK_d <= I2CinACK;
      if(I2CinSTART)
        begin
          dataCounter <= 3'd0;
        end else begin
          dataCounter <= dataCounter + {2'd0, (~i2cGivingAddrs/* & I2CinACK & ~I2CinACK_d*/)};
        end
    end
  
  //Decode I2C states
  assign I2CinREADY = (i2cState == i2cREADY);
  assign I2CinSTART = (i2cState == i2cSTART);
  assign I2CinADDRS = (i2cState == i2cADDRS);
  assign I2CinWRITE = (i2cState == i2cWRITE);
  assign I2CinWRITE_ACK = (i2cState == i2cWRITE_ACK);
  assign I2CinREAD = (i2cState == i2cREAD);
  assign I2CinREAD_ACK = (i2cState == i2cREAD_ACK);
  assign I2CinSTOP = (i2cState == i2cSTOP);
  assign I2CinACK = I2CinREAD_ACK | I2CinWRITE_ACK;

  //I2C State transactions
  always@(negedge i2c_clk or posedge rst) begin
    if(rst) begin
      i2cState <= i2cREADY;
    end else case(i2cState)
      i2cREADY     : i2cState <= (i2c_enable & i2c_clk_half) ? i2cSTART : i2cState;
      i2cSTART     : i2cState <= (~SCL) ? i2cADDRS : i2cState;
      i2cADDRS     : i2cState <= (~SCL & i2cBitCounterDONE) ? i2cWRITE_ACK : i2cState;
      i2cWRITE_ACK : i2cState <= (~SCL) ? ((~SDA_d & (~lastData | i2cGivingAddrs)) ? ((i2cWrite) ? i2cWRITE : i2cREAD): i2cSTOP) : i2cState;
      i2cWRITE     : i2cState <= (~SCL & i2cBitCounterDONE) ? i2cWRITE_ACK : i2cState;
      i2cREAD      : i2cState <= (~SCL & i2cBitCounterDONE) ? i2cREAD_ACK : i2cState;
      i2cREAD_ACK  : i2cState <= (~SCL) ? ((~lastData) ? i2cREAD : i2cSTOP) : i2cState;
      i2cSTOP      : i2cState <=  (SCL) ? i2cREADY : i2cState;
    endcase
  end
  always@(posedge clk) begin
    I2CinSTOP_d <= I2CinSTOP;
  end
  assign I2CinSTOP_posedge = ~I2CinSTOP_d & I2CinSTOP;

  //I2Csend
  always@*
    case(state)
      SLEEP     : I2Csend = (writeCount) ? ENABLEregAddrs : ENABLEregCont;
      READY     : I2Csend = (writeCount) ? ENABLEregAddrs : 8'b0;
      SENDADDRS : I2Csend = DATAregAddrs;
      CHGAIN    : I2Csend = (writeCount) ? GAINregAddrs : {6'b0, gain};
      default   : I2Csend = 8'hff;
    endcase

  //I2C control signals and data routing
  assign SCL = (I2CinREADY) ? 1'b1 : i2c_clk_half;
  assign SDA = (SDA_Claim) ? SDA_Write : 1'bZ;
  assign SDA_Claim = I2CinSTART | I2CinADDRS | I2CinWRITE | I2CinREAD_ACK | I2CinSTOP;
  assign SDA_Write = (I2CinREAD_ACK | I2CinSTART | I2CinSTOP) ? (I2CinREAD_ACK & lastData) : I2CsendBUFF[7];
  assign i2cWrite = ~inUPDATE;
  assign i2c_enable = inUPDATE | inCHGAIN | inSENDADDRS | (~enable & inREADY) | (enable & inSLEEP);
  //i2cGivingAddrs
  always@(posedge clk)
    case(i2cState)
      i2cSTART : i2cGivingAddrs <= 1'b1;
      i2cWRITE : i2cGivingAddrs <= 1'b0;
      i2cREAD  : i2cGivingAddrs <= 1'b0;
      default  : i2cGivingAddrs <= i2cGivingAddrs;
    endcase

  //Handle data in buffer
  always@(negedge i2c_clk) begin
    case(i2cState)
      i2cSTART: //At start load address and op
        I2CsendBUFF <= {CHIPADDRS, ~i2cWrite};
      i2cADDRS: //During address shift
        I2CsendBUFF <= (SCL) ? I2CsendBUFF : (I2CsendBUFF << 1);
      i2cWRITE_ACK: //Load new data during ack
        I2CsendBUFF <= I2Csend;
      i2cWRITE: //During write shift
         I2CsendBUFF <= (SCL) ? I2CsendBUFF : (I2CsendBUFF << 1);
      default: I2CsendBUFF <= I2CsendBUFF;
    endcase
  end

  //writeCount
  always@(posedge I2CinWRITE or posedge I2CinADDRS) begin
    if(I2CinADDRS) begin
      writeCount <= 1'd1;
    end else begin
      writeCount <= 1'd0;
    end
  end
  
  //Handle data out buffer
  always@(posedge i2c_clk) begin
    I2CrecBUFF <= (SCL & I2CinREAD) ? {I2CrecBUFF[6:0], SDA} : I2CrecBUFF;
  end
  //I2C bit Counter
  assign i2cBitCounterDONE = ~|i2cBitCounter;
  always@(negedge i2c_clk_half) begin
    case(i2cState)
      i2cADDRS: i2cBitCounter <= i2cBitCounter + 3'd1;
      i2cWRITE: i2cBitCounter <= i2cBitCounter + 3'd1;
      i2cREAD: i2cBitCounter <= i2cBitCounter + 3'd1;
      default: i2cBitCounter <= 3'd0;
    endcase
  end
  always@(negedge i2c_clk) begin
    SDA_d <= SDA;
  end
  //Divide i2c_clk
  always@(posedge i2c_clk or posedge rst) begin
    if(rst) begin
      i2c_clk_half <= 1;
    end else begin
      i2c_clk_half <= ~i2c_clk_half;
    end
  end
endmodule//color

//output freq: 2x390.625kHz
//Following module will generate correct frequency only for 100 MHz clk_i
module clockGen_i2c(
  input clk,
  input rst,
  output i2c_clk);

  reg [6:0] clk_d;

  assign i2c_clk = clk_d[6];

  //50MHz
  always@(posedge clk or posedge rst)  begin
    if(rst) begin
      clk_d[0] <= 0;
    end else begin
      clk_d[0] <= ~clk_d[0];
    end
  end
  //25MHz
  always@(posedge clk_d[0] or posedge rst)  begin
    if(rst) begin
      clk_d[1] <= 0;
    end else begin
      clk_d[1] <= ~clk_d[1];
    end
  end
  //12.5MHz
  always@(posedge clk_d[1] or posedge rst)  begin
    if(rst) begin
      clk_d[2] <= 0;
    end else begin
      clk_d[2] <= ~clk_d[2];
    end
  end
  //6.25MHz
  always@(posedge clk_d[2] or posedge rst)  begin
    if(rst) begin
      clk_d[3] <= 0;
    end else begin
      clk_d[3] <= ~clk_d[3];
    end
  end
  //3.125MHz
  always@(posedge clk_d[3] or posedge rst)  begin
    if(rst) begin
      clk_d[4] <= 0;
    end else begin
      clk_d[4] <= ~clk_d[4];
    end
  end
  //1.562MHz
  always@(posedge clk_d[4] or posedge rst)  begin
    if(rst) begin
      clk_d[5] <= 0;
    end else begin
      clk_d[5] <= ~clk_d[5];
    end
  end
  //781.25kHz
  always@(posedge clk_d[5] or posedge rst)  begin
    if(rst) begin
      clk_d[6] <= 0;
    end else begin
      clk_d[6] <= ~clk_d[6];
    end
  end
endmodule
