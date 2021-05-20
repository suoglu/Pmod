/* ------------------------------------------------ *
 * Title       : Pmod OLED interface v1.0           *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : oled.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 19/05/2021                         *
 * ------------------------------------------------ *
 * Description : Simple interface to communicate    *
 *               with Pmod OLED                     *
 * ------------------------------------------------ */

//* Pmod OLED driver which uses codes for content *//
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
  wire cursor_update, cursor_in_pos, cursor_flash_on;
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
  always@(negedge ext_spi_clk or posedge rst)
    begin
      if(rst)
        begin
          spi_done <= 1'b0;
        end
      else
        case(spi_done)
          1'b0: spi_done <= spi_working & last_byte & bit_counter_done;
          1'b1: spi_done <= 1'b0;
        endcase
    end
  always@(negedge ext_spi_clk or posedge rst)
    begin
      if(rst)
        begin
          spi_working <= 1'b0;
        end
      else
        case(spi_working)
          1'b0: spi_working <= ~spi_done & inSPIState & spi_clk;
          1'b1: spi_working <= ~spi_done;
        endcase
    end

  //State transactions
  always@(posedge spi_clk or posedge rst)
    begin
      if(rst)
        begin
          state <= POWER_OFF;
        end
      else
        begin
          case(state)
            POWER_OFF:
              begin
                state <= (power_on) ? PONS_DELAY : state;
              end
            PONS_DELAY:
              begin
                state <= (delay_done) ? RESET : state;
              end
            RESET:
              begin
                state <= (delay_done) ?  POST_RESET : state;
              end
            POST_RESET:
              begin
                state <= (delay_done) ?  PONS_DIS_OFF : state;
              end
            PONS_DIS_OFF:
              begin
                state <= (spi_done) ? PONS_DIS_WAIT : state;
              end
            PONS_DIS_WAIT:
              begin
                state <= (delay_done) ? PONS_INIT_DIS : state;
              end
            PONS_INIT_DIS:
              begin
                state <= (spi_done) ? PONS_INIT_WAIT : state;
              end
            PONS_INIT_WAIT:
              begin
                state <= (delay_done) ? DISPLAY_OFF : state;
              end
            CH_DISPLAY:
              begin
                state <= (spi_done) ? ((~power_on | display_off_reg) ? DISPLAY_OFF : IDLE): state;
              end
            CH_CONTRAST:
              begin
                state <= (spi_done) ? ((display_off_reg) ? DISPLAY_OFF : IDLE): state;
              end
            UPDATE:
              begin
                state <= (spi_done) ? ((display_off_reg) ? DISPLAY_OFF : IDLE): state;
              end
            POFFS_DELAY:
              begin
                state <= (delay_done) ?  POWER_OFF : state;
              end
            WRITE_ADDRS:
              begin
                state <= (spi_done) ?  UPDATE : state;
              end
            IDLE:
              begin
                if(display_reset_reg)
                  begin
                    state <= RESET;
                  end
                else if(~power_on | display_off)
                  begin
                    state <= CH_DISPLAY;
                  end
                else if(ch_contrast)
                  begin
                    state <= CH_CONTRAST;
                  end
                else if(update_reg | cursor_update)
                  begin
                    state <= WRITE_ADDRS;
                  end
              end
            DISPLAY_OFF:
              begin
                if(display_reset_reg)
                  begin
                    state <= RESET;
                  end
                else if(~power_on)
                  begin
                    state <= POFFS_DELAY;
                  end
                else if(~display_off)
                  begin
                    state <= CH_DISPLAY;
                  end
                else if(ch_contrast)
                  begin
                    state <= CH_CONTRAST;
                  end
                else if(update_reg)
                  begin
                    state <= WRITE_ADDRS;
                  end
              end
          endcase
        end
    end
  
  //Clk domain change for inputs
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          display_reset_reg <= 1'b0;
          update_reg <= 1'b0;
        end
      else
        begin
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
    begin
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

  always@(negedge spi_clk)
    begin
      if(send_buffer_write)
        begin
          send_buffer <= send_buffer_next;
        end
      else
        begin
          send_buffer <= (send_buffer_shift) ? {send_buffer[6:0],send_buffer[0]} : send_buffer;
        end
    end

  //Byte counter
  assign {current_line, position_in_line} = byte_counter[8:3];
  always@(negedge ext_spi_clk)
    begin
      if(~spi_working)
        begin
          byte_counter <= 9'h0;
        end
      else
        begin
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
  
  always@(negedge ext_spi_clk or posedge rst)
    begin
      if(rst)
        begin
          bit_counter <= 3'd0;
        end
      else
        begin
          bit_counter <= bit_counter + {2'd0, spi_working & spi_clk};
        end
    end

  //Delay Signals and edge detect
  assign inChContrast_posedge = ~inChContrast_d & inChContrast;
  always@(posedge clk)
    begin
      inChContrast_d <= inChContrast;
      state_d <= state;
    end
  
  //Store Signals & Configs
  always@(posedge clk)
    begin
      if(rst | inReset) begin
          contrast_reg <= 8'h7F;
      end else begin
          contrast_reg <= (inChContrast_posedge) ? contrast : contrast_reg;
      end
    end
  always@(posedge clk)
    begin
      display_off_reg <= (inIdle | inPowerOff | inDisplayOff) ? display_off : display_off_reg;
    end
  
  //Determine data index
  always@*
    case(line_count)
      2'd3:
        begin
          data_index = {current_line,position_in_line};
        end
      2'd2:
        case(current_line)
          2'd3: data_index = {2'd2,position_in_line};
          2'd0: data_index = {2'd0,position_in_line};
          default: data_index = {2'd1,position_in_line};
        endcase
      2'd1:
        begin
          data_index = {1'b0, current_line[1],position_in_line};
        end
      2'd0:
        begin
          data_index = {2'd0,position_in_line};
        end
    endcase

  //Change flags
  assign ch_contrast = (contrast_reg != contrast);

  //Generate spi clock
  always@(posedge ext_spi_clk or posedge rst)
    begin
      if(rst)
        begin
          spi_clk <= 1'b1;
        end
      else
        begin
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
  
  always@(posedge clk)
    begin
      if(delay_done | rst)
        begin
          delay_counter <= {COUNTER_SIZE+1{1'b0}};
        end
      else
        begin
          delay_counter <= delay_counter + {{COUNTER_SIZE{1'b0}},delaying};
        end
    end
  always@(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          delay_done <= 1'b0;
        end
      else
        begin
          case(delay_done)
            1'b0: delay_done <= delay_count_done;
            1'b1: delay_done <= (state_d == state); //Delay done when we change state
          endcase
        end
    end

  //Cursor control
  assign current_colmn = (cursor_enable & cursor_flash_on & cursor_in_pos) ?  ~current_colmn_pre :  current_colmn_pre; //Default cursor inverts char, thus implemented by inverting column. For more advenced cursorsors current_bitmap can be edited
  assign cursor_in_pos = (cursor_pos_reg == {current_line,position_in_line});
  assign cursor_flash_on = ~cursor_flash | cursor_counter[CURSOR_COUNTER_SIZE];
  always@(posedge clk or posedge rst) //Store cursor configs
    begin
      if(rst)
        begin
          cursor_pos_reg <= 6'd0;
          cursor_flash_mode  <= 1'd0;
          cursor_enable_reg  <= 1'd0;
        end
      else
        begin
          cursor_pos_reg <= (cursor_update & inUpdate) ? cursor_pos : cursor_pos_reg;
          cursor_flash_mode <= (cursor_update & inUpdate) ? cursor_counter[CURSOR_COUNTER_SIZE] : cursor_flash_mode;
          cursor_enable_reg <= (cursor_update & inUpdate) ? cursor_enable : cursor_enable_reg;
        end
    end
  always@(posedge clk or posedge rst) //Cursor counter
    begin
      if(rst)
        begin
          cursor_counter <= {(CURSOR_COUNTER_SIZE+1){1'b0}}; 
        end
      else
        begin
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

//* Pmod OLED driver which uses a 128 x 32 bitmap
module oled_raw#(parameter CLK_PERIOD = 10)( //TODO
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
  input update,
  /*
   * display_data pixel addresses
   *  | 4095 | 4094 | ... | 3968 |
   *  | 3967 | ...           :   |
   *  |  :                | 128  |
   *  | 127  | ...  |  1  |  0   |
   */
  input [4095:0] display_data);
  //TODO
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

/* ------------------------------------- *
 *            | row0 |
 *  8x8 char: |   :  |
 *            | row7 |
 * decoded_bitmap = {row0,row1,...,row7}
 * ------------------------------------- */
//* Converts a 8 bit code in to 8x8 bit array with ilimunated pixels high
module oled_decoder(
  input [7:0] character_code,
  output reg [63:0] decoded_bitmap);
  localparam    space = 8'h00,
          exclamation = 8'h01,
                 quot = 8'h02,
             hash_tag = 8'h03,
               dollar = 8'h04,
              percent = 8'h05,
            ampersand = 8'h06,
           apostrophe = 8'h07,
     parenthesis_open = 8'h08,
    parenthesis_close = 8'h09,
              asterix = 8'h0a,
                 plus = 8'h0b,
                comma = 8'h0c,
                minus = 8'h0d,
                  dot = 8'h0e,
                slash = 8'h0f,
                 zero = 8'h10,
                  one = 8'h11,
                  two = 8'h12,
                three = 8'h13,
                 four = 8'h14,
                 five = 8'h15,
                  six = 8'h16,
                seven = 8'h17,
                eight = 8'h18,
                 nine = 8'h19,
                colon = 8'h1a,
           semi_colon = 8'h1b,
          little_than = 8'h1c,
                equal = 8'h1d,
         greater_than = 8'h1e,
             question = 8'h1f,
              at_sign = 8'h20,
                A_cap = 8'h21,
                B_cap = 8'h22,
                C_cap = 8'h23,
                D_cap = 8'h24,
                E_cap = 8'h25,
                F_cap = 8'h26,
                G_cap = 8'h27,
                H_cap = 8'h28,
                I_cap = 8'h29,
                J_cap = 8'h2a,
                K_cap = 8'h2b,
                L_cap = 8'h2c,
                M_cap = 8'h2d,
                N_cap = 8'h2e,
                O_cap = 8'h2f,
                P_cap = 8'h30,
                Q_cap = 8'h31,
                R_cap = 8'h32,
                S_cap = 8'h33,
                T_cap = 8'h34,
                U_cap = 8'h35,
                V_cap = 8'h36,
                W_cap = 8'h37,
                X_cap = 8'h38,
                Y_cap = 8'h39,
                Z_cap = 8'h3a,
       square_br_open = 8'h3b,
            backslash = 8'h3c,
      square_br_close = 8'h3d,
                  hat = 8'h3e,
           underscore = 8'h3f,
            grave_acc = 8'h40,
                a_low = 8'h41,
                b_low = 8'h42,
                c_low = 8'h43,
                d_low = 8'h44,
                e_low = 8'h45,
                f_low = 8'h46,
                g_low = 8'h47,
                h_low = 8'h48,
                i_low = 8'h49,
                j_low = 8'h4a,
                k_low = 8'h4b,
                l_low = 8'h4c,
                m_low = 8'h4d,
                n_low = 8'h4e,
                o_low = 8'h4f,
                p_low = 8'h50,
                q_low = 8'h51,
                r_low = 8'h52,
                s_low = 8'h53,
                t_low = 8'h54,
                u_low = 8'h55,
                v_low = 8'h56,
                w_low = 8'h57,
                x_low = 8'h58,
                y_low = 8'h59,
                z_low = 8'h5a,
           curly_open = 8'h5b,
                v_bar = 8'h5c,
          curly_close = 8'h5d,
                tilde = 8'h5e,
               big_sq = 8'h5f,
                 euro = 8'h60,
                degre = 8'h61,
            softG_cap = 8'h62,
              Ind_cap = 8'h63,
             Udot_cap = 8'h64,
             Odot_cap = 8'h65,
              Aum_cap = 8'h66,
               Ch_cap = 8'h67,
              Sch_cap = 8'h68,
             Ahat_cap = 8'h69,
            softG_low = 8'h6a,
              Ind_low = 8'h6b,
             Udot_low = 8'h6c,
             Odot_low = 8'h6d,
              Aum_low = 8'h6e,
               Ch_low = 8'h6f,
              Sch_low = 8'h70,
             Ahat_low = 8'h71,
                   tm = 8'h72,
                pound = 8'h73,
               plusmn = 8'h74,
                micro = 8'h75,
               divide = 8'h76,
               hearth = 8'h77,
                happy = 8'h78,
              natural = 8'h79,
                  sad = 8'h7a,
               approx = 8'h7b,
                   pi = 8'h7c,
          arrow_right = 8'h7d,
           arrow_down = 8'h7e,
           arrow_left = 8'h7f,
             arrow_up = 8'h80,
             arrow_lr = 8'h81,
             arrow_ud = 8'h82,
             arrow_lu = 8'h83,
             arrow_ld = 8'h84,
             arrow_ru = 8'h85,
             arrow_rd = 8'h86,
            not_equal = 8'h87,
              p_bar_1 = 8'h88,
              p_bar_2 = 8'h89,
              p_bar_3 = 8'h8a,
              p_bar_4 = 8'h8b,
              p_bar_5 = 8'h8c,
              p_bar_6 = 8'h8d,
              p_bar_7 = 8'h8e,
              p_bar_8 = 8'h8f,
               stick0 = 8'h90,
              stick45 = 8'h91,
              stick90 = 8'h92,
             stick135 = 8'h93,
               anchor = 8'h94,
             sailboat = 8'h95,
                 play = 8'h96,
                pause = 8'h97,
          suit_hearth = 8'h98,
         suit_diamond = 8'h99,
             suit_cub = 8'h9a,
           suit_spade = 8'h9b;

  always@*
    /* 
     * character_code = {row0[7:0], row1[7:0], ... , row7[7:0]}
     * where row0 is the top row and row7 is the bottom row
     * rowN = {pix0, pix1, ..., pix7}
     * where pix0 is the leftmost pixel and pix7 is the rightmost pixel
     */
    case(character_code)
      suit_spade: decoded_bitmap = /* suit_spade */ {8'h0, 8'h8, 8'h1c, 8'h3e, 8'h7f, 8'h3e, 8'h8, 8'h1c};
      suit_cub: decoded_bitmap = /* suit_cub */ {8'h0, 8'h8, 8'h1c, 8'h2a, 8'h7f, 8'h2a, 8'h8, 8'h1c};
      suit_diamond: decoded_bitmap = /* suit_diamond */ {8'h0, 8'h0, 8'h8, 8'h1c, 8'h3e, 8'h1c, 8'h8, 8'h0};
      suit_hearth: decoded_bitmap = /* suit_hearth */ {8'h0, 8'h22, 8'h77, 8'h7f, 8'h3e, 8'h1c, 8'h8, 8'h0};
      pause: decoded_bitmap = /* pause */ {8'h0, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h0};
      play: decoded_bitmap = /* play */ {8'h0, 8'h40, 8'h70, 8'h7c, 8'h7e, 8'h7c, 8'h70, 8'h40};
      sailboat: decoded_bitmap = /* sailboat / */ {8'h10, 8'h18, 8'h1c, 8'h1e, 8'h1f, 8'h10, 8'hff, 8'h7e};
      anchor: decoded_bitmap = /* anchor / */ {8'h10, 8'h28, 8'h10, 8'h38, 8'h10, 8'h92, 8'h54, 8'h38};
      stick135: decoded_bitmap = /* thick / */ {8'h3, 8'h7, 8'he, 8'h1c, 8'h38, 8'h70, 8'he0, 8'hc0};
      stick90: decoded_bitmap = /* thick | */ {8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18};
      stick45: decoded_bitmap = /* thick \ */ {8'hc0, 8'he0, 8'h70, 8'h38, 8'h1c, 8'he, 8'h7, 8'h3};
      stick0: decoded_bitmap = /* thick - */ {8'h0, 8'h0, 8'h0, 8'hff, 8'hff, 8'h0, 8'h0, 8'h0};
      p_bar_8: decoded_bitmap = /* p_bar */ {8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff};
      p_bar_7: decoded_bitmap = /* p_bar */ {8'hfe, 8'hfe, 8'hfe, 8'hfe, 8'hfe, 8'hfe, 8'hfe, 8'hfe};
      p_bar_6: decoded_bitmap = /* p_bar */ {8'hfc, 8'hfc, 8'hfc, 8'hfc, 8'hfc, 8'hfc, 8'hfc, 8'hfc};
      p_bar_5: decoded_bitmap = /* p_bar */ {8'hf8, 8'hf8, 8'hf8, 8'hf8, 8'hf8, 8'hf8, 8'hf8, 8'hf8};
      p_bar_4: decoded_bitmap = /* p_bar */ {8'hf0, 8'hf0, 8'hf0, 8'hf0, 8'hf0, 8'hf0, 8'hf0, 8'hf0};
      p_bar_3: decoded_bitmap = /* p_bar */ {8'he0, 8'he0, 8'he0, 8'he0, 8'he0, 8'he0, 8'he0, 8'he0};
      p_bar_2: decoded_bitmap = /* p_bar */ {8'hc0, 8'hc0, 8'hc0, 8'hc0, 8'hc0, 8'hc0, 8'hc0, 8'hc0};
      p_bar_1: decoded_bitmap = /* p_bar */ {8'h80, 8'h80, 8'h80, 8'h80, 8'h80, 8'h80, 8'h80, 8'h80};
      not_equal: decoded_bitmap = /* ≠ */ {8'h0, 8'h0, 8'h8, 8'h7c, 8'h10, 8'h7c, 8'h20, 8'h0};
      arrow_rd: decoded_bitmap = /* ↘ */ {8'h80, 8'h40, 8'h20, 8'h10, 8'h9, 8'h5, 8'h3, 8'h1f};
      arrow_ld: decoded_bitmap = /* ↙ */ {8'h1, 8'h2, 8'h4, 8'h88, 8'h90, 8'ha0, 8'hc0, 8'hf0};
      arrow_ru: decoded_bitmap = /* ↗ */ {8'hf, 8'h3, 8'h5, 8'h9, 8'h11, 8'h20, 8'h40, 8'h80};
      arrow_lu: decoded_bitmap = /* ↖ */ {8'hf8, 8'hc0, 8'ha0, 8'h90, 8'h8, 8'h4, 8'h2, 8'h1};
      arrow_ud: decoded_bitmap = /* ↕ */ {8'h10, 8'h38, 8'h54, 8'h10, 8'h10, 8'h54, 8'h38, 8'h10};
      arrow_lr: decoded_bitmap = /* ↔ */ {8'h0, 8'h0, 8'h24, 8'h42, 8'hff, 8'h42, 8'h24, 8'h0};
      pi: decoded_bitmap = /* π */ {8'h0, 8'h0, 8'h0, 8'h7e, 8'h24, 8'h24, 8'h22, 8'h0};
      arrow_up: decoded_bitmap = /* ↑ */ {8'h10, 8'h38, 8'h54, 8'h10, 8'h10, 8'h10, 8'h10, 8'h10};
      arrow_left: decoded_bitmap = /* ← */ {8'h0, 8'h0, 8'h20, 8'h40, 8'hff, 8'h40, 8'h20, 8'h0};
      arrow_down: decoded_bitmap = /* ↓ */ {8'h10, 8'h10, 8'h10, 8'h10, 8'h10, 8'h54, 8'h38, 8'h10};
      arrow_right: decoded_bitmap = /* → */ {8'h0, 8'h0, 8'h4, 8'h2, 8'hff, 8'h2, 8'h4, 8'h0};
      approx: decoded_bitmap = /* ≈ */ {8'h0, 8'h0, 8'h32, 8'h4c, 8'h0, 8'h32, 8'h4c, 8'h0};
      sad: decoded_bitmap = /* :( */ {8'h0, 8'h0, 8'h24, 8'h0, 8'h0, 8'h3c, 8'h42, 8'h0};
      natural: decoded_bitmap = /* :| */ {8'h0, 8'h0, 8'h24, 8'h0, 8'h0, 8'h3c, 8'h0, 8'h0};
      happy: decoded_bitmap = /* :) */ {8'h0, 8'h0, 8'h24, 8'h0, 8'h42, 8'h3c, 8'h0, 8'h0};
      hearth: decoded_bitmap = /* <3 */ {8'h0, 8'h0, 8'h66, 8'hff, 8'h7e, 8'h3c, 8'h18, 8'h0};
      divide: decoded_bitmap = /* ÷ */ {8'h0, 8'h0, 8'h10, 8'h0, 8'h7c, 8'h0, 8'h10, 8'h0};
      micro: decoded_bitmap = /* µ */ {8'h0, 8'h0, 8'h0, 8'h44, 8'h44, 8'h64, 8'h5a, 8'h40};
      plusmn: decoded_bitmap = /* ± */ {8'h10, 8'h10, 8'h7c, 8'h10, 8'h10, 8'h0, 8'h7c, 8'h0};
      pound: decoded_bitmap = /* £ */ {8'h38, 8'h44, 8'h40, 8'h48, 8'hf0, 8'h42, 8'hfc, 8'h0};
      tm: decoded_bitmap = /* ™ */ {8'hfb, 8'h55, 8'h51, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0};
      Ahat_low: decoded_bitmap = /* â */ {8'h8, 8'h14, 8'h1c, 8'h2, 8'h1a, 8'h26, 8'h1a, 8'h0};
      Sch_low: decoded_bitmap = /* ş */ {8'h0, 8'h0, 8'h1c, 8'h20, 8'h1c, 8'h2, 8'h1c, 8'h8};
      Ch_low: decoded_bitmap = /* ç */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h1c, 8'h20, 8'h1c, 8'h8};
      Aum_low: decoded_bitmap = /* ä */ {8'h14, 8'h0, 8'h1c, 8'h2, 8'h1a, 8'h26, 8'h1a, 8'h0};
      Odot_low: decoded_bitmap = /* ö */ {8'h0, 8'h24, 8'h0, 8'h18, 8'h24, 8'h24, 8'h18, 8'h0};
      Udot_low: decoded_bitmap = /* ü */ {8'h0, 8'h0, 8'h28, 8'h0, 8'h28, 8'h28, 8'h18, 8'h0};
      Ind_low: decoded_bitmap = /* ı */ {8'h0, 8'h0, 8'h0, 8'h38, 8'h10, 8'h10, 8'h38, 8'h0};
      softG_low: decoded_bitmap = /* ğ */ {8'h24, 8'h18, 8'h0, 8'h18, 8'h24, 8'h1c, 8'h4, 8'h18};
      Ahat_cap: decoded_bitmap = /* Â */ {8'h3c, 8'h0, 8'h3c, 8'h42, 8'h7e, 8'h42, 8'h42, 8'h0};
      Sch_cap: decoded_bitmap = /* Ş */ {8'h3c, 8'h42, 8'h40, 8'h3c, 8'h2, 8'h3c, 8'h8, 8'h18};
      Ch_cap: decoded_bitmap = /* Ç */ {8'h3c, 8'h42, 8'h40, 8'h40, 8'h42, 8'h3c, 8'h8, 8'h18};
      Aum_cap: decoded_bitmap = /* Ä */ {8'h42, 8'h18, 8'h24, 8'h42, 8'h7e, 8'h42, 8'h42, 8'h0};
      Odot_cap: decoded_bitmap = /* Ö */ {8'h42, 8'h0, 8'h3c, 8'h42, 8'h42, 8'h42, 8'h3c, 8'h0};
      Udot_cap: decoded_bitmap = /* Ü */ {8'h42, 8'h0, 8'h42, 8'h42, 8'h42, 8'h42, 8'h3c, 8'h0};
      Ind_cap: decoded_bitmap = /* İ */ {8'h10, 8'h0, 8'h38, 8'h10, 8'h10, 8'h10, 8'h38, 8'h0};
      softG_cap: decoded_bitmap = /* Ğ */ {8'h38, 8'h3c, 8'h44, 8'h40, 8'h5c, 8'h44, 8'h3c, 8'h0};
      degre: decoded_bitmap = /* ° */ {8'h20, 8'h50, 8'h20, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0};
      euro: decoded_bitmap = /* € */ {8'h1c, 8'h22, 8'h20, 8'h78, 8'h20, 8'h78, 8'h22, 8'h1c};
      big_sq: decoded_bitmap = /* Square */ {8'hff, 8'hff, 8'hc3, 8'hc3, 8'hc3, 8'hc3, 8'hff, 8'hff};
      tilde: decoded_bitmap = /* ~ */ {8'h0, 8'h0, 8'h0, 8'h32, 8'h4c, 8'h0, 8'h0, 8'h0};
      curly_close: decoded_bitmap = /* } */ {8'h0, 8'h30, 8'h8, 8'h8, 8'h4, 8'h8, 8'h8, 8'h30};
      v_bar: decoded_bitmap = /* | */ {8'h0, 8'h8, 8'h8, 8'h8, 8'h8, 8'h8, 8'h8, 8'h0};
      curly_open: decoded_bitmap = /* { */ {8'h0, 8'hc, 8'h10, 8'h10, 8'h20, 8'h10, 8'h10, 8'hc};
      z_low: decoded_bitmap = /* z */ {8'h0, 8'h0, 8'h0, 8'h3c, 8'h8, 8'h10, 8'h3c, 8'h0};
      y_low: decoded_bitmap = /* y */ {8'h0, 8'h0, 8'h0, 8'h14, 8'h14, 8'hc, 8'h4, 8'h8};
      x_low: decoded_bitmap = /* x */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h28, 8'h10, 8'h28, 8'h0};
      w_low: decoded_bitmap = /* w */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h44, 8'h54, 8'h28, 8'h0};
      v_low: decoded_bitmap = /* v */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h28, 8'h28, 8'h10, 8'h0};
      u_low: decoded_bitmap = /* u */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h28, 8'h28, 8'h18, 8'h0};
      t_low: decoded_bitmap = /* t */ {8'h20, 8'h20, 8'h70, 8'h20, 8'h20, 8'h24, 8'h18, 8'h0};
      s_low: decoded_bitmap = /* s */ {8'h0, 8'h0, 8'h38, 8'h40, 8'h30, 8'h8, 8'h70, 8'h0};
      r_low: decoded_bitmap = /* r */ {8'h0, 8'h0, 8'h0, 8'h28, 8'h34, 8'h20, 8'h20, 8'h0};
      q_low: decoded_bitmap = /* q */ {8'h0, 8'h0, 8'h0, 8'h14, 8'h2c, 8'h14, 8'h4, 8'h4};
      p_low: decoded_bitmap = /* p */ {8'h0, 8'h0, 8'h0, 8'h28, 8'h34, 8'h28, 8'h20, 8'h20};
      o_low: decoded_bitmap = /* o */ {8'h0, 8'h0, 8'h0, 8'h18, 8'h24, 8'h24, 8'h18, 8'h0};
      n_low: decoded_bitmap = /* n */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h30, 8'h28, 8'h6c, 8'h0};
      m_low: decoded_bitmap = /* m */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h34, 8'h2a, 8'h6b, 8'h0};
      l_low: decoded_bitmap = /* l */ {8'h30, 8'h10, 8'h10, 8'h10, 8'h10, 8'h10, 8'h8, 8'h0};
      k_low: decoded_bitmap = /* k */ {8'h70, 8'h20, 8'h24, 8'h28, 8'h30, 8'h28, 8'h66, 8'h0};
      j_low: decoded_bitmap = /* j */ {8'h0, 8'h8, 8'h0, 8'h8, 8'h8, 8'h8, 8'h48, 8'h30};
      i_low: decoded_bitmap = /* i */ {8'h0, 8'h10, 8'h0, 8'h38, 8'h10, 8'h10, 8'h38, 8'h0};
      h_low: decoded_bitmap = /* h */ {8'h60, 8'h20, 8'h20, 8'h38, 8'h24, 8'h24, 8'h66, 8'h0};
      g_low: decoded_bitmap = /* g */ {8'h0, 8'h0, 8'h0, 8'h18, 8'h24, 8'h1c, 8'h44, 8'h38};
      f_low: decoded_bitmap = /* f */ {8'h0, 8'h0, 8'h8, 8'h14, 8'h10, 8'h38, 8'h10, 8'h38};
      e_low: decoded_bitmap = /* e */ {8'h0, 8'h0, 8'h1c, 8'h24, 8'h3c, 8'h20, 8'h18, 8'h0};
      d_low: decoded_bitmap = /* d */ {8'h2, 8'h2, 8'h2, 8'h1a, 8'h26, 8'h26, 8'h1a, 8'h0};
      c_low: decoded_bitmap = /* c */ {8'h0, 8'h0, 8'h0, 8'h18, 8'h20, 8'h20, 8'h18, 8'h0};
      b_low: decoded_bitmap = /* b */ {8'h20, 8'h20, 8'h20, 8'h2c, 8'h32, 8'h32, 8'h2c, 8'h0};
      a_low: decoded_bitmap = /* a */ {8'h0, 8'h0, 8'h1c, 8'h2, 8'h1a, 8'h26, 8'h1a, 8'h0};
      grave_acc: decoded_bitmap = /* ` */ {8'h20, 8'h10, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0};
      underscore: decoded_bitmap = /* _ */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h7e, 8'h0};
      hat: decoded_bitmap = /* ^ */ {8'h0, 8'h0, 8'h10, 8'h28, 8'h44, 8'h0, 8'h0, 8'h0};
      square_br_close: decoded_bitmap = /* ] */ {8'h0, 8'h38, 8'h8, 8'h8, 8'h8, 8'h8, 8'h38, 8'h0};
      backslash: decoded_bitmap = /* \ */ {8'h0, 8'h40, 8'h20, 8'h10, 8'h8, 8'h4, 8'h2, 8'h0};
      square_br_open: decoded_bitmap = /* [ */ {8'h0, 8'h1c, 8'h10, 8'h10, 8'h10, 8'h10, 8'h1c, 8'h0};
      Z_cap: decoded_bitmap = /* Z */ {8'h7e, 8'h42, 8'h4, 8'h8, 8'h10, 8'h22, 8'h7e, 8'h0};
      Y_cap: decoded_bitmap = /* Y */ {8'hc6, 8'h44, 8'h28, 8'h10, 8'h10, 8'h10, 8'h10, 8'h0};
      X_cap: decoded_bitmap = /* X */ {8'hc6, 8'h44, 8'h28, 8'h10, 8'h28, 8'h44, 8'hc6, 8'h0};
      W_cap: decoded_bitmap = /* W */ {8'hee, 8'h44, 8'h44, 8'h44, 8'h54, 8'h54, 8'h28, 8'h0};
      V_cap: decoded_bitmap = /* V */ {8'he7, 8'h42, 8'h42, 8'h24, 8'h24, 8'h24, 8'h18, 8'h0};
      U_cap: decoded_bitmap = /* U */ {8'h42, 8'h42, 8'h42, 8'h42, 8'h42, 8'h42, 8'h3c, 8'h0};
      T_cap: decoded_bitmap = /* T */ {8'hfe, 8'h92, 8'h10, 8'h10, 8'h10, 8'h10, 8'h38, 8'h0};
      S_cap: decoded_bitmap = /* S */ {8'h3c, 8'h42, 8'h40, 8'h40, 8'h3c, 8'h2, 8'h42, 8'h3c};
      R_cap: decoded_bitmap = /* R */ {8'h38, 8'h24, 8'h24, 8'h38, 8'h28, 8'h24, 8'h76, 8'h0};
      Q_cap: decoded_bitmap = /* Q */ {8'h38, 8'h44, 8'h44, 8'h44, 8'h44, 8'h44, 8'h38, 8'h6};
      P_cap: decoded_bitmap = /* P */ {8'h38, 8'h24, 8'h24, 8'h38, 8'h20, 8'h20, 8'h70, 8'h0};
      O_cap: decoded_bitmap = /* O */ {8'h3c, 8'h42, 8'h42, 8'h42, 8'h42, 8'h42, 8'h3c, 8'h0};
      N_cap: decoded_bitmap = /* N */ {8'h47, 8'h62, 8'h52, 8'h5a, 8'h4a, 8'h46, 8'he2, 8'h0};
      M_cap: decoded_bitmap = /* M */ {8'h42, 8'h66, 8'h5a, 8'h42, 8'h42, 8'h42, 8'he7, 8'h0};
      L_cap: decoded_bitmap = /* L */ {8'h40, 8'h40, 8'h40, 8'h40, 8'h40, 8'h40, 8'h7c, 8'h0};
      K_cap: decoded_bitmap = /* K */ {8'h44, 8'h48, 8'h50, 8'h60, 8'h50, 8'h48, 8'h44, 8'h0};
      J_cap: decoded_bitmap = /* J */ {8'h18, 8'h8, 8'h8, 8'h8, 8'h8, 8'h48, 8'h30, 8'h0};
      I_cap: decoded_bitmap = /* I */ {8'h38, 8'h10, 8'h10, 8'h10, 8'h10, 8'h10, 8'h38, 8'h0};
      H_cap: decoded_bitmap = /* H */ {8'h44, 8'h44, 8'h44, 8'h7c, 8'h44, 8'h44, 8'h44, 8'h0};
      G_cap: decoded_bitmap = /* G */ {8'h38, 8'h44, 8'h40, 8'h5c, 8'h44, 8'h44, 8'h3c, 8'h0};
      F_cap: decoded_bitmap = /* F */ {8'h7c, 8'h40, 8'h40, 8'h7c, 8'h40, 8'h40, 8'h40, 8'h0};
      E_cap: decoded_bitmap = /* E */ {8'h7c, 8'h40, 8'h40, 8'h7c, 8'h40, 8'h40, 8'h7c, 8'h0};
      D_cap: decoded_bitmap = /* D */ {8'h7c, 8'h42, 8'h42, 8'h42, 8'h42, 8'h42, 8'h7c, 8'h0};
      C_cap: decoded_bitmap = /* C */ {8'h3c, 8'h42, 8'h40, 8'h40, 8'h40, 8'h42, 8'h3c, 8'h0};
      B_cap: decoded_bitmap = /* B */ {8'h78, 8'h44, 8'h44, 8'h78, 8'h44, 8'h44, 8'h78, 8'h0};
      A_cap: decoded_bitmap = /* A */ {8'h18, 8'h24, 8'h42, 8'h7e, 8'h42, 8'h42, 8'he7, 8'h0};
      colon: decoded_bitmap = /* : */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h10, 8'h0, 8'h10, 8'h0};
      semi_colon: decoded_bitmap = /* ; */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h10, 8'h0, 8'h10, 8'h20};
      little_than: decoded_bitmap = /* < */ {8'h0, 8'h0, 8'h6, 8'h18, 8'h60, 8'h18, 8'h6, 8'h0};
      equal: decoded_bitmap = /* = */ {8'h0, 8'h0, 8'h0, 8'h3c, 8'h0, 8'h3c, 8'h0, 8'h0};
      greater_than: decoded_bitmap = /* > */ {8'h0, 8'h0, 8'h60, 8'h18, 8'h6, 8'h18, 8'h60, 8'h0};
      question: decoded_bitmap = /* ? */ {8'h1c, 8'h22, 8'h2, 8'h4, 8'h8, 8'h0, 8'h8, 8'h0};
      at_sign: decoded_bitmap = /* @ */ {8'h0, 8'h1c, 8'h22, 8'h4a, 8'h56, 8'h4e, 8'h20, 8'h18};
      space: decoded_bitmap = /* Space */ {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
      exclamation: decoded_bitmap = /*   !   */ {8'h00,8'h10,8'h10,8'h10,8'h10,8'h00,8'h10,8'h00};
      quot: decoded_bitmap = /*   "   */ {8'h28,8'h28,8'h28,8'h00,8'h00,8'h00,8'h00,8'h00};
      hash_tag: decoded_bitmap = /*   #   */ {8'h24,8'h24,8'hff,8'h24,8'h24,8'hff,8'h24,8'h24};
      dollar: decoded_bitmap = /*   $   */ {8'h08, 8'h1c, 8'h2a, 8'h28, 8'h1c, 8'h0a, 8'h2a, 8'h1c};
      percent: decoded_bitmap = /*   %   */ {8'h60, 8'h92, 8'h64, 8'h08, 8'h10, 8'h26, 8'h49, 8'h06};
      ampersand: decoded_bitmap = /*   &   */ {8'h00,8'h18,8'h24,8'h24,8'h18,8'h2a,8'h24,8'h1a};
      apostrophe: decoded_bitmap = /*   '   */ {8'h08,8'h08,8'h08,8'h00,8'h00,8'h00,8'h00,8'h00};
      parenthesis_open: decoded_bitmap = /*   (   */ {8'h00,8'h08,8'h10,8'h10,8'h10,8'h10,8'h08,8'h00};
      parenthesis_close: decoded_bitmap = /*   )   */ {8'h00,8'h10,8'h08,8'h08,8'h08,8'h08,8'h10,8'h00};
      asterix: decoded_bitmap = /*   *   */ {8'h0, 8'h0, 8'h10, 8'h54, 8'h38, 8'h54, 8'h10, 8'h0};
      plus: decoded_bitmap = /*   +   */ {8'h0, 8'h0, 8'h8, 8'h8, 8'h3e, 8'h8, 8'h8, 8'h0};
      comma: decoded_bitmap = /*   ,   */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h8, 8'h18};
      minus: decoded_bitmap = /*   -   */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h3c, 8'h0, 8'h0, 8'h0};
      dot: decoded_bitmap = /*   .   */ {8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h10, 8'h0};
      slash: decoded_bitmap = /*   /   */ {8'h0, 8'h4, 8'h8, 8'h8, 8'h10, 8'h10, 8'h20, 8'h0};
      zero: decoded_bitmap = /*   0   */ {8'h3c, 8'h42, 8'h62, 8'h52, 8'h4a, 8'h46, 8'h42, 8'h3c};
      one: decoded_bitmap = /*   1   */ {8'h18, 8'h28, 8'h8, 8'h8, 8'h8, 8'h8, 8'h8, 8'h3e};
      two: decoded_bitmap = /*   2   */ {8'h3c, 8'h42, 8'h2, 8'h4, 8'h8, 8'h10, 8'h20, 8'h7e};
      three: decoded_bitmap = /*   3   */ {8'h3c, 8'h42, 8'h2, 8'h6, 8'h3c, 8'h6, 8'h42, 8'h3c};
      four: decoded_bitmap = /*   4   */ {8'h4, 8'hc, 8'h14, 8'h24, 8'h44, 8'h7e, 8'h4, 8'h4};
      five: decoded_bitmap = /*   5   */ {8'h7e, 8'h40, 8'h40, 8'h7c, 8'h2, 8'h2, 8'h2, 8'h7c};
      six: decoded_bitmap = /*   6   */ {8'h3c, 8'h42, 8'h40, 8'h5c, 8'h62, 8'h42, 8'h42, 8'h3c};
      seven: decoded_bitmap = /*   7   */ {8'h7e, 8'h2, 8'h2, 8'h4, 8'h8, 8'h10, 8'h20, 8'h40};
      eight: decoded_bitmap = /*   8   */ {8'h3c, 8'h42, 8'h42, 8'h42, 8'h3c, 8'h42, 8'h42, 8'h3c};
      nine: decoded_bitmap = /*   9   */ {8'h3c, 8'h42, 8'h42, 8'h46, 8'h3a, 8'h2, 8'h42, 8'h3c};
      default: decoded_bitmap = 64'h0;
    endcase
endmodule
