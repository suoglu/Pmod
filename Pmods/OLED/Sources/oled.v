/* ------------------------------------------------ *
 * Title       : Pmod OLED interface v2.0           *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : oled.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 17/06/2021                         *
 * Licence     : CERN-OHL-W                         *
 * ------------------------------------------------ *
 * Description : Simple interface to communicate    *
 *               with Pmod OLED                     *
 * ------------------------------------------------ */

//*+++++++++++++++++++++++++++++++++++++++++++++++*//
//* Pmod OLED driver which uses codes for content *//
//*+++++++++++++++++++++++++++++++++++++++++++++++*//
module oled#(parameter CLK_PERIOD = 10/*Needed for waits*/)(
  input clk,
  input rst,
  input ext_spi_clk,
  //Connection to decoder
  output [7:0] character_code,
  input [63:0] current_bitmap,
  //Module connections
  output CS,
  output MOSI,
  output SCK,
  output data_command_cntr, //high data, low command
  output power_rst,
  output vbat_c, //low to turn on
  output vdd_c, //low to turn on
  //Interface
  input power_on,
  input display_reset,
  input display_off,
  input update,
  input [511:0] display_data, 
  /* MSB(display_data[511:504]): left-up most 
            decreases as left to right
     LSB(display_data[7:0]): right bottum most) */
  input [1:0] line_count,
  input [7:0] contrast,
  input cursor_enable,
  input cursor_flash,
  input [5:0] cursor_pos);
  //Commands, not all of them
  localparam     CMD_NOP = 8'hE3,
           CMD_PRE_CHR_P = 8'hD9,
          CMD_COM_CONFIG = 8'hDA,
          CMD_DISPLAY_ON = 8'hAF,
         CMD_DISPLAY_OFF = 8'hAE,
       CMD_CHRG_PMP_CONF = 8'h8D,
       CMD_SET_MUX_RATIO = 8'hA8,
       CMD_SET_CONSTRAST = 8'h81,
      CMD_SET_ADDRS_MODE = 8'h20,
      CMD_SET_CLMN_ADDRS = 8'h21,
      CMD_SET_PAGE_ADDRS = 8'h22, //Set to 0-7
      CMD_SCAN_DIR_NORML = 8'hC0,
      CMD_SCAN_DIR_INVRT = 8'hC8,
      CMD_SEG_INV_ENABLE = 8'hA1,
     CMD_SEG_INV_DISABLE = 8'hA0,
     CMD_SET_HIGH_CLMN_0 = 8'h10,
     CMD_ACTIVATE_SCROLL = 8'h2F,
   CMD_DEACTIVATE_SCROLL = 8'h2E;
  localparam CONFIG_PRE_CHR_P = 8'hF1,
            CONFIG_COM_CONFIG = 8'h22,
         CONFIG_CHRG_PMP_CONF = 8'h14;
  //Addressing modes, used with CMD_SET_ADDRS_MODE
  localparam ADDRS_MODE_HOR = 2'b00, //This mode is used here
             ADDRS_MODE_VER = 2'b01, 
             ADDRS_MODE_PAG = 2'b10;
  //States
  localparam IDLE = 4'h0, //Ready display on #9
           UPDATE = 4'h2, //Update display content #8-9b
            RESET = 4'hC, //100ms wait in reset #2
        POWER_OFF = 4'hF, //This is inital state, where the display is not powered #0
       PONS_DELAY = 4'hE, //VDD on, VBAT off #1
       POST_RESET = 4'hD, //1ms wait after reset #3
       CH_DISPLAY = 4'h6, //Turn on/off display
      CH_CONTRAST = 4'h3, //Change contrast #8-9a
      WRITE_ADDRS = 4'h4,
      DISPLAY_OFF = 4'h1, //ready but display off #8
      POFFS_DELAY = 4'h7, //VDD on, VBAT off #10
     PONS_DIS_OFF = 4'hB, //send display off #4
    PONS_DIS_WAIT = 4'hA, //2ms wait before crg pump #5
    PONS_INIT_DIS = 4'h8, //init configs #6
   PONS_INIT_WAIT = 4'h9; //100ms wait after init #7
  reg [3:0] state, state_d;
  wire inIdle, inUpdate, inReset, inPowerOff, inPOnSDelay, inChContrast, inDisplayOff, inPOffDelay, inPOnSDisOff, inPOnSDisWait, inPOnSInitDis, inPostReset, inChDisplay, inPOnSInitWait, inWriteAddrs;
  wire inDelayState, inSPIState;
  //Mapping for display_data
  reg [7:0] display_array[0:63];
  reg [5:0] data_index;
  //Generate SPI clk
  reg spi_clk;
  //Clk domain change for inputs
  reg display_reset_reg, update_reg;
  //Counter for data
  reg [2:0] bit_counter;
  reg bit_counter_done;
  reg [8:0] byte_counter; //Count send data/command
  reg last_byte;
  wire [1:0] current_line; //rename byte counter for data access
  wire [3:0] position_in_line; //rename byte counter for data access
  //Intermediate signals
  wire [7:0] current_colmn, current_colmn_pre;
  //Transmisson control singals
  reg spi_done;
  reg spi_working;
  reg [7:0] send_buffer;
  reg [7:0] send_buffer_next;
  wire send_buffer_write;
  wire send_buffer_shift;
  //Cursor control
  wire cursor_update, cursor_flash_on;
  reg cursor_in_pos;
  localparam CURSOR_FLASH_PERIOD = 500_000_000 / CLK_PERIOD;
  localparam CURSOR_COUNTER_SIZE = $clog2(CURSOR_FLASH_PERIOD-1);
  reg [CURSOR_COUNTER_SIZE:0] cursor_counter;
  reg [5:0] cursor_pos_reg;
  reg cursor_flash_mode, cursor_enable_reg;
  //Delays
  reg inChContrast_d;
  wire inChContrast_posedge;
  //Registers for power pins
  reg vdd_reg, vbat_reg;
  //Counter for waits
  localparam DELAY_4us =       4_000 / CLK_PERIOD,
             DELAY_1ms =   1_000_000 / CLK_PERIOD,
             DELAY_2ms =   2_000_000 / CLK_PERIOD,
           DELAY_100ms = 100_000_000 / CLK_PERIOD;
  localparam LONGEST_DELAY = DELAY_100ms;
  localparam COUNTER_SIZE = $clog2(LONGEST_DELAY-1);
  reg [COUNTER_SIZE:0] delay_counter;
  reg delay_done;
  reg delay_count_done;
  wire delaying;
  //Save status
  reg [7:0] contrast_reg;
  reg display_off_reg;
  wire ch_contrast;

  //Module connections
  assign power_rst = ~inReset;
  assign MOSI = send_buffer[7];
  assign data_command_cntr = inUpdate; //Only high during data write
  assign CS = ~spi_working;
  assign SCK = (spi_working) ? spi_clk : 1'b1;
  assign vdd_c = vdd_reg;
  assign vbat_c = vbat_reg;

  //Use registers for stable power control
  always@(posedge ext_spi_clk)
    begin
      vdd_reg <= inPowerOff;
      vbat_reg <= inPowerOff | inPOnSDelay | inPOffDelay;
    end  

  //State decoding
  assign         inIdle = (state == IDLE);
  assign        inReset = (state == RESET);
  assign       inUpdate = (state == UPDATE);
  assign     inPowerOff = (state == POWER_OFF);
  assign    inChDisplay = (state == CH_DISPLAY);
  assign    inPOnSDelay = (state == PONS_DELAY);
  assign    inPostReset = (state == POST_RESET);
  assign    inPOffDelay = (state == POFFS_DELAY);
  assign   inWriteAddrs = (state == WRITE_ADDRS);
  assign   inChContrast = (state == CH_CONTRAST);
  assign   inDisplayOff = (state == DISPLAY_OFF);
  assign   inPOnSDisOff = (state == PONS_DIS_OFF);
  assign  inPOnSDisWait = (state == PONS_DIS_WAIT);
  assign  inPOnSInitDis = (state == PONS_INIT_DIS);
  assign inPOnSInitWait = (state == PONS_INIT_WAIT);
  assign   inDelayState = inReset | inPOnSDelay | inPOffDelay | inPOnSDisWait | inPOnSInitWait | inPostReset;
  assign     inSPIState = inUpdate | inChContrast | inPOnSDisOff | inPOnSInitDis | inChDisplay | inWriteAddrs;

  //SPI flags
  always@(negedge ext_spi_clk or posedge rst) begin
    if(rst) begin
      spi_done <= 1'b0;
    end else case(spi_done)
      1'b0: spi_done <= spi_working & last_byte & bit_counter_done;
      1'b1: spi_done <= 1'b0;
    endcase
  end
  always@(negedge ext_spi_clk or posedge rst) begin
    if(rst) begin
      spi_working <= 1'b0;
    end else case(spi_working)
      1'b0: spi_working <= ~spi_done & inSPIState & spi_clk;
      1'b1: spi_working <= ~spi_done;
    endcase
  end

  //State transactions
  always@(posedge spi_clk or posedge rst) begin
    if(rst) begin
      state <= POWER_OFF;
    end else case(state)
      POWER_OFF      : state <= (power_on) ? PONS_DELAY : state;
      PONS_DELAY     : state <= (delay_done) ? RESET : state;
      RESET          : state <= (delay_done) ?  POST_RESET : state;
      POST_RESET     : state <= (delay_done) ?  PONS_DIS_OFF : state;
      PONS_DIS_OFF   : state <= (spi_done) ? PONS_DIS_WAIT : state;
      PONS_DIS_WAIT  : state <= (delay_done) ? PONS_INIT_DIS : state;
      PONS_INIT_DIS  : state <= (spi_done) ? PONS_INIT_WAIT : state;
      PONS_INIT_WAIT : state <= (delay_done) ? DISPLAY_OFF : state;
      CH_DISPLAY     : state <= (spi_done) ? ((~power_on | display_off_reg) ? DISPLAY_OFF : IDLE): state;
      CH_CONTRAST    : state <= (spi_done) ? ((display_off_reg) ? DISPLAY_OFF : IDLE): state;
      UPDATE         : state <= (spi_done) ? ((display_off_reg) ? DISPLAY_OFF : IDLE): state;
      POFFS_DELAY    : state <= (delay_done) ?  POWER_OFF : state;
      WRITE_ADDRS    : state <= (spi_done) ?  UPDATE : state;
      IDLE: begin
        if(display_reset_reg) begin
          state <= RESET;
        end else if(~power_on | display_off) begin
          state <= CH_DISPLAY;
        end else if(ch_contrast) begin
          state <= CH_CONTRAST;
        end else if(update_reg | cursor_update) begin
          state <= WRITE_ADDRS;
        end
      end
      DISPLAY_OFF: begin
        if(display_reset_reg) begin
          state <= RESET;
        end else if(~power_on) begin
          state <= POFFS_DELAY;
        end else if(~display_off) begin
          state <= CH_DISPLAY;
        end else if(ch_contrast) begin
          state <= CH_CONTRAST;
        end else if(update_reg) begin
          state <= WRITE_ADDRS;
        end
      end
    endcase
  end
  
  //Clk domain change for inputs
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      display_reset_reg <= 1'b0;
      update_reg <= 1'b0;
    end else begin
      case(update_reg)
        1'b0: update_reg <= update;
        1'b1: update_reg <= ~inUpdate;
      endcase
      case(display_reset_reg)
        1'b0: display_reset_reg <= display_reset;
        1'b1: display_reset_reg <= ~inReset;
      endcase
    end
  end

  //Send buffer control
  assign send_buffer_shift = ~send_buffer_write;
  assign send_buffer_write = ~|bit_counter;

  //Determine send_buffer_next
  always@* begin
    case(state)
      WRITE_ADDRS:
        case(byte_counter)
          //Set colmn limits
          9'h00:  send_buffer_next = CMD_SET_CLMN_ADDRS;
          9'h01:  send_buffer_next = 8'd0;
          9'h02:  send_buffer_next = 8'd127;
          //Set page limits
          9'h03:  send_buffer_next = CMD_SET_PAGE_ADDRS;
          9'h04:  send_buffer_next = 8'd0;
          9'h05:  send_buffer_next = 8'd3;
          9'h06:  send_buffer_next = CMD_SET_HIGH_CLMN_0;
          default: send_buffer_next = CMD_NOP;
        endcase
      PONS_INIT_DIS:
        case(byte_counter)
          //Charge pump enable 
          9'h00:  send_buffer_next = CMD_CHRG_PMP_CONF;
          9'h01:  send_buffer_next = CONFIG_CHRG_PMP_CONF;
          //Set pre-charge period 
          9'h02:  send_buffer_next = CMD_PRE_CHR_P;
          9'h03:  send_buffer_next = CONFIG_PRE_CHR_P;
          //Column inversion enable 
          9'h04:  send_buffer_next = CMD_SEG_INV_ENABLE;
          //COM Output Scan Direction
          9'h05:  send_buffer_next = CMD_SCAN_DIR_INVRT;
          //COM pins configuration 
          9'h06:  send_buffer_next = CMD_COM_CONFIG;
          9'h07:  send_buffer_next = CONFIG_COM_CONFIG;
          //Set addressing mode
          9'h08:  send_buffer_next = CMD_SET_ADDRS_MODE;
          9'h09:  send_buffer_next = {6'h0,ADDRS_MODE_HOR};
          default: send_buffer_next = CMD_NOP;
        endcase
      PONS_DIS_OFF: send_buffer_next = CMD_DISPLAY_OFF;
      CH_CONTRAST:
        case(byte_counter)
          9'h0: send_buffer_next = CMD_SET_CONSTRAST;
          9'h1: send_buffer_next = contrast_reg;
          default: send_buffer_next = CMD_NOP;
        endcase
      CH_DISPLAY: send_buffer_next = (display_off_reg) ? CMD_DISPLAY_OFF : CMD_DISPLAY_ON;
      UPDATE:
        case(line_count)
          2'd3: //4 lines
            begin
              send_buffer_next = current_colmn;
            end
          2'd2: //3 lines
            case(current_line)
              2'd2: send_buffer_next = {4'h0,current_colmn[7:4]};
              2'd1: send_buffer_next = {current_colmn[3:0],4'h0};
              default: send_buffer_next = current_colmn;
            endcase
          2'd1: //2 lines
            case(current_line[0])
              1'b1: send_buffer_next = {4'h0,current_colmn[7:4]};
              1'b0: send_buffer_next = {current_colmn[3:0],4'h0};
            endcase
          2'd0: //1 line
            case(current_line)
              2'd2: send_buffer_next = {4'h0,current_colmn[7:4]};
              2'd1: send_buffer_next = {current_colmn[3:0],4'h0};
              default: send_buffer_next = 8'h00;
            endcase
        endcase
      default: send_buffer_next = CMD_NOP;
    endcase
  end

  always@(negedge spi_clk) begin
    if(send_buffer_write) begin
      send_buffer <= send_buffer_next;
    end else begin
      send_buffer <= (send_buffer_shift) ? {send_buffer[6:0],send_buffer[0]} : send_buffer;
    end
  end

  //Byte counter
  assign {current_line, position_in_line} = byte_counter[8:3];
  always@(negedge ext_spi_clk) begin
    if(~spi_working) begin
      byte_counter <= 9'h0;
    end else begin
      byte_counter <= byte_counter + {8'h0, (~last_byte & bit_counter_done & spi_clk)};
    end
  end
  
  //last byte
  always@*
    case(state)
      UPDATE: last_byte = &byte_counter;
      CH_CONTRAST: last_byte = (byte_counter == 9'h1);
      WRITE_ADDRS: last_byte = (byte_counter == 9'h6);
      PONS_INIT_DIS: last_byte = (byte_counter == 9'h9);
      default: last_byte = 1'b1;
    endcase

  //Bit counter
  always@* bit_counter_done = &bit_counter;
  
  always@(negedge ext_spi_clk or posedge rst) begin
    if(rst) begin
      bit_counter <= 3'd0;
    end else begin
      bit_counter <= bit_counter + {2'd0, spi_working & spi_clk};
    end
  end

  //Delay Signals and edge detect
  assign inChContrast_posedge = ~inChContrast_d & inChContrast;
  always@(posedge clk) begin
    inChContrast_d <= inChContrast;
    state_d <= state;
  end
  
  //Store Signals & Configs
  always@(posedge clk) begin
    if(rst | inReset) begin
        contrast_reg <= 8'h7F;
    end else begin
        contrast_reg <= (inChContrast_posedge) ? contrast : contrast_reg;
    end
  end
  always@(posedge clk) begin
    display_off_reg <= (inIdle | inPowerOff | inDisplayOff) ? display_off : display_off_reg;
  end
  
  //Determine data index
  always@*
    case(line_count)
      2'd3: data_index = {current_line,position_in_line};
      2'd2:
        case(current_line)
          2'd3: data_index = {2'd2,position_in_line};
          2'd0: data_index = {2'd0,position_in_line};
          default: data_index = {2'd1,position_in_line};
        endcase
      2'd1: data_index = {1'b0, current_line[1],position_in_line};
      2'd0: data_index = {2'd0,position_in_line};
    endcase

  //Change flags
  assign ch_contrast = (contrast_reg != contrast);

  //Generate spi clock
  always@(posedge ext_spi_clk or posedge rst) begin
    if(rst) begin
      spi_clk <= 1'b1;
    end else begin
      spi_clk <= ~spi_clk;
    end
  end
  
  //Delay wait
  assign delaying = ~delay_done & inDelayState;
  always@*
    case(state)
               RESET: delay_count_done = (delay_counter == DELAY_4us);
          POST_RESET: delay_count_done = (delay_counter == DELAY_1ms);
          PONS_DELAY: delay_count_done = (delay_counter == DELAY_100ms);
         POFFS_DELAY: delay_count_done = (delay_counter == DELAY_100ms);
       PONS_DIS_WAIT: delay_count_done = (delay_counter == DELAY_2ms);
      PONS_INIT_WAIT: delay_count_done = (delay_counter == DELAY_100ms);
      default: delay_count_done = 1'b1;
    endcase
  
  always@(posedge clk) begin
    if(delay_done | rst) begin
      delay_counter <= {COUNTER_SIZE+1{1'b0}};
    end else begin
      delay_counter <= delay_counter + {{COUNTER_SIZE{1'b0}},delaying};
    end
  end
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      delay_done <= 1'b0;
    end else case(delay_done)
      1'b0: delay_done <= delay_count_done;
      1'b1: delay_done <= (state_d == state); //Delay done when we change state
    endcase
  end

  //Cursor control
  assign current_colmn = (cursor_enable & cursor_flash_on & cursor_in_pos) ?  ~current_colmn_pre :  current_colmn_pre; //Default cursor inverts char, thus implemented by inverting column. For more advenced cursorsors current_bitmap can be edited
  always@*
    case(line_count)
      2'd3: //4 lines
         cursor_in_pos = (cursor_pos_reg == {current_line,position_in_line});
      2'd2: //3 lines
        case(current_line)
          2'd0: cursor_in_pos = (cursor_pos_reg == {2'd0,position_in_line});
          2'd3: cursor_in_pos = (cursor_pos_reg == {2'd2,position_in_line});
          default: cursor_in_pos = (cursor_pos_reg == {2'b1,position_in_line});
        endcase
      2'd1: //2 lines
        cursor_in_pos = (cursor_pos_reg[3:0] == position_in_line) & (current_line[1] == cursor_pos_reg[4]);
      2'd0: //1 line
         cursor_in_pos = (cursor_pos_reg[3:0] == position_in_line);
    endcase

  assign cursor_flash_on = ~cursor_flash | cursor_counter[CURSOR_COUNTER_SIZE];

  always@(posedge clk or posedge rst) begin //Store cursor configs  
    if(rst) begin
      cursor_pos_reg <= 6'd0;
      cursor_flash_mode  <= 1'd0;
      cursor_enable_reg  <= 1'd0;
    end else begin
      cursor_pos_reg <= (cursor_update & inUpdate) ? cursor_pos : cursor_pos_reg;
      cursor_flash_mode <= (cursor_update & inUpdate) ? cursor_counter[CURSOR_COUNTER_SIZE] : cursor_flash_mode;
      cursor_enable_reg <= (cursor_update & inUpdate) ? cursor_enable : cursor_enable_reg;
    end
  end

  always@(posedge clk or posedge rst) begin //Cursor counter
    if(rst) begin
      cursor_counter <= {(CURSOR_COUNTER_SIZE+1){1'b0}}; 
    end else begin
      cursor_counter <= cursor_counter + {{CURSOR_COUNTER_SIZE{1'b0}},(cursor_enable & cursor_flash)}; 
    end
  end

  assign cursor_update = (cursor_pos != cursor_pos_reg) | (cursor_enable != cursor_enable_reg) | (cursor_flash_mode != cursor_counter[CURSOR_COUNTER_SIZE]); 

  //Helper modules for decoding
  assign character_code = display_array[data_index];
  bitmap_column column_extractor(current_bitmap,byte_counter[2:0],current_colmn_pre);

  //Map display_data into display_array
  always@* //Inside of this always generated automatically
    begin
      display_array[0]  = display_data[511:504];
      display_array[1]  = display_data[503:496];
      display_array[2]  = display_data[495:488];
      display_array[3]  = display_data[487:480];
      display_array[4]  = display_data[479:472];
      display_array[5]  = display_data[471:464];
      display_array[6]  = display_data[463:456];
      display_array[7]  = display_data[455:448];
      display_array[8]  = display_data[447:440];
      display_array[9]  = display_data[439:432];
      display_array[10] = display_data[431:424];
      display_array[11] = display_data[423:416];
      display_array[12] = display_data[415:408];
      display_array[13] = display_data[407:400];
      display_array[14] = display_data[399:392];
      display_array[15] = display_data[391:384];
      display_array[16] = display_data[383:376];
      display_array[17] = display_data[375:368];
      display_array[18] = display_data[367:360];
      display_array[19] = display_data[359:352];
      display_array[20] = display_data[351:344];
      display_array[21] = display_data[343:336];
      display_array[22] = display_data[335:328];
      display_array[23] = display_data[327:320];
      display_array[24] = display_data[319:312];
      display_array[25] = display_data[311:304];
      display_array[26] = display_data[303:296];
      display_array[27] = display_data[295:288];
      display_array[28] = display_data[287:280];
      display_array[29] = display_data[279:272];
      display_array[30] = display_data[271:264];
      display_array[31] = display_data[263:256];
      display_array[32] = display_data[255:248];
      display_array[33] = display_data[247:240];
      display_array[34] = display_data[239:232];
      display_array[35] = display_data[231:224];
      display_array[36] = display_data[223:216];
      display_array[37] = display_data[215:208];
      display_array[38] = display_data[207:200];
      display_array[39] = display_data[199:192];
      display_array[40] = display_data[191:184];
      display_array[41] = display_data[183:176];
      display_array[42] = display_data[175:168];
      display_array[43] = display_data[167:160];
      display_array[44] = display_data[159:152];
      display_array[45] = display_data[151:144];
      display_array[46] = display_data[143:136];
      display_array[47] = display_data[135:128];
      display_array[48] = display_data[127:120];
      display_array[49] = display_data[119:112];
      display_array[50] = display_data[111:104];
      display_array[51] = display_data[103:96];
      display_array[52] = display_data[95:88];
      display_array[53] = display_data[87:80];
      display_array[54] = display_data[79:72];
      display_array[55] = display_data[71:64];
      display_array[56] = display_data[63:56];
      display_array[57] = display_data[55:48];
      display_array[58] = display_data[47:40];
      display_array[59] = display_data[39:32];
      display_array[60] = display_data[31:24];
      display_array[61] = display_data[23:16];
      display_array[62] = display_data[15:8];
      display_array[63] = display_data[7:0];
    end
endmodule

//*+++++++++++++++++++++++++++++++++++++++++++++++*//
//* Pmod OLED driver which uses a 128 x 32 bitmap *//
//*+++++++++++++++++++++++++++++++++++++++++++++++*//
module oled_bitmap#(parameter CLK_PERIOD = 10)(
  input clk,
  input rst,
  input ext_spi_clk,
  //Module connections
  output CS,
  output MOSI,
  output SCK,
  output data_command_cntr,
  output power_rst,
  output vbat_c,
  output vdd_c,
  //Interface
  input power_on,
  input display_reset,
  input display_off,
  input [7:0] contrast,
  input update,
  /*
   * bitmap pixel addresses
   *  | 4095 | 4094 | ... | 3968 |
   *  | 3967 | ...           :   |
   *  |  :                | 128  |
   *  | 127  | ...  |  1  |  0   |
   */
  input [4095:0] bitmap);
  //Commands, not all of them
  localparam     CMD_NOP = 8'hE3,
           CMD_PRE_CHR_P = 8'hD9,
          CMD_COM_CONFIG = 8'hDA,
          CMD_DISPLAY_ON = 8'hAF,
         CMD_DISPLAY_OFF = 8'hAE,
       CMD_CHRG_PMP_CONF = 8'h8D,
       CMD_SET_MUX_RATIO = 8'hA8,
       CMD_SET_CONSTRAST = 8'h81,
      CMD_SET_ADDRS_MODE = 8'h20,
      CMD_SET_CLMN_ADDRS = 8'h21,
      CMD_SET_PAGE_ADDRS = 8'h22, //Set to 0-7
      CMD_SCAN_DIR_NORML = 8'hC0,
      CMD_SCAN_DIR_INVRT = 8'hC8,
      CMD_SEG_INV_ENABLE = 8'hA1,
     CMD_SEG_INV_DISABLE = 8'hA0,
     CMD_SET_HIGH_CLMN_0 = 8'h10,
     CMD_ACTIVATE_SCROLL = 8'h2F,
   CMD_DEACTIVATE_SCROLL = 8'h2E;
  localparam CONFIG_PRE_CHR_P = 8'hF1,
            CONFIG_COM_CONFIG = 8'h22,
         CONFIG_CHRG_PMP_CONF = 8'h14;
  //Addressing modes, used with CMD_SET_ADDRS_MODE
  localparam ADDRS_MODE_HOR = 2'b00, //This mode is used here
             ADDRS_MODE_VER = 2'b01, 
             ADDRS_MODE_PAG = 2'b10;
  //States
  localparam IDLE = 4'h0, //Ready display on #9
           UPDATE = 4'h2, //Update display content #8-9b
            RESET = 4'hC, //100ms wait in reset #2
        POWER_OFF = 4'hF, //This is inital state, where the display is not powered #0
       PONS_DELAY = 4'hE, //VDD on, VBAT off #1
       POST_RESET = 4'hD, //1ms wait after reset #3
       CH_DISPLAY = 4'h6, //Turn on/off display
      CH_CONTRAST = 4'h3, //Change contrast #8-9a
      WRITE_ADDRS = 4'h4,
      DISPLAY_OFF = 4'h1, //ready but display off #8
      POFFS_DELAY = 4'h7, //VDD on, VBAT off #10
     PONS_DIS_OFF = 4'hB, //send display off #4
    PONS_DIS_WAIT = 4'hA, //2ms wait before crg pump #5
    PONS_INIT_DIS = 4'h8, //init configs #6
   PONS_INIT_WAIT = 4'h9; //100ms wait after init #7
  reg [3:0] state, state_d;
  wire inIdle, inUpdate, inReset, inPowerOff, inPOnSDelay, inChContrast, inDisplayOff, inPOffDelay, inPOnSDisOff, inPOnSDisWait, inPOnSInitDis, inPostReset, inChDisplay, inPOnSInitWait, inWriteAddrs;
  wire inDelayState, inSPIState;
  //Generate SPI clk
  reg spi_clk;
  //Clk domain change for inputs
  reg display_reset_reg, update_reg;
  //Counter for data
  reg [2:0] bit_counter;
  reg bit_counter_done;
  reg [8:0] byte_counter; //Count send data/command
  reg last_byte;
  wire [1:0] current_line; //rename byte counter for data access
  wire [3:0] position_in_line; //rename byte counter for data access
  //Transmisson control singals
  reg spi_done;
  reg spi_working;
  reg [7:0] send_buffer;
  reg [7:0] send_buffer_next;
  wire send_buffer_write;
  wire send_buffer_shift;
  //Delays
  reg inChContrast_d;
  wire inChContrast_posedge;
  //Registers for power pins
  reg vdd_reg, vbat_reg;
  //Counter for waits
  localparam DELAY_4us =       4_000 / CLK_PERIOD,
             DELAY_1ms =   1_000_000 / CLK_PERIOD,
             DELAY_2ms =   2_000_000 / CLK_PERIOD,
           DELAY_100ms = 100_000_000 / CLK_PERIOD;
  localparam LONGEST_DELAY = DELAY_100ms;
  localparam COUNTER_SIZE = $clog2(LONGEST_DELAY-1);
  reg [COUNTER_SIZE:0] delay_counter;
  reg delay_done;
  reg delay_count_done;
  wire delaying;
  //Save status
  reg [7:0] contrast_reg;
  reg display_off_reg;
  wire ch_contrast;
  //Bitmap remap
  reg [7:0] column_array[0:511];

  //Module connections
  assign power_rst = ~inReset;
  assign MOSI = send_buffer[7];
  assign data_command_cntr = inUpdate; //Only high during data write
  assign CS = ~spi_working;
  assign SCK = (spi_working) ? spi_clk : 1'b1;
  assign vdd_c = vdd_reg;
  assign vbat_c = vbat_reg;

  //Use registers for stable power control
  always@(posedge ext_spi_clk) begin
    vdd_reg <= inPowerOff;
    vbat_reg <= inPowerOff | inPOnSDelay | inPOffDelay;
  end
  
  //State decoding
  assign         inIdle = (state == IDLE);
  assign        inReset = (state == RESET);
  assign       inUpdate = (state == UPDATE);
  assign     inPowerOff = (state == POWER_OFF);
  assign    inChDisplay = (state == CH_DISPLAY);
  assign    inPOnSDelay = (state == PONS_DELAY);
  assign    inPostReset = (state == POST_RESET);
  assign    inPOffDelay = (state == POFFS_DELAY);
  assign   inWriteAddrs = (state == WRITE_ADDRS);
  assign   inChContrast = (state == CH_CONTRAST);
  assign   inDisplayOff = (state == DISPLAY_OFF);
  assign   inPOnSDisOff = (state == PONS_DIS_OFF);
  assign  inPOnSDisWait = (state == PONS_DIS_WAIT);
  assign  inPOnSInitDis = (state == PONS_INIT_DIS);
  assign inPOnSInitWait = (state == PONS_INIT_WAIT);
  assign   inDelayState = inReset | inPOnSDelay | inPOffDelay | inPOnSDisWait | inPOnSInitWait | inPostReset;
  assign     inSPIState = inUpdate | inChContrast | inPOnSDisOff | inPOnSInitDis | inChDisplay | inWriteAddrs;

  //SPI flags
  always@(negedge ext_spi_clk or posedge rst) begin
    if(rst) begin
      spi_done <= 1'b0;
    end else case(spi_done)
      1'b0: spi_done <= spi_working & last_byte & bit_counter_done;
      1'b1: spi_done <= 1'b0;
    endcase
  end

  always@(negedge ext_spi_clk or posedge rst) begin
    if(rst) begin
      spi_working <= 1'b0;
    end else case(spi_working)
      1'b0: spi_working <= ~spi_done & inSPIState & spi_clk;
      1'b1: spi_working <= ~spi_done;
    endcase
  end

  //State transactions
  always@(posedge spi_clk or posedge rst) begin
    if(rst) begin
      state <= POWER_OFF;
    end else case(state)
      POWER_OFF      : state <= (power_on) ? PONS_DELAY : state;
      PONS_DELAY     : state <= (delay_done) ? RESET : state;
      RESET          : state <= (delay_done) ?  POST_RESET : state;
      POST_RESET     : state <= (delay_done) ?  PONS_DIS_OFF : state;
      PONS_DIS_OFF   : state <= (spi_done) ? PONS_DIS_WAIT : state;
      PONS_DIS_WAIT  : state <= (delay_done) ? PONS_INIT_DIS : state;
      PONS_INIT_DIS  : state <= (spi_done) ? PONS_INIT_WAIT : state;
      PONS_INIT_WAIT : state <= (delay_done) ? DISPLAY_OFF : state;
      CH_DISPLAY     : state <= (spi_done) ? ((~power_on | display_off_reg) ? DISPLAY_OFF : IDLE): state;
      CH_CONTRAST    : state <= (spi_done) ? ((display_off_reg) ? DISPLAY_OFF : IDLE): state;
      UPDATE         : state <= (spi_done) ? ((display_off_reg) ? DISPLAY_OFF : IDLE): state;
      POFFS_DELAY    : state <= (delay_done) ?  POWER_OFF : state;
      WRITE_ADDRS    : state <= (spi_done) ?  UPDATE : state;
      IDLE: begin
        if(display_reset_reg) begin
          state <= RESET;
        end else if(~power_on | display_off) begin
          state <= CH_DISPLAY;
        end else if(ch_contrast) begin
          state <= CH_CONTRAST;
        end else if(update_reg) begin
          state <= WRITE_ADDRS;
        end
      end
      DISPLAY_OFF: begin
        if(display_reset_reg) begin
          state <= RESET;
        end else if(~power_on) begin
          state <= POFFS_DELAY;
        end else if(~display_off) begin
          state <= CH_DISPLAY;
        end else if(ch_contrast) begin
          state <= CH_CONTRAST;
        end else if(update_reg) begin
          state <= WRITE_ADDRS;
        end
      end
    endcase
  end
  
  //Clk domain change for inputs
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      display_reset_reg <= 1'b0;
      update_reg <= 1'b0;
    end else begin
      case(update_reg)
        1'b0: update_reg <= update;
        1'b1: update_reg <= ~inUpdate;
      endcase
      case(display_reset_reg)
        1'b0: display_reset_reg <= display_reset;
        1'b1: display_reset_reg <= ~inReset;
      endcase
    end
  end

  //Send buffer control
  assign send_buffer_shift = ~send_buffer_write;
  assign send_buffer_write = ~|bit_counter;

  //Determine send_buffer_next
  always@*
    case(state)
      WRITE_ADDRS:
        case(byte_counter)
          //Set colmn limits
          9'h00:  send_buffer_next = CMD_SET_CLMN_ADDRS;
          9'h01:  send_buffer_next = 8'd0;
          9'h02:  send_buffer_next = 8'd127;
          //Set page limits
          9'h03:  send_buffer_next = CMD_SET_PAGE_ADDRS;
          9'h04:  send_buffer_next = 8'd0;
          9'h05:  send_buffer_next = 8'd3;
          9'h06:  send_buffer_next = CMD_SET_HIGH_CLMN_0;
          default: send_buffer_next = CMD_NOP;
        endcase
      PONS_INIT_DIS:
        case(byte_counter)
          //Charge pump enable 
          9'h00:  send_buffer_next = CMD_CHRG_PMP_CONF;
          9'h01:  send_buffer_next = CONFIG_CHRG_PMP_CONF;
          //Set pre-charge period 
          9'h02:  send_buffer_next = CMD_PRE_CHR_P;
          9'h03:  send_buffer_next = CONFIG_PRE_CHR_P;
          //Column inversion enable 
          9'h04:  send_buffer_next = CMD_SEG_INV_ENABLE;
          //COM Output Scan Direction
          9'h05:  send_buffer_next = CMD_SCAN_DIR_INVRT;
          //COM pins configuration 
          9'h06:  send_buffer_next = CMD_COM_CONFIG;
          9'h07:  send_buffer_next = CONFIG_COM_CONFIG;
          //Set addressing mode
          9'h08:  send_buffer_next = CMD_SET_ADDRS_MODE;
          9'h09:  send_buffer_next = {6'h0,ADDRS_MODE_HOR};
          default: send_buffer_next = CMD_NOP;
        endcase
      PONS_DIS_OFF: send_buffer_next = CMD_DISPLAY_OFF;
      CH_CONTRAST:
        case(byte_counter)
          9'h0: send_buffer_next = CMD_SET_CONSTRAST;
          9'h1: send_buffer_next = contrast_reg;
          default: send_buffer_next = CMD_NOP;
        endcase
      CH_DISPLAY: 
        send_buffer_next = (display_off_reg) ? CMD_DISPLAY_OFF : CMD_DISPLAY_ON;
      UPDATE:
        send_buffer_next = column_array[byte_counter];
      default: send_buffer_next = CMD_NOP;
    endcase
  
  always@(negedge spi_clk) begin
    if(send_buffer_write) begin
      send_buffer <= send_buffer_next;
    end else begin
      send_buffer <= (send_buffer_shift) ? {send_buffer[6:0],send_buffer[0]} : send_buffer;
    end
  end

  //Byte counter
  assign {current_line, position_in_line} = byte_counter[8:3];
  always@(negedge ext_spi_clk) begin
    if(~spi_working) begin
      byte_counter <= 9'h0;
    end else begin
      byte_counter <= byte_counter + {8'h0, (~last_byte & bit_counter_done & spi_clk)};
    end
  end
  
  //last byte
  always@*
    case(state)
      UPDATE: last_byte = &byte_counter;
      CH_CONTRAST: last_byte = (byte_counter == 9'h1);
      WRITE_ADDRS: last_byte = (byte_counter == 9'h6);
      PONS_INIT_DIS: last_byte = (byte_counter == 9'h9);
      default: last_byte = 1'b1;
    endcase

  //Bit counter
  always@* bit_counter_done = &bit_counter;
  
  always@(negedge ext_spi_clk or posedge rst) begin
    if(rst) begin
      bit_counter <= 3'd0;
    end else begin
      bit_counter <= bit_counter + {2'd0, spi_working & spi_clk};
    end
  end

  //Delay Signals and edge detect
  assign inChContrast_posedge = ~inChContrast_d & inChContrast;
  always@(posedge clk) begin
    inChContrast_d <= inChContrast;
    state_d <= state;
  end
  
  //Store Signals & Configs
  always@(posedge clk) begin
    if(rst | inReset) begin
        contrast_reg <= 8'h7F;
    end else begin
        contrast_reg <= (inChContrast_posedge) ? contrast : contrast_reg;
    end
  end
  always@(posedge clk) begin
    display_off_reg <= (inIdle | inPowerOff | inDisplayOff) ? display_off : display_off_reg;
  end

  //Change flags
  assign ch_contrast = (contrast_reg != contrast);

  //Generate spi clock
  always@(posedge ext_spi_clk or posedge rst) begin
    if(rst) begin
      spi_clk <= 1'b1;
    end else begin
      spi_clk <= ~spi_clk;
    end
  end
  
  //Delay wait
  assign delaying = ~delay_done & inDelayState;
  always@*
    case(state)
               RESET: delay_count_done = (delay_counter == DELAY_4us);
          POST_RESET: delay_count_done = (delay_counter == DELAY_1ms);
          PONS_DELAY: delay_count_done = (delay_counter == DELAY_100ms);
         POFFS_DELAY: delay_count_done = (delay_counter == DELAY_100ms);
       PONS_DIS_WAIT: delay_count_done = (delay_counter == DELAY_2ms);
      PONS_INIT_WAIT: delay_count_done = (delay_counter == DELAY_100ms);
      default: delay_count_done = 1'b1;
    endcase
  
  always@(posedge clk) begin
    if(delay_done | rst) begin
      delay_counter <= {COUNTER_SIZE+1{1'b0}};
    end else begin
      delay_counter <= delay_counter + {{COUNTER_SIZE{1'b0}},delaying};
    end
  end
  always@(posedge clk or posedge rst) begin
    if(rst) begin
      delay_done <= 1'b0;
    end else begin
      case(delay_done)
        1'b0: delay_done <= delay_count_done;
        1'b1: delay_done <= (state_d == state); //Delay done when we change state
      endcase
    end
  end

  //Map bitmap into column_array
  always@* //Inside of this always generated automatically
    begin
      column_array[0] = {bitmap[4095], bitmap[3967], bitmap[3839], bitmap[3711], bitmap[3583], bitmap[3455], bitmap[3327], bitmap[3199]};
      column_array[1] = {bitmap[4094], bitmap[3966], bitmap[3838], bitmap[3710], bitmap[3582], bitmap[3454], bitmap[3326], bitmap[3198]};
      column_array[2] = {bitmap[4093], bitmap[3965], bitmap[3837], bitmap[3709], bitmap[3581], bitmap[3453], bitmap[3325], bitmap[3197]};
      column_array[3] = {bitmap[4092], bitmap[3964], bitmap[3836], bitmap[3708], bitmap[3580], bitmap[3452], bitmap[3324], bitmap[3196]};
      column_array[4] = {bitmap[4091], bitmap[3963], bitmap[3835], bitmap[3707], bitmap[3579], bitmap[3451], bitmap[3323], bitmap[3195]};
      column_array[5] = {bitmap[4090], bitmap[3962], bitmap[3834], bitmap[3706], bitmap[3578], bitmap[3450], bitmap[3322], bitmap[3194]};
      column_array[6] = {bitmap[4089], bitmap[3961], bitmap[3833], bitmap[3705], bitmap[3577], bitmap[3449], bitmap[3321], bitmap[3193]};
      column_array[7] = {bitmap[4088], bitmap[3960], bitmap[3832], bitmap[3704], bitmap[3576], bitmap[3448], bitmap[3320], bitmap[3192]};
      column_array[8] = {bitmap[4087], bitmap[3959], bitmap[3831], bitmap[3703], bitmap[3575], bitmap[3447], bitmap[3319], bitmap[3191]};
      column_array[9] = {bitmap[4086], bitmap[3958], bitmap[3830], bitmap[3702], bitmap[3574], bitmap[3446], bitmap[3318], bitmap[3190]};
      column_array[10] = {bitmap[4085], bitmap[3957], bitmap[3829], bitmap[3701], bitmap[3573], bitmap[3445], bitmap[3317], bitmap[3189]};
      column_array[11] = {bitmap[4084], bitmap[3956], bitmap[3828], bitmap[3700], bitmap[3572], bitmap[3444], bitmap[3316], bitmap[3188]};
      column_array[12] = {bitmap[4083], bitmap[3955], bitmap[3827], bitmap[3699], bitmap[3571], bitmap[3443], bitmap[3315], bitmap[3187]};
      column_array[13] = {bitmap[4082], bitmap[3954], bitmap[3826], bitmap[3698], bitmap[3570], bitmap[3442], bitmap[3314], bitmap[3186]};
      column_array[14] = {bitmap[4081], bitmap[3953], bitmap[3825], bitmap[3697], bitmap[3569], bitmap[3441], bitmap[3313], bitmap[3185]};
      column_array[15] = {bitmap[4080], bitmap[3952], bitmap[3824], bitmap[3696], bitmap[3568], bitmap[3440], bitmap[3312], bitmap[3184]};
      column_array[16] = {bitmap[4079], bitmap[3951], bitmap[3823], bitmap[3695], bitmap[3567], bitmap[3439], bitmap[3311], bitmap[3183]};
      column_array[17] = {bitmap[4078], bitmap[3950], bitmap[3822], bitmap[3694], bitmap[3566], bitmap[3438], bitmap[3310], bitmap[3182]};
      column_array[18] = {bitmap[4077], bitmap[3949], bitmap[3821], bitmap[3693], bitmap[3565], bitmap[3437], bitmap[3309], bitmap[3181]};
      column_array[19] = {bitmap[4076], bitmap[3948], bitmap[3820], bitmap[3692], bitmap[3564], bitmap[3436], bitmap[3308], bitmap[3180]};
      column_array[20] = {bitmap[4075], bitmap[3947], bitmap[3819], bitmap[3691], bitmap[3563], bitmap[3435], bitmap[3307], bitmap[3179]};
      column_array[21] = {bitmap[4074], bitmap[3946], bitmap[3818], bitmap[3690], bitmap[3562], bitmap[3434], bitmap[3306], bitmap[3178]};
      column_array[22] = {bitmap[4073], bitmap[3945], bitmap[3817], bitmap[3689], bitmap[3561], bitmap[3433], bitmap[3305], bitmap[3177]};
      column_array[23] = {bitmap[4072], bitmap[3944], bitmap[3816], bitmap[3688], bitmap[3560], bitmap[3432], bitmap[3304], bitmap[3176]};
      column_array[24] = {bitmap[4071], bitmap[3943], bitmap[3815], bitmap[3687], bitmap[3559], bitmap[3431], bitmap[3303], bitmap[3175]};
      column_array[25] = {bitmap[4070], bitmap[3942], bitmap[3814], bitmap[3686], bitmap[3558], bitmap[3430], bitmap[3302], bitmap[3174]};
      column_array[26] = {bitmap[4069], bitmap[3941], bitmap[3813], bitmap[3685], bitmap[3557], bitmap[3429], bitmap[3301], bitmap[3173]};
      column_array[27] = {bitmap[4068], bitmap[3940], bitmap[3812], bitmap[3684], bitmap[3556], bitmap[3428], bitmap[3300], bitmap[3172]};
      column_array[28] = {bitmap[4067], bitmap[3939], bitmap[3811], bitmap[3683], bitmap[3555], bitmap[3427], bitmap[3299], bitmap[3171]};
      column_array[29] = {bitmap[4066], bitmap[3938], bitmap[3810], bitmap[3682], bitmap[3554], bitmap[3426], bitmap[3298], bitmap[3170]};
      column_array[30] = {bitmap[4065], bitmap[3937], bitmap[3809], bitmap[3681], bitmap[3553], bitmap[3425], bitmap[3297], bitmap[3169]};
      column_array[31] = {bitmap[4064], bitmap[3936], bitmap[3808], bitmap[3680], bitmap[3552], bitmap[3424], bitmap[3296], bitmap[3168]};
      column_array[32] = {bitmap[4063], bitmap[3935], bitmap[3807], bitmap[3679], bitmap[3551], bitmap[3423], bitmap[3295], bitmap[3167]};
      column_array[33] = {bitmap[4062], bitmap[3934], bitmap[3806], bitmap[3678], bitmap[3550], bitmap[3422], bitmap[3294], bitmap[3166]};
      column_array[34] = {bitmap[4061], bitmap[3933], bitmap[3805], bitmap[3677], bitmap[3549], bitmap[3421], bitmap[3293], bitmap[3165]};
      column_array[35] = {bitmap[4060], bitmap[3932], bitmap[3804], bitmap[3676], bitmap[3548], bitmap[3420], bitmap[3292], bitmap[3164]};
      column_array[36] = {bitmap[4059], bitmap[3931], bitmap[3803], bitmap[3675], bitmap[3547], bitmap[3419], bitmap[3291], bitmap[3163]};
      column_array[37] = {bitmap[4058], bitmap[3930], bitmap[3802], bitmap[3674], bitmap[3546], bitmap[3418], bitmap[3290], bitmap[3162]};
      column_array[38] = {bitmap[4057], bitmap[3929], bitmap[3801], bitmap[3673], bitmap[3545], bitmap[3417], bitmap[3289], bitmap[3161]};
      column_array[39] = {bitmap[4056], bitmap[3928], bitmap[3800], bitmap[3672], bitmap[3544], bitmap[3416], bitmap[3288], bitmap[3160]};
      column_array[40] = {bitmap[4055], bitmap[3927], bitmap[3799], bitmap[3671], bitmap[3543], bitmap[3415], bitmap[3287], bitmap[3159]};
      column_array[41] = {bitmap[4054], bitmap[3926], bitmap[3798], bitmap[3670], bitmap[3542], bitmap[3414], bitmap[3286], bitmap[3158]};
      column_array[42] = {bitmap[4053], bitmap[3925], bitmap[3797], bitmap[3669], bitmap[3541], bitmap[3413], bitmap[3285], bitmap[3157]};
      column_array[43] = {bitmap[4052], bitmap[3924], bitmap[3796], bitmap[3668], bitmap[3540], bitmap[3412], bitmap[3284], bitmap[3156]};
      column_array[44] = {bitmap[4051], bitmap[3923], bitmap[3795], bitmap[3667], bitmap[3539], bitmap[3411], bitmap[3283], bitmap[3155]};
      column_array[45] = {bitmap[4050], bitmap[3922], bitmap[3794], bitmap[3666], bitmap[3538], bitmap[3410], bitmap[3282], bitmap[3154]};
      column_array[46] = {bitmap[4049], bitmap[3921], bitmap[3793], bitmap[3665], bitmap[3537], bitmap[3409], bitmap[3281], bitmap[3153]};
      column_array[47] = {bitmap[4048], bitmap[3920], bitmap[3792], bitmap[3664], bitmap[3536], bitmap[3408], bitmap[3280], bitmap[3152]};
      column_array[48] = {bitmap[4047], bitmap[3919], bitmap[3791], bitmap[3663], bitmap[3535], bitmap[3407], bitmap[3279], bitmap[3151]};
      column_array[49] = {bitmap[4046], bitmap[3918], bitmap[3790], bitmap[3662], bitmap[3534], bitmap[3406], bitmap[3278], bitmap[3150]};
      column_array[50] = {bitmap[4045], bitmap[3917], bitmap[3789], bitmap[3661], bitmap[3533], bitmap[3405], bitmap[3277], bitmap[3149]};
      column_array[51] = {bitmap[4044], bitmap[3916], bitmap[3788], bitmap[3660], bitmap[3532], bitmap[3404], bitmap[3276], bitmap[3148]};
      column_array[52] = {bitmap[4043], bitmap[3915], bitmap[3787], bitmap[3659], bitmap[3531], bitmap[3403], bitmap[3275], bitmap[3147]};
      column_array[53] = {bitmap[4042], bitmap[3914], bitmap[3786], bitmap[3658], bitmap[3530], bitmap[3402], bitmap[3274], bitmap[3146]};
      column_array[54] = {bitmap[4041], bitmap[3913], bitmap[3785], bitmap[3657], bitmap[3529], bitmap[3401], bitmap[3273], bitmap[3145]};
      column_array[55] = {bitmap[4040], bitmap[3912], bitmap[3784], bitmap[3656], bitmap[3528], bitmap[3400], bitmap[3272], bitmap[3144]};
      column_array[56] = {bitmap[4039], bitmap[3911], bitmap[3783], bitmap[3655], bitmap[3527], bitmap[3399], bitmap[3271], bitmap[3143]};
      column_array[57] = {bitmap[4038], bitmap[3910], bitmap[3782], bitmap[3654], bitmap[3526], bitmap[3398], bitmap[3270], bitmap[3142]};
      column_array[58] = {bitmap[4037], bitmap[3909], bitmap[3781], bitmap[3653], bitmap[3525], bitmap[3397], bitmap[3269], bitmap[3141]};
      column_array[59] = {bitmap[4036], bitmap[3908], bitmap[3780], bitmap[3652], bitmap[3524], bitmap[3396], bitmap[3268], bitmap[3140]};
      column_array[60] = {bitmap[4035], bitmap[3907], bitmap[3779], bitmap[3651], bitmap[3523], bitmap[3395], bitmap[3267], bitmap[3139]};
      column_array[61] = {bitmap[4034], bitmap[3906], bitmap[3778], bitmap[3650], bitmap[3522], bitmap[3394], bitmap[3266], bitmap[3138]};
      column_array[62] = {bitmap[4033], bitmap[3905], bitmap[3777], bitmap[3649], bitmap[3521], bitmap[3393], bitmap[3265], bitmap[3137]};
      column_array[63] = {bitmap[4032], bitmap[3904], bitmap[3776], bitmap[3648], bitmap[3520], bitmap[3392], bitmap[3264], bitmap[3136]};
      column_array[64] = {bitmap[4031], bitmap[3903], bitmap[3775], bitmap[3647], bitmap[3519], bitmap[3391], bitmap[3263], bitmap[3135]};
      column_array[65] = {bitmap[4030], bitmap[3902], bitmap[3774], bitmap[3646], bitmap[3518], bitmap[3390], bitmap[3262], bitmap[3134]};
      column_array[66] = {bitmap[4029], bitmap[3901], bitmap[3773], bitmap[3645], bitmap[3517], bitmap[3389], bitmap[3261], bitmap[3133]};
      column_array[67] = {bitmap[4028], bitmap[3900], bitmap[3772], bitmap[3644], bitmap[3516], bitmap[3388], bitmap[3260], bitmap[3132]};
      column_array[68] = {bitmap[4027], bitmap[3899], bitmap[3771], bitmap[3643], bitmap[3515], bitmap[3387], bitmap[3259], bitmap[3131]};
      column_array[69] = {bitmap[4026], bitmap[3898], bitmap[3770], bitmap[3642], bitmap[3514], bitmap[3386], bitmap[3258], bitmap[3130]};
      column_array[70] = {bitmap[4025], bitmap[3897], bitmap[3769], bitmap[3641], bitmap[3513], bitmap[3385], bitmap[3257], bitmap[3129]};
      column_array[71] = {bitmap[4024], bitmap[3896], bitmap[3768], bitmap[3640], bitmap[3512], bitmap[3384], bitmap[3256], bitmap[3128]};
      column_array[72] = {bitmap[4023], bitmap[3895], bitmap[3767], bitmap[3639], bitmap[3511], bitmap[3383], bitmap[3255], bitmap[3127]};
      column_array[73] = {bitmap[4022], bitmap[3894], bitmap[3766], bitmap[3638], bitmap[3510], bitmap[3382], bitmap[3254], bitmap[3126]};
      column_array[74] = {bitmap[4021], bitmap[3893], bitmap[3765], bitmap[3637], bitmap[3509], bitmap[3381], bitmap[3253], bitmap[3125]};
      column_array[75] = {bitmap[4020], bitmap[3892], bitmap[3764], bitmap[3636], bitmap[3508], bitmap[3380], bitmap[3252], bitmap[3124]};
      column_array[76] = {bitmap[4019], bitmap[3891], bitmap[3763], bitmap[3635], bitmap[3507], bitmap[3379], bitmap[3251], bitmap[3123]};
      column_array[77] = {bitmap[4018], bitmap[3890], bitmap[3762], bitmap[3634], bitmap[3506], bitmap[3378], bitmap[3250], bitmap[3122]};
      column_array[78] = {bitmap[4017], bitmap[3889], bitmap[3761], bitmap[3633], bitmap[3505], bitmap[3377], bitmap[3249], bitmap[3121]};
      column_array[79] = {bitmap[4016], bitmap[3888], bitmap[3760], bitmap[3632], bitmap[3504], bitmap[3376], bitmap[3248], bitmap[3120]};
      column_array[80] = {bitmap[4015], bitmap[3887], bitmap[3759], bitmap[3631], bitmap[3503], bitmap[3375], bitmap[3247], bitmap[3119]};
      column_array[81] = {bitmap[4014], bitmap[3886], bitmap[3758], bitmap[3630], bitmap[3502], bitmap[3374], bitmap[3246], bitmap[3118]};
      column_array[82] = {bitmap[4013], bitmap[3885], bitmap[3757], bitmap[3629], bitmap[3501], bitmap[3373], bitmap[3245], bitmap[3117]};
      column_array[83] = {bitmap[4012], bitmap[3884], bitmap[3756], bitmap[3628], bitmap[3500], bitmap[3372], bitmap[3244], bitmap[3116]};
      column_array[84] = {bitmap[4011], bitmap[3883], bitmap[3755], bitmap[3627], bitmap[3499], bitmap[3371], bitmap[3243], bitmap[3115]};
      column_array[85] = {bitmap[4010], bitmap[3882], bitmap[3754], bitmap[3626], bitmap[3498], bitmap[3370], bitmap[3242], bitmap[3114]};
      column_array[86] = {bitmap[4009], bitmap[3881], bitmap[3753], bitmap[3625], bitmap[3497], bitmap[3369], bitmap[3241], bitmap[3113]};
      column_array[87] = {bitmap[4008], bitmap[3880], bitmap[3752], bitmap[3624], bitmap[3496], bitmap[3368], bitmap[3240], bitmap[3112]};
      column_array[88] = {bitmap[4007], bitmap[3879], bitmap[3751], bitmap[3623], bitmap[3495], bitmap[3367], bitmap[3239], bitmap[3111]};
      column_array[89] = {bitmap[4006], bitmap[3878], bitmap[3750], bitmap[3622], bitmap[3494], bitmap[3366], bitmap[3238], bitmap[3110]};
      column_array[90] = {bitmap[4005], bitmap[3877], bitmap[3749], bitmap[3621], bitmap[3493], bitmap[3365], bitmap[3237], bitmap[3109]};
      column_array[91] = {bitmap[4004], bitmap[3876], bitmap[3748], bitmap[3620], bitmap[3492], bitmap[3364], bitmap[3236], bitmap[3108]};
      column_array[92] = {bitmap[4003], bitmap[3875], bitmap[3747], bitmap[3619], bitmap[3491], bitmap[3363], bitmap[3235], bitmap[3107]};
      column_array[93] = {bitmap[4002], bitmap[3874], bitmap[3746], bitmap[3618], bitmap[3490], bitmap[3362], bitmap[3234], bitmap[3106]};
      column_array[94] = {bitmap[4001], bitmap[3873], bitmap[3745], bitmap[3617], bitmap[3489], bitmap[3361], bitmap[3233], bitmap[3105]};
      column_array[95] = {bitmap[4000], bitmap[3872], bitmap[3744], bitmap[3616], bitmap[3488], bitmap[3360], bitmap[3232], bitmap[3104]};
      column_array[96] = {bitmap[3999], bitmap[3871], bitmap[3743], bitmap[3615], bitmap[3487], bitmap[3359], bitmap[3231], bitmap[3103]};
      column_array[97] = {bitmap[3998], bitmap[3870], bitmap[3742], bitmap[3614], bitmap[3486], bitmap[3358], bitmap[3230], bitmap[3102]};
      column_array[98] = {bitmap[3997], bitmap[3869], bitmap[3741], bitmap[3613], bitmap[3485], bitmap[3357], bitmap[3229], bitmap[3101]};
      column_array[99] = {bitmap[3996], bitmap[3868], bitmap[3740], bitmap[3612], bitmap[3484], bitmap[3356], bitmap[3228], bitmap[3100]};
      column_array[100] = {bitmap[3995], bitmap[3867], bitmap[3739], bitmap[3611], bitmap[3483], bitmap[3355], bitmap[3227], bitmap[3099]};
      column_array[101] = {bitmap[3994], bitmap[3866], bitmap[3738], bitmap[3610], bitmap[3482], bitmap[3354], bitmap[3226], bitmap[3098]};
      column_array[102] = {bitmap[3993], bitmap[3865], bitmap[3737], bitmap[3609], bitmap[3481], bitmap[3353], bitmap[3225], bitmap[3097]};
      column_array[103] = {bitmap[3992], bitmap[3864], bitmap[3736], bitmap[3608], bitmap[3480], bitmap[3352], bitmap[3224], bitmap[3096]};
      column_array[104] = {bitmap[3991], bitmap[3863], bitmap[3735], bitmap[3607], bitmap[3479], bitmap[3351], bitmap[3223], bitmap[3095]};
      column_array[105] = {bitmap[3990], bitmap[3862], bitmap[3734], bitmap[3606], bitmap[3478], bitmap[3350], bitmap[3222], bitmap[3094]};
      column_array[106] = {bitmap[3989], bitmap[3861], bitmap[3733], bitmap[3605], bitmap[3477], bitmap[3349], bitmap[3221], bitmap[3093]};
      column_array[107] = {bitmap[3988], bitmap[3860], bitmap[3732], bitmap[3604], bitmap[3476], bitmap[3348], bitmap[3220], bitmap[3092]};
      column_array[108] = {bitmap[3987], bitmap[3859], bitmap[3731], bitmap[3603], bitmap[3475], bitmap[3347], bitmap[3219], bitmap[3091]};
      column_array[109] = {bitmap[3986], bitmap[3858], bitmap[3730], bitmap[3602], bitmap[3474], bitmap[3346], bitmap[3218], bitmap[3090]};
      column_array[110] = {bitmap[3985], bitmap[3857], bitmap[3729], bitmap[3601], bitmap[3473], bitmap[3345], bitmap[3217], bitmap[3089]};
      column_array[111] = {bitmap[3984], bitmap[3856], bitmap[3728], bitmap[3600], bitmap[3472], bitmap[3344], bitmap[3216], bitmap[3088]};
      column_array[112] = {bitmap[3983], bitmap[3855], bitmap[3727], bitmap[3599], bitmap[3471], bitmap[3343], bitmap[3215], bitmap[3087]};
      column_array[113] = {bitmap[3982], bitmap[3854], bitmap[3726], bitmap[3598], bitmap[3470], bitmap[3342], bitmap[3214], bitmap[3086]};
      column_array[114] = {bitmap[3981], bitmap[3853], bitmap[3725], bitmap[3597], bitmap[3469], bitmap[3341], bitmap[3213], bitmap[3085]};
      column_array[115] = {bitmap[3980], bitmap[3852], bitmap[3724], bitmap[3596], bitmap[3468], bitmap[3340], bitmap[3212], bitmap[3084]};
      column_array[116] = {bitmap[3979], bitmap[3851], bitmap[3723], bitmap[3595], bitmap[3467], bitmap[3339], bitmap[3211], bitmap[3083]};
      column_array[117] = {bitmap[3978], bitmap[3850], bitmap[3722], bitmap[3594], bitmap[3466], bitmap[3338], bitmap[3210], bitmap[3082]};
      column_array[118] = {bitmap[3977], bitmap[3849], bitmap[3721], bitmap[3593], bitmap[3465], bitmap[3337], bitmap[3209], bitmap[3081]};
      column_array[119] = {bitmap[3976], bitmap[3848], bitmap[3720], bitmap[3592], bitmap[3464], bitmap[3336], bitmap[3208], bitmap[3080]};
      column_array[120] = {bitmap[3975], bitmap[3847], bitmap[3719], bitmap[3591], bitmap[3463], bitmap[3335], bitmap[3207], bitmap[3079]};
      column_array[121] = {bitmap[3974], bitmap[3846], bitmap[3718], bitmap[3590], bitmap[3462], bitmap[3334], bitmap[3206], bitmap[3078]};
      column_array[122] = {bitmap[3973], bitmap[3845], bitmap[3717], bitmap[3589], bitmap[3461], bitmap[3333], bitmap[3205], bitmap[3077]};
      column_array[123] = {bitmap[3972], bitmap[3844], bitmap[3716], bitmap[3588], bitmap[3460], bitmap[3332], bitmap[3204], bitmap[3076]};
      column_array[124] = {bitmap[3971], bitmap[3843], bitmap[3715], bitmap[3587], bitmap[3459], bitmap[3331], bitmap[3203], bitmap[3075]};
      column_array[125] = {bitmap[3970], bitmap[3842], bitmap[3714], bitmap[3586], bitmap[3458], bitmap[3330], bitmap[3202], bitmap[3074]};
      column_array[126] = {bitmap[3969], bitmap[3841], bitmap[3713], bitmap[3585], bitmap[3457], bitmap[3329], bitmap[3201], bitmap[3073]};
      column_array[127] = {bitmap[3968], bitmap[3840], bitmap[3712], bitmap[3584], bitmap[3456], bitmap[3328], bitmap[3200], bitmap[3072]};
      column_array[128] = {bitmap[3071], bitmap[2943], bitmap[2815], bitmap[2687], bitmap[2559], bitmap[2431], bitmap[2303], bitmap[2175]};
      column_array[129] = {bitmap[3070], bitmap[2942], bitmap[2814], bitmap[2686], bitmap[2558], bitmap[2430], bitmap[2302], bitmap[2174]};
      column_array[130] = {bitmap[3069], bitmap[2941], bitmap[2813], bitmap[2685], bitmap[2557], bitmap[2429], bitmap[2301], bitmap[2173]};
      column_array[131] = {bitmap[3068], bitmap[2940], bitmap[2812], bitmap[2684], bitmap[2556], bitmap[2428], bitmap[2300], bitmap[2172]};
      column_array[132] = {bitmap[3067], bitmap[2939], bitmap[2811], bitmap[2683], bitmap[2555], bitmap[2427], bitmap[2299], bitmap[2171]};
      column_array[133] = {bitmap[3066], bitmap[2938], bitmap[2810], bitmap[2682], bitmap[2554], bitmap[2426], bitmap[2298], bitmap[2170]};
      column_array[134] = {bitmap[3065], bitmap[2937], bitmap[2809], bitmap[2681], bitmap[2553], bitmap[2425], bitmap[2297], bitmap[2169]};
      column_array[135] = {bitmap[3064], bitmap[2936], bitmap[2808], bitmap[2680], bitmap[2552], bitmap[2424], bitmap[2296], bitmap[2168]};
      column_array[136] = {bitmap[3063], bitmap[2935], bitmap[2807], bitmap[2679], bitmap[2551], bitmap[2423], bitmap[2295], bitmap[2167]};
      column_array[137] = {bitmap[3062], bitmap[2934], bitmap[2806], bitmap[2678], bitmap[2550], bitmap[2422], bitmap[2294], bitmap[2166]};
      column_array[138] = {bitmap[3061], bitmap[2933], bitmap[2805], bitmap[2677], bitmap[2549], bitmap[2421], bitmap[2293], bitmap[2165]};
      column_array[139] = {bitmap[3060], bitmap[2932], bitmap[2804], bitmap[2676], bitmap[2548], bitmap[2420], bitmap[2292], bitmap[2164]};
      column_array[140] = {bitmap[3059], bitmap[2931], bitmap[2803], bitmap[2675], bitmap[2547], bitmap[2419], bitmap[2291], bitmap[2163]};
      column_array[141] = {bitmap[3058], bitmap[2930], bitmap[2802], bitmap[2674], bitmap[2546], bitmap[2418], bitmap[2290], bitmap[2162]};
      column_array[142] = {bitmap[3057], bitmap[2929], bitmap[2801], bitmap[2673], bitmap[2545], bitmap[2417], bitmap[2289], bitmap[2161]};
      column_array[143] = {bitmap[3056], bitmap[2928], bitmap[2800], bitmap[2672], bitmap[2544], bitmap[2416], bitmap[2288], bitmap[2160]};
      column_array[144] = {bitmap[3055], bitmap[2927], bitmap[2799], bitmap[2671], bitmap[2543], bitmap[2415], bitmap[2287], bitmap[2159]};
      column_array[145] = {bitmap[3054], bitmap[2926], bitmap[2798], bitmap[2670], bitmap[2542], bitmap[2414], bitmap[2286], bitmap[2158]};
      column_array[146] = {bitmap[3053], bitmap[2925], bitmap[2797], bitmap[2669], bitmap[2541], bitmap[2413], bitmap[2285], bitmap[2157]};
      column_array[147] = {bitmap[3052], bitmap[2924], bitmap[2796], bitmap[2668], bitmap[2540], bitmap[2412], bitmap[2284], bitmap[2156]};
      column_array[148] = {bitmap[3051], bitmap[2923], bitmap[2795], bitmap[2667], bitmap[2539], bitmap[2411], bitmap[2283], bitmap[2155]};
      column_array[149] = {bitmap[3050], bitmap[2922], bitmap[2794], bitmap[2666], bitmap[2538], bitmap[2410], bitmap[2282], bitmap[2154]};
      column_array[150] = {bitmap[3049], bitmap[2921], bitmap[2793], bitmap[2665], bitmap[2537], bitmap[2409], bitmap[2281], bitmap[2153]};
      column_array[151] = {bitmap[3048], bitmap[2920], bitmap[2792], bitmap[2664], bitmap[2536], bitmap[2408], bitmap[2280], bitmap[2152]};
      column_array[152] = {bitmap[3047], bitmap[2919], bitmap[2791], bitmap[2663], bitmap[2535], bitmap[2407], bitmap[2279], bitmap[2151]};
      column_array[153] = {bitmap[3046], bitmap[2918], bitmap[2790], bitmap[2662], bitmap[2534], bitmap[2406], bitmap[2278], bitmap[2150]};
      column_array[154] = {bitmap[3045], bitmap[2917], bitmap[2789], bitmap[2661], bitmap[2533], bitmap[2405], bitmap[2277], bitmap[2149]};
      column_array[155] = {bitmap[3044], bitmap[2916], bitmap[2788], bitmap[2660], bitmap[2532], bitmap[2404], bitmap[2276], bitmap[2148]};
      column_array[156] = {bitmap[3043], bitmap[2915], bitmap[2787], bitmap[2659], bitmap[2531], bitmap[2403], bitmap[2275], bitmap[2147]};
      column_array[157] = {bitmap[3042], bitmap[2914], bitmap[2786], bitmap[2658], bitmap[2530], bitmap[2402], bitmap[2274], bitmap[2146]};
      column_array[158] = {bitmap[3041], bitmap[2913], bitmap[2785], bitmap[2657], bitmap[2529], bitmap[2401], bitmap[2273], bitmap[2145]};
      column_array[159] = {bitmap[3040], bitmap[2912], bitmap[2784], bitmap[2656], bitmap[2528], bitmap[2400], bitmap[2272], bitmap[2144]};
      column_array[160] = {bitmap[3039], bitmap[2911], bitmap[2783], bitmap[2655], bitmap[2527], bitmap[2399], bitmap[2271], bitmap[2143]};
      column_array[161] = {bitmap[3038], bitmap[2910], bitmap[2782], bitmap[2654], bitmap[2526], bitmap[2398], bitmap[2270], bitmap[2142]};
      column_array[162] = {bitmap[3037], bitmap[2909], bitmap[2781], bitmap[2653], bitmap[2525], bitmap[2397], bitmap[2269], bitmap[2141]};
      column_array[163] = {bitmap[3036], bitmap[2908], bitmap[2780], bitmap[2652], bitmap[2524], bitmap[2396], bitmap[2268], bitmap[2140]};
      column_array[164] = {bitmap[3035], bitmap[2907], bitmap[2779], bitmap[2651], bitmap[2523], bitmap[2395], bitmap[2267], bitmap[2139]};
      column_array[165] = {bitmap[3034], bitmap[2906], bitmap[2778], bitmap[2650], bitmap[2522], bitmap[2394], bitmap[2266], bitmap[2138]};
      column_array[166] = {bitmap[3033], bitmap[2905], bitmap[2777], bitmap[2649], bitmap[2521], bitmap[2393], bitmap[2265], bitmap[2137]};
      column_array[167] = {bitmap[3032], bitmap[2904], bitmap[2776], bitmap[2648], bitmap[2520], bitmap[2392], bitmap[2264], bitmap[2136]};
      column_array[168] = {bitmap[3031], bitmap[2903], bitmap[2775], bitmap[2647], bitmap[2519], bitmap[2391], bitmap[2263], bitmap[2135]};
      column_array[169] = {bitmap[3030], bitmap[2902], bitmap[2774], bitmap[2646], bitmap[2518], bitmap[2390], bitmap[2262], bitmap[2134]};
      column_array[170] = {bitmap[3029], bitmap[2901], bitmap[2773], bitmap[2645], bitmap[2517], bitmap[2389], bitmap[2261], bitmap[2133]};
      column_array[171] = {bitmap[3028], bitmap[2900], bitmap[2772], bitmap[2644], bitmap[2516], bitmap[2388], bitmap[2260], bitmap[2132]};
      column_array[172] = {bitmap[3027], bitmap[2899], bitmap[2771], bitmap[2643], bitmap[2515], bitmap[2387], bitmap[2259], bitmap[2131]};
      column_array[173] = {bitmap[3026], bitmap[2898], bitmap[2770], bitmap[2642], bitmap[2514], bitmap[2386], bitmap[2258], bitmap[2130]};
      column_array[174] = {bitmap[3025], bitmap[2897], bitmap[2769], bitmap[2641], bitmap[2513], bitmap[2385], bitmap[2257], bitmap[2129]};
      column_array[175] = {bitmap[3024], bitmap[2896], bitmap[2768], bitmap[2640], bitmap[2512], bitmap[2384], bitmap[2256], bitmap[2128]};
      column_array[176] = {bitmap[3023], bitmap[2895], bitmap[2767], bitmap[2639], bitmap[2511], bitmap[2383], bitmap[2255], bitmap[2127]};
      column_array[177] = {bitmap[3022], bitmap[2894], bitmap[2766], bitmap[2638], bitmap[2510], bitmap[2382], bitmap[2254], bitmap[2126]};
      column_array[178] = {bitmap[3021], bitmap[2893], bitmap[2765], bitmap[2637], bitmap[2509], bitmap[2381], bitmap[2253], bitmap[2125]};
      column_array[179] = {bitmap[3020], bitmap[2892], bitmap[2764], bitmap[2636], bitmap[2508], bitmap[2380], bitmap[2252], bitmap[2124]};
      column_array[180] = {bitmap[3019], bitmap[2891], bitmap[2763], bitmap[2635], bitmap[2507], bitmap[2379], bitmap[2251], bitmap[2123]};
      column_array[181] = {bitmap[3018], bitmap[2890], bitmap[2762], bitmap[2634], bitmap[2506], bitmap[2378], bitmap[2250], bitmap[2122]};
      column_array[182] = {bitmap[3017], bitmap[2889], bitmap[2761], bitmap[2633], bitmap[2505], bitmap[2377], bitmap[2249], bitmap[2121]};
      column_array[183] = {bitmap[3016], bitmap[2888], bitmap[2760], bitmap[2632], bitmap[2504], bitmap[2376], bitmap[2248], bitmap[2120]};
      column_array[184] = {bitmap[3015], bitmap[2887], bitmap[2759], bitmap[2631], bitmap[2503], bitmap[2375], bitmap[2247], bitmap[2119]};
      column_array[185] = {bitmap[3014], bitmap[2886], bitmap[2758], bitmap[2630], bitmap[2502], bitmap[2374], bitmap[2246], bitmap[2118]};
      column_array[186] = {bitmap[3013], bitmap[2885], bitmap[2757], bitmap[2629], bitmap[2501], bitmap[2373], bitmap[2245], bitmap[2117]};
      column_array[187] = {bitmap[3012], bitmap[2884], bitmap[2756], bitmap[2628], bitmap[2500], bitmap[2372], bitmap[2244], bitmap[2116]};
      column_array[188] = {bitmap[3011], bitmap[2883], bitmap[2755], bitmap[2627], bitmap[2499], bitmap[2371], bitmap[2243], bitmap[2115]};
      column_array[189] = {bitmap[3010], bitmap[2882], bitmap[2754], bitmap[2626], bitmap[2498], bitmap[2370], bitmap[2242], bitmap[2114]};
      column_array[190] = {bitmap[3009], bitmap[2881], bitmap[2753], bitmap[2625], bitmap[2497], bitmap[2369], bitmap[2241], bitmap[2113]};
      column_array[191] = {bitmap[3008], bitmap[2880], bitmap[2752], bitmap[2624], bitmap[2496], bitmap[2368], bitmap[2240], bitmap[2112]};
      column_array[192] = {bitmap[3007], bitmap[2879], bitmap[2751], bitmap[2623], bitmap[2495], bitmap[2367], bitmap[2239], bitmap[2111]};
      column_array[193] = {bitmap[3006], bitmap[2878], bitmap[2750], bitmap[2622], bitmap[2494], bitmap[2366], bitmap[2238], bitmap[2110]};
      column_array[194] = {bitmap[3005], bitmap[2877], bitmap[2749], bitmap[2621], bitmap[2493], bitmap[2365], bitmap[2237], bitmap[2109]};
      column_array[195] = {bitmap[3004], bitmap[2876], bitmap[2748], bitmap[2620], bitmap[2492], bitmap[2364], bitmap[2236], bitmap[2108]};
      column_array[196] = {bitmap[3003], bitmap[2875], bitmap[2747], bitmap[2619], bitmap[2491], bitmap[2363], bitmap[2235], bitmap[2107]};
      column_array[197] = {bitmap[3002], bitmap[2874], bitmap[2746], bitmap[2618], bitmap[2490], bitmap[2362], bitmap[2234], bitmap[2106]};
      column_array[198] = {bitmap[3001], bitmap[2873], bitmap[2745], bitmap[2617], bitmap[2489], bitmap[2361], bitmap[2233], bitmap[2105]};
      column_array[199] = {bitmap[3000], bitmap[2872], bitmap[2744], bitmap[2616], bitmap[2488], bitmap[2360], bitmap[2232], bitmap[2104]};
      column_array[200] = {bitmap[2999], bitmap[2871], bitmap[2743], bitmap[2615], bitmap[2487], bitmap[2359], bitmap[2231], bitmap[2103]};
      column_array[201] = {bitmap[2998], bitmap[2870], bitmap[2742], bitmap[2614], bitmap[2486], bitmap[2358], bitmap[2230], bitmap[2102]};
      column_array[202] = {bitmap[2997], bitmap[2869], bitmap[2741], bitmap[2613], bitmap[2485], bitmap[2357], bitmap[2229], bitmap[2101]};
      column_array[203] = {bitmap[2996], bitmap[2868], bitmap[2740], bitmap[2612], bitmap[2484], bitmap[2356], bitmap[2228], bitmap[2100]};
      column_array[204] = {bitmap[2995], bitmap[2867], bitmap[2739], bitmap[2611], bitmap[2483], bitmap[2355], bitmap[2227], bitmap[2099]};
      column_array[205] = {bitmap[2994], bitmap[2866], bitmap[2738], bitmap[2610], bitmap[2482], bitmap[2354], bitmap[2226], bitmap[2098]};
      column_array[206] = {bitmap[2993], bitmap[2865], bitmap[2737], bitmap[2609], bitmap[2481], bitmap[2353], bitmap[2225], bitmap[2097]};
      column_array[207] = {bitmap[2992], bitmap[2864], bitmap[2736], bitmap[2608], bitmap[2480], bitmap[2352], bitmap[2224], bitmap[2096]};
      column_array[208] = {bitmap[2991], bitmap[2863], bitmap[2735], bitmap[2607], bitmap[2479], bitmap[2351], bitmap[2223], bitmap[2095]};
      column_array[209] = {bitmap[2990], bitmap[2862], bitmap[2734], bitmap[2606], bitmap[2478], bitmap[2350], bitmap[2222], bitmap[2094]};
      column_array[210] = {bitmap[2989], bitmap[2861], bitmap[2733], bitmap[2605], bitmap[2477], bitmap[2349], bitmap[2221], bitmap[2093]};
      column_array[211] = {bitmap[2988], bitmap[2860], bitmap[2732], bitmap[2604], bitmap[2476], bitmap[2348], bitmap[2220], bitmap[2092]};
      column_array[212] = {bitmap[2987], bitmap[2859], bitmap[2731], bitmap[2603], bitmap[2475], bitmap[2347], bitmap[2219], bitmap[2091]};
      column_array[213] = {bitmap[2986], bitmap[2858], bitmap[2730], bitmap[2602], bitmap[2474], bitmap[2346], bitmap[2218], bitmap[2090]};
      column_array[214] = {bitmap[2985], bitmap[2857], bitmap[2729], bitmap[2601], bitmap[2473], bitmap[2345], bitmap[2217], bitmap[2089]};
      column_array[215] = {bitmap[2984], bitmap[2856], bitmap[2728], bitmap[2600], bitmap[2472], bitmap[2344], bitmap[2216], bitmap[2088]};
      column_array[216] = {bitmap[2983], bitmap[2855], bitmap[2727], bitmap[2599], bitmap[2471], bitmap[2343], bitmap[2215], bitmap[2087]};
      column_array[217] = {bitmap[2982], bitmap[2854], bitmap[2726], bitmap[2598], bitmap[2470], bitmap[2342], bitmap[2214], bitmap[2086]};
      column_array[218] = {bitmap[2981], bitmap[2853], bitmap[2725], bitmap[2597], bitmap[2469], bitmap[2341], bitmap[2213], bitmap[2085]};
      column_array[219] = {bitmap[2980], bitmap[2852], bitmap[2724], bitmap[2596], bitmap[2468], bitmap[2340], bitmap[2212], bitmap[2084]};
      column_array[220] = {bitmap[2979], bitmap[2851], bitmap[2723], bitmap[2595], bitmap[2467], bitmap[2339], bitmap[2211], bitmap[2083]};
      column_array[221] = {bitmap[2978], bitmap[2850], bitmap[2722], bitmap[2594], bitmap[2466], bitmap[2338], bitmap[2210], bitmap[2082]};
      column_array[222] = {bitmap[2977], bitmap[2849], bitmap[2721], bitmap[2593], bitmap[2465], bitmap[2337], bitmap[2209], bitmap[2081]};
      column_array[223] = {bitmap[2976], bitmap[2848], bitmap[2720], bitmap[2592], bitmap[2464], bitmap[2336], bitmap[2208], bitmap[2080]};
      column_array[224] = {bitmap[2975], bitmap[2847], bitmap[2719], bitmap[2591], bitmap[2463], bitmap[2335], bitmap[2207], bitmap[2079]};
      column_array[225] = {bitmap[2974], bitmap[2846], bitmap[2718], bitmap[2590], bitmap[2462], bitmap[2334], bitmap[2206], bitmap[2078]};
      column_array[226] = {bitmap[2973], bitmap[2845], bitmap[2717], bitmap[2589], bitmap[2461], bitmap[2333], bitmap[2205], bitmap[2077]};
      column_array[227] = {bitmap[2972], bitmap[2844], bitmap[2716], bitmap[2588], bitmap[2460], bitmap[2332], bitmap[2204], bitmap[2076]};
      column_array[228] = {bitmap[2971], bitmap[2843], bitmap[2715], bitmap[2587], bitmap[2459], bitmap[2331], bitmap[2203], bitmap[2075]};
      column_array[229] = {bitmap[2970], bitmap[2842], bitmap[2714], bitmap[2586], bitmap[2458], bitmap[2330], bitmap[2202], bitmap[2074]};
      column_array[230] = {bitmap[2969], bitmap[2841], bitmap[2713], bitmap[2585], bitmap[2457], bitmap[2329], bitmap[2201], bitmap[2073]};
      column_array[231] = {bitmap[2968], bitmap[2840], bitmap[2712], bitmap[2584], bitmap[2456], bitmap[2328], bitmap[2200], bitmap[2072]};
      column_array[232] = {bitmap[2967], bitmap[2839], bitmap[2711], bitmap[2583], bitmap[2455], bitmap[2327], bitmap[2199], bitmap[2071]};
      column_array[233] = {bitmap[2966], bitmap[2838], bitmap[2710], bitmap[2582], bitmap[2454], bitmap[2326], bitmap[2198], bitmap[2070]};
      column_array[234] = {bitmap[2965], bitmap[2837], bitmap[2709], bitmap[2581], bitmap[2453], bitmap[2325], bitmap[2197], bitmap[2069]};
      column_array[235] = {bitmap[2964], bitmap[2836], bitmap[2708], bitmap[2580], bitmap[2452], bitmap[2324], bitmap[2196], bitmap[2068]};
      column_array[236] = {bitmap[2963], bitmap[2835], bitmap[2707], bitmap[2579], bitmap[2451], bitmap[2323], bitmap[2195], bitmap[2067]};
      column_array[237] = {bitmap[2962], bitmap[2834], bitmap[2706], bitmap[2578], bitmap[2450], bitmap[2322], bitmap[2194], bitmap[2066]};
      column_array[238] = {bitmap[2961], bitmap[2833], bitmap[2705], bitmap[2577], bitmap[2449], bitmap[2321], bitmap[2193], bitmap[2065]};
      column_array[239] = {bitmap[2960], bitmap[2832], bitmap[2704], bitmap[2576], bitmap[2448], bitmap[2320], bitmap[2192], bitmap[2064]};
      column_array[240] = {bitmap[2959], bitmap[2831], bitmap[2703], bitmap[2575], bitmap[2447], bitmap[2319], bitmap[2191], bitmap[2063]};
      column_array[241] = {bitmap[2958], bitmap[2830], bitmap[2702], bitmap[2574], bitmap[2446], bitmap[2318], bitmap[2190], bitmap[2062]};
      column_array[242] = {bitmap[2957], bitmap[2829], bitmap[2701], bitmap[2573], bitmap[2445], bitmap[2317], bitmap[2189], bitmap[2061]};
      column_array[243] = {bitmap[2956], bitmap[2828], bitmap[2700], bitmap[2572], bitmap[2444], bitmap[2316], bitmap[2188], bitmap[2060]};
      column_array[244] = {bitmap[2955], bitmap[2827], bitmap[2699], bitmap[2571], bitmap[2443], bitmap[2315], bitmap[2187], bitmap[2059]};
      column_array[245] = {bitmap[2954], bitmap[2826], bitmap[2698], bitmap[2570], bitmap[2442], bitmap[2314], bitmap[2186], bitmap[2058]};
      column_array[246] = {bitmap[2953], bitmap[2825], bitmap[2697], bitmap[2569], bitmap[2441], bitmap[2313], bitmap[2185], bitmap[2057]};
      column_array[247] = {bitmap[2952], bitmap[2824], bitmap[2696], bitmap[2568], bitmap[2440], bitmap[2312], bitmap[2184], bitmap[2056]};
      column_array[248] = {bitmap[2951], bitmap[2823], bitmap[2695], bitmap[2567], bitmap[2439], bitmap[2311], bitmap[2183], bitmap[2055]};
      column_array[249] = {bitmap[2950], bitmap[2822], bitmap[2694], bitmap[2566], bitmap[2438], bitmap[2310], bitmap[2182], bitmap[2054]};
      column_array[250] = {bitmap[2949], bitmap[2821], bitmap[2693], bitmap[2565], bitmap[2437], bitmap[2309], bitmap[2181], bitmap[2053]};
      column_array[251] = {bitmap[2948], bitmap[2820], bitmap[2692], bitmap[2564], bitmap[2436], bitmap[2308], bitmap[2180], bitmap[2052]};
      column_array[252] = {bitmap[2947], bitmap[2819], bitmap[2691], bitmap[2563], bitmap[2435], bitmap[2307], bitmap[2179], bitmap[2051]};
      column_array[253] = {bitmap[2946], bitmap[2818], bitmap[2690], bitmap[2562], bitmap[2434], bitmap[2306], bitmap[2178], bitmap[2050]};
      column_array[254] = {bitmap[2945], bitmap[2817], bitmap[2689], bitmap[2561], bitmap[2433], bitmap[2305], bitmap[2177], bitmap[2049]};
      column_array[255] = {bitmap[2944], bitmap[2816], bitmap[2688], bitmap[2560], bitmap[2432], bitmap[2304], bitmap[2176], bitmap[2048]};
      column_array[256] = {bitmap[2047], bitmap[1919], bitmap[1791], bitmap[1663], bitmap[1535], bitmap[1407], bitmap[1279], bitmap[1151]};
      column_array[257] = {bitmap[2046], bitmap[1918], bitmap[1790], bitmap[1662], bitmap[1534], bitmap[1406], bitmap[1278], bitmap[1150]};
      column_array[258] = {bitmap[2045], bitmap[1917], bitmap[1789], bitmap[1661], bitmap[1533], bitmap[1405], bitmap[1277], bitmap[1149]};
      column_array[259] = {bitmap[2044], bitmap[1916], bitmap[1788], bitmap[1660], bitmap[1532], bitmap[1404], bitmap[1276], bitmap[1148]};
      column_array[260] = {bitmap[2043], bitmap[1915], bitmap[1787], bitmap[1659], bitmap[1531], bitmap[1403], bitmap[1275], bitmap[1147]};
      column_array[261] = {bitmap[2042], bitmap[1914], bitmap[1786], bitmap[1658], bitmap[1530], bitmap[1402], bitmap[1274], bitmap[1146]};
      column_array[262] = {bitmap[2041], bitmap[1913], bitmap[1785], bitmap[1657], bitmap[1529], bitmap[1401], bitmap[1273], bitmap[1145]};
      column_array[263] = {bitmap[2040], bitmap[1912], bitmap[1784], bitmap[1656], bitmap[1528], bitmap[1400], bitmap[1272], bitmap[1144]};
      column_array[264] = {bitmap[2039], bitmap[1911], bitmap[1783], bitmap[1655], bitmap[1527], bitmap[1399], bitmap[1271], bitmap[1143]};
      column_array[265] = {bitmap[2038], bitmap[1910], bitmap[1782], bitmap[1654], bitmap[1526], bitmap[1398], bitmap[1270], bitmap[1142]};
      column_array[266] = {bitmap[2037], bitmap[1909], bitmap[1781], bitmap[1653], bitmap[1525], bitmap[1397], bitmap[1269], bitmap[1141]};
      column_array[267] = {bitmap[2036], bitmap[1908], bitmap[1780], bitmap[1652], bitmap[1524], bitmap[1396], bitmap[1268], bitmap[1140]};
      column_array[268] = {bitmap[2035], bitmap[1907], bitmap[1779], bitmap[1651], bitmap[1523], bitmap[1395], bitmap[1267], bitmap[1139]};
      column_array[269] = {bitmap[2034], bitmap[1906], bitmap[1778], bitmap[1650], bitmap[1522], bitmap[1394], bitmap[1266], bitmap[1138]};
      column_array[270] = {bitmap[2033], bitmap[1905], bitmap[1777], bitmap[1649], bitmap[1521], bitmap[1393], bitmap[1265], bitmap[1137]};
      column_array[271] = {bitmap[2032], bitmap[1904], bitmap[1776], bitmap[1648], bitmap[1520], bitmap[1392], bitmap[1264], bitmap[1136]};
      column_array[272] = {bitmap[2031], bitmap[1903], bitmap[1775], bitmap[1647], bitmap[1519], bitmap[1391], bitmap[1263], bitmap[1135]};
      column_array[273] = {bitmap[2030], bitmap[1902], bitmap[1774], bitmap[1646], bitmap[1518], bitmap[1390], bitmap[1262], bitmap[1134]};
      column_array[274] = {bitmap[2029], bitmap[1901], bitmap[1773], bitmap[1645], bitmap[1517], bitmap[1389], bitmap[1261], bitmap[1133]};
      column_array[275] = {bitmap[2028], bitmap[1900], bitmap[1772], bitmap[1644], bitmap[1516], bitmap[1388], bitmap[1260], bitmap[1132]};
      column_array[276] = {bitmap[2027], bitmap[1899], bitmap[1771], bitmap[1643], bitmap[1515], bitmap[1387], bitmap[1259], bitmap[1131]};
      column_array[277] = {bitmap[2026], bitmap[1898], bitmap[1770], bitmap[1642], bitmap[1514], bitmap[1386], bitmap[1258], bitmap[1130]};
      column_array[278] = {bitmap[2025], bitmap[1897], bitmap[1769], bitmap[1641], bitmap[1513], bitmap[1385], bitmap[1257], bitmap[1129]};
      column_array[279] = {bitmap[2024], bitmap[1896], bitmap[1768], bitmap[1640], bitmap[1512], bitmap[1384], bitmap[1256], bitmap[1128]};
      column_array[280] = {bitmap[2023], bitmap[1895], bitmap[1767], bitmap[1639], bitmap[1511], bitmap[1383], bitmap[1255], bitmap[1127]};
      column_array[281] = {bitmap[2022], bitmap[1894], bitmap[1766], bitmap[1638], bitmap[1510], bitmap[1382], bitmap[1254], bitmap[1126]};
      column_array[282] = {bitmap[2021], bitmap[1893], bitmap[1765], bitmap[1637], bitmap[1509], bitmap[1381], bitmap[1253], bitmap[1125]};
      column_array[283] = {bitmap[2020], bitmap[1892], bitmap[1764], bitmap[1636], bitmap[1508], bitmap[1380], bitmap[1252], bitmap[1124]};
      column_array[284] = {bitmap[2019], bitmap[1891], bitmap[1763], bitmap[1635], bitmap[1507], bitmap[1379], bitmap[1251], bitmap[1123]};
      column_array[285] = {bitmap[2018], bitmap[1890], bitmap[1762], bitmap[1634], bitmap[1506], bitmap[1378], bitmap[1250], bitmap[1122]};
      column_array[286] = {bitmap[2017], bitmap[1889], bitmap[1761], bitmap[1633], bitmap[1505], bitmap[1377], bitmap[1249], bitmap[1121]};
      column_array[287] = {bitmap[2016], bitmap[1888], bitmap[1760], bitmap[1632], bitmap[1504], bitmap[1376], bitmap[1248], bitmap[1120]};
      column_array[288] = {bitmap[2015], bitmap[1887], bitmap[1759], bitmap[1631], bitmap[1503], bitmap[1375], bitmap[1247], bitmap[1119]};
      column_array[289] = {bitmap[2014], bitmap[1886], bitmap[1758], bitmap[1630], bitmap[1502], bitmap[1374], bitmap[1246], bitmap[1118]};
      column_array[290] = {bitmap[2013], bitmap[1885], bitmap[1757], bitmap[1629], bitmap[1501], bitmap[1373], bitmap[1245], bitmap[1117]};
      column_array[291] = {bitmap[2012], bitmap[1884], bitmap[1756], bitmap[1628], bitmap[1500], bitmap[1372], bitmap[1244], bitmap[1116]};
      column_array[292] = {bitmap[2011], bitmap[1883], bitmap[1755], bitmap[1627], bitmap[1499], bitmap[1371], bitmap[1243], bitmap[1115]};
      column_array[293] = {bitmap[2010], bitmap[1882], bitmap[1754], bitmap[1626], bitmap[1498], bitmap[1370], bitmap[1242], bitmap[1114]};
      column_array[294] = {bitmap[2009], bitmap[1881], bitmap[1753], bitmap[1625], bitmap[1497], bitmap[1369], bitmap[1241], bitmap[1113]};
      column_array[295] = {bitmap[2008], bitmap[1880], bitmap[1752], bitmap[1624], bitmap[1496], bitmap[1368], bitmap[1240], bitmap[1112]};
      column_array[296] = {bitmap[2007], bitmap[1879], bitmap[1751], bitmap[1623], bitmap[1495], bitmap[1367], bitmap[1239], bitmap[1111]};
      column_array[297] = {bitmap[2006], bitmap[1878], bitmap[1750], bitmap[1622], bitmap[1494], bitmap[1366], bitmap[1238], bitmap[1110]};
      column_array[298] = {bitmap[2005], bitmap[1877], bitmap[1749], bitmap[1621], bitmap[1493], bitmap[1365], bitmap[1237], bitmap[1109]};
      column_array[299] = {bitmap[2004], bitmap[1876], bitmap[1748], bitmap[1620], bitmap[1492], bitmap[1364], bitmap[1236], bitmap[1108]};
      column_array[300] = {bitmap[2003], bitmap[1875], bitmap[1747], bitmap[1619], bitmap[1491], bitmap[1363], bitmap[1235], bitmap[1107]};
      column_array[301] = {bitmap[2002], bitmap[1874], bitmap[1746], bitmap[1618], bitmap[1490], bitmap[1362], bitmap[1234], bitmap[1106]};
      column_array[302] = {bitmap[2001], bitmap[1873], bitmap[1745], bitmap[1617], bitmap[1489], bitmap[1361], bitmap[1233], bitmap[1105]};
      column_array[303] = {bitmap[2000], bitmap[1872], bitmap[1744], bitmap[1616], bitmap[1488], bitmap[1360], bitmap[1232], bitmap[1104]};
      column_array[304] = {bitmap[1999], bitmap[1871], bitmap[1743], bitmap[1615], bitmap[1487], bitmap[1359], bitmap[1231], bitmap[1103]};
      column_array[305] = {bitmap[1998], bitmap[1870], bitmap[1742], bitmap[1614], bitmap[1486], bitmap[1358], bitmap[1230], bitmap[1102]};
      column_array[306] = {bitmap[1997], bitmap[1869], bitmap[1741], bitmap[1613], bitmap[1485], bitmap[1357], bitmap[1229], bitmap[1101]};
      column_array[307] = {bitmap[1996], bitmap[1868], bitmap[1740], bitmap[1612], bitmap[1484], bitmap[1356], bitmap[1228], bitmap[1100]};
      column_array[308] = {bitmap[1995], bitmap[1867], bitmap[1739], bitmap[1611], bitmap[1483], bitmap[1355], bitmap[1227], bitmap[1099]};
      column_array[309] = {bitmap[1994], bitmap[1866], bitmap[1738], bitmap[1610], bitmap[1482], bitmap[1354], bitmap[1226], bitmap[1098]};
      column_array[310] = {bitmap[1993], bitmap[1865], bitmap[1737], bitmap[1609], bitmap[1481], bitmap[1353], bitmap[1225], bitmap[1097]};
      column_array[311] = {bitmap[1992], bitmap[1864], bitmap[1736], bitmap[1608], bitmap[1480], bitmap[1352], bitmap[1224], bitmap[1096]};
      column_array[312] = {bitmap[1991], bitmap[1863], bitmap[1735], bitmap[1607], bitmap[1479], bitmap[1351], bitmap[1223], bitmap[1095]};
      column_array[313] = {bitmap[1990], bitmap[1862], bitmap[1734], bitmap[1606], bitmap[1478], bitmap[1350], bitmap[1222], bitmap[1094]};
      column_array[314] = {bitmap[1989], bitmap[1861], bitmap[1733], bitmap[1605], bitmap[1477], bitmap[1349], bitmap[1221], bitmap[1093]};
      column_array[315] = {bitmap[1988], bitmap[1860], bitmap[1732], bitmap[1604], bitmap[1476], bitmap[1348], bitmap[1220], bitmap[1092]};
      column_array[316] = {bitmap[1987], bitmap[1859], bitmap[1731], bitmap[1603], bitmap[1475], bitmap[1347], bitmap[1219], bitmap[1091]};
      column_array[317] = {bitmap[1986], bitmap[1858], bitmap[1730], bitmap[1602], bitmap[1474], bitmap[1346], bitmap[1218], bitmap[1090]};
      column_array[318] = {bitmap[1985], bitmap[1857], bitmap[1729], bitmap[1601], bitmap[1473], bitmap[1345], bitmap[1217], bitmap[1089]};
      column_array[319] = {bitmap[1984], bitmap[1856], bitmap[1728], bitmap[1600], bitmap[1472], bitmap[1344], bitmap[1216], bitmap[1088]};
      column_array[320] = {bitmap[1983], bitmap[1855], bitmap[1727], bitmap[1599], bitmap[1471], bitmap[1343], bitmap[1215], bitmap[1087]};
      column_array[321] = {bitmap[1982], bitmap[1854], bitmap[1726], bitmap[1598], bitmap[1470], bitmap[1342], bitmap[1214], bitmap[1086]};
      column_array[322] = {bitmap[1981], bitmap[1853], bitmap[1725], bitmap[1597], bitmap[1469], bitmap[1341], bitmap[1213], bitmap[1085]};
      column_array[323] = {bitmap[1980], bitmap[1852], bitmap[1724], bitmap[1596], bitmap[1468], bitmap[1340], bitmap[1212], bitmap[1084]};
      column_array[324] = {bitmap[1979], bitmap[1851], bitmap[1723], bitmap[1595], bitmap[1467], bitmap[1339], bitmap[1211], bitmap[1083]};
      column_array[325] = {bitmap[1978], bitmap[1850], bitmap[1722], bitmap[1594], bitmap[1466], bitmap[1338], bitmap[1210], bitmap[1082]};
      column_array[326] = {bitmap[1977], bitmap[1849], bitmap[1721], bitmap[1593], bitmap[1465], bitmap[1337], bitmap[1209], bitmap[1081]};
      column_array[327] = {bitmap[1976], bitmap[1848], bitmap[1720], bitmap[1592], bitmap[1464], bitmap[1336], bitmap[1208], bitmap[1080]};
      column_array[328] = {bitmap[1975], bitmap[1847], bitmap[1719], bitmap[1591], bitmap[1463], bitmap[1335], bitmap[1207], bitmap[1079]};
      column_array[329] = {bitmap[1974], bitmap[1846], bitmap[1718], bitmap[1590], bitmap[1462], bitmap[1334], bitmap[1206], bitmap[1078]};
      column_array[330] = {bitmap[1973], bitmap[1845], bitmap[1717], bitmap[1589], bitmap[1461], bitmap[1333], bitmap[1205], bitmap[1077]};
      column_array[331] = {bitmap[1972], bitmap[1844], bitmap[1716], bitmap[1588], bitmap[1460], bitmap[1332], bitmap[1204], bitmap[1076]};
      column_array[332] = {bitmap[1971], bitmap[1843], bitmap[1715], bitmap[1587], bitmap[1459], bitmap[1331], bitmap[1203], bitmap[1075]};
      column_array[333] = {bitmap[1970], bitmap[1842], bitmap[1714], bitmap[1586], bitmap[1458], bitmap[1330], bitmap[1202], bitmap[1074]};
      column_array[334] = {bitmap[1969], bitmap[1841], bitmap[1713], bitmap[1585], bitmap[1457], bitmap[1329], bitmap[1201], bitmap[1073]};
      column_array[335] = {bitmap[1968], bitmap[1840], bitmap[1712], bitmap[1584], bitmap[1456], bitmap[1328], bitmap[1200], bitmap[1072]};
      column_array[336] = {bitmap[1967], bitmap[1839], bitmap[1711], bitmap[1583], bitmap[1455], bitmap[1327], bitmap[1199], bitmap[1071]};
      column_array[337] = {bitmap[1966], bitmap[1838], bitmap[1710], bitmap[1582], bitmap[1454], bitmap[1326], bitmap[1198], bitmap[1070]};
      column_array[338] = {bitmap[1965], bitmap[1837], bitmap[1709], bitmap[1581], bitmap[1453], bitmap[1325], bitmap[1197], bitmap[1069]};
      column_array[339] = {bitmap[1964], bitmap[1836], bitmap[1708], bitmap[1580], bitmap[1452], bitmap[1324], bitmap[1196], bitmap[1068]};
      column_array[340] = {bitmap[1963], bitmap[1835], bitmap[1707], bitmap[1579], bitmap[1451], bitmap[1323], bitmap[1195], bitmap[1067]};
      column_array[341] = {bitmap[1962], bitmap[1834], bitmap[1706], bitmap[1578], bitmap[1450], bitmap[1322], bitmap[1194], bitmap[1066]};
      column_array[342] = {bitmap[1961], bitmap[1833], bitmap[1705], bitmap[1577], bitmap[1449], bitmap[1321], bitmap[1193], bitmap[1065]};
      column_array[343] = {bitmap[1960], bitmap[1832], bitmap[1704], bitmap[1576], bitmap[1448], bitmap[1320], bitmap[1192], bitmap[1064]};
      column_array[344] = {bitmap[1959], bitmap[1831], bitmap[1703], bitmap[1575], bitmap[1447], bitmap[1319], bitmap[1191], bitmap[1063]};
      column_array[345] = {bitmap[1958], bitmap[1830], bitmap[1702], bitmap[1574], bitmap[1446], bitmap[1318], bitmap[1190], bitmap[1062]};
      column_array[346] = {bitmap[1957], bitmap[1829], bitmap[1701], bitmap[1573], bitmap[1445], bitmap[1317], bitmap[1189], bitmap[1061]};
      column_array[347] = {bitmap[1956], bitmap[1828], bitmap[1700], bitmap[1572], bitmap[1444], bitmap[1316], bitmap[1188], bitmap[1060]};
      column_array[348] = {bitmap[1955], bitmap[1827], bitmap[1699], bitmap[1571], bitmap[1443], bitmap[1315], bitmap[1187], bitmap[1059]};
      column_array[349] = {bitmap[1954], bitmap[1826], bitmap[1698], bitmap[1570], bitmap[1442], bitmap[1314], bitmap[1186], bitmap[1058]};
      column_array[350] = {bitmap[1953], bitmap[1825], bitmap[1697], bitmap[1569], bitmap[1441], bitmap[1313], bitmap[1185], bitmap[1057]};
      column_array[351] = {bitmap[1952], bitmap[1824], bitmap[1696], bitmap[1568], bitmap[1440], bitmap[1312], bitmap[1184], bitmap[1056]};
      column_array[352] = {bitmap[1951], bitmap[1823], bitmap[1695], bitmap[1567], bitmap[1439], bitmap[1311], bitmap[1183], bitmap[1055]};
      column_array[353] = {bitmap[1950], bitmap[1822], bitmap[1694], bitmap[1566], bitmap[1438], bitmap[1310], bitmap[1182], bitmap[1054]};
      column_array[354] = {bitmap[1949], bitmap[1821], bitmap[1693], bitmap[1565], bitmap[1437], bitmap[1309], bitmap[1181], bitmap[1053]};
      column_array[355] = {bitmap[1948], bitmap[1820], bitmap[1692], bitmap[1564], bitmap[1436], bitmap[1308], bitmap[1180], bitmap[1052]};
      column_array[356] = {bitmap[1947], bitmap[1819], bitmap[1691], bitmap[1563], bitmap[1435], bitmap[1307], bitmap[1179], bitmap[1051]};
      column_array[357] = {bitmap[1946], bitmap[1818], bitmap[1690], bitmap[1562], bitmap[1434], bitmap[1306], bitmap[1178], bitmap[1050]};
      column_array[358] = {bitmap[1945], bitmap[1817], bitmap[1689], bitmap[1561], bitmap[1433], bitmap[1305], bitmap[1177], bitmap[1049]};
      column_array[359] = {bitmap[1944], bitmap[1816], bitmap[1688], bitmap[1560], bitmap[1432], bitmap[1304], bitmap[1176], bitmap[1048]};
      column_array[360] = {bitmap[1943], bitmap[1815], bitmap[1687], bitmap[1559], bitmap[1431], bitmap[1303], bitmap[1175], bitmap[1047]};
      column_array[361] = {bitmap[1942], bitmap[1814], bitmap[1686], bitmap[1558], bitmap[1430], bitmap[1302], bitmap[1174], bitmap[1046]};
      column_array[362] = {bitmap[1941], bitmap[1813], bitmap[1685], bitmap[1557], bitmap[1429], bitmap[1301], bitmap[1173], bitmap[1045]};
      column_array[363] = {bitmap[1940], bitmap[1812], bitmap[1684], bitmap[1556], bitmap[1428], bitmap[1300], bitmap[1172], bitmap[1044]};
      column_array[364] = {bitmap[1939], bitmap[1811], bitmap[1683], bitmap[1555], bitmap[1427], bitmap[1299], bitmap[1171], bitmap[1043]};
      column_array[365] = {bitmap[1938], bitmap[1810], bitmap[1682], bitmap[1554], bitmap[1426], bitmap[1298], bitmap[1170], bitmap[1042]};
      column_array[366] = {bitmap[1937], bitmap[1809], bitmap[1681], bitmap[1553], bitmap[1425], bitmap[1297], bitmap[1169], bitmap[1041]};
      column_array[367] = {bitmap[1936], bitmap[1808], bitmap[1680], bitmap[1552], bitmap[1424], bitmap[1296], bitmap[1168], bitmap[1040]};
      column_array[368] = {bitmap[1935], bitmap[1807], bitmap[1679], bitmap[1551], bitmap[1423], bitmap[1295], bitmap[1167], bitmap[1039]};
      column_array[369] = {bitmap[1934], bitmap[1806], bitmap[1678], bitmap[1550], bitmap[1422], bitmap[1294], bitmap[1166], bitmap[1038]};
      column_array[370] = {bitmap[1933], bitmap[1805], bitmap[1677], bitmap[1549], bitmap[1421], bitmap[1293], bitmap[1165], bitmap[1037]};
      column_array[371] = {bitmap[1932], bitmap[1804], bitmap[1676], bitmap[1548], bitmap[1420], bitmap[1292], bitmap[1164], bitmap[1036]};
      column_array[372] = {bitmap[1931], bitmap[1803], bitmap[1675], bitmap[1547], bitmap[1419], bitmap[1291], bitmap[1163], bitmap[1035]};
      column_array[373] = {bitmap[1930], bitmap[1802], bitmap[1674], bitmap[1546], bitmap[1418], bitmap[1290], bitmap[1162], bitmap[1034]};
      column_array[374] = {bitmap[1929], bitmap[1801], bitmap[1673], bitmap[1545], bitmap[1417], bitmap[1289], bitmap[1161], bitmap[1033]};
      column_array[375] = {bitmap[1928], bitmap[1800], bitmap[1672], bitmap[1544], bitmap[1416], bitmap[1288], bitmap[1160], bitmap[1032]};
      column_array[376] = {bitmap[1927], bitmap[1799], bitmap[1671], bitmap[1543], bitmap[1415], bitmap[1287], bitmap[1159], bitmap[1031]};
      column_array[377] = {bitmap[1926], bitmap[1798], bitmap[1670], bitmap[1542], bitmap[1414], bitmap[1286], bitmap[1158], bitmap[1030]};
      column_array[378] = {bitmap[1925], bitmap[1797], bitmap[1669], bitmap[1541], bitmap[1413], bitmap[1285], bitmap[1157], bitmap[1029]};
      column_array[379] = {bitmap[1924], bitmap[1796], bitmap[1668], bitmap[1540], bitmap[1412], bitmap[1284], bitmap[1156], bitmap[1028]};
      column_array[380] = {bitmap[1923], bitmap[1795], bitmap[1667], bitmap[1539], bitmap[1411], bitmap[1283], bitmap[1155], bitmap[1027]};
      column_array[381] = {bitmap[1922], bitmap[1794], bitmap[1666], bitmap[1538], bitmap[1410], bitmap[1282], bitmap[1154], bitmap[1026]};
      column_array[382] = {bitmap[1921], bitmap[1793], bitmap[1665], bitmap[1537], bitmap[1409], bitmap[1281], bitmap[1153], bitmap[1025]};
      column_array[383] = {bitmap[1920], bitmap[1792], bitmap[1664], bitmap[1536], bitmap[1408], bitmap[1280], bitmap[1152], bitmap[1024]};
      column_array[384] = {bitmap[1023], bitmap[895], bitmap[767], bitmap[639], bitmap[511], bitmap[383], bitmap[255], bitmap[127]};
      column_array[385] = {bitmap[1022], bitmap[894], bitmap[766], bitmap[638], bitmap[510], bitmap[382], bitmap[254], bitmap[126]};
      column_array[386] = {bitmap[1021], bitmap[893], bitmap[765], bitmap[637], bitmap[509], bitmap[381], bitmap[253], bitmap[125]};
      column_array[387] = {bitmap[1020], bitmap[892], bitmap[764], bitmap[636], bitmap[508], bitmap[380], bitmap[252], bitmap[124]};
      column_array[388] = {bitmap[1019], bitmap[891], bitmap[763], bitmap[635], bitmap[507], bitmap[379], bitmap[251], bitmap[123]};
      column_array[389] = {bitmap[1018], bitmap[890], bitmap[762], bitmap[634], bitmap[506], bitmap[378], bitmap[250], bitmap[122]};
      column_array[390] = {bitmap[1017], bitmap[889], bitmap[761], bitmap[633], bitmap[505], bitmap[377], bitmap[249], bitmap[121]};
      column_array[391] = {bitmap[1016], bitmap[888], bitmap[760], bitmap[632], bitmap[504], bitmap[376], bitmap[248], bitmap[120]};
      column_array[392] = {bitmap[1015], bitmap[887], bitmap[759], bitmap[631], bitmap[503], bitmap[375], bitmap[247], bitmap[119]};
      column_array[393] = {bitmap[1014], bitmap[886], bitmap[758], bitmap[630], bitmap[502], bitmap[374], bitmap[246], bitmap[118]};
      column_array[394] = {bitmap[1013], bitmap[885], bitmap[757], bitmap[629], bitmap[501], bitmap[373], bitmap[245], bitmap[117]};
      column_array[395] = {bitmap[1012], bitmap[884], bitmap[756], bitmap[628], bitmap[500], bitmap[372], bitmap[244], bitmap[116]};
      column_array[396] = {bitmap[1011], bitmap[883], bitmap[755], bitmap[627], bitmap[499], bitmap[371], bitmap[243], bitmap[115]};
      column_array[397] = {bitmap[1010], bitmap[882], bitmap[754], bitmap[626], bitmap[498], bitmap[370], bitmap[242], bitmap[114]};
      column_array[398] = {bitmap[1009], bitmap[881], bitmap[753], bitmap[625], bitmap[497], bitmap[369], bitmap[241], bitmap[113]};
      column_array[399] = {bitmap[1008], bitmap[880], bitmap[752], bitmap[624], bitmap[496], bitmap[368], bitmap[240], bitmap[112]};
      column_array[400] = {bitmap[1007], bitmap[879], bitmap[751], bitmap[623], bitmap[495], bitmap[367], bitmap[239], bitmap[111]};
      column_array[401] = {bitmap[1006], bitmap[878], bitmap[750], bitmap[622], bitmap[494], bitmap[366], bitmap[238], bitmap[110]};
      column_array[402] = {bitmap[1005], bitmap[877], bitmap[749], bitmap[621], bitmap[493], bitmap[365], bitmap[237], bitmap[109]};
      column_array[403] = {bitmap[1004], bitmap[876], bitmap[748], bitmap[620], bitmap[492], bitmap[364], bitmap[236], bitmap[108]};
      column_array[404] = {bitmap[1003], bitmap[875], bitmap[747], bitmap[619], bitmap[491], bitmap[363], bitmap[235], bitmap[107]};
      column_array[405] = {bitmap[1002], bitmap[874], bitmap[746], bitmap[618], bitmap[490], bitmap[362], bitmap[234], bitmap[106]};
      column_array[406] = {bitmap[1001], bitmap[873], bitmap[745], bitmap[617], bitmap[489], bitmap[361], bitmap[233], bitmap[105]};
      column_array[407] = {bitmap[1000], bitmap[872], bitmap[744], bitmap[616], bitmap[488], bitmap[360], bitmap[232], bitmap[104]};
      column_array[408] = {bitmap[999], bitmap[871], bitmap[743], bitmap[615], bitmap[487], bitmap[359], bitmap[231], bitmap[103]};
      column_array[409] = {bitmap[998], bitmap[870], bitmap[742], bitmap[614], bitmap[486], bitmap[358], bitmap[230], bitmap[102]};
      column_array[410] = {bitmap[997], bitmap[869], bitmap[741], bitmap[613], bitmap[485], bitmap[357], bitmap[229], bitmap[101]};
      column_array[411] = {bitmap[996], bitmap[868], bitmap[740], bitmap[612], bitmap[484], bitmap[356], bitmap[228], bitmap[100]};
      column_array[412] = {bitmap[995], bitmap[867], bitmap[739], bitmap[611], bitmap[483], bitmap[355], bitmap[227], bitmap[99]};
      column_array[413] = {bitmap[994], bitmap[866], bitmap[738], bitmap[610], bitmap[482], bitmap[354], bitmap[226], bitmap[98]};
      column_array[414] = {bitmap[993], bitmap[865], bitmap[737], bitmap[609], bitmap[481], bitmap[353], bitmap[225], bitmap[97]};
      column_array[415] = {bitmap[992], bitmap[864], bitmap[736], bitmap[608], bitmap[480], bitmap[352], bitmap[224], bitmap[96]};
      column_array[416] = {bitmap[991], bitmap[863], bitmap[735], bitmap[607], bitmap[479], bitmap[351], bitmap[223], bitmap[95]};
      column_array[417] = {bitmap[990], bitmap[862], bitmap[734], bitmap[606], bitmap[478], bitmap[350], bitmap[222], bitmap[94]};
      column_array[418] = {bitmap[989], bitmap[861], bitmap[733], bitmap[605], bitmap[477], bitmap[349], bitmap[221], bitmap[93]};
      column_array[419] = {bitmap[988], bitmap[860], bitmap[732], bitmap[604], bitmap[476], bitmap[348], bitmap[220], bitmap[92]};
      column_array[420] = {bitmap[987], bitmap[859], bitmap[731], bitmap[603], bitmap[475], bitmap[347], bitmap[219], bitmap[91]};
      column_array[421] = {bitmap[986], bitmap[858], bitmap[730], bitmap[602], bitmap[474], bitmap[346], bitmap[218], bitmap[90]};
      column_array[422] = {bitmap[985], bitmap[857], bitmap[729], bitmap[601], bitmap[473], bitmap[345], bitmap[217], bitmap[89]};
      column_array[423] = {bitmap[984], bitmap[856], bitmap[728], bitmap[600], bitmap[472], bitmap[344], bitmap[216], bitmap[88]};
      column_array[424] = {bitmap[983], bitmap[855], bitmap[727], bitmap[599], bitmap[471], bitmap[343], bitmap[215], bitmap[87]};
      column_array[425] = {bitmap[982], bitmap[854], bitmap[726], bitmap[598], bitmap[470], bitmap[342], bitmap[214], bitmap[86]};
      column_array[426] = {bitmap[981], bitmap[853], bitmap[725], bitmap[597], bitmap[469], bitmap[341], bitmap[213], bitmap[85]};
      column_array[427] = {bitmap[980], bitmap[852], bitmap[724], bitmap[596], bitmap[468], bitmap[340], bitmap[212], bitmap[84]};
      column_array[428] = {bitmap[979], bitmap[851], bitmap[723], bitmap[595], bitmap[467], bitmap[339], bitmap[211], bitmap[83]};
      column_array[429] = {bitmap[978], bitmap[850], bitmap[722], bitmap[594], bitmap[466], bitmap[338], bitmap[210], bitmap[82]};
      column_array[430] = {bitmap[977], bitmap[849], bitmap[721], bitmap[593], bitmap[465], bitmap[337], bitmap[209], bitmap[81]};
      column_array[431] = {bitmap[976], bitmap[848], bitmap[720], bitmap[592], bitmap[464], bitmap[336], bitmap[208], bitmap[80]};
      column_array[432] = {bitmap[975], bitmap[847], bitmap[719], bitmap[591], bitmap[463], bitmap[335], bitmap[207], bitmap[79]};
      column_array[433] = {bitmap[974], bitmap[846], bitmap[718], bitmap[590], bitmap[462], bitmap[334], bitmap[206], bitmap[78]};
      column_array[434] = {bitmap[973], bitmap[845], bitmap[717], bitmap[589], bitmap[461], bitmap[333], bitmap[205], bitmap[77]};
      column_array[435] = {bitmap[972], bitmap[844], bitmap[716], bitmap[588], bitmap[460], bitmap[332], bitmap[204], bitmap[76]};
      column_array[436] = {bitmap[971], bitmap[843], bitmap[715], bitmap[587], bitmap[459], bitmap[331], bitmap[203], bitmap[75]};
      column_array[437] = {bitmap[970], bitmap[842], bitmap[714], bitmap[586], bitmap[458], bitmap[330], bitmap[202], bitmap[74]};
      column_array[438] = {bitmap[969], bitmap[841], bitmap[713], bitmap[585], bitmap[457], bitmap[329], bitmap[201], bitmap[73]};
      column_array[439] = {bitmap[968], bitmap[840], bitmap[712], bitmap[584], bitmap[456], bitmap[328], bitmap[200], bitmap[72]};
      column_array[440] = {bitmap[967], bitmap[839], bitmap[711], bitmap[583], bitmap[455], bitmap[327], bitmap[199], bitmap[71]};
      column_array[441] = {bitmap[966], bitmap[838], bitmap[710], bitmap[582], bitmap[454], bitmap[326], bitmap[198], bitmap[70]};
      column_array[442] = {bitmap[965], bitmap[837], bitmap[709], bitmap[581], bitmap[453], bitmap[325], bitmap[197], bitmap[69]};
      column_array[443] = {bitmap[964], bitmap[836], bitmap[708], bitmap[580], bitmap[452], bitmap[324], bitmap[196], bitmap[68]};
      column_array[444] = {bitmap[963], bitmap[835], bitmap[707], bitmap[579], bitmap[451], bitmap[323], bitmap[195], bitmap[67]};
      column_array[445] = {bitmap[962], bitmap[834], bitmap[706], bitmap[578], bitmap[450], bitmap[322], bitmap[194], bitmap[66]};
      column_array[446] = {bitmap[961], bitmap[833], bitmap[705], bitmap[577], bitmap[449], bitmap[321], bitmap[193], bitmap[65]};
      column_array[447] = {bitmap[960], bitmap[832], bitmap[704], bitmap[576], bitmap[448], bitmap[320], bitmap[192], bitmap[64]};
      column_array[448] = {bitmap[959], bitmap[831], bitmap[703], bitmap[575], bitmap[447], bitmap[319], bitmap[191], bitmap[63]};
      column_array[449] = {bitmap[958], bitmap[830], bitmap[702], bitmap[574], bitmap[446], bitmap[318], bitmap[190], bitmap[62]};
      column_array[450] = {bitmap[957], bitmap[829], bitmap[701], bitmap[573], bitmap[445], bitmap[317], bitmap[189], bitmap[61]};
      column_array[451] = {bitmap[956], bitmap[828], bitmap[700], bitmap[572], bitmap[444], bitmap[316], bitmap[188], bitmap[60]};
      column_array[452] = {bitmap[955], bitmap[827], bitmap[699], bitmap[571], bitmap[443], bitmap[315], bitmap[187], bitmap[59]};
      column_array[453] = {bitmap[954], bitmap[826], bitmap[698], bitmap[570], bitmap[442], bitmap[314], bitmap[186], bitmap[58]};
      column_array[454] = {bitmap[953], bitmap[825], bitmap[697], bitmap[569], bitmap[441], bitmap[313], bitmap[185], bitmap[57]};
      column_array[455] = {bitmap[952], bitmap[824], bitmap[696], bitmap[568], bitmap[440], bitmap[312], bitmap[184], bitmap[56]};
      column_array[456] = {bitmap[951], bitmap[823], bitmap[695], bitmap[567], bitmap[439], bitmap[311], bitmap[183], bitmap[55]};
      column_array[457] = {bitmap[950], bitmap[822], bitmap[694], bitmap[566], bitmap[438], bitmap[310], bitmap[182], bitmap[54]};
      column_array[458] = {bitmap[949], bitmap[821], bitmap[693], bitmap[565], bitmap[437], bitmap[309], bitmap[181], bitmap[53]};
      column_array[459] = {bitmap[948], bitmap[820], bitmap[692], bitmap[564], bitmap[436], bitmap[308], bitmap[180], bitmap[52]};
      column_array[460] = {bitmap[947], bitmap[819], bitmap[691], bitmap[563], bitmap[435], bitmap[307], bitmap[179], bitmap[51]};
      column_array[461] = {bitmap[946], bitmap[818], bitmap[690], bitmap[562], bitmap[434], bitmap[306], bitmap[178], bitmap[50]};
      column_array[462] = {bitmap[945], bitmap[817], bitmap[689], bitmap[561], bitmap[433], bitmap[305], bitmap[177], bitmap[49]};
      column_array[463] = {bitmap[944], bitmap[816], bitmap[688], bitmap[560], bitmap[432], bitmap[304], bitmap[176], bitmap[48]};
      column_array[464] = {bitmap[943], bitmap[815], bitmap[687], bitmap[559], bitmap[431], bitmap[303], bitmap[175], bitmap[47]};
      column_array[465] = {bitmap[942], bitmap[814], bitmap[686], bitmap[558], bitmap[430], bitmap[302], bitmap[174], bitmap[46]};
      column_array[466] = {bitmap[941], bitmap[813], bitmap[685], bitmap[557], bitmap[429], bitmap[301], bitmap[173], bitmap[45]};
      column_array[467] = {bitmap[940], bitmap[812], bitmap[684], bitmap[556], bitmap[428], bitmap[300], bitmap[172], bitmap[44]};
      column_array[468] = {bitmap[939], bitmap[811], bitmap[683], bitmap[555], bitmap[427], bitmap[299], bitmap[171], bitmap[43]};
      column_array[469] = {bitmap[938], bitmap[810], bitmap[682], bitmap[554], bitmap[426], bitmap[298], bitmap[170], bitmap[42]};
      column_array[470] = {bitmap[937], bitmap[809], bitmap[681], bitmap[553], bitmap[425], bitmap[297], bitmap[169], bitmap[41]};
      column_array[471] = {bitmap[936], bitmap[808], bitmap[680], bitmap[552], bitmap[424], bitmap[296], bitmap[168], bitmap[40]};
      column_array[472] = {bitmap[935], bitmap[807], bitmap[679], bitmap[551], bitmap[423], bitmap[295], bitmap[167], bitmap[39]};
      column_array[473] = {bitmap[934], bitmap[806], bitmap[678], bitmap[550], bitmap[422], bitmap[294], bitmap[166], bitmap[38]};
      column_array[474] = {bitmap[933], bitmap[805], bitmap[677], bitmap[549], bitmap[421], bitmap[293], bitmap[165], bitmap[37]};
      column_array[475] = {bitmap[932], bitmap[804], bitmap[676], bitmap[548], bitmap[420], bitmap[292], bitmap[164], bitmap[36]};
      column_array[476] = {bitmap[931], bitmap[803], bitmap[675], bitmap[547], bitmap[419], bitmap[291], bitmap[163], bitmap[35]};
      column_array[477] = {bitmap[930], bitmap[802], bitmap[674], bitmap[546], bitmap[418], bitmap[290], bitmap[162], bitmap[34]};
      column_array[478] = {bitmap[929], bitmap[801], bitmap[673], bitmap[545], bitmap[417], bitmap[289], bitmap[161], bitmap[33]};
      column_array[479] = {bitmap[928], bitmap[800], bitmap[672], bitmap[544], bitmap[416], bitmap[288], bitmap[160], bitmap[32]};
      column_array[480] = {bitmap[927], bitmap[799], bitmap[671], bitmap[543], bitmap[415], bitmap[287], bitmap[159], bitmap[31]};
      column_array[481] = {bitmap[926], bitmap[798], bitmap[670], bitmap[542], bitmap[414], bitmap[286], bitmap[158], bitmap[30]};
      column_array[482] = {bitmap[925], bitmap[797], bitmap[669], bitmap[541], bitmap[413], bitmap[285], bitmap[157], bitmap[29]};
      column_array[483] = {bitmap[924], bitmap[796], bitmap[668], bitmap[540], bitmap[412], bitmap[284], bitmap[156], bitmap[28]};
      column_array[484] = {bitmap[923], bitmap[795], bitmap[667], bitmap[539], bitmap[411], bitmap[283], bitmap[155], bitmap[27]};
      column_array[485] = {bitmap[922], bitmap[794], bitmap[666], bitmap[538], bitmap[410], bitmap[282], bitmap[154], bitmap[26]};
      column_array[486] = {bitmap[921], bitmap[793], bitmap[665], bitmap[537], bitmap[409], bitmap[281], bitmap[153], bitmap[25]};
      column_array[487] = {bitmap[920], bitmap[792], bitmap[664], bitmap[536], bitmap[408], bitmap[280], bitmap[152], bitmap[24]};
      column_array[488] = {bitmap[919], bitmap[791], bitmap[663], bitmap[535], bitmap[407], bitmap[279], bitmap[151], bitmap[23]};
      column_array[489] = {bitmap[918], bitmap[790], bitmap[662], bitmap[534], bitmap[406], bitmap[278], bitmap[150], bitmap[22]};
      column_array[490] = {bitmap[917], bitmap[789], bitmap[661], bitmap[533], bitmap[405], bitmap[277], bitmap[149], bitmap[21]};
      column_array[491] = {bitmap[916], bitmap[788], bitmap[660], bitmap[532], bitmap[404], bitmap[276], bitmap[148], bitmap[20]};
      column_array[492] = {bitmap[915], bitmap[787], bitmap[659], bitmap[531], bitmap[403], bitmap[275], bitmap[147], bitmap[19]};
      column_array[493] = {bitmap[914], bitmap[786], bitmap[658], bitmap[530], bitmap[402], bitmap[274], bitmap[146], bitmap[18]};
      column_array[494] = {bitmap[913], bitmap[785], bitmap[657], bitmap[529], bitmap[401], bitmap[273], bitmap[145], bitmap[17]};
      column_array[495] = {bitmap[912], bitmap[784], bitmap[656], bitmap[528], bitmap[400], bitmap[272], bitmap[144], bitmap[16]};
      column_array[496] = {bitmap[911], bitmap[783], bitmap[655], bitmap[527], bitmap[399], bitmap[271], bitmap[143], bitmap[15]};
      column_array[497] = {bitmap[910], bitmap[782], bitmap[654], bitmap[526], bitmap[398], bitmap[270], bitmap[142], bitmap[14]};
      column_array[498] = {bitmap[909], bitmap[781], bitmap[653], bitmap[525], bitmap[397], bitmap[269], bitmap[141], bitmap[13]};
      column_array[499] = {bitmap[908], bitmap[780], bitmap[652], bitmap[524], bitmap[396], bitmap[268], bitmap[140], bitmap[12]};
      column_array[500] = {bitmap[907], bitmap[779], bitmap[651], bitmap[523], bitmap[395], bitmap[267], bitmap[139], bitmap[11]};
      column_array[501] = {bitmap[906], bitmap[778], bitmap[650], bitmap[522], bitmap[394], bitmap[266], bitmap[138], bitmap[10]};
      column_array[502] = {bitmap[905], bitmap[777], bitmap[649], bitmap[521], bitmap[393], bitmap[265], bitmap[137], bitmap[9]};
      column_array[503] = {bitmap[904], bitmap[776], bitmap[648], bitmap[520], bitmap[392], bitmap[264], bitmap[136], bitmap[8]};
      column_array[504] = {bitmap[903], bitmap[775], bitmap[647], bitmap[519], bitmap[391], bitmap[263], bitmap[135], bitmap[7]};
      column_array[505] = {bitmap[902], bitmap[774], bitmap[646], bitmap[518], bitmap[390], bitmap[262], bitmap[134], bitmap[6]};
      column_array[506] = {bitmap[901], bitmap[773], bitmap[645], bitmap[517], bitmap[389], bitmap[261], bitmap[133], bitmap[5]};
      column_array[507] = {bitmap[900], bitmap[772], bitmap[644], bitmap[516], bitmap[388], bitmap[260], bitmap[132], bitmap[4]};
      column_array[508] = {bitmap[899], bitmap[771], bitmap[643], bitmap[515], bitmap[387], bitmap[259], bitmap[131], bitmap[3]};
      column_array[509] = {bitmap[898], bitmap[770], bitmap[642], bitmap[514], bitmap[386], bitmap[258], bitmap[130], bitmap[2]};
      column_array[510] = {bitmap[897], bitmap[769], bitmap[641], bitmap[513], bitmap[385], bitmap[257], bitmap[129], bitmap[1]};
      column_array[511] = {bitmap[896], bitmap[768], bitmap[640], bitmap[512], bitmap[384], bitmap[256], bitmap[128], bitmap[0]};
    end
endmodule

/* ------------------------------------- *
 * column[n], increses top to bottom         
 * column_number increases left to right
 *           
 * decoded_bitmap = {row0,row1,...,row7}
 * ------------------------------------- */
//* Extracts a column from 8x8 bit array 
module bitmap_column(
  input [63:0] decoded_bitmap,
  input [2:0] column_number,
  output [7:0] column);
  wire [2:0] column_index;

  assign column_index = 3'b111 - column_number;

  assign column = {decoded_bitmap[{3'b000,column_index}],
                   decoded_bitmap[{3'b001,column_index}],
                   decoded_bitmap[{3'b010,column_index}],
                   decoded_bitmap[{3'b011,column_index}],
                   decoded_bitmap[{3'b100,column_index}],
                   decoded_bitmap[{3'b101,column_index}],
                   decoded_bitmap[{3'b110,column_index}],
                   decoded_bitmap[{3'b111,column_index}]};
endmodule
