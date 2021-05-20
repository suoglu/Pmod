/* ------------------------------------------------ *
 * Title       : Pmod OLED interface v1.0           *
 * Project     : Pmod Collection                    *
 * ------------------------------------------------ *
 * File        : oled.v                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 20/05/2021                         *
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
  always@*
    begin
      case(line_count)
         2'd3: //4 lines
          begin
           cursor_in_pos = (cursor_pos_reg == {current_line,position_in_line});
          end
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
    end
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
module oled_bitmap#(parameter CLK_PERIOD = 10)( //TODO
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
   * display_data pixel addresses
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
                else if(update_reg)
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
          send_buffer_next = column_array[byte_counter];
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

  //Map bitmap into column_array
  always@* //Inside of this always generated automatically
    begin
      column_array[0] = bitmap[4095:4088];
      column_array[1] = bitmap[4087:4080];
      column_array[2] = bitmap[4079:4072];
      column_array[3] = bitmap[4071:4064];
      column_array[4] = bitmap[4063:4056];
      column_array[5] = bitmap[4055:4048];
      column_array[6] = bitmap[4047:4040];
      column_array[7] = bitmap[4039:4032];
      column_array[8] = bitmap[4031:4024];
      column_array[9] = bitmap[4023:4016];
      column_array[10] = bitmap[4015:4008];
      column_array[11] = bitmap[4007:4000];
      column_array[12] = bitmap[3999:3992];
      column_array[13] = bitmap[3991:3984];
      column_array[14] = bitmap[3983:3976];
      column_array[15] = bitmap[3975:3968];
      column_array[16] = bitmap[3967:3960];
      column_array[17] = bitmap[3959:3952];
      column_array[18] = bitmap[3951:3944];
      column_array[19] = bitmap[3943:3936];
      column_array[20] = bitmap[3935:3928];
      column_array[21] = bitmap[3927:3920];
      column_array[22] = bitmap[3919:3912];
      column_array[23] = bitmap[3911:3904];
      column_array[24] = bitmap[3903:3896];
      column_array[25] = bitmap[3895:3888];
      column_array[26] = bitmap[3887:3880];
      column_array[27] = bitmap[3879:3872];
      column_array[28] = bitmap[3871:3864];
      column_array[29] = bitmap[3863:3856];
      column_array[30] = bitmap[3855:3848];
      column_array[31] = bitmap[3847:3840];
      column_array[32] = bitmap[3839:3832];
      column_array[33] = bitmap[3831:3824];
      column_array[34] = bitmap[3823:3816];
      column_array[35] = bitmap[3815:3808];
      column_array[36] = bitmap[3807:3800];
      column_array[37] = bitmap[3799:3792];
      column_array[38] = bitmap[3791:3784];
      column_array[39] = bitmap[3783:3776];
      column_array[40] = bitmap[3775:3768];
      column_array[41] = bitmap[3767:3760];
      column_array[42] = bitmap[3759:3752];
      column_array[43] = bitmap[3751:3744];
      column_array[44] = bitmap[3743:3736];
      column_array[45] = bitmap[3735:3728];
      column_array[46] = bitmap[3727:3720];
      column_array[47] = bitmap[3719:3712];
      column_array[48] = bitmap[3711:3704];
      column_array[49] = bitmap[3703:3696];
      column_array[50] = bitmap[3695:3688];
      column_array[51] = bitmap[3687:3680];
      column_array[52] = bitmap[3679:3672];
      column_array[53] = bitmap[3671:3664];
      column_array[54] = bitmap[3663:3656];
      column_array[55] = bitmap[3655:3648];
      column_array[56] = bitmap[3647:3640];
      column_array[57] = bitmap[3639:3632];
      column_array[58] = bitmap[3631:3624];
      column_array[59] = bitmap[3623:3616];
      column_array[60] = bitmap[3615:3608];
      column_array[61] = bitmap[3607:3600];
      column_array[62] = bitmap[3599:3592];
      column_array[63] = bitmap[3591:3584];
      column_array[64] = bitmap[3583:3576];
      column_array[65] = bitmap[3575:3568];
      column_array[66] = bitmap[3567:3560];
      column_array[67] = bitmap[3559:3552];
      column_array[68] = bitmap[3551:3544];
      column_array[69] = bitmap[3543:3536];
      column_array[70] = bitmap[3535:3528];
      column_array[71] = bitmap[3527:3520];
      column_array[72] = bitmap[3519:3512];
      column_array[73] = bitmap[3511:3504];
      column_array[74] = bitmap[3503:3496];
      column_array[75] = bitmap[3495:3488];
      column_array[76] = bitmap[3487:3480];
      column_array[77] = bitmap[3479:3472];
      column_array[78] = bitmap[3471:3464];
      column_array[79] = bitmap[3463:3456];
      column_array[80] = bitmap[3455:3448];
      column_array[81] = bitmap[3447:3440];
      column_array[82] = bitmap[3439:3432];
      column_array[83] = bitmap[3431:3424];
      column_array[84] = bitmap[3423:3416];
      column_array[85] = bitmap[3415:3408];
      column_array[86] = bitmap[3407:3400];
      column_array[87] = bitmap[3399:3392];
      column_array[88] = bitmap[3391:3384];
      column_array[89] = bitmap[3383:3376];
      column_array[90] = bitmap[3375:3368];
      column_array[91] = bitmap[3367:3360];
      column_array[92] = bitmap[3359:3352];
      column_array[93] = bitmap[3351:3344];
      column_array[94] = bitmap[3343:3336];
      column_array[95] = bitmap[3335:3328];
      column_array[96] = bitmap[3327:3320];
      column_array[97] = bitmap[3319:3312];
      column_array[98] = bitmap[3311:3304];
      column_array[99] = bitmap[3303:3296];
      column_array[100] = bitmap[3295:3288];
      column_array[101] = bitmap[3287:3280];
      column_array[102] = bitmap[3279:3272];
      column_array[103] = bitmap[3271:3264];
      column_array[104] = bitmap[3263:3256];
      column_array[105] = bitmap[3255:3248];
      column_array[106] = bitmap[3247:3240];
      column_array[107] = bitmap[3239:3232];
      column_array[108] = bitmap[3231:3224];
      column_array[109] = bitmap[3223:3216];
      column_array[110] = bitmap[3215:3208];
      column_array[111] = bitmap[3207:3200];
      column_array[112] = bitmap[3199:3192];
      column_array[113] = bitmap[3191:3184];
      column_array[114] = bitmap[3183:3176];
      column_array[115] = bitmap[3175:3168];
      column_array[116] = bitmap[3167:3160];
      column_array[117] = bitmap[3159:3152];
      column_array[118] = bitmap[3151:3144];
      column_array[119] = bitmap[3143:3136];
      column_array[120] = bitmap[3135:3128];
      column_array[121] = bitmap[3127:3120];
      column_array[122] = bitmap[3119:3112];
      column_array[123] = bitmap[3111:3104];
      column_array[124] = bitmap[3103:3096];
      column_array[125] = bitmap[3095:3088];
      column_array[126] = bitmap[3087:3080];
      column_array[127] = bitmap[3079:3072];
      column_array[128] = bitmap[3071:3064];
      column_array[129] = bitmap[3063:3056];
      column_array[130] = bitmap[3055:3048];
      column_array[131] = bitmap[3047:3040];
      column_array[132] = bitmap[3039:3032];
      column_array[133] = bitmap[3031:3024];
      column_array[134] = bitmap[3023:3016];
      column_array[135] = bitmap[3015:3008];
      column_array[136] = bitmap[3007:3000];
      column_array[137] = bitmap[2999:2992];
      column_array[138] = bitmap[2991:2984];
      column_array[139] = bitmap[2983:2976];
      column_array[140] = bitmap[2975:2968];
      column_array[141] = bitmap[2967:2960];
      column_array[142] = bitmap[2959:2952];
      column_array[143] = bitmap[2951:2944];
      column_array[144] = bitmap[2943:2936];
      column_array[145] = bitmap[2935:2928];
      column_array[146] = bitmap[2927:2920];
      column_array[147] = bitmap[2919:2912];
      column_array[148] = bitmap[2911:2904];
      column_array[149] = bitmap[2903:2896];
      column_array[150] = bitmap[2895:2888];
      column_array[151] = bitmap[2887:2880];
      column_array[152] = bitmap[2879:2872];
      column_array[153] = bitmap[2871:2864];
      column_array[154] = bitmap[2863:2856];
      column_array[155] = bitmap[2855:2848];
      column_array[156] = bitmap[2847:2840];
      column_array[157] = bitmap[2839:2832];
      column_array[158] = bitmap[2831:2824];
      column_array[159] = bitmap[2823:2816];
      column_array[160] = bitmap[2815:2808];
      column_array[161] = bitmap[2807:2800];
      column_array[162] = bitmap[2799:2792];
      column_array[163] = bitmap[2791:2784];
      column_array[164] = bitmap[2783:2776];
      column_array[165] = bitmap[2775:2768];
      column_array[166] = bitmap[2767:2760];
      column_array[167] = bitmap[2759:2752];
      column_array[168] = bitmap[2751:2744];
      column_array[169] = bitmap[2743:2736];
      column_array[170] = bitmap[2735:2728];
      column_array[171] = bitmap[2727:2720];
      column_array[172] = bitmap[2719:2712];
      column_array[173] = bitmap[2711:2704];
      column_array[174] = bitmap[2703:2696];
      column_array[175] = bitmap[2695:2688];
      column_array[176] = bitmap[2687:2680];
      column_array[177] = bitmap[2679:2672];
      column_array[178] = bitmap[2671:2664];
      column_array[179] = bitmap[2663:2656];
      column_array[180] = bitmap[2655:2648];
      column_array[181] = bitmap[2647:2640];
      column_array[182] = bitmap[2639:2632];
      column_array[183] = bitmap[2631:2624];
      column_array[184] = bitmap[2623:2616];
      column_array[185] = bitmap[2615:2608];
      column_array[186] = bitmap[2607:2600];
      column_array[187] = bitmap[2599:2592];
      column_array[188] = bitmap[2591:2584];
      column_array[189] = bitmap[2583:2576];
      column_array[190] = bitmap[2575:2568];
      column_array[191] = bitmap[2567:2560];
      column_array[192] = bitmap[2559:2552];
      column_array[193] = bitmap[2551:2544];
      column_array[194] = bitmap[2543:2536];
      column_array[195] = bitmap[2535:2528];
      column_array[196] = bitmap[2527:2520];
      column_array[197] = bitmap[2519:2512];
      column_array[198] = bitmap[2511:2504];
      column_array[199] = bitmap[2503:2496];
      column_array[200] = bitmap[2495:2488];
      column_array[201] = bitmap[2487:2480];
      column_array[202] = bitmap[2479:2472];
      column_array[203] = bitmap[2471:2464];
      column_array[204] = bitmap[2463:2456];
      column_array[205] = bitmap[2455:2448];
      column_array[206] = bitmap[2447:2440];
      column_array[207] = bitmap[2439:2432];
      column_array[208] = bitmap[2431:2424];
      column_array[209] = bitmap[2423:2416];
      column_array[210] = bitmap[2415:2408];
      column_array[211] = bitmap[2407:2400];
      column_array[212] = bitmap[2399:2392];
      column_array[213] = bitmap[2391:2384];
      column_array[214] = bitmap[2383:2376];
      column_array[215] = bitmap[2375:2368];
      column_array[216] = bitmap[2367:2360];
      column_array[217] = bitmap[2359:2352];
      column_array[218] = bitmap[2351:2344];
      column_array[219] = bitmap[2343:2336];
      column_array[220] = bitmap[2335:2328];
      column_array[221] = bitmap[2327:2320];
      column_array[222] = bitmap[2319:2312];
      column_array[223] = bitmap[2311:2304];
      column_array[224] = bitmap[2303:2296];
      column_array[225] = bitmap[2295:2288];
      column_array[226] = bitmap[2287:2280];
      column_array[227] = bitmap[2279:2272];
      column_array[228] = bitmap[2271:2264];
      column_array[229] = bitmap[2263:2256];
      column_array[230] = bitmap[2255:2248];
      column_array[231] = bitmap[2247:2240];
      column_array[232] = bitmap[2239:2232];
      column_array[233] = bitmap[2231:2224];
      column_array[234] = bitmap[2223:2216];
      column_array[235] = bitmap[2215:2208];
      column_array[236] = bitmap[2207:2200];
      column_array[237] = bitmap[2199:2192];
      column_array[238] = bitmap[2191:2184];
      column_array[239] = bitmap[2183:2176];
      column_array[240] = bitmap[2175:2168];
      column_array[241] = bitmap[2167:2160];
      column_array[242] = bitmap[2159:2152];
      column_array[243] = bitmap[2151:2144];
      column_array[244] = bitmap[2143:2136];
      column_array[245] = bitmap[2135:2128];
      column_array[246] = bitmap[2127:2120];
      column_array[247] = bitmap[2119:2112];
      column_array[248] = bitmap[2111:2104];
      column_array[249] = bitmap[2103:2096];
      column_array[250] = bitmap[2095:2088];
      column_array[251] = bitmap[2087:2080];
      column_array[252] = bitmap[2079:2072];
      column_array[253] = bitmap[2071:2064];
      column_array[254] = bitmap[2063:2056];
      column_array[255] = bitmap[2055:2048];
      column_array[256] = bitmap[2047:2040];
      column_array[257] = bitmap[2039:2032];
      column_array[258] = bitmap[2031:2024];
      column_array[259] = bitmap[2023:2016];
      column_array[260] = bitmap[2015:2008];
      column_array[261] = bitmap[2007:2000];
      column_array[262] = bitmap[1999:1992];
      column_array[263] = bitmap[1991:1984];
      column_array[264] = bitmap[1983:1976];
      column_array[265] = bitmap[1975:1968];
      column_array[266] = bitmap[1967:1960];
      column_array[267] = bitmap[1959:1952];
      column_array[268] = bitmap[1951:1944];
      column_array[269] = bitmap[1943:1936];
      column_array[270] = bitmap[1935:1928];
      column_array[271] = bitmap[1927:1920];
      column_array[272] = bitmap[1919:1912];
      column_array[273] = bitmap[1911:1904];
      column_array[274] = bitmap[1903:1896];
      column_array[275] = bitmap[1895:1888];
      column_array[276] = bitmap[1887:1880];
      column_array[277] = bitmap[1879:1872];
      column_array[278] = bitmap[1871:1864];
      column_array[279] = bitmap[1863:1856];
      column_array[280] = bitmap[1855:1848];
      column_array[281] = bitmap[1847:1840];
      column_array[282] = bitmap[1839:1832];
      column_array[283] = bitmap[1831:1824];
      column_array[284] = bitmap[1823:1816];
      column_array[285] = bitmap[1815:1808];
      column_array[286] = bitmap[1807:1800];
      column_array[287] = bitmap[1799:1792];
      column_array[288] = bitmap[1791:1784];
      column_array[289] = bitmap[1783:1776];
      column_array[290] = bitmap[1775:1768];
      column_array[291] = bitmap[1767:1760];
      column_array[292] = bitmap[1759:1752];
      column_array[293] = bitmap[1751:1744];
      column_array[294] = bitmap[1743:1736];
      column_array[295] = bitmap[1735:1728];
      column_array[296] = bitmap[1727:1720];
      column_array[297] = bitmap[1719:1712];
      column_array[298] = bitmap[1711:1704];
      column_array[299] = bitmap[1703:1696];
      column_array[300] = bitmap[1695:1688];
      column_array[301] = bitmap[1687:1680];
      column_array[302] = bitmap[1679:1672];
      column_array[303] = bitmap[1671:1664];
      column_array[304] = bitmap[1663:1656];
      column_array[305] = bitmap[1655:1648];
      column_array[306] = bitmap[1647:1640];
      column_array[307] = bitmap[1639:1632];
      column_array[308] = bitmap[1631:1624];
      column_array[309] = bitmap[1623:1616];
      column_array[310] = bitmap[1615:1608];
      column_array[311] = bitmap[1607:1600];
      column_array[312] = bitmap[1599:1592];
      column_array[313] = bitmap[1591:1584];
      column_array[314] = bitmap[1583:1576];
      column_array[315] = bitmap[1575:1568];
      column_array[316] = bitmap[1567:1560];
      column_array[317] = bitmap[1559:1552];
      column_array[318] = bitmap[1551:1544];
      column_array[319] = bitmap[1543:1536];
      column_array[320] = bitmap[1535:1528];
      column_array[321] = bitmap[1527:1520];
      column_array[322] = bitmap[1519:1512];
      column_array[323] = bitmap[1511:1504];
      column_array[324] = bitmap[1503:1496];
      column_array[325] = bitmap[1495:1488];
      column_array[326] = bitmap[1487:1480];
      column_array[327] = bitmap[1479:1472];
      column_array[328] = bitmap[1471:1464];
      column_array[329] = bitmap[1463:1456];
      column_array[330] = bitmap[1455:1448];
      column_array[331] = bitmap[1447:1440];
      column_array[332] = bitmap[1439:1432];
      column_array[333] = bitmap[1431:1424];
      column_array[334] = bitmap[1423:1416];
      column_array[335] = bitmap[1415:1408];
      column_array[336] = bitmap[1407:1400];
      column_array[337] = bitmap[1399:1392];
      column_array[338] = bitmap[1391:1384];
      column_array[339] = bitmap[1383:1376];
      column_array[340] = bitmap[1375:1368];
      column_array[341] = bitmap[1367:1360];
      column_array[342] = bitmap[1359:1352];
      column_array[343] = bitmap[1351:1344];
      column_array[344] = bitmap[1343:1336];
      column_array[345] = bitmap[1335:1328];
      column_array[346] = bitmap[1327:1320];
      column_array[347] = bitmap[1319:1312];
      column_array[348] = bitmap[1311:1304];
      column_array[349] = bitmap[1303:1296];
      column_array[350] = bitmap[1295:1288];
      column_array[351] = bitmap[1287:1280];
      column_array[352] = bitmap[1279:1272];
      column_array[353] = bitmap[1271:1264];
      column_array[354] = bitmap[1263:1256];
      column_array[355] = bitmap[1255:1248];
      column_array[356] = bitmap[1247:1240];
      column_array[357] = bitmap[1239:1232];
      column_array[358] = bitmap[1231:1224];
      column_array[359] = bitmap[1223:1216];
      column_array[360] = bitmap[1215:1208];
      column_array[361] = bitmap[1207:1200];
      column_array[362] = bitmap[1199:1192];
      column_array[363] = bitmap[1191:1184];
      column_array[364] = bitmap[1183:1176];
      column_array[365] = bitmap[1175:1168];
      column_array[366] = bitmap[1167:1160];
      column_array[367] = bitmap[1159:1152];
      column_array[368] = bitmap[1151:1144];
      column_array[369] = bitmap[1143:1136];
      column_array[370] = bitmap[1135:1128];
      column_array[371] = bitmap[1127:1120];
      column_array[372] = bitmap[1119:1112];
      column_array[373] = bitmap[1111:1104];
      column_array[374] = bitmap[1103:1096];
      column_array[375] = bitmap[1095:1088];
      column_array[376] = bitmap[1087:1080];
      column_array[377] = bitmap[1079:1072];
      column_array[378] = bitmap[1071:1064];
      column_array[379] = bitmap[1063:1056];
      column_array[380] = bitmap[1055:1048];
      column_array[381] = bitmap[1047:1040];
      column_array[382] = bitmap[1039:1032];
      column_array[383] = bitmap[1031:1024];
      column_array[384] = bitmap[1023:1016];
      column_array[385] = bitmap[1015:1008];
      column_array[386] = bitmap[1007:1000];
      column_array[387] = bitmap[999:992];
      column_array[388] = bitmap[991:984];
      column_array[389] = bitmap[983:976];
      column_array[390] = bitmap[975:968];
      column_array[391] = bitmap[967:960];
      column_array[392] = bitmap[959:952];
      column_array[393] = bitmap[951:944];
      column_array[394] = bitmap[943:936];
      column_array[395] = bitmap[935:928];
      column_array[396] = bitmap[927:920];
      column_array[397] = bitmap[919:912];
      column_array[398] = bitmap[911:904];
      column_array[399] = bitmap[903:896];
      column_array[400] = bitmap[895:888];
      column_array[401] = bitmap[887:880];
      column_array[402] = bitmap[879:872];
      column_array[403] = bitmap[871:864];
      column_array[404] = bitmap[863:856];
      column_array[405] = bitmap[855:848];
      column_array[406] = bitmap[847:840];
      column_array[407] = bitmap[839:832];
      column_array[408] = bitmap[831:824];
      column_array[409] = bitmap[823:816];
      column_array[410] = bitmap[815:808];
      column_array[411] = bitmap[807:800];
      column_array[412] = bitmap[799:792];
      column_array[413] = bitmap[791:784];
      column_array[414] = bitmap[783:776];
      column_array[415] = bitmap[775:768];
      column_array[416] = bitmap[767:760];
      column_array[417] = bitmap[759:752];
      column_array[418] = bitmap[751:744];
      column_array[419] = bitmap[743:736];
      column_array[420] = bitmap[735:728];
      column_array[421] = bitmap[727:720];
      column_array[422] = bitmap[719:712];
      column_array[423] = bitmap[711:704];
      column_array[424] = bitmap[703:696];
      column_array[425] = bitmap[695:688];
      column_array[426] = bitmap[687:680];
      column_array[427] = bitmap[679:672];
      column_array[428] = bitmap[671:664];
      column_array[429] = bitmap[663:656];
      column_array[430] = bitmap[655:648];
      column_array[431] = bitmap[647:640];
      column_array[432] = bitmap[639:632];
      column_array[433] = bitmap[631:624];
      column_array[434] = bitmap[623:616];
      column_array[435] = bitmap[615:608];
      column_array[436] = bitmap[607:600];
      column_array[437] = bitmap[599:592];
      column_array[438] = bitmap[591:584];
      column_array[439] = bitmap[583:576];
      column_array[440] = bitmap[575:568];
      column_array[441] = bitmap[567:560];
      column_array[442] = bitmap[559:552];
      column_array[443] = bitmap[551:544];
      column_array[444] = bitmap[543:536];
      column_array[445] = bitmap[535:528];
      column_array[446] = bitmap[527:520];
      column_array[447] = bitmap[519:512];
      column_array[448] = bitmap[511:504];
      column_array[449] = bitmap[503:496];
      column_array[450] = bitmap[495:488];
      column_array[451] = bitmap[487:480];
      column_array[452] = bitmap[479:472];
      column_array[453] = bitmap[471:464];
      column_array[454] = bitmap[463:456];
      column_array[455] = bitmap[455:448];
      column_array[456] = bitmap[447:440];
      column_array[457] = bitmap[439:432];
      column_array[458] = bitmap[431:424];
      column_array[459] = bitmap[423:416];
      column_array[460] = bitmap[415:408];
      column_array[461] = bitmap[407:400];
      column_array[462] = bitmap[399:392];
      column_array[463] = bitmap[391:384];
      column_array[464] = bitmap[383:376];
      column_array[465] = bitmap[375:368];
      column_array[466] = bitmap[367:360];
      column_array[467] = bitmap[359:352];
      column_array[468] = bitmap[351:344];
      column_array[469] = bitmap[343:336];
      column_array[470] = bitmap[335:328];
      column_array[471] = bitmap[327:320];
      column_array[472] = bitmap[319:312];
      column_array[473] = bitmap[311:304];
      column_array[474] = bitmap[303:296];
      column_array[475] = bitmap[295:288];
      column_array[476] = bitmap[287:280];
      column_array[477] = bitmap[279:272];
      column_array[478] = bitmap[271:264];
      column_array[479] = bitmap[263:256];
      column_array[480] = bitmap[255:248];
      column_array[481] = bitmap[247:240];
      column_array[482] = bitmap[239:232];
      column_array[483] = bitmap[231:224];
      column_array[484] = bitmap[223:216];
      column_array[485] = bitmap[215:208];
      column_array[486] = bitmap[207:200];
      column_array[487] = bitmap[199:192];
      column_array[488] = bitmap[191:184];
      column_array[489] = bitmap[183:176];
      column_array[490] = bitmap[175:168];
      column_array[491] = bitmap[167:160];
      column_array[492] = bitmap[159:152];
      column_array[493] = bitmap[151:144];
      column_array[494] = bitmap[143:136];
      column_array[495] = bitmap[135:128];
      column_array[496] = bitmap[127:120];
      column_array[497] = bitmap[119:112];
      column_array[498] = bitmap[111:104];
      column_array[499] = bitmap[103:96];
      column_array[500] = bitmap[95:88];
      column_array[501] = bitmap[87:80];
      column_array[502] = bitmap[79:72];
      column_array[503] = bitmap[71:64];
      column_array[504] = bitmap[63:56];
      column_array[505] = bitmap[55:48];
      column_array[506] = bitmap[47:40];
      column_array[507] = bitmap[39:32];
      column_array[508] = bitmap[31:24];
      column_array[509] = bitmap[23:16];
      column_array[510] = bitmap[15:8];
      column_array[511] = bitmap[7:0];
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
